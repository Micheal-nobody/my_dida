
// @Collection
import 'dart:ui';

import 'package:isar/isar.dart';
part 'Task.g.dart';

//TODO:接入 Isar 数据库！
@Collection()
class Task {
  Id id = Isar.autoIncrement;

  String name;
  String description;
  bool isDone;

  /// 检查点
  List<int> checkpointIds;

  /// 时间（两个时间是因为任务可以接受 时间段/时间点）
  DateTime? startTime;
  DateTime? endTime;

  /// 父子任务
  int? parentTaskId;
  List<int> subTaskIds;

  /// 所属收集箱
  int? belongingBoxId;


  /// Constructor for TodoItem
  Task({
    required this.name,
    this.description = '',
    this.isDone = false,

    this.checkpointIds = const [],

    /// 两个时间默认为 null
    this.startTime,
    this.endTime,

    /// 父子任务
    this.parentTaskId,
    this.subTaskIds = const [],

    /// 所属收集箱
    this.belongingBoxId = 0,
  });

  //
  // void addCheckPoint(String name) {
  //   checkpoints.add(CheckPoint(name: name));
  // }
  // void removeCheckPoint(int index) {
  //   checkpoints.removeAt(index);
  // }
  //
  // void addChild(TaskId childId) {
  //   child.parentTaskId = this; // Set the parent of the child
  //   subTasks.add(child);
  // }
  // void removeChild(int index) {
  //   subTasks.removeAt(index);
  // }
}