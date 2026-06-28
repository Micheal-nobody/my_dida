import 'package:my_dida/features/tasks/models/task.dart';

extension TaskFilter on List<Task> {
  List<Task> filterByPriority(TaskPriority priority) =>
      where((t) => t.priority == priority).toList();

  List<Task> filterByIsDone(bool doFilter) =>
      doFilter ? where((t) => !t.isDone).toList() : this;
}
