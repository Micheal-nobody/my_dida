import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_dida/core/constants/app_constants.dart';
import 'package:my_dida/features/calendar/widgets/calendar_all_day_task_section.dart';
import 'package:my_dida/features/calendar/widgets/calendar_time_task_section.dart';
import 'package:my_dida/features/calendar/widgets/calendar_widgets/calendar_date_header.dart';
import 'package:my_dida/features/calendar/widgets/calendar_widgets/calendar_entry_card.dart';
import 'package:my_dida/features/habits/widgets/habit_check_in_dialog.dart';
import 'package:my_dida/features/tasks/pages/task_detail_page.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/calendar/models/task_calendar_view_data.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/calendar/providers/calendar_page_provider.dart';
import 'package:my_dida/features/calendar/models/calendar_page_config.dart';
import 'package:my_dida/features/calendar/widgets/calendar_visible_range_dialog.dart';
import 'package:my_dida/features/tasks/widgets/add_task_dialog.dart';
import 'package:my_dida/features/calendar/widgets/calendar_widgets/calendar_task_list_bottom.dart';
import 'package:my_dida/shared/widgets/datetime/calendar_grid.dart';
import 'package:my_dida/shared/widgets/datetime/custom_date_picker_dialog.dart';
import 'package:my_dida/shared/widgets/datetime/time_axis_column.dart';
import 'package:my_dida/core/utils/performance_monitor.dart';
import 'package:my_dida/core/utils/rrule_util.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const double _timeAxisWidth = 60.0;
  static const double _timeAxisGap = 8.0;
  static const double _timeAreaHeight = 1440.0;
  static const double _timeAxisSpacerHeight = 4000.0;
  static const double _timedEntryHeight = 15.0;
  static const double _allDayEntryHeight = 28.0;

  late final DateTime _currentDate;
  late DateTime _selectedDate;
  int _dateRange = 3;
  Map<DateTime, List<Task>> _tasksForDates = {};
  Map<DateTime, List<Task>> _allDayTasksForDates = {};
  List<Task> _crossDayTasks = [];
  Map<DateTime, int> _crossDayTaskCountForDates = {};
  Map<DateTime, List<Task>> _futureTasks = {};
  Map<DateTime, List<Habit>> _habitsForDates = {};
  DateTime? _dragPreviewTime;
  double _timeContentScrollOffset = 0;
  late TaskProvider _taskProvider;
  late HabitProvider _habitProvider;
  late CalendarPageProvider _calendarPageProvider;

  final Map<DateTime, int> _rruleBatchLimit = {};
  final Map<DateTime, bool> _rruleHasMore = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentDate = now;
    _selectedDate = now;
    _taskProvider = Provider.of<TaskProvider>(context, listen: false);
    _habitProvider = Provider.of<HabitProvider>(context, listen: false);
    _calendarPageProvider = Provider.of<CalendarPageProvider>(
      context,
      listen: false,
    );
    _loadTasksForVisibleDates();
    _taskProvider.addListener(_onTaskProviderChanged);
    _habitProvider.addListener(_onTaskProviderChanged);
    _calendarPageProvider.addListener(_onTaskProviderChanged);
  }

  @override
  void dispose() {
    _taskProvider.removeListener(_onTaskProviderChanged);
    _habitProvider.removeListener(_onTaskProviderChanged);
    _calendarPageProvider.removeListener(_onTaskProviderChanged);
    super.dispose();
  }

  void _onTaskProviderChanged() {
    _loadTasksForVisibleDates();
  }

  List<DateTime> get _visibleDates {
    final config = _calendarPageProvider.config;
    final dates = <DateTime>[];
    final startDate = _selectedDate;
    final range = config.viewMode == 'week' ? 7 : 3;

    for (var index = 0; index < range; index++) {
      dates.add(startDate.add(Duration(days: index)));
    }
    return dates;
  }

  List<DateTime> get _loadRangeDates {
    final config = _calendarPageProvider.config;
    if (config.viewMode == 'month') {
      final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
      final days = lastDay.difference(firstDay).inDays + 1;
      return List.generate(days, (i) => firstDay.add(Duration(days: i)));
    } else {
      return _visibleDates;
    }
  }

  List<Task> _filterTasks(List<Task> tasks, CalendarPageConfig config) {
    return tasks.where((task) {
      if (!config.showCompletedTasks && task.isDone) {
        return false;
      }
      if (config.visibleMode == 'custom') {
        if (!config.visibleChecklistIds.contains(task.checklistId)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _loadTasksForVisibleDates() async {
    await PerformanceMonitor.timeAsyncOperation(
      'calendar_load_tasks',
      () async {
        final habitProvider = Provider.of<HabitProvider>(
          context,
          listen: false,
        );
        final habitsMap = <DateTime, List<Habit>>{};
        final visibleDates = _loadRangeDates;
        if (visibleDates.isEmpty) {
          return;
        }

        final taskViewData = await PerformanceMonitor.timeAsyncOperation(
          'load_calendar_task_view',
          () => _taskProvider.loadCalendarTaskViewData(
            visibleDates: visibleDates,
            rruleBatchLimit: _rruleBatchLimit,
          ),
        );

        final allHabits = habitProvider.habits;

        for (final date in visibleDates) {
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
                'rrule_habit_processing',
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

            if (shouldShowToday && !habitProvider.isTodayCompleted(habit)) {
              habitsForDate.add(habit);
            }
          }

          habitsMap[normalizedDate] = habitsForDate;
        }

        setState(() {
          _applyTaskViewData(taskViewData);
          _habitsForDates = habitsMap;
        });
      },
    );

    PerformanceMonitor.printReport();
  }

  void _loadMoreRRuleForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final current = _rruleBatchLimit[normalizedDate] ?? 5;
    _rruleBatchLimit[normalizedDate] = current + 5;
    _loadTasksForVisibleDates();
  }

  void _applyTaskViewData(TaskCalendarViewData taskViewData) {
    final config = _calendarPageProvider.config;

    _tasksForDates = taskViewData.tasksForDates.map((date, list) {
      return MapEntry(date, _filterTasks(list, config));
    });

    _allDayTasksForDates = taskViewData.allDayTasksForDates.map((date, list) {
      return MapEntry(date, _filterTasks(list, config));
    });

    _crossDayTasks = _filterTasks(taskViewData.crossDayTasks, config);

    _crossDayTaskCountForDates = {};
    for (final date in _visibleDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      int count = 0;
      for (final task in _crossDayTasks) {
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
      _crossDayTaskCountForDates[normalizedDate] = count;
    }

    _futureTasks = taskViewData.futureTasks.map((date, list) {
      return MapEntry(date, _filterTasks(list, config));
    });

    _rruleHasMore
      ..clear()
      ..addAll(taskViewData.rruleHasMore);

    for (final date in _loadRangeDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      _rruleBatchLimit.putIfAbsent(normalizedDate, () => 5);
    }
  }

  void _showDatePicker() {
    showDialog(
      context: context,
      builder: (context) => CustomDatePickerDialog(
        selectedDate: _selectedDate,
        onDateSelected: _setSelectedDate,
      ),
    );
  }

  void _setSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadTasksForVisibleDates();
  }

  List<Task> _getSelectedDateTasks() {
    final normalizedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final tasks = _tasksForDates[normalizedDate] ?? [];
    final allDayTasks = _allDayTasksForDates[normalizedDate] ?? [];
    return [...allDayTasks, ...tasks];
  }

  Widget _buildCalendarDay(
    BuildContext context,
    DateTime date,
    bool isSelected,
  ) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final tasks = _tasksForDates[normalizedDate] ?? [];
    final allDayTasks = _allDayTasksForDates[normalizedDate] ?? [];
    final totalTasks = [...tasks, ...allDayTasks];

    final colors = <Color>{};
    for (final task in totalTasks) {
      colors.add(_getTaskColor(context, task));
      if (colors.length >= 3) break;
    }

    final isToday =
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Colors.blue
                  : (isToday
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.transparent),
            ),
            child: Center(
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isToday ? Colors.blue : Colors.black),
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: colors
                .map(
                  (color) => Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  void _handleDragPreviewChanged(DateTime? previewTime) {
    if (_dragPreviewTime == previewTime) {
      return;
    }

    setState(() {
      _dragPreviewTime = previewTime;
    });
  }

  void _handleTimeContentScrollOffsetChanged(double offset) {
    if ((_timeContentScrollOffset - offset).abs() < 0.5) {
      return;
    }

    setState(() {
      _timeContentScrollOffset = offset;
    });
  }

  Color _getTaskColor(BuildContext context, Task task) {
    final checklistProvider = Provider.of<ChecklistProvider>(
      context,
      listen: false,
    );
    final checklist = checklistProvider.allCheckLists.firstWhere(
      (item) => item.id == task.checklistId,
      orElse: () => AppConstants.defaultCheckList,
    );
    return checklist.color;
  }

  Widget _buildTimedTaskEntry(
    BuildContext context, {
    required Task task,
    required double columnWidth,
  }) {
    if (task.startTime == null) {
      return const SizedBox.shrink();
    }

    final taskColor = _getTaskColor(context, task);

    Widget buildCard({
      required Color backgroundColor,
      Color? borderColor,
      required VoidCallback onPressed,
    }) => SizedBox(
      width: columnWidth,
      height: _timedEntryHeight,
      child: CalendarEntryCard(
        text: task.name,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        onPressed: onPressed,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        opacity: task.isDone ? 0.4 : 1,
      ),
    );

    return Draggable<Task>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: buildCard(
          backgroundColor: taskColor.withValues(alpha: 0.9),
          onPressed: () {},
        ),
      ),
      childWhenDragging: buildCard(
        backgroundColor: taskColor.withValues(alpha: 0.3),
        borderColor: taskColor,
        onPressed: () {},
      ),
      child: buildCard(
        backgroundColor: taskColor.withValues(alpha: 0.8),
        onPressed: () {
          TaskDetailPage.show(context, task);
        },
      ),
    );
  }

  Widget _buildTimedHabitEntry(
    BuildContext context, {
    required Habit habit,
    required double columnWidth,
  }) => SizedBox(
    width: columnWidth,
    child: CalendarEntryCard(
      text: habit.name,
      backgroundColor: Colors.orange.withValues(alpha: 0.8),
      onPressed: () {
        HabitCheckInDialog.show(context: context, habit: habit);
      },
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    ),
  );

  Widget _buildAllDayTaskEntry(
    BuildContext context, {
    required Task task,
    required double columnWidth,
    required int stackIndex,
    required double availableHeight,
    required int displayedCount,
    required bool isCrossDay,
    double left = 0,
    double? width,
  }) {
    final taskColor = _getTaskColor(context, task);

    if (isCrossDay) {
      return Positioned(
        left: left,
        top: stackIndex * _allDayEntryHeight,
        width: width ?? columnWidth,
        height: _allDayEntryHeight,
        child: CalendarEntryCard(
          text: task.name,
          backgroundColor: taskColor.withValues(alpha: 0.9),
          onPressed: () {
            TaskDetailPage.show(context, task);
          },
          padding: const EdgeInsets.symmetric(horizontal: 6),
          borderRadius: 6,
          alignment: Alignment.centerLeft,
          textStyle: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          opacity: task.isDone ? 0.4 : 1,
        ),
      );
    }

    final taskCount = displayedCount.clamp(1, 6);
    const taskSpacing = 1.0;
    final totalSpacing = (taskCount - 1) * taskSpacing;
    final taskHeight = (availableHeight - totalSpacing) / taskCount;
    final topPosition = stackIndex * (taskHeight + taskSpacing);

    Widget buildCard({
      required Color backgroundColor,
      Color? borderColor,
      required VoidCallback onPressed,
    }) => SizedBox(
      width: width ?? columnWidth,
      height: taskHeight,
      child: CalendarEntryCard(
        text: task.name,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        onPressed: onPressed,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        useFittedBox: true,
        opacity: task.isDone ? 0.4 : 1,
      ),
    );

    return Positioned(
      top: topPosition,
      left: left,
      width: width ?? columnWidth,
      height: taskHeight,
      child: Draggable<Task>(
        data: task,
        feedback: Material(
          color: Colors.transparent,
          child: buildCard(
            backgroundColor: taskColor.withValues(alpha: 0.9),
            onPressed: () {},
          ),
        ),
        childWhenDragging: buildCard(
          backgroundColor: taskColor.withValues(alpha: 0.3),
          borderColor: taskColor,
          onPressed: () {},
        ),
        child: buildCard(
          backgroundColor: taskColor.withValues(alpha: 0.8),
          onPressed: () {
            TaskDetailPage.show(context, task);
          },
        ),
      ),
    );
  }

  Widget _buildAllDayHabitEntry(
    BuildContext context, {
    required Habit habit,
    required double columnWidth,
    required int stackIndex,
    required double availableHeight,
    required int displayedCount,
  }) {
    final topPosition = stackIndex * _allDayEntryHeight;
    if (topPosition + _allDayEntryHeight > availableHeight) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      top: topPosition,
      width: columnWidth,
      height: _allDayEntryHeight,
      child: CalendarEntryCard(
        text: habit.name,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        onPressed: () {
          HabitCheckInDialog.show(context: context, habit: habit);
        },
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        borderRadius: 6,
        alignment: Alignment.centerLeft,
        textStyle: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<int> _getActiveHours() {
    final config = _calendarPageProvider.config;
    if (!config.isTimeFolded) {
      return List.generate(24, (i) => i);
    }

    final activeHours = <int>{};
    for (final date in _visibleDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final tasks = _tasksForDates[normalizedDate] ?? [];
      for (final task in tasks) {
        if (task.startTime != null && !task.isAllDay) {
          activeHours.add(task.startTime!.hour);
        }
      }
      final habits = _habitsForDates[normalizedDate] ?? [];
      for (final habit in habits) {
        activeHours.add(habit.remindTime.hour);
      }
    }

    if (activeHours.isEmpty) {
      return List.generate(10, (i) => 9 + i);
    }

    final sorted = activeHours.toList()..sort();
    return sorted;
  }

  Widget _buildTimeAxisViewport(List<int> activeHours) => ClipRect(
    child: IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, -_timeContentScrollOffset),
        child: OverflowBox(
          minHeight: 0.0,
          maxHeight: activeHours.length * 60.0,
          alignment: Alignment.topCenter,
          child: TimeAxisColumn(
            width: _timeAxisWidth,
            previewTime: _dragPreviewTime,
            hours: activeHours,
            hourHeight: 60.0,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final calendarPageProvider = Provider.of<CalendarPageProvider>(context);
    final config = calendarPageProvider.config;
    final activeHours = _getActiveHours();
    final dynamicTimeAreaHeight = activeHours.length * 60.0;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showDatePicker,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('yyyy年M月').format(_selectedDate),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: Icon(Icons.refresh, color: Colors.grey[600]),
            onPressed: _loadTasksForVisibleDates,
          ),
          IconButton(
            tooltip: '视图模式',
            icon: Icon(
              config.viewMode == 'month'
                  ? Icons.view_module
                  : (config.viewMode == 'week'
                        ? Icons.view_week
                        : Icons.view_day),
              color: Colors.grey[600],
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            '切换日历视图',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.view_module,
                            color: Colors.orange,
                          ),
                          title: const Text('月视图'),
                          trailing: config.viewMode == 'month'
                              ? const Icon(Icons.check, color: Colors.orange)
                              : null,
                          onTap: () {
                            calendarPageProvider.updateConfig(
                              viewMode: 'month',
                            );
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.view_week,
                            color: Colors.orange,
                          ),
                          title: const Text('周视图 (7天)'),
                          trailing: config.viewMode == 'week'
                              ? const Icon(Icons.check, color: Colors.orange)
                              : null,
                          onTap: () {
                            calendarPageProvider.updateConfig(viewMode: 'week');
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.view_day,
                            color: Colors.orange,
                          ),
                          title: const Text('3天视图'),
                          trailing: config.viewMode == '3day'
                              ? const Icon(Icons.check, color: Colors.orange)
                              : null,
                          onTap: () {
                            calendarPageProvider.updateConfig(viewMode: '3day');
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            onSelected: (value) {
              if (value == 'visible_range') {
                CalendarVisibleRangeDialog.show(context);
              } else if (value == 'show_completed') {
                calendarPageProvider.updateConfig(
                  showCompletedTasks: !config.showCompletedTasks,
                );
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem<String>(
                  value: 'visible_range',
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('显示范围'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'show_completed',
                  child: Row(
                    children: [
                      Icon(
                        config.showCompletedTasks
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      const Text('显示完成任务'),
                    ],
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: config.viewMode == 'month'
          ? Column(
              children: [
                CalendarGrid(
                  selectedDate: _selectedDate,
                  showHeader: false,
                  onDateSelected: _setSelectedDate,
                  dayBuilder: _buildCalendarDay,
                ),
                GestureDetector(
                  onTap: () {
                    calendarPageProvider.updateConfig(
                      isTimeFolded: !config.isTimeFolded,
                    );
                  },
                  child: Container(
                    height: 12,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CalendarTaskListBottom(
                    selectedDate: _selectedDate,
                    tasks: _getSelectedDateTasks(),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                CalendarDateHeader(
                  selectedDate: _selectedDate,
                  dateRange: config.viewMode == 'week' ? 7 : 3,
                  tasksForDates: _tasksForDates,
                  onDateSelected: _setSelectedDate,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: _timeAxisWidth),
                    const SizedBox(width: _timeAxisGap),
                    Expanded(
                      child: CalendarAllDayTaskSection(
                        visibleDates: _visibleDates,
                        habitsForDates: _habitsForDates,
                        allDayTasksForDates: _allDayTasksForDates,
                        crossDayTasks: _crossDayTasks,
                        crossDayTaskCountForDates: _crossDayTaskCountForDates,
                        allDayTaskEntryBuilder: _buildAllDayTaskEntry,
                        allDayHabitEntryBuilder: _buildAllDayHabitEntry,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _timeAxisWidth,
                        child: _buildTimeAxisViewport(activeHours),
                      ),
                      const SizedBox(width: _timeAxisGap),
                      Expanded(
                        child: CalendarTimeTaskSection(
                          selectedDate: _selectedDate,
                          visibleDates: _visibleDates,
                          tasksForDates: _tasksForDates,
                          habitsForDates: _habitsForDates,
                          futureTasks: _futureTasks,
                          rruleHasMore: _rruleHasMore,
                          onLoadMoreRRule: _loadMoreRRuleForDate,
                          onDateChanged: _setSelectedDate,
                          timeAreaHeight: dynamicTimeAreaHeight,
                          timedTaskEntryBuilder: _buildTimedTaskEntry,
                          timedHabitEntryBuilder: _buildTimedHabitEntry,
                          onDragPreviewChanged: _handleDragPreviewChanged,
                          onScrollOffsetChanged:
                              _handleTimeContentScrollOffsetChanged,
                          hours: activeHours,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: AddTaskDialog(
                presetTask: Task(
                  name: '',
                  isAllDay: true,
                  startTime: _selectedDate,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
