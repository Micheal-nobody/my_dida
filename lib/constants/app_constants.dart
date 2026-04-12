import '../model/vo/checklist_vo.dart';

/// Application-wide constants
class AppConstants {
  // App Information
  static const String appName = 'My dida';
  static const String appDescription = '这里是简介';

  // Special IDs
  static ChecklistVO todayCheckList = ChecklistVO(id: -1, name: '今天');
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
