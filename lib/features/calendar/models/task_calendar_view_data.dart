import 'package:my_dida/features/tasks/models/task.dart';

class TaskCalendarViewData {
  const TaskCalendarViewData({
    required this.tasksForDates,
    required this.allDayTasksForDates,
    required this.crossDayTasks,
    required this.crossDayTaskCountForDates,
    required this.futureTasks,
    required this.rruleHasMore,
  });

  final Map<DateTime, List<Task>> tasksForDates;
  final Map<DateTime, List<Task>> allDayTasksForDates;
  final List<Task> crossDayTasks;
  final Map<DateTime, int> crossDayTaskCountForDates;
  final Map<DateTime, List<Task>> futureTasks;
  final Map<DateTime, bool> rruleHasMore;
}
