import 'package:flutter/foundation.dart';
import 'package:my_dida/model/vo/repeat_pattern.dart';

RepeatPattern mapSelectionToRepeatPattern(String selection, DateTime? baseDate) {
  if (selection == '无') return const RepeatPattern.none();
  if (selection == '每天') return const RepeatPattern.daily();
  if (selection.startsWith('每周')) {
    if (selection.startsWith('每周工作日')) {
      return const RepeatPattern.weekly([1, 2, 3, 4, 5]);
    }
    final DateTime date = baseDate ?? DateTime.now();
    return RepeatPattern.weekly([date.weekday]);
  }
  if (selection.startsWith('每月')) {
    final DateTime date = baseDate ?? DateTime.now();
    return RepeatPattern.monthly(date.day);
  }
  if (selection.startsWith('每年')) {
    final DateTime date = baseDate ?? DateTime.now();
    return RepeatPattern.yearly(date.month, date.day);
  }
  if (selection.startsWith('每周工作日')) {
    return const RepeatPattern.weekly([1, 2, 3, 4, 5]);
  }
  if (selection == '法定工作日') {
    return const RepeatPattern.workday();
  }
  if (selection == '艾宾浩斯记忆法') {
    return const RepeatPattern.ebbinghaus();
  }
  return const RepeatPattern.none();
}

String rruleToSelection(RepeatPattern pattern) {
  switch (pattern.type) {
    case RepeatType.none:
      return '无';
    case RepeatType.daily:
      return '每天';
    case RepeatType.weekly:
      if (listEquals(pattern.weekdays, [1, 2, 3, 4, 5])) {
        return '每周工作日';
      }
      return '每周';
    case RepeatType.monthly:
      return '每月';
    case RepeatType.yearly:
      return '每年';
    case RepeatType.workday:
      return '法定工作日';
    case RepeatType.ebbinghaus:
      return '艾宾浩斯记忆法';
  }
}

List<String> buildRepeatOptions(DateTime? baseDate) {
  String weekdayCn(int weekday) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return names[(weekday - 1).clamp(0, 6)];
  }

  String weeklyLabel() {
    if (baseDate == null) return '每周';
    return '每周 (周${weekdayCn(baseDate.weekday)})';
  }

  String monthlyLabel() {
    if (baseDate == null) return '每月';
    return '每月 (${baseDate.day}日)';
  }

  String yearlyLabel() {
    if (baseDate == null) return '每年';
    return '每年 (${baseDate.month}月${baseDate.day}日)';
  }

  return [
    '无',
    '每天',
    weeklyLabel(),
    monthlyLabel(),
    yearlyLabel(),
    '每周工作日 (周一至周五)',
    '法定工作日',
    '艾宾浩斯记忆法',
    '自定义重复',
  ];
}
