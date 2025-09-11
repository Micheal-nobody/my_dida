import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/model/vo/BelongingBoxVO.dart';
import 'package:my_dida/provider/BelongingBoxProvider.dart';
import 'package:my_dida/repository/TaskRepository.dart';
import 'package:provider/provider.dart';

import '../config/locator.dart';
import '../model/entity/Task.dart';
import '../model/vo/TaskVO.dart';

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
  TaskProvider(BelongingBoxVO? cur_belongingBox)
      : _taskRepository = locator<TaskRepository>(),
      cur_belongingBox = cur_belongingBox {
    updateCurTasks(cur_belongingBox);
  }

  // 依赖 BelongingBoxProvider.cur_belongingBox 更新 _currentTasks
  BelongingBoxVO?  cur_belongingBox; // 用于性能优化，在更新前会被用来做判断，如果BelongingBoxProvider.cur_belongingBox 和 cur_belongingBox相等，则不更新
  updateCurTasks(BelongingBoxVO? new_belongingBox) async {
    // logger.i("因为 cur_belongingBox 改变所以更新 _currentTasks！");
    cur_belongingBox = new_belongingBox;

    if(new_belongingBox == null || new_belongingBox.id == -1){
      await loadTodayTasks();
    }else{
      await loadTasksByBelongingBoxId(
        new_belongingBox.id,
      );
    }
  }

  // 获取所有任务
  Future<void> loadAllTasks() async {
    _tasks = await _taskRepository.getAll();
    notifyListeners();
  }

  // 获得当前要显示的任务
  Future<void> loadCurrentBoxTasks() async {
    if(cur_belongingBox == null || cur_belongingBox!.id == -1){
      await loadTodayTasks();
      return;
    }
    _currentTasks = await _taskRepository.getTasksByBelongingBoxId(cur_belongingBox!.id);
    notifyListeners();
  }

  // 获得今天所有的待办事项
  Future<void> loadTodayTasks() async {
    _currentTasks = await _taskRepository.getTodayTasks();
    notifyListeners();
  }

  // 获得某个收藏夹下的所有待办事项
  Future<void> loadTasksByBelongingBoxId(int belongingBoxId) async {
    _currentTasks = await _taskRepository.getTasksByBelongingBoxId(belongingBoxId);
    notifyListeners();
  }

  //region 看起来没什么用的转换
  Task convertToEntity(TaskVO vo) {
    return Task(name: vo.name)
      ..id = vo.id
      ..description = vo.description
      ..isDone = vo.isDone
      ..checkpoints = vo.checkpoints
      ..startTime = vo.startTime
      ..endTime = vo.endTime
      ..parentTaskId = vo.parentTask?.id
      ..subTaskIds = [for (var subTask in vo.subTasks) subTask.id]
      ..belongingBoxId = vo.belongingBox?.id;
  }

  //TODO: 完善 parentTask 和 subTasks
  TaskVO convertToVO(Task entity) {
    // ..parentTask = entity.parentTaskId != null ? convertToVO(await _repository.getTaskById(entity.parentTaskId)) : null
    // ..subTasks = [ for (var subTaskId in entity.subTaskIds) convertToVO(await _repository.getTaskById(subTaskId)) ];

    return TaskVO(id: entity.id, name: entity.name)
      ..description = entity.description
      ..isDone = entity.isDone
      ..checkpoints = entity.checkpoints
      ..startTime = entity.startTime
      ..endTime = entity.endTime
      ..parentTask = null
      ..subTasks = []
      ..belongingBox = null;
  }
  //endregion

  //TODO: 如果添加的任务属于一个盒子，则需要刷新页面！但是 notifyListeners()也够用！
  Future<void> addTask(Task newTask) async {
    await _taskRepository.addTask(newTask);
    loadCurrentBoxTasks();
  }

  void updateTaskIsDone(Task task, bool value) {
    // 1、更新数据库
    _taskRepository.updateTaskIsDone(task, value);

    // 2、更新数据
    loadCurrentBoxTasks();
  }
}

