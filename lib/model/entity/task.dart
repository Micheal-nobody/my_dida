import 'package:isar_community/isar.dart';
import 'package:my_dida/model/entity/base_entity.dart';
import 'package:my_dida/model/entity/check_point.dart';

part 'task.g.dart';

@Collection()
class Task extends BaseEntity {
  /// Constructor for TodoItem
  Task({
    required this.name,
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
    this.notificationEnabled = false,
    this.reminderOffsetMinutes,
  });


  String name;
  String description;
  @Index(
    name: 'is_done_start_time',
    composite: [CompositeIndex('startTime')],
  )
  @Index(
    name: 'is_done_end_time',
    composite: [CompositeIndex('endTime')],
  )
  bool isDone;

  /// 检查点
  List<CheckPoint> checkpoints;

  /// 表示是否为全天任务
  bool isAllDay;

  /// 时间（两个时间是因为任务可以接受 时间段/时间点）
  @Index()
  DateTime? startTime;
  @Index()
  DateTime? endTime;

  /// 父子任务
  int? parentTaskId;
  List<int> subTaskIds;

  /// 所属收集箱
  @Index()
  int? checklistId;

  /// 重复规则 (RRule)
  String? rrule;

  /// 是否启用任务提醒
  bool notificationEnabled;

  /// 距离开始时间提前多少分钟提醒
  int? reminderOffsetMinutes;

  // toString 方法
  @override
  String toString() =>
      'Task{id: $id, name: $name, description: $description, isDone: $isDone, checkpoints: $checkpoints,isAllDay: $isAllDay, startTime: $startTime, endTime: $endTime, parentTaskId: $parentTaskId, subTaskIds: $subTaskIds, checklistId: $checklistId, rrule: $rrule, notificationEnabled: $notificationEnabled, reminderOffsetMinutes: $reminderOffsetMinutes}';

  /// 深度复制 Task 实例
  Task copyWith({
    String? name,
    bool? isAllDay,
    String? description,
    bool? isDone,
    List<CheckPoint>? checkpoints,
    DateTime? startTime,
    DateTime? endTime,
    int? parentTaskId,
    List<int>? subTaskIds,
    int? checklistId,
    String? rrule,
    bool? notificationEnabled,
    int? reminderOffsetMinutes,
  }) {
    final copy = Task(
      name: name ?? this.name,
      isAllDay: isAllDay ?? this.isAllDay,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      checkpoints: checkpoints ??
          this.checkpoints
              .map((cp) => CheckPoint(name: cp.name, isDone: cp.isDone))
              .toList(),
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      subTaskIds: subTaskIds ?? List<int>.from(this.subTaskIds),
      checklistId: checklistId ?? this.checklistId,
      rrule: rrule ?? this.rrule,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      reminderOffsetMinutes:
          reminderOffsetMinutes ?? this.reminderOffsetMinutes,
    );
    copy.id = id;
    return copy;
  }

  /// 转换为标准 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isDone': isDone,
      'isAllDay': isAllDay,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'parentTaskId': parentTaskId,
      'subTaskIds': subTaskIds,
      'checklistId': checklistId,
      'rrule': rrule,
      'notificationEnabled': notificationEnabled,
      'reminderOffsetMinutes': reminderOffsetMinutes,
      'checkpoints': checkpoints
          .map((cp) => {'name': cp.name, 'isDone': cp.isDone})
          .toList(),
    };
  }

  /// 从标准 JSON Map 反序列化生成 Task
  factory Task.fromJson(Map<String, dynamic> json) {
    // 处理 checkpoints 列表
    List<CheckPoint> cpList = [];
    if (json['checkpoints'] != null && json['checkpoints'] is List) {
      for (final cp in json['checkpoints']) {
        if (cp is Map) {
          cpList.add(CheckPoint(
            name: cp['name']?.toString() ?? '',
            isDone: cp['isDone'] == true,
          ));
        }
      }
    }

    final task = Task(
      name: json['name']?.toString() ?? '',
      isAllDay: json['isAllDay'] == true,
      description: json['description']?.toString() ?? '',
      isDone: json['isDone'] == true,
      checkpoints: cpList,
      startTime: json['startTime'] != null && json['startTime'].toString().isNotEmpty
          ? DateTime.parse(json['startTime'].toString())
          : null,
      endTime: json['endTime'] != null && json['endTime'].toString().isNotEmpty
          ? DateTime.parse(json['endTime'].toString())
          : null,
      parentTaskId: json['parentTaskId'] as int?,
      subTaskIds: json['subTaskIds'] != null
          ? List<int>.from(json['subTaskIds'] as List)
          : const [],
      checklistId: json['checklistId'] as int? ?? 1,
      rrule: json['rrule']?.toString().isEmpty == true
          ? null
          : json['rrule']?.toString(),
      notificationEnabled: json['notificationEnabled'] == true,
      reminderOffsetMinutes: json['reminderOffsetMinutes'] as int?,
    );
    if (json['id'] != null) {
      task.id = json['id'] as int;
    }
    return task;
  }
}
