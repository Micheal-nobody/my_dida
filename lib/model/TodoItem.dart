
// @Collection
import 'dart:ui';

import 'package:isar/isar.dart';

//TODO:接入 Isar 数据库！
@Collection()
class TodoItem {
  Id id = Isar.autoIncrement;

  String name;
  String description;
  bool isDone;

  /// 检查点
  List<_CheckPoint> checkpoints;

  /// 时间（两个时间是因为任务可以接受 时间段/时间点）
  DateTime? startTime;
  DateTime? endTime;

  /// 父子任务
  TodoItem? parentTask;
  List<TodoItem> subTasks;

  /// 所属收集箱
  BelongingBox? belongingBox;



  /// Constructor for TodoItem
  TodoItem({
    required this.name,
    this.description = '',
    this.isDone = false,

    this.checkpoints = const [],

    /// 两个时间默认为 null
    this.startTime,
    this.endTime,

    this.parentTask,
    this.subTasks = const [],

    this.belongingBox,
  }){
    // this.endTime ??= DateTime.now();
    //TODO：BelongList应该被管理，默认值为代理类中lists[0]
    // ??= 表示如果变量为 null，则赋值
    this.belongingBox ??= BelongingBox(name: 'Default List', color: const Color(0xFF000000));
  }

  void addCheckPoint(String name) {
    checkpoints.add(_CheckPoint(name: name));
  }
  void removeCheckPoint(int index) {
    checkpoints.removeAt(index);
  }

  void addChild(TodoItem child) {
    child.parentTask = this; // Set the parent of the child
    subTasks.add(child);
  }
  void removeChild(int index) {
    subTasks.removeAt(index);
  }
}

/// 每个任务可以有多个检查点
class _CheckPoint{
  String name; // The name of the checkpoint
  bool isDone; // Whether the checkpoint is completed

  _CheckPoint({required this.name, this.isDone = false});
}

/// 任务所属的家庭
class BelongingBox{
  String name;
  Color color; // 任务列表的颜色
  List<TodoItem> items = []; // 任务列表中的任务

  BelongingBox({
    required this.name,
    this.color = const Color(0xFF000000), // 默认颜色为黑色
  });
}