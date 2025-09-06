import 'package:isar/isar.dart';

part 'CheckPoint.g.dart';

/// 每个任务可以有多个检查点
@Embedded()
class CheckPoint {
  String name; // The name of the checkpoint
  bool isDone; // Whether the checkpoint is completed

  CheckPoint({this.name = '', this.isDone = false});
}
