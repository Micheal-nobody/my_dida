import 'dart:ui';

import 'package:isar/isar.dart';
import 'package:my_dida/model/vo/TaskVO.dart';

import '../entity/BelongingBox.dart';


/// 任务所属的家庭
class BelongingBoxVO{
  Id id;
  String name;
  Color color; // 任务列表的颜色
  List<int> taskIds = []; // 任务列表中的任务

  BelongingBoxVO({
    required this.id,
    required this.name,
    this.color = const Color(0xFF000000), // 默认颜色为黑色
    this.taskIds = const [],
  });
}