import 'package:isar/isar.dart';
import 'package:my_dida/model/entity/CheckPoint.dart';
part 'Task.g.dart';

@Collection()
class Task {
  Id id = Isar.autoIncrement;

  String name;
  String description;
  bool isDone;

  /// 检查点
  List<CheckPoint> checkpoints;

  /// 时间（两个时间是因为任务可以接受 时间段/时间点）
  DateTime? startTime;
  DateTime? endTime;

  /// 父子任务
  int? parentTaskId;
  List<int> subTaskIds;

  /// 所属收集箱
  int? belongingBoxId;

  /// 重复规则 (RRule)
  String? rrule;

  /// Constructor for TodoItem
  Task({
    required this.name,
    this.description = '',
    this.isDone = false,

    this.checkpoints = const [],

    /// 两个时间默认为 null
    this.startTime,
    this.endTime,

    /// 父子任务
    this.parentTaskId,
    this.subTaskIds = const [],

    /// 所属收集箱（默认为 "收集箱"）
    this.belongingBoxId = 1,

    /// 重复规则默认为 null
    this.rrule,
  });

  // toString 方法
  @override
  String toString() {
    return 'TodoItem{id: $id, name: $name, description: $description, isDone: $isDone, checkpoints: $checkpoints, startTime: $startTime, endTime: $endTime, parentTaskId: $parentTaskId, subTaskIds: $subTaskIds, belongingBoxId: $belongingBoxId}';
  }
}
