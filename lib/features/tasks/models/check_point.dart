import 'package:isar_community/isar.dart';

part 'check_point.g.dart';

/// 每个任务可以有多个检查点
@Embedded()
class CheckPoint {
  // Whether the checkpoint is completed

  CheckPoint({this.name = '', this.isDone = false});

  String name; // The name of the checkpoint
  bool isDone;
}
