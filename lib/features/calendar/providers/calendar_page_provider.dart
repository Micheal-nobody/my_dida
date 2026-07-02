import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/utils/performance_monitor.dart';
import 'package:my_dida/core/utils/rrule_util.dart';
import 'package:my_dida/core/utils/task_filter.dart';
import 'package:my_dida/features/calendar/models/calendar_page_config.dart';
import 'package:my_dida/features/calendar/models/task_calendar_view_data.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';

class CalendarPageProvider extends ChangeNotifier {
  CalendarPageProvider() {
    _loadConfig();
  }

  final Isar _isar = getIt<Isar>();
  CalendarPageConfig _config = CalendarPageConfig();
  CalendarPageConfig get config => _config;

  // 依赖的 Provider
  TaskProvider? _taskProvider;
  HabitProvider? _habitProvider;

  // 选中日期状态
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // 数据投影结果映射
  Map<DateTime, List<Task>> tasksForDates = {};
  Map<DateTime, List<Task>> allDayTasksForDates = {};
  List<Task> crossDayTasks = [];
  Map<DateTime, int> crossDayTaskCountForDates = {};
  Map<DateTime, List<Task>> futureTasks = {};
  Map<DateTime, bool> rruleHasMore = {};
  Map<DateTime, List<Habit>> habitsForDates = {};

  final Map<DateTime, int> _rruleBatchLimit = {};
  int _loadVersion = 0;

  List<DateTime> get visibleDates {
    final dates = <DateTime>[];
    final startDate = _selectedDate;
    final range = _config.viewMode == CalendarViewMode.week ? 7 : 3;

    for (var index = 0; index < range; index++) {
      dates.add(startDate.add(Duration(days: index)));
    }
    return dates;
  }

  List<DateTime> get loadRangeDates {
    if (_config.viewMode == CalendarViewMode.month) {
      final firstDay = DateTime(_selectedDate.year, _selectedDate.month);
      final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
      final days = lastDay.difference(firstDay).inDays + 1;
      return List.generate(days, (i) => firstDay.add(Duration(days: i)));
    } else {
      return visibleDates;
    }
  }

  // 暴露只读的 rruleBatchLimit 映射，方便需要时获取
  Map<DateTime, int> get rruleBatchLimit => Map.unmodifiable(_rruleBatchLimit);

  Future<void> _loadConfig() async {
    final existing = await _isar.calendarPageConfigs.where().findFirst();
    if (existing != null) {
      _config = existing;
    } else {
      await _isar.writeTxn(() async {
        await _isar.calendarPageConfigs.put(_config);
      });
    }
    notifyListeners();
  }

  // 更新底层依赖
  void updateDependencies(
    TaskProvider taskProvider,
    HabitProvider habitProvider,
  ) {
    final isFirstRun = _taskProvider == null || _habitProvider == null;
    final isTaskProviderChanged = _taskProvider != taskProvider;
    final isHabitProviderChanged = _habitProvider != habitProvider;

    // 当依赖发生改变时（包括初次注入），我们需要更新引用并重新加载投影数据
    if (isFirstRun || isTaskProviderChanged || isHabitProviderChanged) {
      // 如果不是初次运行，且只是换了引用，先移除旧监听
      if (_taskProvider != null && isTaskProviderChanged) {
        _taskProvider!.removeListener(_onDependencyChanged);
      }
      if (_habitProvider != null && isHabitProviderChanged) {
        _habitProvider!.removeListener(_onDependencyChanged);
      }

      _taskProvider = taskProvider;
      _habitProvider = habitProvider;

      _taskProvider!.addListener(_onDependencyChanged);
      _habitProvider!.addListener(_onDependencyChanged);

      _loadTasksForVisibleDates();
    }
  }

  @override
  void dispose() {
    _taskProvider?.removeListener(_onDependencyChanged);
    _habitProvider?.removeListener(_onDependencyChanged);
    super.dispose();
  }

  void _onDependencyChanged() {
    _loadTasksForVisibleDates();
  }

  Future<void> updateConfig({
    bool? showCompletedTasks,
    CalendarVisibleMode? visibleMode,
    List<int>? visibleChecklistIds,
    CalendarViewMode? viewMode,
    bool? isTimeFolded,
  }) async {
    if (showCompletedTasks != null) {
      _config.showCompletedTasks = showCompletedTasks;
    }
    if (visibleMode != null) _config.visibleMode = visibleMode;
    if (visibleChecklistIds != null) {
      _config.visibleChecklistIds = visibleChecklistIds;
    }
    if (viewMode != null) _config.viewMode = viewMode;
    if (isTimeFolded != null) _config.isTimeFolded = isTimeFolded;

    await _isar.writeTxn(() async {
      await _isar.calendarPageConfigs.put(_config);
    });

    // 配置变更通常需要重新加载/投影数据
    await _loadTasksForVisibleDates();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _loadTasksForVisibleDates();
  }

  void loadCalendarData() {
    _loadTasksForVisibleDates();
  }

  void loadMoreRRuleForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final current = _rruleBatchLimit[normalizedDate] ?? 5;
    _rruleBatchLimit[normalizedDate] = current + 5;
    _loadTasksForVisibleDates();
  }

  List<Task> _filterTasks(List<Task> tasks) => tasks
      .filterByIsDone(!_config.showCompletedTasks)
      .filterByChecklistIds(
        isCustomMode: _config.visibleMode == CalendarVisibleMode.custom,
        visibleChecklistIds: _config.visibleChecklistIds,
      );

  Future<void> _loadTasksForVisibleDates() async {
    final currentVersion = ++_loadVersion;

    if (_taskProvider == null || _habitProvider == null) {
      return;
    }

    await PerformanceMonitor.timeAsyncOperation(
      OperationName.calendar_load_tasks,
      () async {
        final habitsMap = <DateTime, List<Habit>>{};
        final rangeDates = loadRangeDates;
        if (rangeDates.isEmpty) {
          return;
        }

        final taskViewData = await PerformanceMonitor.timeAsyncOperation(
          OperationName.load_calendar_task_view,
          () => _taskProvider!.loadCalendarTaskViewData(
            visibleDates: rangeDates,
            rruleBatchLimit: _rruleBatchLimit,
          ),
        );

        // 如果在此期间有新的加载任务触发，直接废弃本次旧的加载结果
        if (currentVersion != _loadVersion) {
          return;
        }

        final allHabits = _habitProvider!.habits;

        for (final date in rangeDates) {
          final normalizedDate = DateTime(date.year, date.month, date.day);
          final habitsForDate = <Habit>[];

          for (final habit in allHabits) {
            var shouldShowToday = false;

            if (!habit.rrule.isNone) {
              final startTime = DateTime(
                habit.startDate.year,
                habit.startDate.month,
                habit.startDate.day,
                habit.remindTime.hour,
                habit.remindTime.minute,
              );
              final rangeStart = normalizedDate;
              final rangeEnd = normalizedDate.add(const Duration(days: 1));
              final occurrences = PerformanceMonitor.timeOperation(
                OperationName.rrule_habit_processing,
                () => RRuleUtil.getOccurrencesInRange(
                  startTime,
                  habit.rrule.toRRuleString() ?? '',
                  rangeStart,
                  rangeEnd,
                ),
              );
              shouldShowToday = occurrences.any(
                (occurrence) => occurrence.isAtSameMomentAs(normalizedDate),
              );
            } else {
              shouldShowToday = true;
            }

            if (shouldShowToday && !_habitProvider!.isTodayCompleted(habit)) {
              habitsForDate.add(habit);
            }
          }

          habitsMap[normalizedDate] = habitsForDate;
        }

        if (currentVersion != _loadVersion) {
          return;
        }

        _applyTaskViewData(taskViewData, habitsMap);
      },
    );

    PerformanceMonitor.printReport();
  }

  void _applyTaskViewData(
    TaskCalendarViewData taskViewData,
    Map<DateTime, List<Habit>> habitsMap,
  ) {
    tasksForDates = taskViewData.tasksForDates.map(
      (date, list) => MapEntry(date, _filterTasks(list)),
    );

    allDayTasksForDates = taskViewData.allDayTasksForDates.map(
      (date, list) => MapEntry(date, _filterTasks(list)),
    );

    crossDayTasks = _filterTasks(taskViewData.crossDayTasks);

    crossDayTaskCountForDates = {};
    for (final date in visibleDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      int count = 0;
      for (final task in crossDayTasks) {
        if (task.startTime != null && task.endTime != null) {
          final start = DateTime(
            task.startTime!.year,
            task.startTime!.month,
            task.startTime!.day,
          );
          final end = DateTime(
            task.endTime!.year,
            task.endTime!.month,
            task.endTime!.day,
          );
          if ((normalizedDate.isAtSameMomentAs(start) ||
                  normalizedDate.isAfter(start)) &&
              (normalizedDate.isAtSameMomentAs(end) ||
                  normalizedDate.isBefore(end))) {
            count++;
          }
        }
      }
      crossDayTaskCountForDates[normalizedDate] = count;
    }

    futureTasks = taskViewData.futureTasks.map(
      (date, list) => MapEntry(date, _filterTasks(list)),
    );

    rruleHasMore
      ..clear()
      ..addAll(taskViewData.rruleHasMore);

    for (final date in loadRangeDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      _rruleBatchLimit.putIfAbsent(normalizedDate, () => 5);
    }

    habitsForDates = habitsMap;

    notifyListeners();
  }
}
