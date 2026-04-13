import 'package:isar_community/isar.dart';

part 'habit.g.dart';

// 习惯，习惯是每天都要做的，比如刷牙、洗脸、吃饭等
@Collection()
class Habit {
  Habit({
    required this.name,
    required this.icon,
    required this.remindTime,
    required this.checkInCount,
    required this.currentCheckInCount,
    required this.startDate,
    required this.totalCheckInCount,
    required this.longestContinuousCheckInDays,
    this.rrule,
  });

  Id id = Isar.autoIncrement;

  String name;
  String icon; // 习惯对应的 Icon
  DateTime remindTime; // 每天提醒时间
  int checkInCount; // 所需打卡次数
  int currentCheckInCount; // 当前打卡次数

  //用于统计数据的字段，这些字段需要根据打卡记录进行更新
  DateTime startDate; // 习惯开始日期
  int totalCheckInCount; // 总打卡次数
  int longestContinuousCheckInDays; // 最长连续打卡天数

  /// 重复规则 (RRule)
  String? rrule;
}
