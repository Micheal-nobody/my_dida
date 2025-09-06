import 'package:my_dida/model/entity/BelongingBox.dart';
import 'package:my_dida/model/entity/CheckPoint.dart';

//TODO:接入 Isar 数据库！
class TaskVO {

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


  //TODO: 带参数的构造函数
  // TaskVO.fromTask(Task task){
  //   id = task.id;
  //   name = task.name;
  //   description = task.description;
  //   isDone = task.isDone;
  //   checkpointIds = task.checkpointIds;
  //   startTime = task.startTime;
  //   endTime = task.endTime;
  //
  //   //TODO: 父子任务和所属收集箱
  //   parentTask = null;
  //   subTasks = [];
  //   belongingBox = null;
  //
  //   // parentTaskId = task.parentTaskId;
  //   // subTaskIds = task.subTaskIds;
  //   // belongingBoxId = task.belongingBoxId;
  // }


//
// void addCheckPoint(String name) {
//   checkpoints.add(CheckPoint(name: name));
// }
// void removeCheckPoint(int index) {
//   checkpoints.removeAt(index);
// }
//
// void addChild(TaskId childId) {
//   child.parentTaskId = this; // Set the parent of the child
//   subTasks.add(child);
// }
// void removeChild(int index) {
//   subTasks.removeAt(index);
// }
}