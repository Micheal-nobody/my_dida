import 'package:isar_community/isar.dart';
import 'package:my_dida/shared/models/base_entity.dart';

part 'tomato_record.g.dart';

@Collection()
class TomatoRecord extends BaseEntity {
  TomatoRecord({
    this.taskId,
    this.taskName,
    this.categoryName,
    this.customTomatoId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
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
}
