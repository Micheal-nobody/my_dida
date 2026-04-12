import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/model/vo/checklist_vo.dart';
import 'package:my_dida/repository/task_repository.dart';

import '../config/locator.dart';
import '../model/entity/CheckPoint.dart';
import '../model/entity/Operation.dart';
import '../model/entity/Task.dart';
import '../provider/operation_stack_provider.dart';
import '../services/task_service.dart';

/// Optimized TaskProvider with performance improvements
class TaskProvider with ChangeNotifier {
  //endregion

  /// 创建时注入Repository，并且初始化_currentTasks
  TaskProvider(ChecklistVO? newBelongingBox)
    : _taskRepository = getIt<TaskRepository>(),
      _operationStack = getIt<OperationStackProvider>(),
      _taskService = TaskService(),
      currentBelongingBox = newBelongingBox {
    updateCurrentTasks(currentBelongingBox);
  }

  List<Task> _tasks = [];
  List<Task> _currentTasks = [];
  final TaskRepository _taskRepository;
  final OperationStackProvider _operationStack;
  final TaskService _taskService;

  // Cache for frequently accessed data
  final Map<String, List<Task>> _taskCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  //region 一系列getter
  List<Task> get tasks => _tasks;

  List<Task> get currentTasks => _currentTasks;

  // 依赖 BelongingBoxProvider.currentBelongingBox 更新 _currentTasks
  ChecklistVO?
  currentBelongingBox; // 用于性能优化，在更新前会被用来做判断，如果BelongingBoxProvider.currentBelongingBox 和 currentBelongingBox相等，则不更新

  Future<void> updateCurrentTasks(ChecklistVO? newBelongingBox) async {
    // logger.i("因为 currentBelongingBox 改变所以更新 _currentTasks！");
    currentBelongingBox = newBelongingBox;

    if (newBelongingBox == null || newBelongingBox.id == -1) {
      await loadTodayTasks();
    } else {
      await loadTasksByBelongingBoxId(newBelongingBox.id);
    }
  }

  // Cache management methods
  bool _isCacheValid() =>
      _lastCacheUpdate != null &&
      DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration;

  void _invalidateCache() {
    _taskCache.clear();
    _lastCacheUpdate = null;
  }

  String _getCacheKey(String operation, [String? param]) =>
      param != null ? '${operation}_$param' : operation;

  // 获取所有任务 - with caching
  Future<void> loadAllTasks() async {
    const cacheKey = 'all_tasks';

    if (_isCacheValid() && _taskCache.containsKey(cacheKey)) {
      _tasks = _taskCache[cacheKey]!;
      notifyListeners();
      return;
    }

    _tasks = await _taskRepository.getAll();
    _taskCache[cacheKey] = _tasks;
    _lastCacheUpdate = DateTime.now();
    notifyListeners();
  }

  // Optimized method to load tasks for date range
  Future<List<Task>> loadTasksForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final cacheKey = _getCacheKey(
      'date_range',
      '${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}',
    );

    if (_isCacheValid() && _taskCache.containsKey(cacheKey)) {
      return _taskCache[cacheKey]!;
    }

    final tasks = await _taskRepository.getTasksForDateRange(
      startDate,
      endDate,
    );
    _taskCache[cacheKey] = tasks;
    _lastCacheUpdate = DateTime.now();

    return tasks;
  }

  // 获得当前要显示的任务
  Future<void> loadCurrentBoxTasks() async {
    if (currentBelongingBox == null || currentBelongingBox!.id == -1) {
      await loadTodayTasks();
      return;
    }
    _currentTasks = await _taskRepository.getTasksByBelongingBoxId(
      currentBelongingBox!.id,
    );
    notifyListeners();
  }

  // 获得今天所有的待办事项
  Future<void> loadTodayTasks() async {
    _currentTasks = await _taskRepository.getTodayTasks();
    notifyListeners();
  }

  // 获得某个收藏夹下的所有待办事项
  Future<void> loadTasksByBelongingBoxId(int belongingBoxId) async {
    _currentTasks = await _taskRepository.getTasksByBelongingBoxId(
      belongingBoxId,
    );
    notifyListeners();
  }

  Future<void> addTask(Task newTask) async {
    print('TaskProvider: 开始添加任务: ${newTask.name}');

    try {
      await _taskService.createTask(
        name: newTask.name,
        isAllDay: newTask.isAllDay,
        description: newTask.description,
        startTime: newTask.startTime,
        endTime: newTask.endTime,
        parentTaskId: newTask.parentTaskId,
        belongingBoxId: newTask.belongingBoxId,
        rrule: newTask.rrule,
      );

      // Invalidate cache after modification
      _invalidateCache();
      await loadCurrentBoxTasks();
    } catch (e) {
      print('TaskProvider: Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTaskIsDone(Task task, bool value) async {
    try {
      await _taskService.updateTaskCompletion(task, value);

      // Invalidate cache after modification
      _invalidateCache();
      await loadCurrentBoxTasks();
    } catch (e) {
      print('TaskProvider: Error updating task completion: $e');
      rethrow;
    }
  }

  //region 任务详情：对单个任务的增删改封装
  Stream<Task?> watchTaskById(int id) => _taskRepository.watchById(id);

  Future<Task?> getTaskById(int id) async => _taskRepository.getById(id);

  Future<List<Task>> getTasksByIds(List<int> ids) async {
    final List<Task> tasks = [];
    for (final id in ids) {
      final Task? t = await _taskRepository.getById(id);
      if (t != null) tasks.add(t);
    }
    return tasks;
  }

  Future<void> updateTitle(Task task, String newTitle) async {
    // 保存旧状态
    final oldTask = Task(
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

    await _taskRepository.update(task..name = newTitle);

    // 记录操作
    final newTask = Task(
      name: newTitle,
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

    final operation = Operation.createUpdateTaskOperation(
      oldTask,
      newTask,
      '修改了任务标题为"$newTitle"',
    );
    await _operationStack.addOperation(operation);
  }

  Future<void> updateDescription(Task task, String newDesc) async {
    // 保存旧状态
    final oldTask = Task(
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

    await _taskRepository.update(task..description = newDesc);

    // 记录操作
    final newTask = Task(
      name: task.name,
      isAllDay: task.isAllDay,
      description: newDesc,
      isDone: task.isDone,
      checkpoints: task.checkpoints,
      startTime: task.startTime,
      endTime: task.endTime,
      parentTaskId: task.parentTaskId,
      subTaskIds: task.subTaskIds,
      belongingBoxId: task.belongingBoxId,
      rrule: task.rrule,
    )..id = task.id;

    final operation = Operation.createUpdateTaskOperation(
      oldTask,
      newTask,
      '修改了任务"${task.name}"的描述',
    );
    await _operationStack.addOperation(operation);
  }

  Future<void> toggleCheckpoint(Task task, int index, bool value) async {
    final List<CheckPoint> updated = List.of(task.checkpoints);
    updated[index] = CheckPoint(name: updated[index].name, isDone: value);
    await _taskRepository.update(task..checkpoints = updated);
  }

  Future<void> renameCheckpoint(Task task, int index, String newName) async {
    final List<CheckPoint> updated = List.of(task.checkpoints);
    updated[index] = CheckPoint(name: newName, isDone: updated[index].isDone);
    await _taskRepository.update(task..checkpoints = updated);
  }

  Future<void> addCheckpoint(Task task) async {
    final List<CheckPoint> updated = List.of(task.checkpoints)
      ..add(CheckPoint(name: '新检查点'));
    await _taskRepository.update(task..checkpoints = updated);
  }

  Future<void> removeCheckpoint(Task task, int index) async {
    final List<CheckPoint> updated = List.of(task.checkpoints)..removeAt(index);
    await _taskRepository.update(task..checkpoints = updated);
  }

  Future<int> createSubTask(Task parent) async {
    final Task sub = Task(
      name: '子任务',
      isAllDay: false,
      parentTaskId: parent.id,
      belongingBoxId: parent.belongingBoxId,
    );
    final int newId = await _taskRepository.insert(sub);
    final List<int> newIds = List.of(parent.subTaskIds)..add(newId);
    await _taskRepository.update(parent..subTaskIds = newIds);
    return newId;
  }

  Future<void> deleteSubTask(Task parent, int subTaskId) async {
    await _taskRepository.deleteById(subTaskId);
    final List<int> newIds = List.of(parent.subTaskIds)..remove(subTaskId);
    await _taskRepository.update(parent..subTaskIds = newIds);
  }

  Future<void> updateBelongingBox(Task task, int? newBelongingBoxId) async {
    await _taskRepository.update(task..belongingBoxId = newBelongingBoxId);
    await loadCurrentBoxTasks();
  }

  Future<void> updateStartTime(Task task, DateTime? newStartTime) async {
    // 保存旧状态
    final oldTask = Task(
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

    await _taskRepository.update(task..startTime = newStartTime);

    // 记录操作
    final newTask = Task(
      name: task.name,
      isAllDay: task.isAllDay,
      description: task.description,
      isDone: task.isDone,
      checkpoints: task.checkpoints,
      startTime: newStartTime,
      endTime: task.endTime,
      parentTaskId: task.parentTaskId,
      subTaskIds: task.subTaskIds,
      belongingBoxId: task.belongingBoxId,
      rrule: task.rrule,
    )..id = task.id;

    final operation = Operation.createUpdateTaskOperation(
      oldTask,
      newTask,
      '修改了任务"${task.name}"的开始时间',
    );
    await _operationStack.addOperation(operation);

    await loadCurrentBoxTasks();
  }

  Future<void> updateEndTime(Task task, DateTime? newEndTime) async {
    // 保存旧状态
    final oldTask = Task(
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

    await _taskRepository.update(task..endTime = newEndTime);

    // 记录操作
    final newTask = Task(
      name: task.name,
      isAllDay: task.isAllDay,
      description: task.description,
      isDone: task.isDone,
      checkpoints: task.checkpoints,
      startTime: task.startTime,
      endTime: newEndTime,
      parentTaskId: task.parentTaskId,
      subTaskIds: task.subTaskIds,
      belongingBoxId: task.belongingBoxId,
      rrule: task.rrule,
    )..id = task.id;

    final operation = Operation.createUpdateTaskOperation(
      oldTask,
      newTask,
      '修改了任务"${task.name}"的结束时间',
    );
    await _operationStack.addOperation(operation);

    await loadCurrentBoxTasks();
  }

  Future<void> updateTimeRange(
    Task task,
    DateTime? newStartTime,
    DateTime? newEndTime,
  ) async {
    // 保存旧状态
    final oldTask = Task(
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

    await _taskRepository.update(
      task
        ..startTime = newStartTime
        ..endTime = newEndTime,
    );

    // 记录操作
    final newTask = Task(
      name: task.name,
      isAllDay: task.isAllDay,
      description: task.description,
      isDone: task.isDone,
      checkpoints: task.checkpoints,
      startTime: newStartTime,
      endTime: newEndTime,
      parentTaskId: task.parentTaskId,
      subTaskIds: task.subTaskIds,
      belongingBoxId: task.belongingBoxId,
      rrule: task.rrule,
    )..id = task.id;

    final operation = Operation.createUpdateTaskOperation(
      oldTask,
      newTask,
      '修改了任务"${task.name}"的时间范围',
    );
    await _operationStack.addOperation(operation);

    await loadCurrentBoxTasks();
  }

  Future<void> deleteTask(Task task) async {
    // 记录删除操作
    final operation = Operation.createDeleteTaskOperation(task);
    await _operationStack.addOperation(operation);

    await _taskRepository.deleteById(task.id);
    await loadCurrentBoxTasks();
  }

  // 搜索未完成的任务
  Future<List<Task>> searchIncompleteTasks(String query) async {
    final allTasks = await _taskRepository.getAll();
    final incompleteTasks = allTasks.where((task) => !task.isDone).toList();

    // 按创建时间排序（最新的在前）
    incompleteTasks.sort((a, b) => b.id.compareTo(a.id));

    if (query.isEmpty) {
      // 返回最近创建的10个任务
      return incompleteTasks.take(10).toList();
    }

    final filteredTasks = incompleteTasks
        .where(
          (task) =>
              task.name.toLowerCase().contains(query.toLowerCase()) ||
              task.description.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return filteredTasks;
  }

  // 关联主任务
  Future<void> associateMainTask(Task subTask, Task mainTask) async {
    // 1. 更新子任务的parentTaskId
    await _taskRepository.update(subTask..parentTaskId = mainTask.id);

    // 2. 更新主任务的subTaskIds，添加子任务ID（避免重复添加）
    final updatedSubTaskIds = List<int>.from(mainTask.subTaskIds);
    if (!updatedSubTaskIds.contains(subTask.id)) {
      updatedSubTaskIds.add(subTask.id);
      await _taskRepository.update(mainTask..subTaskIds = updatedSubTaskIds);
    }

    await loadCurrentBoxTasks();
  }

  // 更新重复规则
  Future<void> updateRRule(Task task, String? rrule) async {
    // 保存旧状态
    final oldTask = Task(
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

    await _taskRepository.update(task..rrule = rrule);

    // 记录操作
    final newTask = Task(
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
      rrule: rrule,
    )..id = task.id;

    final operation = Operation.createUpdateTaskOperation(
      oldTask,
      newTask,
      '修改了任务"${task.name}"的重复规则',
    );
    await _operationStack.addOperation(operation);

    await loadCurrentBoxTasks();
  }

  // 复制任务（递归复制子任务）
  Future<void> copyTask(Task originalTask) async {
    // 递归复制任务及其所有子任务
    await _copyTaskRecursively(originalTask, null);

    // 更新当前任务列表
    await loadCurrentBoxTasks();
  }

  // 递归复制任务及其子任务的私有方法
  Future<Task> _copyTaskRecursively(
    Task originalTask,
    int? newParentTaskId,
  ) async {
    // 创建新任务，继承除了id以外的一切属性
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
      // 设置新的父任务ID
      subTaskIds: [],
      // 先设为空，稍后会递归复制子任务
      belongingBoxId: originalTask.belongingBoxId,
      rrule: originalTask.rrule,
    );

    // 添加新任务到数据库
    await _taskRepository.addTask(copiedTask);

    // 记录复制操作
    final operation = Operation.createAddTaskOperation(copiedTask);
    await _operationStack.addOperation(operation);

    // 递归复制所有子任务
    final List<int> newSubTaskIds = [];
    for (final subTaskId in originalTask.subTaskIds) {
      final subTask = await _taskRepository.getById(subTaskId);
      if (subTask != null) {
        final copiedSubTask = await _copyTaskRecursively(
          subTask,
          copiedTask.id,
        );
        newSubTaskIds.add(copiedSubTask.id);
      }
    }

    // 更新复制任务的子任务ID列表
    await _taskRepository.update(copiedTask..subTaskIds = newSubTaskIds);

    return copiedTask;
  }

  //endregion
}
