import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/errors/exceptions.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/features/checklist/repositories/checklist_repository.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';
import 'package:my_dida/features/operation_undo/providers/operation_stack_provider.dart';
import 'package:my_dida/features/tasks/repositories/task_repository.dart';

abstract class ChecklistLifecycleManager {
  Future<void> createChecklist(String name, int colorValue);

  Future<void> updateChecklist(Checklist checklist);

  Future<void> deleteChecklist(int id, {required String name});
}

class ChecklistLifecycleManagerImpl implements ChecklistLifecycleManager {
  ChecklistLifecycleManagerImpl({
    ChecklistRepository? checklistRepository,
    TaskRepository? taskRepository,
    OperationStackProvider? operationStack,
    AppMessageService? messageService,
  }) : _checklistRepository =
           checklistRepository ?? getIt<ChecklistRepository>(),
       _taskRepository = taskRepository ?? getIt<TaskRepository>(),
       _operationStack =
           operationStack ??
           (getIt.isRegistered<OperationStackProvider>()
               ? getIt<OperationStackProvider>()
               : null),
       _messageService = messageService ?? getIt<AppMessageService>();

  final ChecklistRepository _checklistRepository;
  final TaskRepository _taskRepository;
  final OperationStackProvider? _operationStack;
  final AppMessageService _messageService;

  @override
  Future<void> createChecklist(String name, int colorValue) async {
    try {
      if (name.trim().isEmpty) {
        throw const ChecklistException('清单名称不能为空');
      }
      final checklist = Checklist(name: name, colorValue: colorValue);
      final id = await _checklistRepository.insert(checklist);

      checklist.id = id;
      if (_operationStack != null) {
        await _operationStack.addOperation(
          Operation.createAddChecklistOperation(checklist),
        );
      }

      _messageService.showSuccess('清单创建成功！');
    } catch (e) {
      _messageService.showError('创建清单失败: $e');
      throw ChecklistException('Failed to create checklist: $e');
    }
  }

  @override
  Future<void> updateChecklist(Checklist checklist) async {
    try {
      if (checklist.name.trim().isEmpty) {
        throw const ChecklistException('清单名称不能为空');
      }
      final oldChecklist = await _checklistRepository.selectById(checklist.id);

      await _checklistRepository.update(checklist);

      if (oldChecklist != null && _operationStack != null) {
        await _operationStack.addOperation(
          Operation.createUpdateChecklistOperation(
            oldChecklist,
            checklist,
            '修改了清单"${checklist.name}"的配置',
          ),
        );
      }

      _messageService.showSuccess('清单更新成功！');
    } catch (e) {
      _messageService.showError('更新清单失败: $e');
      throw ChecklistException('Failed to update checklist: $e');
    }
  }

  @override
  Future<void> deleteChecklist(int id, {required String name}) async {
    try {
      final checklist = await _checklistRepository.selectById(id);
      if (checklist == null) {
        throw const ChecklistException('清单不存在');
      }

      final affectedTasks = await _taskRepository.getTasksByChecklistId(id);
      final affectedTaskIds = affectedTasks.map((t) => t.id).toList();

      // Reassign affected tasks to Inbox (ID = 1)
      for (final task in affectedTasks) {
        task.checklistId = 1;
      }
      await _taskRepository.insertAll(affectedTasks);

      // Delete the checklist itself
      await _checklistRepository.deleteById(id);

      // Save delete operation snapshot
      if (_operationStack != null) {
        await _operationStack.addOperation(
          Operation.createDeleteChecklistOperation(checklist, affectedTaskIds),
        );
      }

      _messageService.showSuccess('Deleted "$name"');
    } catch (e) {
      _messageService.showError('Error deleting: $e');
      throw ChecklistException('Failed to delete checklist: $e');
    }
  }
}
