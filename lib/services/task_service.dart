import '../config/locator.dart';
import '../constants/app_constants.dart';
import '../constants/ui_constants.dart';
import '../core/errors/exceptions.dart';
import '../core/validators/task_validator.dart';
import '../model/entity/CheckPoint.dart';
import '../model/entity/Operation.dart';
import '../model/entity/Task.dart';
import '../model/vo/task_calendar_view_data.dart';
import '../provider/operation_stack_provider.dart';
import '../repository/task_repository.dart';
import '../utils/RRuleUtil.dart';

/// Service class for task-related business logic.
class TaskService {
  TaskService({
    TaskRepository? taskRepository,
    OperationStackProvider? operationStack,
  }) : _taskRepository = taskRepository ?? getIt<TaskRepository>(),
       _operationStack = operationStack ?? getIt<OperationStackProvider>();

  final TaskRepository _taskRepository;
  final OperationStackProvider _operationStack;

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

      if (parentTaskId != null) {
        await _updateParentTaskSubIds(parentTaskId, task.id, isAdd: true);
      }

      await _operationStack.addOperation(
        Operation.createAddTaskOperation(task),
      );
      return task;
    } catch (e) {
      throw TaskException('Failed to create task: ${e.toString()}');
    }
  }

  Future<void> updateTaskCompletion(Task task, bool isDone) async {
    try {
      final oldTask = _copyTask(task);
      await _taskRepository.updateTaskIsDone(task, isDone);

      final newTask = _copyTask(task)..isDone = isDone;
      final description = isDone
          ? '${UIStrings.completedTask}"${task.name}"'
          : '${UIStrings.cancelledTaskCompletion}"${task.name}"${UIStrings.completionStatus}';

      await _operationStack.addOperation(
        Operation.createUpdateTaskOperation(oldTask, newTask, description),
      );

      if (isDone && task.rrule != null && task.rrule!.isNotEmpty) {
        await _createRecurringTask(task);
      }
    } catch (e) {
      throw TaskException('Failed to update task completion: ${e.toString()}');
    }
  }

  Future<void> updateTaskTitle(Task task, String newTitle) async {
    try {
      TaskValidator.validateTaskName(newTitle);
      await _updateTask(
        task: task,
        mutate: (draft) => draft.name = newTitle.trim(),
        description: '${UIStrings.modifiedTaskTitle}"${newTitle.trim()}"',
      );
    } catch (e) {
      throw TaskException('Failed to update task title: ${e.toString()}');
    }
  }

  Future<void> updateTaskDescription(Task task, String newDescription) async {
    try {
      TaskValidator.validateTaskDescription(newDescription);
      await _updateTask(
        task: task,
        mutate: (draft) => draft.description = newDescription.trim(),
        description:
            '${UIStrings.modifiedTaskDescription}"${task.name}"${UIStrings.descriptionSuffix}',
      );
    } catch (e) {
      throw TaskException('Failed to update task description: ${e.toString()}');
    }
  }

  Future<void> updateTaskTimeRange(
    Task task,
    DateTime? startTime,
    DateTime? endTime,
  ) async {
    try {
      TaskValidator.validateTaskTimeRange(startTime, endTime);
      await _updateTask(
        task: task,
        mutate: (draft) {
          draft
            ..startTime = startTime
            ..endTime = endTime;
        },
        description:
            '${UIStrings.modifiedTimeRange}"${task.name}"${UIStrings.timeRangeSuffix}',
      );
    } catch (e) {
      throw TaskException('Failed to update task time range: ${e.toString()}');
    }
  }

  Future<void> updateTaskRRule(Task task, String? rrule) async {
    try {
      TaskValidator.validateRRule(rrule);
      await _updateTask(
        task: task,
        mutate: (draft) => draft.rrule = rrule,
        description: '修改了任务"${task.name}"的重复规则',
      );
    } catch (e) {
      throw TaskException('Failed to update task rrule: ${e.toString()}');
    }
  }

  Future<void> clearTaskSchedule(Task task) async {
    await updateTaskTimeRange(task, null, null);
    if (task.rrule != null) {
      await updateTaskRRule(task, null);
    }
  }

  Future<void> updateBelongingBox(Task task, int? newBelongingBoxId) async {
    try {
      TaskValidator.validateBelongingBoxId(newBelongingBoxId);
      await _updateTask(
        task: task,
        mutate: (draft) => draft.belongingBoxId = newBelongingBoxId,
        description: '修改了任务"${task.name}"的清单归属',
      );
    } catch (e) {
      throw TaskException(
        'Failed to update task belonging box: ${e.toString()}',
      );
    }
  }

  Future<void> toggleCheckpoint(Task task, int index, bool value) async {
    try {
      final updated = List<CheckPoint>.from(task.checkpoints);
      updated[index] = CheckPoint(name: updated[index].name, isDone: value);
      await _taskRepository.update(task..checkpoints = updated);
    } catch (e) {
      throw TaskException('Failed to toggle checkpoint: ${e.toString()}');
    }
  }

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

  Future<void> addCheckpoint(Task task, {String name = '新检查点'}) async {
    try {
      TaskValidator.validateCheckpointName(name);
      final updated = List<CheckPoint>.from(task.checkpoints)
        ..add(CheckPoint(name: name.trim()));
      await _taskRepository.update(task..checkpoints = updated);
    } catch (e) {
      throw TaskException('Failed to add checkpoint: ${e.toString()}');
    }
  }

  Future<void> removeCheckpoint(Task task, int index) async {
    try {
      final updated = List<CheckPoint>.from(task.checkpoints)..removeAt(index);
      await _taskRepository.update(task..checkpoints = updated);
    } catch (e) {
      throw TaskException('Failed to remove checkpoint: ${e.toString()}');
    }
  }

  Future<int> createSubTask(
    Task parent, {
    String name = UIStrings.subTask,
  }) async {
    final task = await createTask(
      name: name,
      isAllDay: false,
      parentTaskId: parent.id,
      belongingBoxId: parent.belongingBoxId,
    );
    return task.id;
  }

  Future<void> deleteSubTask(Task parent, int subTaskId) async {
    try {
      final subTask = await _taskRepository.getById(subTaskId);
      if (subTask == null) {
        final newIds = List<int>.from(parent.subTaskIds)..remove(subTaskId);
        await _taskRepository.update(parent..subTaskIds = newIds);
        return;
      }
      await deleteTask(subTask);
    } catch (e) {
      throw TaskException('Failed to delete sub task: ${e.toString()}');
    }
  }

  Future<void> associateMainTask(Task subTask, Task mainTask) async {
    try {
      if (subTask.parentTaskId != null && subTask.parentTaskId != mainTask.id) {
        await _updateParentTaskSubIds(
          subTask.parentTaskId!,
          subTask.id,
          isAdd: false,
        );
      }

      final oldSubTask = _copyTask(subTask);
      await _taskRepository.update(subTask..parentTaskId = mainTask.id);
      await _operationStack.addOperation(
        Operation.createUpdateTaskOperation(
          oldSubTask,
          _copyTask(subTask),
          '关联了任务"${subTask.name}"的主任务',
        ),
      );

      await _updateParentTaskSubIds(mainTask.id, subTask.id, isAdd: true);
    } catch (e) {
      throw TaskException('Failed to associate main task: ${e.toString()}');
    }
  }

  Future<void> copyTask(Task originalTask) async {
    try {
      await _copyTaskRecursively(originalTask, null);
    } catch (e) {
      throw TaskException('Failed to copy task: ${e.toString()}');
    }
  }

  Future<void> deleteTask(Task task) async {
    try {
      await _operationStack.addOperation(
        Operation.createDeleteTaskOperation(task),
      );

      if (task.parentTaskId != null) {
        await _updateParentTaskSubIds(
          task.parentTaskId!,
          task.id,
          isAdd: false,
        );
      }

      for (final subTaskId in task.subTaskIds) {
        final subTask = await _taskRepository.getById(subTaskId);
        if (subTask != null) {
          await deleteTask(subTask);
        } else {
          await _taskRepository.deleteById(subTaskId);
        }
      }

      await _taskRepository.deleteById(task.id);
    } catch (e) {
      throw TaskException('Failed to delete task: ${e.toString()}');
    }
  }

  Future<List<Task>> searchIncompleteTasks(String query) async {
    try {
      final allTasks = await _taskRepository.getAll();
      final incompleteTasks = allTasks.where((task) => !task.isDone).toList()
        ..sort((a, b) => b.id.compareTo(a.id));

      if (query.isEmpty) {
        return incompleteTasks.take(10).toList();
      }

      final normalizedQuery = query.toLowerCase();
      return incompleteTasks
          .where(
            (task) =>
                task.name.toLowerCase().contains(normalizedQuery) ||
                task.description.toLowerCase().contains(normalizedQuery),
          )
          .toList();
    } catch (e) {
      throw TaskException('Failed to search tasks: ${e.toString()}');
    }
  }

  TaskCalendarViewData buildCalendarTaskViewData({
    required List<Task> tasks,
    required List<DateTime> visibleDates,
    required Map<DateTime, int> rruleBatchLimit,
    int futureHorizonDays = 30,
  }) {
    final tasksMap = <DateTime, List<Task>>{};
    final futureTasksMap = <DateTime, List<Task>>{};
    final rruleHasMore = <DateTime, bool>{};

    for (final date in visibleDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final tasksForDate = _buildTasksForDate(
        tasks: tasks,
        normalizedDate: normalizedDate,
        limit: rruleBatchLimit[normalizedDate] ?? 5,
      );

      tasksMap[normalizedDate] = tasksForDate.tasks;
      rruleHasMore[normalizedDate] = tasksForDate.hasMoreRRule;
    }

    if (visibleDates.isNotEmpty) {
      final lastVisibleDate = visibleDates.last;
      for (int i = 1; i <= futureHorizonDays; i++) {
        final date = lastVisibleDate.add(Duration(days: i));
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final futureTasks =
            tasks.where((task) {
              if (task.rrule != null && task.rrule!.isNotEmpty) {
                return false;
              }
              if (task.startTime == null || task.isDone) {
                return false;
              }

              final taskDate = DateTime(
                task.startTime!.year,
                task.startTime!.month,
                task.startTime!.day,
              );
              return taskDate.isAtSameMomentAs(normalizedDate);
            }).toList()..sort(
              (a, b) => (a.startTime ?? DateTime(0)).compareTo(
                b.startTime ?? DateTime(0),
              ),
            );

        if (futureTasks.isNotEmpty) {
          futureTasksMap[normalizedDate] = futureTasks;
        }
      }
    }

    return TaskCalendarViewData(
      tasksForDates: tasksMap,
      futureTasks: futureTasksMap,
      rruleHasMore: rruleHasMore,
    );
  }

  Future<void> _updateTask({
    required Task task,
    required void Function(Task draft) mutate,
    required String description,
  }) async {
    final oldTask = _copyTask(task);
    mutate(task);
    await _taskRepository.update(task);
    await _operationStack.addOperation(
      Operation.createUpdateTaskOperation(
        oldTask,
        _copyTask(task),
        description,
      ),
    );
  }

  Task _copyTask(Task task) => Task(
    name: task.name,
    isAllDay: task.isAllDay,
    description: task.description,
    isDone: task.isDone,
    checkpoints: task.checkpoints
        .map(
          (checkpoint) =>
              CheckPoint(name: checkpoint.name, isDone: checkpoint.isDone),
        )
        .toList(),
    startTime: task.startTime,
    endTime: task.endTime,
    parentTaskId: task.parentTaskId,
    subTaskIds: List<int>.from(task.subTaskIds),
    belongingBoxId: task.belongingBoxId,
    rrule: task.rrule,
  )..id = task.id;

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
      belongingBoxId: task.belongingBoxId,
      rrule: task.rrule,
    );

    await _taskRepository.addTask(newRecurring);
  }

  Future<void> _updateParentTaskSubIds(
    int parentTaskId,
    int subTaskId, {
    required bool isAdd,
  }) async {
    final parentTask = await _taskRepository.getById(parentTaskId);
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
      belongingBoxId: originalTask.belongingBoxId,
      rrule: originalTask.rrule,
    );

    await _taskRepository.addTask(copiedTask);
    await _operationStack.addOperation(
      Operation.createAddTaskOperation(copiedTask),
    );

    final newSubTaskIds = <int>[];
    for (final subTaskId in originalTask.subTaskIds) {
      final subTask = await _taskRepository.getById(subTaskId);
      if (subTask == null) {
        continue;
      }
      final copiedSubTask = await _copyTaskRecursively(subTask, copiedTask.id);
      newSubTaskIds.add(copiedSubTask.id);
    }

    await _taskRepository.update(copiedTask..subTaskIds = newSubTaskIds);
    return copiedTask;
  }

  _TasksForDateResult _buildTasksForDate({
    required List<Task> tasks,
    required DateTime normalizedDate,
    required int limit,
  }) {
    final baseTasksForDate = tasks.where((task) {
      if (task.rrule != null && task.rrule!.isNotEmpty) {
        return false;
      }
      if (task.startTime == null) {
        return false;
      }
      final taskDate = DateTime(
        task.startTime!.year,
        task.startTime!.month,
        task.startTime!.day,
      );
      return taskDate.isAtSameMomentAs(normalizedDate);
    }).toList();

    final rruleTasksForDate = <Task>[];
    for (final task in tasks) {
      if (task.rrule == null || task.rrule!.isEmpty || task.startTime == null) {
        continue;
      }

      final occurrences = RRuleUtil.getOccurrencesInRange(
        task.startTime!,
        task.rrule!,
        normalizedDate,
        normalizedDate.add(const Duration(days: 1)),
      );

      if (!occurrences.any((date) => date.isAtSameMomentAs(normalizedDate))) {
        continue;
      }

      final instanceStart = DateTime(
        normalizedDate.year,
        normalizedDate.month,
        normalizedDate.day,
        task.startTime!.hour,
        task.startTime!.minute,
      );

      final instance = _copyTask(task)..startTime = instanceStart;
      rruleTasksForDate.add(instance);
    }

    final combined = [
      ...baseTasksForDate,
      ...rruleTasksForDate,
    ].where((task) => !task.isDone).toList();

    final allDayTasks = combined.where((task) => task.isAllDay).toList();
    final timedNonRRuleTasks =
        combined
            .where(
              (task) =>
                  (task.rrule == null || task.rrule!.isEmpty) && !task.isAllDay,
            )
            .toList()
          ..sort(
            (a, b) => (a.startTime ?? DateTime(0)).compareTo(
              b.startTime ?? DateTime(0),
            ),
          );

    final timedRRuleTasks =
        combined
            .where(
              (task) =>
                  task.rrule != null &&
                  task.rrule!.isNotEmpty &&
                  !task.isAllDay,
            )
            .toList()
          ..sort(
            (a, b) => (a.startTime ?? DateTime(0)).compareTo(
              b.startTime ?? DateTime(0),
            ),
          );

    return _TasksForDateResult(
      tasks: [
        ...allDayTasks,
        ...timedNonRRuleTasks,
        ...timedRRuleTasks.take(limit),
      ],
      hasMoreRRule: timedRRuleTasks.length > limit,
    );
  }
}

class _TasksForDateResult {
  const _TasksForDateResult({required this.tasks, required this.hasMoreRRule});

  final List<Task> tasks;
  final bool hasMoreRRule;
}
