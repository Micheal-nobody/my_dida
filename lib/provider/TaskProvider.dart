import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/model/vo/BelongingBoxVO.dart';
import 'package:my_dida/repository/TaskRepository.dart';

import '../config/locator.dart';
import '../model/entity/Task.dart';
import '../model/entity/CheckPoint.dart';
import '../model/entity/Operation.dart';
import '../provider/OperationStackProvider.dart';

/// 给TodoPage用的Provider！
class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _currentTasks = [];
  final TaskRepository _taskRepository;
  final OperationStackProvider _operationStack;

  //region 一系列getter
  List<Task> get tasks => _tasks;

  List<Task> get cur_tasks => _currentTasks;

  //endregion

  /// 创建时注入Repository，并且初始化_currentTasks
  TaskProvider(BelongingBoxVO? new_belongingBox)
    : _taskRepository = locator<TaskRepository>(),
      _operationStack = locator<OperationStackProvider>(),
      cur_belongingBox = new_belongingBox {
    updateCurTasks(cur_belongingBox);
  }

  // 依赖 BelongingBoxProvider.cur_belongingBox 更新 _currentTasks
  BelongingBoxVO?
  cur_belongingBox; // 用于性能优化，在更新前会被用来做判断，如果BelongingBoxProvider.cur_belongingBox 和 cur_belongingBox相等，则不更新
  updateCurTasks(BelongingBoxVO? new_belongingBox) async {
    // logger.i("因为 cur_belongingBox 改变所以更新 _currentTasks！");
    cur_belongingBox = new_belongingBox;

    if (new_belongingBox == null || new_belongingBox.id == -1) {
      await loadTodayTasks();
    } else {
      await loadTasksByBelongingBoxId(new_belongingBox.id);
    }
  }

  // 获取所有任务
  Future<void> loadAllTasks() async {
    _tasks = await _taskRepository.getAll();
    notifyListeners();
  }

  // 获得当前要显示的任务
  Future<void> loadCurrentBoxTasks() async {
    if (cur_belongingBox == null || cur_belongingBox!.id == -1) {
      await loadTodayTasks();
      return;
    }
    _currentTasks = await _taskRepository.getTasksByBelongingBoxId(
      cur_belongingBox!.id,
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

    await _taskRepository.addTask(newTask);

    // 记录添加任务操作
    final operation = Operation.createAddTaskOperation(newTask);
    print('TaskProvider: 创建操作记录: ${operation.description}');
    await _operationStack.addOperation(operation);

    loadCurrentBoxTasks();
  }

  Future<void> updateTaskIsDone(Task task, bool value) async {
    // 保存旧状态用于操作记录
    final oldTask = Task(
      name: task.name,
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

    // 1、更新数据库
    await _taskRepository.updateTaskIsDone(task, value);

    // 2、记录操作
    final newTask = Task(
      name: task.name,
      description: task.description,
      isDone: value,
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
      value ? '完成了任务"${task.name}"' : '取消了任务"${task.name}"的完成状态',
    );
    await _operationStack.addOperation(operation);

    // 3、更新数据
    loadCurrentBoxTasks();
  }

  //region 任务详情：对单个任务的增删改封装
  Stream<Task?> watchTaskById(int id) {
    return _taskRepository.watchById(id);
  }

  Future<Task?> getTaskById(int id) async {
    return await _taskRepository.getById(id);
  }

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

  // 复制任务
  Future<void> copyTask(Task originalTask) async {
    // 创建新任务，继承除了id以外的一切属性
    final copiedTask = Task(
      name: '${originalTask.name} (副本)',
      description: originalTask.description,
      isDone: false, // 复制的任务默认为未完成状态
      checkpoints: originalTask.checkpoints
          .map(
            (checkpoint) => CheckPoint(
              name: checkpoint.name,
              isDone: false, // 复制的检查点默认为未完成状态
            ),
          )
          .toList(),
      startTime: originalTask.startTime,
      endTime: originalTask.endTime,
      parentTaskId: null, // 复制的任务不继承父子关系
      subTaskIds: [], // 复制的任务不继承子任务
      belongingBoxId: originalTask.belongingBoxId,
      rrule: originalTask.rrule,
    );

    // 添加新任务到数据库
    await _taskRepository.addTask(copiedTask);

    // 记录复制操作
    final operation = Operation.createAddTaskOperation(copiedTask);
    await _operationStack.addOperation(operation);

    // 更新当前任务列表
    await loadCurrentBoxTasks();
  }

  //endregion
}
