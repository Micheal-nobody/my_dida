import 'package:my_dida/features/tasks/models/task.dart';

extension TaskFilter on List<Task> {
  List<Task> filterByPriority(TaskPriority priority) =>
      where((t) => t.priority == priority).toList();

  List<Task> filterByIsDone(bool doFilter) =>
      doFilter ? where((t) => !t.isDone).toList() : this;

  List<Task> filterByChecklistIds({
    required bool isCustomMode,
    required List<int> visibleChecklistIds,
  }) {
    if (!isCustomMode) return this;
    return where((t) => visibleChecklistIds.contains(t.checklistId)).toList();
  }
}
