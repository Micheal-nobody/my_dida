import 'package:isar_community/isar.dart';
import 'package:my_dida/shared/models/base_entity.dart';
import 'package:my_dida/shared/models/revertible_entity.dart';

part 'tomato_record.g.dart';

@Collection()
class TomatoRecord extends RevertibleEntity {
  TomatoRecord({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.taskId,
    this.taskName,
    this.categoryName,
    this.customTomatoId,
    this.isCompleted = true,
  });

  @Index()
  int? taskId;

  @Index()
  int? customTomatoId;

  String? taskName;

  String? categoryName;

  @Index()
  DateTime startTime;

  DateTime endTime;

  int durationMinutes;

  bool isCompleted;

  @override
  String toString() =>
      'TomatoRecord{id: $id, taskId: $taskId, taskName: $taskName, categoryName: $categoryName, startTime: $startTime, endTime: $endTime, durationMinutes: $durationMinutes, isCompleted: $isCompleted}';

  factory TomatoRecord.fromJson(Map<String, dynamic> json) {
    final record = TomatoRecord(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      durationMinutes: json['durationMinutes'] as int,
      taskId: json['taskId'] as int?,
      taskName: json['taskName'] as String?,
      categoryName: json['categoryName'] as String?,
      customTomatoId: json['customTomatoId'] as int?,
      isCompleted: json['isCompleted'] as bool? ?? true,
    );
    if (json['id'] != null) {
      record.id = json['id'] as int;
    }
    return record;
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id == Isar.autoIncrement ? null : id,
    'taskId': taskId,
    'customTomatoId': customTomatoId,
    'taskName': taskName,
    'categoryName': categoryName,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'durationMinutes': durationMinutes,
    'isCompleted': isCompleted,
  };

  @override
  String get displayName => '';
}
