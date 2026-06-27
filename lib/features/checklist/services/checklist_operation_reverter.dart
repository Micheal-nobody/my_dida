import 'dart:convert';

import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/features/checklist/repositories/checklist_repository.dart';
import 'package:my_dida/core/events/event_bus.dart';
import 'package:my_dida/features/checklist/events/checklist_events.dart';
import 'package:my_dida/features/operation_undo/services/operation_reverter.dart';

class ChecklistOperationReverter implements DomainOperationReverter {
  final ChecklistRepository _checklistRepo = getIt<ChecklistRepository>();
  final EventBus _eventBus = getIt<EventBus>();

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
      final checklist = Checklist.fromJson(
        decoded['checklist'] as Map<String, dynamic>,
      );
      await _checklistRepo.insert(checklist);

      final List<dynamic>? affectedTaskIds = decoded['affectedTaskIds'];
      final List<int> taskIds = affectedTaskIds != null
          ? affectedTaskIds.cast<int>().toList()
          : [];

      // 触发领域事件，让任务模块还原任务的清单绑定
      _eventBus.fire(
        ChecklistRestoredEvent(
          checklistId: checklist.id,
          affectedTaskIds: taskIds,
        ),
      );
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
