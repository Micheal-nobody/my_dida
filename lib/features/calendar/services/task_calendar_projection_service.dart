import 'package:my_dida/core/utils/rrule_util.dart';
import 'package:my_dida/features/calendar/models/task_calendar_view_data.dart';
import 'package:my_dida/features/tasks/models/task.dart';

/// Service class for assembling calendar-specific task visualization maps.
class TaskCalendarProjectionService {
  TaskCalendarViewData buildCalendarTaskViewData({
    required List<Task> tasks,
    required List<DateTime> visibleDates,
    required Map<DateTime, int> rruleBatchLimit,
    int futureHorizonDays = 30,
  }) {
    final tasksMap = <DateTime, List<Task>>{};
    final allDayTasksForDates = <DateTime, List<Task>>{};
    final crossDayTasks = _buildCrossDayTasks(tasks, visibleDates);
    final crossDayTaskCountForDates = <DateTime, int>{};
    final futureTasksMap = <DateTime, List<Task>>{};
    final rruleHasMore = <DateTime, bool>{};

    for (final date in visibleDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final tasksForDate = _buildTasksForDate(
        tasks: tasks,
        normalizedDate: normalizedDate,
        limit: rruleBatchLimit[normalizedDate] ?? 5,
      );

      tasksMap[normalizedDate] = tasksForDate.tasks;
      allDayTasksForDates[normalizedDate] = tasksForDate.tasks
          .where(
            (task) =>
                _shouldRenderInAllDaySection(task) && !_isCrossDayTask(task),
          )
          .toList();
      crossDayTaskCountForDates[normalizedDate] = crossDayTasks
          .where((task) => _doesCrossDayTaskOverlapDate(task, normalizedDate))
          .length;
      rruleHasMore[normalizedDate] = tasksForDate.hasMoreRRule;
    }

    if (visibleDates.isNotEmpty) {
      final lastVisibleDate = visibleDates.last;
      for (int i = 1; i <= futureHorizonDays; i++) {
        final date = lastVisibleDate.add(Duration(days: i));
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final futureTasks =
            tasks.where((task) {
              if (!task.rrule.isNone) {
                return false;
              }
              if (task.startTime == null || task.isDone) {
                return false;
              }

              final taskDate = DateTime(
                task.startTime!.year,
                task.startTime!.month,
                task.startTime!.day,
              );
              return taskDate.isAtSameMomentAs(normalizedDate);
            }).toList()..sort(
              (a, b) => (a.startTime ?? DateTime(0)).compareTo(
                b.startTime ?? DateTime(0),
              ),
            );

        if (futureTasks.isNotEmpty) {
          futureTasksMap[normalizedDate] = futureTasks;
        }
      }
    }

    return TaskCalendarViewData(
      tasksForDates: tasksMap,
      allDayTasksForDates: allDayTasksForDates,
      crossDayTasks: crossDayTasks,
      crossDayTaskCountForDates: crossDayTaskCountForDates,
      futureTasks: futureTasksMap,
      rruleHasMore: rruleHasMore,
    );
  }

  _TasksForDateResult _buildTasksForDate({
    required List<Task> tasks,
    required DateTime normalizedDate,
    required int limit,
  }) {
    final baseTasksForDate = tasks.where((task) {
      if (!task.rrule.isNone) {
        return false;
      }
      if (task.startTime == null) {
        return false;
      }
      final taskDate = DateTime(
        task.startTime!.year,
        task.startTime!.month,
        task.startTime!.day,
      );
      return taskDate.isAtSameMomentAs(normalizedDate);
    }).toList();

    final rruleTasksForDate = <Task>[];
    for (final task in tasks) {
      if (task.rrule.isNone || task.startTime == null) {
        continue;
      }

      final occurrences = RRuleUtil.getOccurrencesInRange(
        task.startTime!,
        task.rrule.toRRuleString() ?? '',
        normalizedDate,
        normalizedDate.add(const Duration(days: 1)),
      );

      if (!occurrences.any((date) => date.isAtSameMomentAs(normalizedDate))) {
        continue;
      }

      final instanceStart = DateTime(
        normalizedDate.year,
        normalizedDate.month,
        normalizedDate.day,
        task.startTime!.hour,
        task.startTime!.minute,
      );

      // 使用重构后的 copyWith 替代原本的私有构造拷贝方法
      final instance = task.copyWith(startTime: instanceStart);
      rruleTasksForDate.add(instance);
    }

    final combined = [
      ...baseTasksForDate,
      ...rruleTasksForDate,
    ].where((task) => !task.isDone).toList();

    final allDayTasks = combined.where((task) => task.isAllDay).toList();
    final timedNonRRuleTasks =
        combined.where((task) => task.rrule.isNone && !task.isAllDay).toList()
          ..sort(
            (a, b) => (a.startTime ?? DateTime(0)).compareTo(
              b.startTime ?? DateTime(0),
            ),
          );

    final timedRRuleTasks =
        combined.where((task) => !task.rrule.isNone && !task.isAllDay).toList()
          ..sort(
            (a, b) => (a.startTime ?? DateTime(0)).compareTo(
              b.startTime ?? DateTime(0),
            ),
          );

    return _TasksForDateResult(
      tasks: [
        ...allDayTasks,
        ...timedNonRRuleTasks,
        ...timedRRuleTasks.take(limit),
      ],
      hasMoreRRule: timedRRuleTasks.length > limit,
    );
  }

  List<Task> _buildCrossDayTasks(
    List<Task> tasks,
    List<DateTime> visibleDates,
  ) {
    if (visibleDates.isEmpty) {
      return const [];
    }

    final normalizedVisibleDates = visibleDates
        .map((date) => DateTime(date.year, date.month, date.day))
        .toList();
    final firstVisibleDate = normalizedVisibleDates.first;
    final lastVisibleDate = normalizedVisibleDates.last;

    return tasks
        .where(
          (task) =>
              !task.isDone &&
              _isCrossDayTask(task) &&
              _doesTaskOverlapVisibleRange(
                task,
                firstVisibleDate,
                lastVisibleDate,
              ),
        )
        .toList()
      ..sort((a, b) {
        final startComparison = (a.startTime ?? DateTime(0)).compareTo(
          b.startTime ?? DateTime(0),
        );
        if (startComparison != 0) {
          return startComparison;
        }
        return a.id.compareTo(b.id);
      });
  }

  bool _shouldRenderInAllDaySection(Task task) {
    if (task.startTime == null) {
      return true;
    }

    return task.isAllDay;
  }

  bool _isCrossDayTask(Task task) {
    if (task.startTime == null || task.endTime == null) {
      return false;
    }

    final startTime = task.startTime!;
    final endTime = task.endTime!;
    final sameDay =
        startTime.year == endTime.year &&
        startTime.month == endTime.month &&
        startTime.day == endTime.day;
    final isCrossDay = !sameDay && endTime.isAfter(startTime);
    final isOver24Hours = endTime.difference(startTime).inHours > 24;
    return isCrossDay || isOver24Hours;
  }

  bool _doesTaskOverlapVisibleRange(
    Task task,
    DateTime firstVisibleDate,
    DateTime lastVisibleDate,
  ) {
    final startTime = task.startTime;
    final endTime = task.endTime;
    if (startTime == null || endTime == null) {
      return false;
    }

    final startDate = DateTime(startTime.year, startTime.month, startTime.day);
    final endDate = DateTime(endTime.year, endTime.month, endTime.day);
    return !startDate.isAfter(lastVisibleDate) &&
        !endDate.isBefore(firstVisibleDate);
  }

  bool _doesCrossDayTaskOverlapDate(Task task, DateTime normalizedDate) {
    final startTime = task.startTime;
    final endTime = task.endTime;
    if (startTime == null || endTime == null) {
      return false;
    }

    final startDate = DateTime(startTime.year, startTime.month, startTime.day);
    final endDate = DateTime(endTime.year, endTime.month, endTime.day);
    return !normalizedDate.isBefore(startDate) &&
        !normalizedDate.isAfter(endDate);
  }
}

class _TasksForDateResult {
  const _TasksForDateResult({required this.tasks, required this.hasMoreRRule});

  final List<Task> tasks;
  final bool hasMoreRRule;
}
