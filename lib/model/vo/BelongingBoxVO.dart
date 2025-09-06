import 'dart:ui';

import 'package:isar/isar.dart';
import 'package:my_dida/model/vo/TaskVO.dart';

/// 任务所属的家庭
class BelongingBoxVO{
  Id id;
  String name;
  Color color; // 任务列表的颜色
  List<TaskVO> tasks = []; // 任务列表中的任务

  BelongingBoxVO({
    required this.id,
    required this.name,
    this.color = const Color(0xFF000000), // 默认颜色为黑色
  });

  //TODO：带参数的构造函数，或许应该写道Provider之中？
  // BelongingBoxVO.fromEntity(BelongingBox entity){
  //   id = entity.id;
  //   name = entity.name;
  //   color = Color(entity.colorValue);
  //
  //   // TODO: 获取任务
  //   tasks = [];
  //   // tasks = entity.taskIds.map((id) => TaskVO.fromEntity(Task.getById(id))).toList();
  // }



}