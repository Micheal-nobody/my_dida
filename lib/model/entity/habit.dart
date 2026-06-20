import 'package:isar_community/isar.dart';
import 'package:my_dida/model/entity/revertible_entity.dart';

part 'habit.g.dart';

// 习惯，习惯是每天都要做的，比如刷牙、洗脸、吃饭等
@Collection()
class Habit extends RevertibleEntity {
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
    this.isArchived = false,
    this.sortOrder = 0,
    this.isTodaySkipped = false,
  });

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

  /// 是否归档
  bool isArchived;

  /// 排序权重
  int sortOrder;

  /// 今日是否跳过
  bool isTodaySkipped;

  /// 转换为标准 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'remindTime': remindTime.toIso8601String(),
      'checkInCount': checkInCount,
      'currentCheckInCount': currentCheckInCount,
      'startDate': startDate.toIso8601String(),
      'totalCheckInCount': totalCheckInCount,
      'longestContinuousCheckInDays': longestContinuousCheckInDays,
      'rrule': rrule,
      'isArchived': isArchived,
      'sortOrder': sortOrder,
      'isTodaySkipped': isTodaySkipped,
    };
  }

  /// 从标准 JSON Map 反序列化生成 Habit
  factory Habit.fromJson(Map<String, dynamic> json) {
    final habit = Habit(
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      remindTime: json['remindTime'] != null
          ? DateTime.parse(json['remindTime'].toString())
          : DateTime.now(),
      checkInCount: json['checkInCount'] as int? ?? 1,
      currentCheckInCount: json['currentCheckInCount'] as int? ?? 0,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'].toString())
          : DateTime.now(),
      totalCheckInCount: json['totalCheckInCount'] as int? ?? 0,
      longestContinuousCheckInDays:
          json['longestContinuousCheckInDays'] as int? ?? 0,
      rrule: json['rrule']?.toString().isEmpty == true
          ? null
          : json['rrule']?.toString(),
      isArchived: json['isArchived'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isTodaySkipped: json['isTodaySkipped'] as bool? ?? false,
    );
    if (json['id'] != null) {
      habit.id = json['id'] as int;
    }
    return habit;
  }
}
