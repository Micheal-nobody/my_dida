import 'package:isar_community/isar.dart';
import 'package:my_dida/model/entity/base_entity.dart';

part 'habit_check_in_record.g.dart';

@Collection()
class HabitCheckInRecord extends BaseEntity {
  HabitCheckInRecord({
    required this.habitId,
    required this.checkInTime,
    this.isSkip = false,
  });

  @Index()
  int habitId;

  @Index()
  DateTime checkInTime;

  bool isSkip;

  @override
  String toString() =>
      'HabitCheckInRecord{id: $id, habitId: $habitId, checkInTime: $checkInTime, isSkip: $isSkip}';
}
