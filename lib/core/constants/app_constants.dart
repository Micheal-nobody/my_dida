import 'package:my_dida/features/checklist/models/checklist_vo.dart';

/// Application-wide constants
class AppConstants {
  // App Information
  static const String appName = 'My dida';
  static const String appDescription = '这里是简介';

  // Special IDs
  static ChecklistVO todayCheckList = ChecklistVO(id: -1, name: '今天');
  static ChecklistVO tomorrowCheckList = ChecklistVO(id: -2, name: '明天');
  static ChecklistVO nextSevenDaysCheckList = ChecklistVO(id: -3, name: '最近七天');
  static ChecklistVO allCheckList = ChecklistVO(id: -4, name: '所有');
  static ChecklistVO completedCheckList = ChecklistVO(id: -5, name: '已完成');
  static ChecklistVO trashCheckList = ChecklistVO(id: -6, name: '垃圾桶');
  static ChecklistVO defaultCheckList = ChecklistVO(id: 1, name: '收集箱');

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 20.0;

  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  // Limits
  static const int maxRecentTasks = 10;
  static const int maxRecurrenceOccurrences = 10;
}
