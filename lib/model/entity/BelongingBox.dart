import 'dart:ui';

import 'package:isar/isar.dart';

part 'BelongingBox.g.dart';

/// 任务所属的家庭
@Collection()
class BelongingBox{
  Id id = Isar.autoIncrement;
  String name;
  int colorValue; // 任务列表的颜色
  List<Id> taskIds = []; // 任务列表中的任务

  BelongingBox({
    required this.name,
    this.colorValue = 0,
  });
}