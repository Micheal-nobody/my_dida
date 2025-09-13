import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/model/vo/BelongingBoxVO.dart';
import 'package:my_dida/repository/TaskRepository.dart';

import '../config/locator.dart';
import '../model/entity/Task.dart';
import '../model/vo/TaskVO.dart';
import '../model/entity/CheckPoint.dart';

/// 给TodoPage用的Provider！
class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _currentTasks = [];
  final TaskRepository _taskRepository;

  //region 一系列getter
  List<Task> get tasks => _tasks;

  List<Task> get cur_tasks => _currentTasks;

  //endregion

  /// 创建时注入Repository，并且初始化_currentTasks
  TaskProvider(BelongingBoxVO? new_belongingBox)
    : _taskRepository = locator<TaskRepository>(),
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
    await _taskRepository.addTask(newTask);
    loadCurrentBoxTasks();
  }

  Future<void> updateTaskIsDone(Task task, bool value) async {
    // 1、更新数据库
    await _taskRepository.updateTaskIsDone(task, value);

    // 2、更新数据
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
    await _taskRepository.update(task..name = newTitle);
  }

  Future<void> updateDescription(Task task, String newDesc) async {
    await _taskRepository.update(task..description = newDesc);
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
    await _taskRepository.update(task..startTime = newStartTime);
    await loadCurrentBoxTasks();
  }

  //endregion
}
