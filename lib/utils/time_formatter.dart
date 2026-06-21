import 'package:my_dida/utils/TimeUtils.dart';

class TimeFormatter {
  static String formatTaskDate(DateTime? dateTime, {DateTime? now}) {
    if (dateTime == null) return '';
    final currentTime = now ?? DateTime.now();
    final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (dateTime.isAtSameMomentAs(today)) {
      return dateTime.hasTime()
          ? '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
          : '今天';
    } else if (dateTime.isAtSameMomentAs(tomorrow)) {
      return dateTime.hasTime()
          ? '明天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
          : '明天';
    } else {
      return dateTime.hasTime()
          ? '${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
          : '${dateTime.month}月${dateTime.day}日';
    }
  }

  static String formatTaskDateTimeRange(DateTime? start, DateTime? end) {
    if (start == null) return '未设置时间';
    if (end != null) {
      if (start.hour == 0 && start.minute == 0) {
        return '${start.month}月${start.day}日';
      } else {
        final startStr = "${start.month}月${start.day}日 ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
        final endStr = "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}";
        return '$startStr --> $endStr';
      }
    } else {
      if (start.hour == 0 && start.minute == 0) {
        return '${start.month}月${start.day}日';
      } else {
        return "${start.month}月${start.day}日 ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
      }
    }
  }

  static String formatFullDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  static String formatTimeOnly(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
