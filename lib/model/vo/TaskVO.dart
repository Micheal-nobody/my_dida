import 'package:my_dida/model/entity/BelongingBox.dart';
import 'package:my_dida/model/entity/CheckPoint.dart';

class TaskVO {
  /// Constructor for TodoItem
  TaskVO({
    required this.id,
    required this.name,
    this.description = '',
    this.isDone = false,

    this.checkpoints = const [],

    /// 两个时间默认为 null
    this.startTime,
    this.endTime,

    /// 父子任务
    this.parentTask,
    this.subTasks = const [],

    /// 所属收集箱
    this.belongingBox,
  });
  int id;
  String name;
  String description;
  bool isDone;

  /// 检查点
  List<CheckPoint> checkpoints;

  /// 时间（两个时间是因为任务可以接受 时间段/时间点）
  DateTime? startTime;
  DateTime? endTime;

  /// 父子任务
  TaskVO? parentTask;
  List<TaskVO> subTasks;

  /// 所属收集箱
  BelongingBox? belongingBox;
}
