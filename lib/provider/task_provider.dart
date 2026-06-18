import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:my_dida/model/vo/checklist_vo.dart';

import '../config/locator.dart';
import '../constants/app_constants.dart';
import '../constants/ui_constants.dart';
import '../core/errors/exceptions.dart';
import '../core/validators/task_validator.dart';
import '../model/entity/check_point.dart';
import '../model/entity/operation.dart';
import '../model/entity/task.dart';
import '../model/vo/task_calendar_view_data.dart';
import '../provider/operation_stack_provider.dart';
import '../repository/task_repository.dart';
import '../services/task_calendar_projection_service.dart';
import '../services/task_reminder_scheduler_port.dart';
import '../services/task_reminder_service.dart';
import '../utils/RRuleUtil.dart';

enum TaskViewMode { list, board }
enum TaskGroupBy { date, checklist, priority, tag, none }
enum TaskSortBy { dueDate, priority, title, createTime, custom }
enum TaskVisibleRange { all, undone, done }

class TaskProvider with ChangeNotifier {
  TaskProvider(
    ChecklistVO? newChecklist, {
    TaskRepository? taskRepository,
    TaskCalendarProjectionService? taskCalendarProjectionService,
    OperationStackProvider? operationStack,
    TaskReminderService? taskReminderService,
    TaskReminderSchedulerPort? taskReminderScheduler,
  }) : _taskRepository = taskRepository ?? getIt<TaskRepository>(),
       _taskCalendarProjectionService =
           taskCalendarProjectionService ??
           getIt<TaskCalendarProjectionService>(),
       _operationStack = operationStack ?? getIt<OperationStackProvider>(),
       _taskReminderService =
           taskReminderService ?? getIt<TaskReminderService>(),
       _taskReminderScheduler =
           taskReminderScheduler ?? getIt<TaskReminderSchedulerPort>(),
       currentChecklist = newChecklist {
    updateCurrentTasks(currentChecklist);
  }

  final TaskRepository _taskRepository;
  final TaskCalendarProjectionService _taskCalendarProjectionService;
  final OperationStackProvider _operationStack;
  final TaskReminderService _taskReminderService;
  final TaskReminderSchedulerPort _taskReminderScheduler;

  List<Task> _tasks = [];
  List<Task> _currentTasks = [];
  StreamSubscription<List<Task>>? _currentTasksSubscription;

  List<Task> get tasks => _tasks;

  List<Task> get currentTasks => _currentTasks;

  ChecklistVO? currentChecklist;

  // UI 筛选与视图状态
  TaskViewMode _viewMode = TaskViewMode.list;
  TaskGroupBy _groupBy = TaskGroupBy.date;
  TaskSortBy _sortBy = TaskSortBy.dueDate;
  TaskVisibleRange _visibleRange = TaskVisibleRange.undone;

  TaskViewMode get viewMode => _viewMode;
  TaskGroupBy get groupBy => _groupBy;
  TaskSortBy get sortBy => _sortBy;
  TaskVisibleRange get visibleRange => _visibleRange;

  void setViewMode(TaskViewMode val) {
    if (_viewMode != val) {
      _viewMode = val;
      notifyListeners();
    }
  }

  void setGroupBy(TaskGroupBy val) {
    if (_groupBy != val) {
      _groupBy = val;
      notifyListeners();
    }
  }

  void setSortBy(TaskSortBy val) {
    if (_sortBy != val) {
      _sortBy = val;
      notifyListeners();
    }
  }

  void setVisibleRange(TaskVisibleRange val) {
    if (_visibleRange != val) {
      _visibleRange = val;
      notifyListeners();
    }
  }

  Future<void> updatePriority(Task task, int newPriority) async {
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

  Map<String, List<Task>> getGroupedCurrentTasks(List<ChecklistVO> allChecklists) {
    // 1. 过滤可见范围
    List<Task> filtered = List.from(_currentTasks);
    if (_visibleRange == TaskVisibleRange.undone) {
      filtered = filtered.where((t) => !t.isDone).toList();
    } else if (_visibleRange == TaskVisibleRange.done) {
      filtered = filtered.where((t) => t.isDone).toList();
    }

    // 2. 按照 selected sortBy 进行排序
    filtered.sort((a, b) {
      if (_sortBy == TaskSortBy.dueDate) {
        if (a.startTime == null && b.startTime == null) return 0;
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        return a.startTime!.compareTo(b.startTime!);
      } else if (_sortBy == TaskSortBy.priority) {
        return b.priority.compareTo(a.priority);
      } else if (_sortBy == TaskSortBy.title) {
        return a.name.compareTo(b.name);
      } else if (_sortBy == TaskSortBy.createTime) {
        return b.id.compareTo(a.id);
      }
      return 0;
    });

    // 3. 根据 groupBy 进行分组
    final Map<String, List<Task>> grouped = {};

    if (_groupBy == TaskGroupBy.none) {
      grouped['所有任务'] = filtered;
      return grouped;
    }

    if (_groupBy == TaskGroupBy.priority) {
      const keys = ['高优先级', '中优先级', '低优先级', '无优先级'];
      for (final k in keys) {
        grouped[k] = [];
      }
      for (final t in filtered) {
        if (t.priority == 3) {
          grouped['高优先级']!.add(t);
        } else if (t.priority == 2) {
          grouped['中优先级']!.add(t);
        } else if (t.priority == 1) {
          grouped['低优先级']!.add(t);
        } else {
          grouped['无优先级']!.add(t);
        }
      }
      grouped.removeWhere((key, value) => value.isEmpty);
      return grouped;
    }

    if (_groupBy == TaskGroupBy.checklist) {
      final Map<int, String> checklistMap = {
        for (final cl in allChecklists) cl.id: cl.name
      };
      for (final t in filtered) {
        final clName = checklistMap[t.checklistId] ?? '其他清单';
        grouped.putIfAbsent(clName, () => []).add(t);
      }
      return grouped;
    }

    if (_groupBy == TaskGroupBy.tag) {
      for (final t in filtered) {
        if (t.tags.isNotEmpty) {
          for (final tag in t.tags) {
            grouped.putIfAbsent(tag, () => []).add(t);
          }
        } else {
          grouped.putIfAbsent('无标签', () => []).add(t);
        }
      }
      return grouped;
    }

    if (_groupBy == TaskGroupBy.date) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final sevenDaysLater = today.add(const Duration(days: 7));

      grouped['已过期'] = [];
      grouped['今天'] = [];
      grouped['明天'] = [];
      grouped['最近7天'] = [];
      grouped['稍后'] = [];
      grouped['无日期'] = [];

      for (final t in filtered) {
        if (t.startTime == null) {
          grouped['无日期']!.add(t);
        } else {
          final date = DateTime(t.startTime!.year, t.startTime!.month, t.startTime!.day);
          if (date.isBefore(today)) {
            if (!t.isDone) {
              grouped['已过期']!.add(t);
            } else {
              grouped['今天']!.add(t);
            }
          } else if (date.isAtSameMomentAs(today)) {
            grouped['今天']!.add(t);
          } else if (date.isAtSameMomentAs(tomorrow)) {
            grouped['明天']!.add(t);
          } else if (date.isAfter(tomorrow) && date.isBefore(sevenDaysLater)) {
            grouped['最近7天']!.add(t);
          } else {
            grouped['稍后']!.add(t);
          }
        }
      }

      grouped.removeWhere((key, value) => value.isEmpty);
      return grouped;
    }

    return grouped;
  }

  // ==================================================================
  // 查询方法 (direct Repository access)
  // ==================================================================

  Future<void> updateCurrentTasks(ChecklistVO? newChecklist) async {
    currentChecklist = newChecklist;
    await _currentTasksSubscription?.cancel();

    final Stream<List<Task>> stream;
    if (newChecklist == null || newChecklist.id == -1) {
      stream = _taskRepository.watchTodayTasks();
    } else {
      stream = _taskRepository.watchByChecklistId(newChecklist.id);
    }

    _currentTasksSubscription = stream.listen((tasks) {
      print('DEBUG: Stream emitted tasks: $tasks, type: ${tasks.runtimeType}');
      _currentTasks = tasks;
      notifyListeners();
    });
  }

  Future<void> loadAllTasks() async {
    _tasks = await _taskRepository.selectAll();
    notifyListeners();
  }

  Future<List<Task>> loadTasksForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final tasks = await _taskRepository.getTasksForDateRange(
      startDate,
      endDate,
    );
    _tasks = tasks;
    return tasks;
  }

  Stream<Task?> watchTaskById(int id) => _taskRepository.watchById(id);

  @override
  void dispose() {
    _currentTasksSubscription?.cancel();
    super.dispose();
  }

  Future<Task?> getTaskById(int id) => _taskRepository.selectById(id);

  Future<List<Task>> getTasksByIds(List<int> ids) async {
    final tasks = <Task>[];
    for (final id in ids) {
      final task = await _taskRepository.selectById(id);
      if (task != null) {
        tasks.add(task);
      }
    }
    return tasks;
  }

  Future<Map<int, int>> getTaskCountsByChecklistIds(Iterable<int> ids) async {
    final counts = <int, int>{};
    for (final id in ids.toSet()) {
      final tasks = await _taskRepository.getTasksByChecklistId(id);
      counts[id] = tasks.length;
    }
    return counts;
  }

  // ==================================================================
  // 写入方法 (完全委派给 TaskService 处理，随后刷新本地状态与缓存)
  // ==================================================================

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
    );
    return task;
  }

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

  Future<void> addCheckpoint(Task task) async {
    try {
      final updated = List<CheckPoint>.from(task.checkpoints)
        ..add(CheckPoint(name: ''));
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
    final task = await _createTask(
      name: name,
      isAllDay: false,
      parentTaskId: parent.id,
      checklistId: parent.checklistId,
    );
    return task.id;
  }

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

  Future<void> updateStartTime(
    Task task,
    DateTime? newStartTime, {
    bool? isAllDay,
  }) async {
    await updateTimeRange(task, newStartTime, task.endTime, isAllDay: isAllDay);
  }

  Future<void> updateEndTime(
    Task task,
    DateTime? newEndTime, {
    bool? isAllDay,
  }) async {
    await updateTimeRange(task, task.startTime, newEndTime, isAllDay: isAllDay);
  }

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

  Future<List<Task>> searchIncompleteTasks(String query) async {
    final allTasks = await _taskRepository.selectAll();
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
  }

  Future<void> deleteTask(Task task) async {
    try {
      await _doDeleteTask(task);
    } catch (e) {
      throw TaskException('Failed to delete task: ${e.toString()}');
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

  Future<TaskCalendarViewData> loadCalendarTaskViewData({
    required List<DateTime> visibleDates,
    required Map<DateTime, int> rruleBatchLimit,
    int futureHorizonDays = 30,
  }) async {
    if (visibleDates.isEmpty) {
      return const TaskCalendarViewData(
        tasksForDates: {},
        allDayTasksForDates: {},
        crossDayTasks: [],
        crossDayTaskCountForDates: {},
        futureTasks: {},
        rruleHasMore: {},
      );
    }

    final startDate = visibleDates.first;
    final futureEndDate = visibleDates.last.add(
      Duration(days: futureHorizonDays),
    );
    final allTasks = await loadTasksForDateRange(startDate, futureEndDate);
    return _taskCalendarProjectionService.buildCalendarTaskViewData(
      tasks: allTasks,
      visibleDates: visibleDates,
      rruleBatchLimit: rruleBatchLimit,
      futureHorizonDays: futureHorizonDays,
    );
  }

  // ==================================================================
  // 刷新与重载辅助方法
  // ==================================================================

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
