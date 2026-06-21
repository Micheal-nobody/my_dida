import 'package:isar_community/isar.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/errors/exceptions.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/checklist/repositories/checklist_repository.dart';

abstract class ChecklistLifecycleManager {
  Future<void> createChecklist(String name, int colorValue);
  Future<void> updateChecklist(Checklist checklist);
  Future<void> deleteChecklist(int id, {required String name});
}

class ChecklistLifecycleManagerImpl implements ChecklistLifecycleManager {
  ChecklistLifecycleManagerImpl({
    ChecklistRepository? checklistRepository,
    AppMessageService? messageService,
  }) : _checklistRepository =
           checklistRepository ?? getIt<ChecklistRepository>(),
       _messageService = messageService ?? getIt<AppMessageService>();

  final ChecklistRepository _checklistRepository;
  final AppMessageService _messageService;

  @override
  Future<void> createChecklist(String name, int colorValue) async {
    try {
      if (name.trim().isEmpty) {
        throw const ChecklistException('清单名称不能为空');
      }
      final checklist = Checklist(name: name, colorValue: colorValue);
      await _checklistRepository.addData(checklist);
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
      await _checklistRepository.addData(checklist); // put() updates if exists
      _messageService.showSuccess('清单更新成功！');
    } catch (e) {
      _messageService.showError('更新清单失败: $e');
      throw ChecklistException('Failed to update checklist: $e');
    }
  }

  @override
  Future<void> deleteChecklist(int id, {required String name}) async {
    try {
      final isar = getIt<Isar>();
      await isar.writeTxn(() async {
        // Find tasks referencing this checklistId
        final affectedTasks = await isar.tasks
            .where()
            .checklistIdEqualTo(id)
            .findAll();

        // Reassign affected tasks to Inbox (ID = 1)
        for (final task in affectedTasks) {
          task.checklistId = 1;
        }
        await isar.tasks.putAll(affectedTasks);

        // Delete the checklist itself
        await isar.checklists.delete(id);
      });
      _messageService.showSuccess('Deleted "$name"');
    } catch (e) {
      _messageService.showError('Error deleting: $e');
      throw ChecklistException('Failed to delete checklist: $e');
    }
  }
}
