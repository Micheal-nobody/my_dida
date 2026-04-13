import '../entity/task.dart';

class TaskCalendarViewData {
  const TaskCalendarViewData({
    required this.tasksForDates,
    required this.futureTasks,
    required this.rruleHasMore,
  });

  final Map<DateTime, List<Task>> tasksForDates;
  final Map<DateTime, List<Task>> futureTasks;
  final Map<DateTime, bool> rruleHasMore;
}
