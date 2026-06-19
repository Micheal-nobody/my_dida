import 'dart:async';
import 'package:isar_community/isar.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/constants/app_constants.dart';
import 'package:my_dida/constants/ui_constants.dart';
import 'package:my_dida/core/errors/exceptions.dart';
import 'package:my_dida/core/validators/task_validator.dart';
import 'package:my_dida/model/entity/check_point.dart';
import 'package:my_dida/model/entity/operation.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/provider/operation_stack_provider.dart';
import 'package:my_dida/repository/task_repository.dart';
import 'package:my_dida/services/task_reminder_scheduler_port.dart';
import 'package:my_dida/services/task_reminder_service.dart';
import 'package:my_dida/utils/RRuleUtil.dart';

abstract class TaskLifecycleManager {
  Future<Task> addTask(Task newTask);
  Future<void> updateTaskIsDone(Task task, bool value);
  Future<void> updatePriority(Task task, TaskPriority newPriority);
  Future<void> updateTags(Task task, List<String> newTags);
  Future<void> updateTitle(Task task, String newTitle);
  Future<void> updateDescription(Task task, String newDesc);
  Future<void> toggleCheckpoint(Task task, int index, bool value);
  Future<void> renameCheckpoint(Task task, int index, String newName);
  Future<void> addCheckpoint(Task task);
  Future<void> removeCheckpoint(Task task, int index);
  Future<int> createSubTask(Task parent, {String name});
  Future<void> deleteSubTask(Task parent, int subTaskId);
  Future<void> updateChecklist(Task task, int? newChecklistId);
  Future<void> updateStartTime(Task task, DateTime? newStartTime, {bool? isAllDay});
  Future<void> updateEndTime(Task task, DateTime? newEndTime, {bool? isAllDay});
  Future<void> updateTimeRange(Task task, DateTime? newStartTime, DateTime? newEndTime, {bool? isAllDay});
  Future<void> clearTaskSchedule(Task task);
  Future<void> updateRRule(Task task, String? rrule);
  Future<void> updateTaskReminder(Task task, {required bool enabled, int? offsetMinutes});
  Future<void> deleteTask(Task task);
  Future<void> deletePermanently(Task task);
  Future<void> restoreTask(Task task);
  Future<void> associateMainTask(Task subTask, Task mainTask);
  Future<void> copyTask(Task originalTask);
}

class TaskLifecycleManagerImpl implements TaskLifecycleManager {
  TaskLifecycleManagerImpl({
    TaskRepository? taskRepository,
    TaskReminderService? taskReminderService,
    TaskReminderSchedulerPort? taskReminderScheduler,
    OperationStackProvider? operationStack,
  }) : _taskRepository = taskRepository ?? getIt<TaskRepository>(),
       _taskReminderService = taskReminderService ?? getIt<TaskReminderService>(),
       _taskReminderScheduler = taskReminderScheduler ?? getIt<TaskReminderSchedulerPort>(),
       _operationStack = operationStack ?? getIt<OperationStackProvider>();

  final TaskRepository _taskRepository;
  final TaskReminderService _taskReminderService;
  final TaskReminderSchedulerPort _taskReminderScheduler;
  final OperationStackProvider _operationStack;

  @override
  Future<void> updatePriority(Task task, TaskPriority newPriority) async {
    try {
      await _updateTaskHelper(
        task: task,
        mutate: (draft) => draft.priority = newPriority,
        description: '修改了任务"${task.name}"的优先级',
      );
    } catch (e) {
      throw TaskException('Failed to update task priority: ${e.toString()}');
    }
  }

  @override
  Future<void> updateTags(Task task, List<String> newTags) async {
    try {
      await _updateTaskHelper(
        task: task,
        mutate: (draft) => draft.tags = List.from(newTags),
        description: '修改了任务"${task.name}"的标签',
      );
    } catch (e) {
      throw TaskException('Failed to update task tags: ${e.toString()}');
    }
  }

  @override
  Future<Task> addTask(Task newTask) async {
    final task = await _createTask(
      name: newTask.name,
      isAllDay: newTask.isAllDay,
      description: newTask.description,
      startTime: newTask.startTime,
      endTime: newTask.endTime,
      parentTaskId: newTask.parentTaskId,
      checklistId: newTask.checklistId,
      rrule: newTask.rrule,
      notificationEnabled: newTask.notificationEnabled,
      reminderOffsetMinutes: newTask.reminderOffsetMinutes,
      priority: newTask.priority,
      tags: newTask.tags,
      checkpoints: newTask.checkpoints,
    );
    return task;
  }

  @override
  Future<void> updateTaskIsDone(Task task, bool value) async {
    try {
      final oldTask = task.copyWith();
      await _taskRepository.updateTaskIsDone(task, value);

      final newTask = task.copyWith(isDone: value);
      final description = value
          ? '${UIStrings.completedTask}"${task.name}"'
          : '${UIStrings.cancelledTaskCompletion}"${task.name}"${UIStrings.completionStatus}';

      await _operationStack.addOperation(
        Operation.createUpdateTaskOperation(oldTask, newTask, description),
      );

      await _syncTaskReminder(task);

      if (value && task.rrule != null && task.rrule!.isNotEmpty) {
        await _createRecurringTask(task);
      }
    } catch (e) {
      throw TaskException('Failed to update task completion: ${e.toString()}');
    }
  }

  @override
  Future<void> updateTitle(Task task, String newTitle) async {
    try {
      TaskValidator.validateTaskName(newTitle);
      await _updateTaskHelper(
        task: task,
        mutate: (draft) => draft.name = newTitle.trim(),
        description: '${UIStrings.modifiedTaskTitle}"${newTitle.trim()}"',
      );
    } catch (e) {
      throw TaskException('Failed to update task title: ${e.toString()}');
    }
  }

  @override
  Future<void> updateDescription(Task task, String newDesc) async {
    try {
      TaskValidator.validateTaskDescription(newDesc);
      await _updateTaskHelper(
        task: task,
        mutate: (draft) => draft.description = newDesc.trim(),
        description:
            '${UIStrings.modifiedTaskDescription}"${task.name}"${UIStrings.descriptionSuffix}',
      );
    } catch (e) {
      throw TaskException('Failed to update task description: ${e.toString()}');
    }
  }

  @override
  Future<void> toggleCheckpoint(Task task, int index, bool value) async {
    try {
      final updated = List<CheckPoint>.from(task.checkpoints);
      updated[index] = CheckPoint(name: updated[index].name, isDone: value);
      await _taskRepository.update(task..checkpoints = updated);
    } catch (e) {
      throw TaskException('Failed to toggle checkpoint: ${e.toString()}');
    }
  }

  @override
  Future<void> renameCheckpoint(Task task, int index, String newName) async {
    try {
      TaskValidator.validateCheckpointName(newName);
      final updated = List<CheckPoint>.from(task.checkpoints);
      updated[index] = CheckPoint(
        name: newName.trim(),
        isDone: updated[index].isDone,
      );
      await _taskRepository.update(task..checkpoints = updated);
    } catch (e) {
      throw TaskException('Failed to rename checkpoint: ${e.toString()}');
    }
  }

  @override
  Future<void> addCheckpoint(Task task) async {
    try {
      final updated = List<CheckPoint>.from(task.checkpoints)
        ..add(CheckPoint(name: ''));
      await _taskRepository.update(task..checkpoints = updated);
    } catch (e) {
      throw TaskException('Failed to add checkpoint: ${e.toString()}');
    }
  }

  @override
  Future<void> removeCheckpoint(Task task, int index) async {
    try {
      final updated = List<CheckPoint>.from(task.checkpoints)..removeAt(index);
      await _taskRepository.update(task..checkpoints = updated);
    } catch (e) {
      throw TaskException('Failed to remove checkpoint: ${e.toString()}');
    }
  }

  @override
  Future<int> createSubTask(Task parent, {String name = UIStrings.subTask}) async {
    final task = await _createTask(
      name: name,
      isAllDay: false,
      parentTaskId: parent.id,
      checklistId: parent.checklistId,
    );
    return task.id;
  }

  @override
  Future<void> deleteSubTask(Task parent, int subTaskId) async {
    try {
      final subTask = await _taskRepository.selectById(subTaskId);
      if (subTask == null) {
        final newIds = List<int>.from(parent.subTaskIds)..remove(subTaskId);
        await _taskRepository.update(parent..subTaskIds = newIds);
        return;
      }
      await _doDeleteTask(subTask);
    } catch (e) {
      throw TaskException('Failed to delete sub task: ${e.toString()}');
    }
  }

  @override
  Future<void> updateChecklist(Task task, int? newChecklistId) async {
    try {
      TaskValidator.validateChecklistId(newChecklistId);
      await _updateTaskHelper(
        task: task,
        mutate: (draft) => draft.checklistId = newChecklistId,
        description: '修改了任务"${task.name}"的清单归属',
      );
    } catch (e) {
      throw TaskException(
        'Failed to update task belonging box: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> updateStartTime(Task task, DateTime? newStartTime, {bool? isAllDay}) async {
    await updateTimeRange(task, newStartTime, task.endTime, isAllDay: isAllDay);
  }

  @override
  Future<void> updateEndTime(Task task, DateTime? newEndTime, {bool? isAllDay}) async {
    await updateTimeRange(task, task.startTime, newEndTime, isAllDay: isAllDay);
  }

  @override
  Future<void> updateTimeRange(
    Task task,
    DateTime? newStartTime,
    DateTime? newEndTime, {
    bool? isAllDay,
  }) async {
    try {
      TaskValidator.validateTaskTimeRange(newStartTime, newEndTime);
      final nextIsAllDay = isAllDay ?? task.isAllDay;
      final nextNotificationEnabled =
          task.notificationEnabled && newStartTime != null && !nextIsAllDay;
      final nextReminderOffsetMinutes = nextNotificationEnabled
          ? task.reminderOffsetMinutes
          : null;
      _taskReminderService.validateTaskReminderConfiguration(
        notificationEnabled: nextNotificationEnabled,
        reminderOffsetMinutes: nextReminderOffsetMinutes,
        startTime: newStartTime,
        isAllDay: nextIsAllDay,
      );
      await _updateTaskHelper(
        task: task,
        mutate: (draft) {
          draft
            ..startTime = newStartTime
            ..endTime = newEndTime;
          if (isAllDay != null) {
            draft.isAllDay = isAllDay;
          }
          draft
            ..notificationEnabled = nextNotificationEnabled
            ..reminderOffsetMinutes = nextReminderOffsetMinutes;
        },
        description:
            '${UIStrings.modifiedTimeRange}"${task.name}"${UIStrings.timeRangeSuffix}',
        syncReminder: true,
      );
    } catch (e) {
      throw TaskException('Failed to update task time range: ${e.toString()}');
    }
  }

  @override
  Future<void> clearTaskSchedule(Task task) async {
    try {
      await _updateTaskHelper(
        task: task,
        mutate: (draft) {
          draft
            ..startTime = null
            ..endTime = null
            ..rrule = null
            ..notificationEnabled = false
            ..reminderOffsetMinutes = null;
        },
        description: '清除了任务"${task.name}"的日程安排',
        syncReminder: true,
      );
    } catch (e) {
      throw TaskException('Failed to clear task schedule: ${e.toString()}');
    }
  }

  @override
  Future<void> updateRRule(Task task, String? rrule) async {
    try {
      TaskValidator.validateRRule(rrule);
      await _updateTaskHelper(
        task: task,
        mutate: (draft) => draft.rrule = rrule,
        description: '修改了任务"${task.name}"的重复规则',
        syncReminder: true,
      );
    } catch (e) {
      throw TaskException('Failed to update task rrule: ${e.toString()}');
    }
  }

  @override
  Future<void> updateTaskReminder(
    Task task, {
    required bool enabled,
    int? offsetMinutes,
  }) async {
    try {
      final reminderOffsetMinutes = enabled ? offsetMinutes : null;
      _taskReminderService.validateTaskReminderConfiguration(
        notificationEnabled: enabled,
        reminderOffsetMinutes: reminderOffsetMinutes,
        startTime: task.startTime,
        isAllDay: task.isAllDay,
      );
      await _updateTaskHelper(
        task: task,
        mutate: (draft) {
          draft
            ..notificationEnabled = enabled
            ..reminderOffsetMinutes = reminderOffsetMinutes;
        },
        description: '修改了任务"${task.name}"的提醒设置',
        syncReminder: true,
      );
    } catch (e) {
      throw TaskException('Failed to update task reminder: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteTask(Task task) async {
    try {
      await _doDeleteTask(task);
    } catch (e) {
      throw TaskException('Failed to delete task: ${e.toString()}');
    }
  }

  @override
  Future<void> deletePermanently(Task task) async {
    try {
      final isar = getIt<Isar>();
      await isar.writeTxn(() async {
        await isar.operations.delete(task.id);
      });
    } catch (e) {
      throw TaskException('Failed to delete task permanently: ${e.toString()}');
    }
  }

  @override
  Future<void> restoreTask(Task task) async {
    try {
      final isar = getIt<Isar>();
      final op = await isar.operations.get(task.id);
      if (op != null) {
        await _operationStack.undoOperation(op);
      }
    } catch (e) {
      throw TaskException('Failed to restore task: ${e.toString()}');
    }
  }

  @override
  Future<void> associateMainTask(Task subTask, Task mainTask) async {
    try {
      if (subTask.parentTaskId != null && subTask.parentTaskId != mainTask.id) {
        await _updateParentTaskSubIds(
          subTask.parentTaskId!,
          subTask.id,
          isAdd: false,
        );
      }

      final oldSubTask = subTask.copyWith();
      await _taskRepository.update(subTask..parentTaskId = mainTask.id);
      await _operationStack.addOperation(
        Operation.createUpdateTaskOperation(
          oldSubTask,
          subTask.copyWith(),
          '关联了任务"${subTask.name}"的主任务',
        ),
      );

      await _updateParentTaskSubIds(mainTask.id, subTask.id, isAdd: true);
    } catch (e) {
      throw TaskException('Failed to associate main task: ${e.toString()}');
    }
  }

  @override
  Future<void> copyTask(Task originalTask) async {
    try {
      final latest = await _taskRepository.selectById(originalTask.id);
      if (latest != null) {
        await _copyTaskRecursively(latest, null);
      }
    } catch (e) {
      throw TaskException('Failed to copy task: ${e.toString()}');
    }
  }

  // ==================================================================
  // 业务私有辅助方法
  // ==================================================================

  Future<Task> _createTask({
    required String name,
    bool isAllDay = false,
    String description = '',
    DateTime? startTime,
    DateTime? endTime,
    int? parentTaskId,
    int? checklistId,
    String? rrule,
    bool notificationEnabled = false,
    int? reminderOffsetMinutes,
    TaskPriority priority = TaskPriority.none,
    List<String> tags = const [],
    List<CheckPoint> checkpoints = const [],
  }) async {
    try {
      TaskValidator.validateTaskName(name);
      TaskValidator.validateTaskDescription(description);
      TaskValidator.validateTaskTimeRange(startTime, endTime);
      TaskValidator.validateChecklistId(checklistId);
      TaskValidator.validateRRule(rrule);
      _taskReminderService.validateTaskReminderConfiguration(
        notificationEnabled: notificationEnabled,
        reminderOffsetMinutes: reminderOffsetMinutes,
        startTime: startTime,
        isAllDay: isAllDay,
      );

      final task = Task(
        name: name.trim(),
        isAllDay: isAllDay,
        description: description.trim(),
        startTime: startTime,
        endTime: endTime,
        parentTaskId: parentTaskId,
        checklistId: checklistId ?? AppConstants.defaultCheckList.id,
        rrule: rrule,
        notificationEnabled: notificationEnabled,
        reminderOffsetMinutes: reminderOffsetMinutes,
        priority: priority,
        tags: tags,
        checkpoints: checkpoints,
      );

      await _taskRepository.addTask(task);

      if (parentTaskId != null) {
        await _updateParentTaskSubIds(parentTaskId, task.id, isAdd: true);
      }

      await _operationStack.addOperation(
        Operation.createAddTaskOperation(task),
      );
      await _syncTaskReminder(task);
      return task;
    } catch (e) {
      throw TaskException('Failed to create task: ${e.toString()}');
    }
  }

  Future<void> _doDeleteTask(Task task) async {
    await _operationStack.addOperation(
      Operation.createDeleteTaskOperation(task),
    );

    if (task.parentTaskId != null) {
      await _updateParentTaskSubIds(task.parentTaskId!, task.id, isAdd: false);
    }

    for (final subTaskId in task.subTaskIds) {
      final subTask = await _taskRepository.selectById(subTaskId);
      if (subTask != null) {
        await _doDeleteTask(subTask);
      } else {
        await _taskRepository.deleteById(subTaskId);
      }
    }

    await _taskRepository.deleteById(task.id);
    await _taskReminderScheduler.cancelByTaskId(task.id);
  }

  Future<void> _updateTaskHelper({
    required Task task,
    required void Function(Task draft) mutate,
    required String description,
    bool syncReminder = false,
  }) async {
    final oldTask = task.copyWith();
    mutate(task);
    await _taskRepository.update(task);
    await _operationStack.addOperation(
      Operation.createUpdateTaskOperation(
        oldTask,
        task.copyWith(),
        description,
      ),
    );
    if (syncReminder) {
      await _syncTaskReminder(task);
    }
  }

  Future<void> _createRecurringTask(Task task) async {
    final start = task.startTime;
    if (start == null) {
      return;
    }

    final occurrences = RRuleUtil.nextOccurrences(
      start,
      task.rrule!,
      AppConstants.maxRecurrenceOccurrences,
    );

    final normalizedCurrent = DateTime(start.year, start.month, start.day);
    DateTime? nextDay;
    for (final occurrence in occurrences) {
      if (occurrence.isAfter(normalizedCurrent)) {
        nextDay = occurrence;
        break;
      }
    }

    if (nextDay == null && occurrences.isNotEmpty) {
      final more = RRuleUtil.nextOccurrences(
        start.add(const Duration(days: 1)),
        task.rrule!,
        1,
      );
      if (more.isNotEmpty) {
        nextDay = more.first;
      }
    }

    if (nextDay == null) {
      return;
    }

    final nextStart = DateTime(
      nextDay.year,
      nextDay.month,
      nextDay.day,
      start.hour,
      start.minute,
    );

    final newRecurring = Task(
      name: task.name,
      isAllDay: task.isAllDay,
      description: task.description,
      checkpoints: task.checkpoints
          .map((c) => CheckPoint(name: c.name))
          .toList(),
      startTime: nextStart,
      endTime: task.endTime,
      parentTaskId: task.parentTaskId,
      subTaskIds: List<int>.from(task.subTaskIds),
      checklistId: task.checklistId,
      rrule: task.rrule,
      notificationEnabled: task.notificationEnabled,
      reminderOffsetMinutes: task.reminderOffsetMinutes,
    );

    await _taskRepository.addTask(newRecurring);
    await _syncTaskReminder(newRecurring);
  }

  Future<void> _updateParentTaskSubIds(
    int parentTaskId,
    int subTaskId, {
    required bool isAdd,
  }) async {
    final parentTask = await _taskRepository.selectById(parentTaskId);
    if (parentTask == null) {
      return;
    }

    final newIds = List<int>.from(parentTask.subTaskIds);
    if (isAdd) {
      if (!newIds.contains(subTaskId)) {
        newIds.add(subTaskId);
      }
    } else {
      newIds.remove(subTaskId);
    }
    await _taskRepository.update(parentTask..subTaskIds = newIds);
  }

  Future<Task> _copyTaskRecursively(
    Task originalTask,
    int? newParentTaskId,
  ) async {
    final copiedTask = Task(
      name: '${originalTask.name} (副本)',
      isAllDay: originalTask.isAllDay,
      description: originalTask.description,
      checkpoints: originalTask.checkpoints
          .map((checkpoint) => CheckPoint(name: checkpoint.name))
          .toList(),
      startTime: originalTask.startTime,
      endTime: originalTask.endTime,
      parentTaskId: newParentTaskId,
      subTaskIds: [],
      checklistId: originalTask.checklistId,
      rrule: originalTask.rrule,
      notificationEnabled: originalTask.notificationEnabled,
      reminderOffsetMinutes: originalTask.reminderOffsetMinutes,
    );

    await _taskRepository.addTask(copiedTask);
    await _operationStack.addOperation(
      Operation.createAddTaskOperation(copiedTask),
    );
    await _syncTaskReminder(copiedTask);

    final newSubTaskIds = <int>[];
    for (final subTaskId in originalTask.subTaskIds) {
      final subTask = await _taskRepository.selectById(subTaskId);
      if (subTask == null) {
        continue;
      }
      final copiedSubTask = await _copyTaskRecursively(subTask, copiedTask.id);
      newSubTaskIds.add(copiedSubTask.id);
    }

    await _taskRepository.update(copiedTask..subTaskIds = newSubTaskIds);
    return copiedTask;
  }

  Future<void> _syncTaskReminder(Task task) async {
    final plan = _taskReminderService.buildPlan(task);
    if (plan == null) {
      await _taskReminderScheduler.cancelByTaskId(task.id);
      return;
    }

    await _taskReminderScheduler.schedule(plan);
  }
}
