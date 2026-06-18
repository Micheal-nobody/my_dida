import 'package:flutter/foundation.dart';
import 'package:my_dida/model/vo/checklist_vo.dart';

import '../config/locator.dart';
import '../model/entity/task.dart';
import '../model/vo/task_calendar_view_data.dart';
import '../repository/task_repository.dart';
import '../services/task_calendar_projection_service.dart';
import '../services/task_service.dart';

class TaskProvider with ChangeNotifier {
  TaskProvider(
    ChecklistVO? newChecklist, {
    TaskRepository? taskRepository,
    TaskService? taskService,
    TaskCalendarProjectionService? taskCalendarProjectionService,
  }) : _taskRepository = taskRepository ?? getIt<TaskRepository>(),
       _taskService = taskService ?? getIt<TaskService>(),
       _taskCalendarProjectionService =
           taskCalendarProjectionService ?? getIt<TaskCalendarProjectionService>(),
       currentChecklist = newChecklist {
    updateCurrentTasks(currentChecklist);
  }

  final TaskRepository _taskRepository;
  final TaskService _taskService;
  final TaskCalendarProjectionService _taskCalendarProjectionService;

  List<Task> _tasks = [];
  List<Task> _currentTasks = [];
  final Map<String, List<Task>> _taskCache = {};
  DateTime? _lastCacheUpdate;

  static const Duration _cacheValidDuration = Duration(minutes: 5);

  List<Task> get tasks => _tasks;

  List<Task> get currentTasks => _currentTasks;

  ChecklistVO? currentChecklist;

  Future<void> updateCurrentTasks(ChecklistVO? newChecklist) async {
    currentChecklist = newChecklist;

    if (newChecklist == null || newChecklist.id == -1) {
      await loadTodayTasks();
      return;
    }

    await loadTasksByChecklistId(newChecklist.id);
  }

  bool _isCacheValid() {
    return _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration;
  }

  String _getCacheKey(String operation, [String? param]) {
    return param != null ? '${operation}_$param' : operation;
  }

  void _invalidateCache() {
    _taskCache.clear();
    _lastCacheUpdate = null;
  }

  Future<void> loadAllTasks() async {
    const cacheKey = 'all_tasks';
    if (_isCacheValid() && _taskCache.containsKey(cacheKey)) {
      _tasks = _taskCache[cacheKey]!;
      notifyListeners();
      return;
    }

    _tasks = await _taskRepository.selectAll();
    _taskCache[cacheKey] = _tasks;
    _lastCacheUpdate = DateTime.now();
    notifyListeners();
  }

  Future<List<Task>> loadTasksForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final cacheKey = _getCacheKey(
      'date_range',
      '${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}',
    );

    if (_isCacheValid() && _taskCache.containsKey(cacheKey)) {
      _tasks = _taskCache[cacheKey]!;
      return _taskCache[cacheKey]!;
    }

    final tasks = await _taskRepository.getTasksForDateRange(
      startDate,
      endDate,
    );
    _tasks = tasks;
    _taskCache[cacheKey] = tasks;
    _lastCacheUpdate = DateTime.now();
    return tasks;
  }

  Future<void> loadCurrentBoxTasks() async {
    if (currentChecklist == null || currentChecklist!.id == -1) {
      await loadTodayTasks();
      return;
    }

    _currentTasks = await _taskRepository.getTasksByChecklistId(
      currentChecklist!.id,
    );
    notifyListeners();
  }

  Future<void> loadTodayTasks() async {
    _currentTasks = await _taskRepository.getTodayTasks();
    notifyListeners();
  }

  Future<void> loadTasksByChecklistId(int checklistId) async {
    _currentTasks = await _taskRepository.getTasksByChecklistId(checklistId);
    notifyListeners();
  }

  Stream<Task?> watchTaskById(int id) => _taskRepository.watchById(id);

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

  Future<void> addTask(Task newTask) async {
    await _taskService.createTask(
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
    await _reloadAfterMutation();
  }

  Future<void> updateTaskIsDone(Task task, bool value) async {
    await _taskService.updateTaskCompletion(task, value);
    await _reloadAfterMutation();
  }

  Future<void> updateTitle(Task task, String newTitle) async {
    await _taskService.updateTaskTitle(task, newTitle);
    await _reloadAfterMutation();
  }

  Future<void> updateDescription(Task task, String newDesc) async {
    await _taskService.updateTaskDescription(task, newDesc);
    await _reloadAfterMutation();
  }

  Future<void> toggleCheckpoint(Task task, int index, bool value) async {
    await _taskService.toggleCheckpoint(task, index, value);
    await _reloadAfterMutation();
  }

  Future<void> renameCheckpoint(Task task, int index, String newName) async {
    await _taskService.renameCheckpoint(task, index, newName);
    await _reloadAfterMutation();
  }

  Future<void> addCheckpoint(Task task) async {
    await _taskService.addCheckpoint(task);
    await _reloadAfterMutation();
  }

  Future<void> removeCheckpoint(Task task, int index) async {
    await _taskService.removeCheckpoint(task, index);
    await _reloadAfterMutation();
  }

  Future<int> createSubTask(Task parent) async {
    final taskId = await _taskService.createSubTask(parent);
    await _reloadAfterMutation();
    return taskId;
  }

  Future<void> deleteSubTask(Task parent, int subTaskId) async {
    await _taskService.deleteSubTask(parent, subTaskId);
    await _reloadAfterMutation();
  }

  Future<void> updateChecklist(Task task, int? newChecklistId) async {
    await _taskService.updateChecklist(task, newChecklistId);
    await _reloadAfterMutation();
  }

  Future<void> updateStartTime(
    Task task,
    DateTime? newStartTime, {
    bool? isAllDay,
  }) async {
    await _taskService.updateTaskTimeRange(
      task,
      newStartTime,
      task.endTime,
      isAllDay: isAllDay,
    );
    await _reloadAfterMutation();
  }

  Future<void> updateEndTime(
    Task task,
    DateTime? newEndTime, {
    bool? isAllDay,
  }) async {
    await _taskService.updateTaskTimeRange(
      task,
      task.startTime,
      newEndTime,
      isAllDay: isAllDay,
    );
    await _reloadAfterMutation();
  }

  Future<void> updateTimeRange(
    Task task,
    DateTime? newStartTime,
    DateTime? newEndTime, {
    bool? isAllDay,
  }) async {
    await _taskService.updateTaskTimeRange(
      task,
      newStartTime,
      newEndTime,
      isAllDay: isAllDay,
    );
    await _reloadAfterMutation();
  }

  Future<void> clearTaskSchedule(Task task) async {
    await _taskService.clearTaskSchedule(task);
    await _reloadAfterMutation();
  }

  Future<void> updateRRule(Task task, String? rrule) async {
    await _taskService.updateTaskRRule(task, rrule);
    await _reloadAfterMutation();
  }

  Future<void> updateTaskReminder(
    Task task, {
    required bool enabled,
    int? offsetMinutes,
  }) async {
    await _taskService.updateTaskReminder(
      task,
      enabled: enabled,
      offsetMinutes: offsetMinutes,
    );
    await _reloadAfterMutation();
  }

  Future<void> deleteTask(Task task) async {
    await _taskService.deleteTask(task);
    await _reloadAfterMutation();
  }

  Future<List<Task>> searchIncompleteTasks(String query) {
    return _taskService.searchIncompleteTasks(query);
  }

  Future<void> associateMainTask(Task subTask, Task mainTask) async {
    await _taskService.associateMainTask(subTask, mainTask);
    await _reloadAfterMutation();
  }

  Future<void> copyTask(Task originalTask) async {
    await _taskService.copyTask(originalTask);
    await _reloadAfterMutation();
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

  Future<void> _reloadAfterMutation() async {
    _invalidateCache();
    await loadCurrentBoxTasks();
  }
}
