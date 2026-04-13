import 'package:isar_community/isar.dart';
import 'package:my_dida/model/entity/check_point.dart';

part 'task.g.dart';

@Collection()
class Task {
  /// Constructor for TodoItem
  Task({
    required this.name,
    // this.isAllDay = false,
    required this.isAllDay,

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
    this.checklistId = 1,

    /// 重复规则默认为 null
    this.rrule,
  });

  Id id = Isar.autoIncrement;

  String name;
  String description;
  bool isDone;

  /// 检查点
  List<CheckPoint> checkpoints;

  /// 表示是否为全天任务
  bool isAllDay;

  /// 时间（两个时间是因为任务可以接受 时间段/时间点）
  DateTime? startTime;
  DateTime? endTime;

  /// 父子任务
  int? parentTaskId;
  List<int> subTaskIds;

  /// 所属收集箱
  int? checklistId;

  /// 重复规则 (RRule)
  String? rrule;

  // toString 方法
  @override
  String toString() =>
      'Task{id: $id, name: $name, description: $description, isDone: $isDone, checkpoints: $checkpoints,isAllDay: $isAllDay, startTime: $startTime, endTime: $endTime, parentTaskId: $parentTaskId, subTaskIds: $subTaskIds, checklistId: $checklistId, rrule: $rrule}';
}
