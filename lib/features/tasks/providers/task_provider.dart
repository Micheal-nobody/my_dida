import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:my_dida/core/constants/app_constants.dart';
import 'package:my_dida/core/constants/ui_constants.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/errors/exceptions.dart';
import 'package:my_dida/features/calendar/models/task_calendar_view_data.dart';
import 'package:my_dida/features/calendar/services/task_calendar_projection_service.dart';
import 'package:my_dida/features/checklist/models/checklist_vo.dart';
import 'package:my_dida/features/tasks/models/repeat_pattern.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/models/task_operation.dart';
import 'package:my_dida/features/tasks/repositories/task_repository.dart';
import 'package:my_dida/features/tasks/services/task_lifecycle_manager.dart';

export 'package:my_dida/features/tasks/models/task_operation.dart';

enum TaskViewMode { list, board }

enum TaskGroupBy { date, checklist, priority, tag, none }

enum TaskSortBy { dueDate, priority, title, createTime, custom }

enum TaskVisibleRange { all, undone, done }

class TaskProvider with ChangeNotifier {
  TaskProvider(
    ChecklistVO? newChecklist, {
    TaskRepository? taskRepository,
    TaskCalendarProjectionService? taskCalendarProjectionService,
    TaskLifecycleManager? taskLifecycleManager,
  }) : _taskRepository = taskRepository ?? getIt<TaskRepository>(),
       _taskCalendarProjectionService =
           taskCalendarProjectionService ??
           getIt<TaskCalendarProjectionService>(),
       _taskLifecycleManager =
           taskLifecycleManager ?? getIt<TaskLifecycleManager>(),
       currentChecklist = newChecklist {
    updateCurrentTasks(currentChecklist);
  }

  final TaskRepository _taskRepository;
  final TaskCalendarProjectionService _taskCalendarProjectionService;
  final TaskLifecycleManager _taskLifecycleManager;

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

  Future<void> updatePriority(Task task, TaskPriority newPriority) async {
    await _taskLifecycleManager.updatePriority(task, newPriority);
  }

  Future<void> updateTags(Task task, List<String> newTags) async {
    await _taskLifecycleManager.updateTags(task, newTags);
  }

  Map<String, List<Task>> getGroupedCurrentTasks(
    List<ChecklistVO> allChecklists,
  ) {
    // 1. 过滤可见范围
    List<Task> filtered = List.from(_currentTasks);
    if (currentChecklist != null &&
        !currentChecklist!.isCompleted &&
        !currentChecklist!.isTrash) {
      if (_visibleRange == TaskVisibleRange.undone) {
        filtered = filtered.where((t) => !t.isDone).toList();
      } else if (_visibleRange == TaskVisibleRange.done) {
        filtered = filtered.where((t) => t.isDone).toList();
      }
    }

    // 2. 按照 selected sortBy 进行排序
    filtered.sort((a, b) {
      if (_sortBy == TaskSortBy.dueDate) {
        if (a.startTime == null && b.startTime == null) return 0;
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        return a.startTime!.compareTo(b.startTime!);
      } else if (_sortBy == TaskSortBy.priority) {
        return b.priority.index.compareTo(a.priority.index);
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
        if (t.priority == TaskPriority.high) {
          grouped['高优先级']!.add(t);
        } else if (t.priority == TaskPriority.medium) {
          grouped['中优先级']!.add(t);
        } else if (t.priority == TaskPriority.low) {
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
        for (final cl in allChecklists) cl.id: cl.name,
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
          final date = DateTime(
            t.startTime!.year,
            t.startTime!.month,
            t.startTime!.day,
          );
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
    if (newChecklist == null || newChecklist.isToday) {
      stream = _taskRepository.watchTodayTasks();
    } else if (newChecklist.isTomorrow) {
      stream = _taskRepository.watchTomorrowTasks();
    } else if (newChecklist.isNextSevenDays) {
      stream = _taskRepository.watchNext7DaysTasks();
    } else if (newChecklist.isAll) {
      stream = _taskRepository.watchAllIncompleteTasks();
    } else if (newChecklist.isCompleted) {
      stream = _taskRepository.watchAllCompletedTasks();
    } else if (newChecklist.isTrash) {
      stream = _taskRepository.watchTrashTasks();
    } else {
      stream = _taskRepository.watchByChecklistId(newChecklist.id);
    }

    _currentTasksSubscription = stream.listen((tasks) {
      if (kDebugMode) {
        print(
          'DEBUG: Stream emitted tasks: $tasks, type: ${tasks.runtimeType}',
        );
      }
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

  Stream<List<Task>> watchAllTasks() => _taskRepository.watchAllTasks();

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

  Future<Map<int, int>> getSmartListCounts() async {
    final counts = <int, int>{};

    counts[AppConstants.todayCheckList.id] = await _taskRepository
        .getTodayTasksCount();
    counts[AppConstants.tomorrowCheckList.id] = await _taskRepository
        .getTomorrowTasksCount();
    counts[AppConstants.nextSevenDaysCheckList.id] = await _taskRepository
        .getNext7DaysTasksCount();
    counts[AppConstants.defaultCheckList.id] = await _taskRepository
        .getInboxTasksCount();
    counts[AppConstants.allCheckList.id] = await _taskRepository
        .getAllIncompleteTasksCount();
    counts[AppConstants.completedCheckList.id] = await _taskRepository
        .getAllCompletedTasksCount();
    counts[AppConstants.trashCheckList.id] = await _taskRepository
        .getTrashTasksCount();

    return counts;
  }

  // ==================================================================
  // 写入方法 (完全委派给 TaskService 处理，随后刷新本地状态与缓存)
  // ==================================================================

  Future<Task> addTask(Task newTask) async =>
      _taskLifecycleManager.addTask(newTask);

  Future<void> updateTaskIsDone(Task task, bool value) async {
    await _taskLifecycleManager.updateTaskIsDone(task, value);
  }

  Future<void> updateTitle(Task task, String newTitle) async {
    await _taskLifecycleManager.updateTitle(task, newTitle);
  }

  Future<void> updateDescription(Task task, String newDesc) async {
    await _taskLifecycleManager.updateDescription(task, newDesc);
  }

  Future<void> toggleCheckpoint(Task task, int index, bool value) async {
    await _taskLifecycleManager.toggleCheckpoint(task, index, value);
  }

  Future<void> renameCheckpoint(Task task, int index, String newName) async {
    await _taskLifecycleManager.renameCheckpoint(task, index, newName);
  }

  Future<void> addCheckpoint(Task task) async {
    await _taskLifecycleManager.addCheckpoint(task);
  }

  Future<void> removeCheckpoint(Task task, int index) async {
    await _taskLifecycleManager.removeCheckpoint(task, index);
  }

  Future<int> createSubTask(
    Task parent, {
    String name = UIStrings.subTask,
  }) async => _taskLifecycleManager.createSubTask(parent, name: name);

  Future<void> deleteSubTask(Task parent, int subTaskId) async {
    await _taskLifecycleManager.deleteSubTask(parent, subTaskId);
  }

  Future<void> updateChecklist(Task task, int? newChecklistId) async {
    await _taskLifecycleManager.updateChecklist(task, newChecklistId);
  }

  Future<void> updateStartTime(
    Task task,
    DateTime? newStartTime, {
    bool? isAllDay,
  }) async {
    await _taskLifecycleManager.updateStartTime(
      task,
      newStartTime,
      isAllDay: isAllDay,
    );
  }

  Future<void> updateEndTime(
    Task task,
    DateTime? newEndTime, {
    bool? isAllDay,
  }) async {
    await _taskLifecycleManager.updateEndTime(
      task,
      newEndTime,
      isAllDay: isAllDay,
    );
  }

  Future<void> updateTimeRange(
    Task task,
    DateTime? newStartTime,
    DateTime? newEndTime, {
    bool? isAllDay,
  }) async {
    await _taskLifecycleManager.updateTimeRange(
      task,
      newStartTime,
      newEndTime,
      isAllDay: isAllDay,
    );
  }

  Future<void> clearTaskSchedule(Task task) async {
    await _taskLifecycleManager.clearTaskSchedule(task);
  }

  Future<void> updateRRule(Task task, RepeatPattern? rrule) async {
    await _taskLifecycleManager.updateRRule(task, rrule);
  }

  Future<void> updateTaskReminder(
    Task task, {
    required bool enabled,
    int? offsetMinutes,
  }) async {
    await _taskLifecycleManager.updateTaskReminder(
      task,
      enabled: enabled,
      offsetMinutes: offsetMinutes,
    );
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

  Future<List<Task>> searchTasks({
    required String query,
    required TaskVisibleRange statusFilter,
    required bool searchInText,
    required bool searchInSubtasks,
    required bool searchInNotes,
  }) async {
    final allTasks = await _taskRepository.selectAll();
    allTasks.sort((a, b) => b.id.compareTo(a.id));

    if (query.isEmpty) {
      return [];
    }

    final normalizedQuery = query.toLowerCase();
    return allTasks.where((task) {
      // 1. 过滤完成状态
      if (statusFilter == TaskVisibleRange.undone && task.isDone) {
        return false;
      }
      if (statusFilter == TaskVisibleRange.done && !task.isDone) {
        return false;
      }

      // 2. 匹配关键字
      bool matches = false;
      final searchAll = !searchInText && !searchInSubtasks && !searchInNotes;

      if ((searchInText || searchAll) &&
          task.name.toLowerCase().contains(normalizedQuery)) {
        matches = true;
      }
      if (!matches &&
          (searchInNotes || searchAll) &&
          task.description.toLowerCase().contains(normalizedQuery)) {
        matches = true;
      }
      if (!matches && (searchInSubtasks || searchAll)) {
        for (final cp in task.checkpoints) {
          if (cp.name.toLowerCase().contains(normalizedQuery)) {
            matches = true;
            break;
          }
        }
      }

      return matches;
    }).toList();
  }

  Future<void> deleteTask(Task task) async {
    try {
      if (currentChecklist != null && currentChecklist!.isTrash) {
        await _taskLifecycleManager.deletePermanently(task);
        return;
      }
      await _taskLifecycleManager.deleteTask(task);
    } catch (e) {
      throw TaskException('Failed to delete task: ${e.toString()}');
    }
  }

  Future<void> restoreTask(Task task) async {
    await _taskLifecycleManager.restoreTask(task);
  }

  Future<void> associateMainTask(Task subTask, Task mainTask) async {
    await _taskLifecycleManager.associateMainTask(subTask, mainTask);
  }

  Future<void> copyTask(Task originalTask) async {
    await _taskLifecycleManager.copyTask(originalTask);
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

  Future<dynamic> execute(TaskOperation op) async {
    if (op is AddTask) {
      return addTask(op.task);
    } else if (op is UpdateTaskIsDone) {
      await updateTaskIsDone(op.task, op.value);
    } else if (op is UpdatePriority) {
      await updatePriority(op.task, op.newPriority);
    } else if (op is UpdateTags) {
      await updateTags(op.task, op.newTags);
    } else if (op is UpdateTitle) {
      await updateTitle(op.task, op.newTitle);
    } else if (op is UpdateDescription) {
      await updateDescription(op.task, op.newDesc);
    } else if (op is ToggleCheckpoint) {
      await toggleCheckpoint(op.task, op.index, op.value);
    } else if (op is RenameCheckpoint) {
      await renameCheckpoint(op.task, op.index, op.newName);
    } else if (op is AddCheckpoint) {
      await addCheckpoint(op.task);
    } else if (op is RemoveCheckpoint) {
      await removeCheckpoint(op.task, op.index);
    } else if (op is CreateSubTask) {
      return createSubTask(op.task, name: op.name);
    } else if (op is DeleteSubTask) {
      await deleteSubTask(op.task, op.subTaskId);
    } else if (op is UpdateChecklist) {
      await updateChecklist(op.task, op.newChecklistId);
    } else if (op is UpdateStartTime) {
      await updateStartTime(op.task, op.newStartTime, isAllDay: op.isAllDay);
    } else if (op is UpdateEndTime) {
      await updateEndTime(op.task, op.newEndTime, isAllDay: op.isAllDay);
    } else if (op is UpdateTimeRange) {
      await updateTimeRange(
        op.task,
        op.newStartTime,
        op.newEndTime,
        isAllDay: op.isAllDay,
      );
    } else if (op is ClearTaskSchedule) {
      await clearTaskSchedule(op.task);
    } else if (op is UpdateRRule) {
      await updateRRule(op.task, op.rrule);
    } else if (op is UpdateTaskReminder) {
      await updateTaskReminder(
        op.task,
        enabled: op.enabled,
        offsetMinutes: op.offsetMinutes,
      );
    } else if (op is DeleteTask) {
      await deleteTask(op.task);
    } else if (op is RestoreTask) {
      await restoreTask(op.task);
    } else if (op is AssociateMainTask) {
      await associateMainTask(op.task, op.mainTask);
    } else if (op is CopyTask) {
      await copyTask(op.task);
    }
  }
}
