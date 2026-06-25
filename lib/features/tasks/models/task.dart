import 'package:isar_community/isar.dart';
import 'package:my_dida/features/tasks/models/check_point.dart';
import 'package:my_dida/features/tasks/models/repeat_pattern.dart';
import 'package:my_dida/shared/models/revertible_entity.dart';

part 'task.g.dart';

enum TaskPriority {
  none, // 无优先级 -> 对应第四象限
  low, // 低优先级 -> 对应第三象限
  medium, // 中优先级 -> 对应第二象限
  high, // 高优先级 -> 对应第一象限
}

@Collection()
class Task extends RevertibleEntity {
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
    RepeatPattern? rrule,
    this.notificationEnabled = false,
    this.reminderOffsetMinutes,
    this.priority = TaskPriority.none,
    this.tags = const [],
  }) {
    if (rrule != null) {
      this.rrule = rrule;
    }
  }

  /// 从标准 JSON Map 反序列化生成 Task
  factory Task.fromJson(Map<String, dynamic> json) {
    // 处理 checkpoints 列表
    final List<CheckPoint> cpList = [];
    if (json['checkpoints'] != null && json['checkpoints'] is List) {
      for (final cp in json['checkpoints']) {
        if (cp is Map) {
          cpList.add(
            CheckPoint(
              name: cp['name']?.toString() ?? '',
              isDone: cp['isDone'] == true,
            ),
          );
        }
      }
    }

    final task = Task(
      name: json['name']?.toString() ?? '',
      isAllDay: json['isAllDay'] == true,
      description: json['description']?.toString() ?? '',
      isDone: json['isDone'] == true,
      checkpoints: cpList,
      startTime:
          json['startTime'] != null && json['startTime'].toString().isNotEmpty
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
      rrule: RepeatPattern.parse(
        json['rrule']?.toString().isEmpty == true
            ? null
            : json['rrule']?.toString(),
      ),
      notificationEnabled: json['notificationEnabled'] == true,
      reminderOffsetMinutes: json['reminderOffsetMinutes'] as int?,
      priority: json['priority'] != null
          ? TaskPriority.values[json['priority'] as int? ?? 0]
          : TaskPriority.none,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
    );
    if (json['id'] != null) {
      task.id = json['id'] as int;
    }
    return task;
  }

  String name;

  /// 任务备注。支持 Markdown 语法，附件（图片/文件）以 attachments:// 虚拟路径形式引用。
  String description;
  @Index(name: 'is_done_start_time', composite: [CompositeIndex('startTime')])
  @Index(name: 'is_done_end_time', composite: [CompositeIndex('endTime')])
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
  @Name('rrule')
  String? rruleString;

  @ignore
  RepeatPattern get rrule => RepeatPattern.parse(rruleString);

  set rrule(RepeatPattern pattern) {
    rruleString = pattern.isNone ? null : pattern.toRRuleString();
  }

  /// 是否启用任务提醒
  bool notificationEnabled;

  /// 距离开始时间提前多少分钟提醒
  int? reminderOffsetMinutes;

  /// 优先级：none-无, low-低, medium-中, high-高
  @Index()
  @enumerated
  TaskPriority priority;

  /// 标签列表
  List<String> tags;

  // toString 方法
  @override
  String toString() =>
      'Task{id: $id, name: $name, description: $description, isDone: $isDone, checkpoints: $checkpoints,isAllDay: $isAllDay, startTime: $startTime, endTime: $endTime, parentTaskId: $parentTaskId, subTaskIds: $subTaskIds, checklistId: $checklistId, rruleString: $rruleString, notificationEnabled: $notificationEnabled, reminderOffsetMinutes: $reminderOffsetMinutes, priority: $priority, tags: $tags}';

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
    RepeatPattern? rrule,
    bool? notificationEnabled,
    int? reminderOffsetMinutes,
    TaskPriority? priority,
    List<String>? tags,
  }) {
    final copy = Task(
      name: name ?? this.name,
      isAllDay: isAllDay ?? this.isAllDay,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      checkpoints:
          checkpoints ??
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
      priority: priority ?? this.priority,
      tags: tags ?? List<String>.from(this.tags),
    )
    ..id = id;
    return copy;
  }

  /// 转换为标准 JSON Map
  @override
  Map<String, dynamic> toJson() => {
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
    'rrule': rruleString,
    'notificationEnabled': notificationEnabled,
    'reminderOffsetMinutes': reminderOffsetMinutes,
    'priority': priority.index,
    'tags': tags,
    'checkpoints': checkpoints
        .map((cp) => {'name': cp.name, 'isDone': cp.isDone})
        .toList(),
  };
}
