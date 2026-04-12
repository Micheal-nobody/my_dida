import '../config/locator.dart';
import '../constants/app_constants.dart';
import '../constants/ui_constants.dart';
import '../core/errors/exceptions.dart';
import '../core/validators/task_validator.dart';
import '../model/entity/CheckPoint.dart';
import '../model/entity/Operation.dart';
import '../model/entity/Task.dart';
import '../provider/operation_stack_provider.dart';
import '../repository/task_repository.dart';
import '../utils/RRuleUtil.dart';

/// Service class for task-related business logic
class TaskService {
  TaskService()
    : _taskRepository = getIt<TaskRepository>(),
      _operationStack = getIt<OperationStackProvider>();
  final TaskRepository _taskRepository;
  final OperationStackProvider _operationStack;

  /// Creates a new task with validation
  Future<Task> createTask({
    required String name,
    bool isAllDay = false,
    String description = '',
    DateTime? startTime,
    DateTime? endTime,
    int? parentTaskId,
    int? belongingBoxId,
    String? rrule,
  }) async {
    try {
      // Validate inputs
      TaskValidator.validateTaskName(name);
      TaskValidator.validateTaskDescription(description);
      TaskValidator.validateTaskTimeRange(startTime, endTime);
      TaskValidator.validateBelongingBoxId(belongingBoxId);
      TaskValidator.validateRRule(rrule);

      final task = Task(
        name: name.trim(),
        isAllDay: isAllDay,
        description: description.trim(),
        startTime: startTime,
        endTime: endTime,
        parentTaskId: parentTaskId,
        belongingBoxId: belongingBoxId ?? AppConstants.defaultCheckList.id,
        rrule: rrule,
      );

      await _taskRepository.addTask(task);

      // Handle parent-child relationship
      if (parentTaskId != null) {
        await _updateParentTaskSubIds(parentTaskId, task.id, isAdd: true);
      }

      // Record operation
      final operation = Operation.createAddTaskOperation(task);
      await _operationStack.addOperation(operation);

      return task;
    } catch (e) {
      throw TaskException('Failed to create task: ${e.toString()}');
    }
  }

  /// Updates task completion status with recurring task handling
  Future<void> updateTaskCompletion(Task task, bool isDone) async {
    try {
      final oldTask = _copyTask(task);

      // Update task status
      await _taskRepository.updateTaskIsDone(task, isDone);

      // Record operation
      final newTask = _copyTask(task)..isDone = isDone;
      final operationDescription = isDone
          ? '${UIStrings.completedTask}"${task.name}"'
          : '${UIStrings.cancelledTaskCompletion}"${task.name}"${UIStrings.completionStatus}';

      final operation = Operation.createUpdateTaskOperation(
        oldTask,
        newTask,
        operationDescription,
      );
      await _operationStack.addOperation(operation);

      // Handle recurring tasks
      if (isDone && task.rrule != null && task.rrule!.isNotEmpty) {
        await _createRecurringTask(task);
      }
    } catch (e) {
      throw TaskException('Failed to update task completion: ${e.toString()}');
    }
  }

  /// Updates task title with validation
  Future<void> updateTaskTitle(Task task, String newTitle) async {
    try {
      TaskValidator.validateTaskName(newTitle);

      final oldTask = _copyTask(task);
      await _taskRepository.update(task..name = newTitle.trim());

      // Record operation
      final newTask = _copyTask(task);
      final operation = Operation.createUpdateTaskOperation(
        oldTask,
        newTask,
        '${UIStrings.modifiedTaskTitle}"$newTitle"',
      );
      await _operationStack.addOperation(operation);
    } catch (e) {
      throw TaskException('Failed to update task title: ${e.toString()}');
    }
  }

  /// Updates task description with validation
  Future<void> updateTaskDescription(Task task, String newDescription) async {
    try {
      TaskValidator.validateTaskDescription(newDescription);

      final oldTask = _copyTask(task);
      await _taskRepository.update(task..description = newDescription.trim());

      // Record operation
      final newTask = _copyTask(task);
      final operation = Operation.createUpdateTaskOperation(
        oldTask,
        newTask,
        '${UIStrings.modifiedTaskDescription}"${task.name}"${UIStrings.descriptionSuffix}',
      );
      await _operationStack.addOperation(operation);
    } catch (e) {
      throw TaskException('Failed to update task description: ${e.toString()}');
    }
  }

  /// Updates task time range with validation
  Future<void> updateTaskTimeRange(
    Task task,
    DateTime? startTime,
    DateTime? endTime,
  ) async {
    try {
      TaskValidator.validateTaskTimeRange(startTime, endTime);

      final oldTask = _copyTask(task);
      await _taskRepository.update(
        task
          ..startTime = startTime
          ..endTime = endTime,
      );

      // Record operation
      final newTask = _copyTask(task);
      final operation = Operation.createUpdateTaskOperation(
        oldTask,
        newTask,
        '${UIStrings.modifiedTimeRange}"${task.name}"${UIStrings.timeRangeSuffix}',
      );
      await _operationStack.addOperation(operation);
    } catch (e) {
      throw TaskException('Failed to update task time range: ${e.toString()}');
    }
  }

  /// Deletes a task and handles cleanup
  Future<void> deleteTask(Task task) async {
    try {
      // Record operation before deletion
      final operation = Operation.createDeleteTaskOperation(task);
      await _operationStack.addOperation(operation);

      // Handle parent-child relationships
      if (task.parentTaskId != null) {
        await _updateParentTaskSubIds(
          task.parentTaskId!,
          task.id,
          isAdd: false,
        );
      }

      // Delete all subtasks
      for (final subTaskId in task.subTaskIds) {
        await _taskRepository.deleteById(subTaskId);
      }

      // Delete the task
      await _taskRepository.deleteById(task.id);
    } catch (e) {
      throw TaskException('Failed to delete task: ${e.toString()}');
    }
  }

  /// Copies a task for operation recording
  Task _copyTask(Task task) => Task(
    name: task.name,
    isAllDay: task.isAllDay,
    description: task.description,
    isDone: task.isDone,
    checkpoints: task.checkpoints,
    startTime: task.startTime,
    endTime: task.endTime,
    parentTaskId: task.parentTaskId,
    subTaskIds: task.subTaskIds,
    belongingBoxId: task.belongingBoxId,
    rrule: task.rrule,
  )..id = task.id;

  /// Creates a recurring task based on RRule
  Future<void> _createRecurringTask(Task task) async {
    final DateTime? start = task.startTime;
    if (start == null) return;

    // Find next occurrence
    final List<DateTime> occurrences = RRuleUtil.nextOccurrences(
      start,
      task.rrule!,
      AppConstants.maxRecurrenceOccurrences,
    );

    final DateTime normalizedCurrent = DateTime(
      start.year,
      start.month,
      start.day,
    );

    DateTime? nextDay;
    for (final d in occurrences) {
      if (d.isAfter(normalizedCurrent)) {
        nextDay = d;
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

    if (nextDay != null) {
      final DateTime nextStart = DateTime(
        nextDay.year,
        nextDay.month,
        nextDay.day,
        start.hour,
        start.minute,
      );

      // Create new recurring task
      final Task newRecurring = Task(
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
        belongingBoxId: task.belongingBoxId,
        rrule: task.rrule,
      );

      await _taskRepository.addTask(newRecurring);
    }
  }

  /// Updates parent task's subtask IDs
  Future<void> _updateParentTaskSubIds(
    int parentTaskId,
    int subTaskId, {
    required bool isAdd,
  }) async {
    final parentTask = await _taskRepository.getById(parentTaskId);
    if (parentTask != null) {
      final List<int> newIds = List.of(parentTask.subTaskIds);
      if (isAdd) {
        if (!newIds.contains(subTaskId)) {
          newIds.add(subTaskId);
        }
      } else {
        newIds.remove(subTaskId);
      }
      await _taskRepository.update(parentTask..subTaskIds = newIds);
    }
  }
}
