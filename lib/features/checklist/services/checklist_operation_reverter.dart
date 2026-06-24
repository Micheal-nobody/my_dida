import 'dart:convert';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/features/checklist/repositories/checklist_repository.dart';
import 'package:my_dida/features/operation_undo/services/operation_reverter.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/repositories/task_repository.dart';

class ChecklistOperationReverter implements DomainOperationReverter {
  final ChecklistRepository _checklistRepo = getIt<ChecklistRepository>();
  final TaskRepository _taskRepo = getIt<TaskRepository>();

  @override
  Future<bool> revertAdd(int id) async {
    await _checklistRepo.deleteById(id);
    return true;
  }

  @override
  Future<bool> revertDelete(int id, String? previousData) async {
    if (previousData == null) return false;
    final decoded = jsonDecode(previousData);

    if (decoded is Map<String, dynamic> && decoded.containsKey('checklist')) {
      final checklist = Checklist.fromJson(decoded['checklist'] as Map<String, dynamic>);
      await _checklistRepo.insert(checklist);

      final List<dynamic>? affectedTaskIds = decoded['affectedTaskIds'];
      if (affectedTaskIds != null && affectedTaskIds.isNotEmpty) {
        final List<int> taskIds = affectedTaskIds.cast<int>().toList();
        final tasks = await _taskRepo.collection.getAll(taskIds);
        final validTasks = tasks.whereType<Task>().toList();
        for (final task in validTasks) {
          task.checklistId = checklist.id;
        }
        await _taskRepo.insertAll(validTasks);
      }
      return true;
    }
    return false;
  }

  @override
  Future<bool> revertUpdate(
    int id,
    String? previousData,
    String description,
  ) async {
    if (previousData == null) return false;
    final decoded = jsonDecode(previousData);
    final checklist = Checklist.fromJson(decoded as Map<String, dynamic>);
    await _checklistRepo.update(checklist);
    return true;
  }
}
