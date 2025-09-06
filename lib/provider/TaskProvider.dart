import 'package:flutter/cupertino.dart';
import 'package:my_dida/repository/TaskRepository.dart';

import '../locator/locator.dart';
import '../model/entity/Task.dart';
import '../model/vo/TaskVO.dart';

class TaskProvider with ChangeNotifier {
  final TaskRepository _repository;
  List<Task> _tasks = [];
  bool _isLoading = false;

  TaskProvider(): _repository = locator<TaskRepository>();

  // 状态字段
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  // 业务方法
  Future<void> loadTasks() async {
    // 设置加载状态为 true
    _isLoading = true;

    //TODO： 通知监听者状态已改变，这里需要通知吗？
    notifyListeners();

    _tasks = await _repository.getAll();
    _isLoading = false;

    // 通知监听者状态已改变
    notifyListeners();
  }


  // Future<void> addTask(String title) async {
  //   final task = Task()..title = title;
  //   await _repository.createTask(task);
  //   await loadTasks(); // 更新状态
  // }
  //
  // Future<void> toggleTask(int taskId) async {
  //   // 业务逻辑：先获取，再修改，再保存
  //   final task = await _repository.getTaskById(taskId);
  //   if (task != null) {
  //     task.isCompleted = !task.isCompleted;
  //     await _repository.updateTask(task);
  //     await loadTasks(); // 更新状态
  //   }
  // }

  Task convertToEntity(TaskVO vo){
    return Task(name: vo.name)
      ..id = vo.id
      ..description = vo.description
      ..isDone = vo.isDone
      ..checkpoints = vo.checkpoints
      ..startTime = vo.startTime
      ..endTime = vo.endTime
      ..parentTaskId = vo.parentTask?.id
      ..subTaskIds = [ for (var subTask in vo.subTasks) subTask.id ]
      ..belongingBoxId = vo.belongingBox?.id
    ;
  }

  TaskVO convertToVO(Task entity){
    return TaskVO(id: entity.id, name: entity.name)
        ..description = entity.description
        ..isDone = entity.isDone
        ..checkpoints = entity.checkpoints
        ..startTime = entity.startTime
        ..endTime = entity.endTime
        ..parentTask = null
        ..subTasks = [];
        // ..parentTask = entity.parentTaskId != null ? convertToVO(await _repository.getTaskById(entity.parentTaskId)) : null
        // ..subTasks = [ for (var subTaskId in entity.subTaskIds) convertToVO(await _repository.getTaskById(subTaskId)) ];
  }
}