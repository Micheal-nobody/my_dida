import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/repository/TaskRepository.dart';

import '../locator/locator.dart';
import '../model/entity/Task.dart';
import '../model/vo/TaskVO.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _currentTasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;

  List<Task> get currentTasks => _currentTasks;

  bool get isLoading => _isLoading;

  final TaskRepository _repository;

  TaskProvider() : _repository = locator<TaskRepository>();

  // 业务方法
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

  Future<void> loadTodayTasks() async {
    _isLoading = true;
    notifyListeners();

    _currentTasks = await _repository.getTodayTasks();
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

  //TODO: 这是暂时的测试数据
  void initTasks() {
    _currentTasks = [
      Task(name: "Task 1"),
      Task(name: "Task 2"),
      Task(name: "Task 3"),
    ];

    notifyListeners();
  }



  //TODO: 如果添加的任务属于一个盒子，则需要刷新页面！
  Future<void> addTask(Task newTask) async {
    await _repository.addTask(newTask);
    notifyListeners();
  }
}
