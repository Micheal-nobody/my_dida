import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/model/vo/BelongingBoxVO.dart';
import 'package:my_dida/provider/BelongingBoxProvider.dart';
import 'package:my_dida/repository/TaskRepository.dart';
import 'package:provider/provider.dart';

import '../locator/locator.dart';
import '../model/entity/Task.dart';
import '../model/vo/TaskVO.dart';

/// 给TodoPage用的Provider！
class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _currentTasks = [];
  bool _isLoading = false;
  final TaskRepository _repository;

  //region 一系列getter
  List<Task> get tasks => _tasks;
  List<Task> get cur_tasks => _currentTasks;
  bool get isLoading => _isLoading;
  //endregion


  /// 创建时注入Repository，并且初始化_currentTasks
  TaskProvider(BelongingBoxVO? cur_belongingBox)
      : _repository = locator<TaskRepository>(),
      cur_belongingBox = cur_belongingBox {
    updateCurTasks(cur_belongingBox);
  }

  // 依赖 BelongingBoxProvider.cur_belongingBox 更新 _currentTasks
  BelongingBoxVO?  cur_belongingBox; // 用于性能优化，在更新前会被用来做判断，如果BelongingBoxProvider.cur_belongingBox 和 cur_belongingBox相等，则不更新
  updateCurTasks(BelongingBoxVO? cur_belongingBox) async {
    print("更新 _currentTasks");
    this.cur_belongingBox = cur_belongingBox;

    if(cur_belongingBox == null || cur_belongingBox.id == -1){
      await loadTodayTasks();
    }else{
      await loadTasksByBelongingBoxId(
        cur_belongingBox!.id,
      );
    }
  }


  /// 获取所有任务
  Future<void> loadAllTasks() async {
    // 设置加载状态为 true
    _isLoading = true;
    _tasks = await _repository.getAll();
    _isLoading = false;

    // 通知监听者状态已改变
    notifyListeners();
  }

  //TODO:获得当前要显示的任务
  Future<void> loadCurrentTasks() async {
    // 设置加载状态为 true
    _isLoading = true;
    notifyListeners();

    _currentTasks = await _repository.getAll();
    _isLoading = false;

    // 通知监听者状态已改变
    notifyListeners();
  }

  //TODO: 根据VO生成Wight，或许不应该写入Provider之中？
  void generateTestAllTodos() {
    notifyListeners(); // 通知监听者状态已更改
  }

  /// 获得今天所有的待办事项
  Future<void> loadTodayTasks() async {
    _isLoading = true;
    notifyListeners();

    _currentTasks = await _repository.getTodayTasks();
    _isLoading = false;
    notifyListeners();
  }

  /// 获得某个收藏夹下的所有待办事项
  Future<void> loadTasksByBelongingBoxId(int belongingBoxId) async {
    _isLoading = true;
    notifyListeners();

    _currentTasks = await _repository.getTasksByBelongingBoxId(belongingBoxId);
    _isLoading = false;
    notifyListeners();
  }

  //TODO: 获得 某一天所有的待办事项
  // Future<List<TaskVO>> getTodosForDate(DateTime date) async {
  //   List<Task> tasks = await _repository.getTodosForDate(date);
  //   List<TaskVO> todos = [ for (var task in tasks) convertToVO(task) ];;
  //
  //   return todos;
  // }

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


  //TODO: 如果添加的任务属于一个盒子，则需要刷新页面！但是 notifyListeners()也够用！
  Future<void> addTask(Task newTask) async {
    await _repository.addTask(newTask);
    notifyListeners();
  }
}
