import 'dart:ui';

import 'package:isar_community/isar.dart';

/// 任务所属的家庭
class ChecklistVO {
  // 任务列表中的任务

  ChecklistVO({
    required this.id,
    required this.name,
    this.color = const Color(0xFF000000), // 默认颜色为黑色
  });

  Id id;
  String name;
  Color color; // 任务列表的颜色

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistVO &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
