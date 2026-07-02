import 'dart:convert';

import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/features/operation_undo/services/operation_reverter.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/repositories/task_repository.dart';

import 'package:my_dida/features/tasks/services/task_reminder_service.dart';

class TaskOperationReverter implements DomainOperationReverter {
  TaskRepository get _taskRepo => getIt<TaskRepository>();
  TaskReminderService get _taskReminderService => getIt<TaskReminderService>();

  @override
  Future<bool> revertAdd(int id) async {
    final taskToDelete = await _taskRepo.selectById(id);
    if (taskToDelete != null && taskToDelete.parentTaskId != null) {
      final parent = await _taskRepo.selectById(taskToDelete.parentTaskId!);
      if (parent != null) {
        final newIds = List<int>.from(parent.subTaskIds)
          ..remove(taskToDelete.id);
        await _taskRepo.update(parent..subTaskIds = newIds);
      }
    }
    await _taskRepo.deleteById(id);
    await _taskReminderService.cancelReminder(id);
    return true;
  }

  @override
  Future<bool> revertDelete(int id, String? previousData) async {
    if (previousData == null) return false;
    final decoded = jsonDecode(previousData);
    final task = Task.fromJson(decoded as Map<String, dynamic>);
    await _taskRepo.insert(task);

    if (task.parentTaskId != null) {
      final parent = await _taskRepo.selectById(task.parentTaskId!);
      if (parent != null) {
        final newIds = List<int>.from(parent.subTaskIds);
        if (!newIds.contains(task.id)) {
          newIds.add(task.id);
          await _taskRepo.update(parent..subTaskIds = newIds);
        }
      }
    }
    await _taskReminderService.syncReminder(task);
    return true;
  }

  @override
  Future<bool> revertUpdate(
    int id,
    String? previousData,
    String description,
  ) async {
    if (previousData == null) return false;
    final decoded = jsonDecode(previousData);
    final task = Task.fromJson(decoded as Map<String, dynamic>);
    await _taskRepo.update(task);
    await _taskReminderService.syncReminder(task);
    return true;
  }
}
