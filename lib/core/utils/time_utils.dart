import 'package:flutter/material.dart';

extension DateOnly on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  DateTime get dateAndTime => DateTime(year, month, day, hour, minute);

  DateTime toBeijingTime() => toUtc().add(const Duration(hours: 8));

  bool isToday({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    return dateOnly.isAtSameMomentAs(currentTime.dateOnly);
  }

  bool hasTime() => hour != 0 || minute != 0;

  bool justDate() => hour == 0 && minute == 0;
}

/// 通用日期时间工具类，提取重复的日期处理逻辑
class DateTimeUtils {
  /// 获取指定日期的开始时间 (00:00:00)
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// 获取指定日期的结束时间 (23:59:59.999)
  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  /// 获取日期范围
  static DateRange getDateRange(DateTime startDate, DateTime endDate) =>
      DateRange(start: startOfDay(startDate), end: endOfDay(endDate));

  /// 获取今天的日期范围
  static DateRange getTodayRange() {
    final now = DateTime.now();
    return DateRange(start: startOfDay(now), end: endOfDay(now));
  }

  /// 获取本周的日期范围
  static DateRange getThisWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return DateRange(start: startOfDay(startOfWeek), end: endOfDay(endOfWeek));
  }

  /// 获取本月的日期范围
  static DateRange getThisMonthRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return DateRange(
      start: startOfDay(startOfMonth),
      end: endOfDay(endOfMonth),
    );
  }

  /// 格式化时间显示
  static String formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  /// 格式化日期显示
  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
    switch (format) {
      case 'yyyy-MM-dd':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case 'MM-dd':
        return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case 'MM/dd':
        return '${date.month}/${date.day}';
      default:
        return date.toString();
    }
  }

  /// 创建带时间的DateTime
  static DateTime createDateTime(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  /// 获取当前北京时间
  static DateTime nowBeijing() => DateTime.now().toBeijingTime();

  /// 检查日期是否在范围内
  static bool isDateInRange(DateTime date, DateTime start, DateTime end) =>
      !date.isBefore(start) && !date.isAfter(end);
}

/// 日期范围类
class DateRange {
  const DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  /// 检查日期是否在范围内
  bool contains(DateTime date) => DateTimeUtils.isDateInRange(date, start, end);

  /// 获取范围内的天数
  int get days => end.difference(start).inDays + 1;

  @override
  String toString() =>
      'DateRange(${DateTimeUtils.formatDate(start)} - ${DateTimeUtils.formatDate(end)})';
}
