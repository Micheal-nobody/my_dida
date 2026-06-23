import 'package:isar_community/isar.dart';
import 'package:my_dida/shared/models/base_entity.dart';

part 'habit_check_in_record.g.dart';

@Collection()
class HabitCheckInRecord extends BaseEntity {
  HabitCheckInRecord({
    required this.habitId,
    required this.checkInTime,
    this.isSkip = false,
    this.checkInValue = 1.0,
  });

  @Index()
  int habitId;

  @Index()
  DateTime checkInTime;

  bool isSkip;

  double checkInValue;

  Map<String, dynamic> toJson() => {
    'id': id == Isar.autoIncrement ? null : id,
    'habitId': habitId,
    'checkInTime': checkInTime.toIso8601String(),
    'isSkip': isSkip,
    'checkInValue': checkInValue,
  };

  static HabitCheckInRecord fromJson(Map<String, dynamic> json) {
    final record = HabitCheckInRecord(
      habitId: json['habitId'] as int,
      checkInTime: DateTime.parse(json['checkInTime'] as String),
      isSkip: json['isSkip'] as bool? ?? false,
      checkInValue: (json['checkInValue'] as num?)?.toDouble() ?? 1.0,
    );
    if (json['id'] != null) {
      record.id = json['id'] as int;
    }
    return record;
  }

  @override
  String toString() =>
      'HabitCheckInRecord{id: $id, habitId: $habitId, checkInTime: $checkInTime, isSkip: $isSkip}';
}
