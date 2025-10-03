import 'package:isar/isar.dart';
part 'BelongingBox.g.dart';

/// 任务所属的家庭
@Collection()
class BelongingBox {
  // 任务列表中的任务

  BelongingBox({
    required this.name,
    this.colorValue = 0xFFFF9800,
    this.taskIds = const [],
  });
  Id id = Isar.autoIncrement;
  String name;
  int colorValue; // 任务列表的颜色
  List<Id> taskIds;
}
