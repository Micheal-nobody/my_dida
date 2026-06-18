import 'dart:async';

class TaskNotificationNavigationService {
  final StreamController<int> _taskSelections =
      StreamController<int>.broadcast();
  int? _pendingTaskId;

  Stream<int> get taskSelections => _taskSelections.stream;

  void openTask(int taskId) {
    _pendingTaskId = taskId;
    _taskSelections.add(taskId);
  }

  int? consumePendingTaskId() {
    final pendingTaskId = _pendingTaskId;
    _pendingTaskId = null;
    return pendingTaskId;
  }

  Future<void> dispose() => _taskSelections.close();
}
