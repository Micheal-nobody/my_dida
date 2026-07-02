import 'package:flutter/material.dart';
import 'package:my_dida/core/utils/time_utils.dart';

class TimeFormatter {
  static String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }

  static String formatRelativeDate(
    DateTime dateTime, {
    DateTime? now,
    bool includeDayAfterTomorrow = false,
  }) {
    final currentTime = now ?? DateTime.now();
    final today = currentTime.dateOnly;
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));

    final dateOnly = dateTime.dateOnly;

    if (dateOnly == today) {
      return '今天';
    } else if (dateOnly == tomorrow) {
      return '明天';
    } else if (includeDayAfterTomorrow && dateOnly == dayAfterTomorrow) {
      return '后天';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }

  static String formatTaskDate(DateTime? dateTime, {DateTime? now}) {
    if (dateTime == null) return '';
    final relativeDate = formatRelativeDate(dateTime, now: now);
    if (dateTime.hasTime) {
      return '$relativeDate,${formatTimeOnly(dateTime)}';
    }
    return relativeDate;
  }

  static String formatTaskDateTime(DateTime dateTime) =>
      '${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} ${formatTimeOnly(dateTime)}';

  static String formatDateTimeRange(
    DateTime? date, {
    required bool isAllDay,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    DateTime? now,
  }) {
    if (date == null) return '';
    final relativeStr = formatRelativeDate(date, now: now);

    if (!isAllDay && startTime != null) {
      final startStr =
          '${_twoDigits(startTime.hour)}:${_twoDigits(startTime.minute)}';
      if (endTime != null) {
        final endStr =
            '${_twoDigits(endTime.hour)}:${_twoDigits(endTime.minute)}';
        return '$relativeStr $startStr-$endStr';
      }
      return '$relativeStr $startStr';
    }
    return relativeStr;
  }

  static String formatFullDateTimeRange(
    DateTime? date, {
    required bool isAllDay,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    DateTime? now,
  }) {
    if (date == null) return '';
    final currentTime = now ?? DateTime.now();
    final today = currentTime.dateOnly;
    final tomorrow = today.add(const Duration(days: 1));

    final dateOnly = date.dateOnly;
    String relativeStr = '';
    if (dateOnly == today) {
      relativeStr = '今天, ';
    } else if (dateOnly == tomorrow) {
      relativeStr = '明天, ';
    }

    final String dateStr = '${date.month}月${date.day}日';
    String timeStr = '';

    if (!isAllDay && startTime != null) {
      final startStr =
          '${_twoDigits(startTime.hour)}:${_twoDigits(startTime.minute)}';
      if (endTime != null) {
        final endStr =
            '${_twoDigits(endTime.hour)}:${_twoDigits(endTime.minute)}';
        timeStr = ' $startStr-$endStr';
      } else {
        timeStr = ' $startStr';
      }
    }

    return '$relativeStr$dateStr$timeStr';
  }

  static String formatTaskDateTimeRange(DateTime? start, DateTime? end) {
    if (start == null) return '';

    final StringBuffer stringBuffer = StringBuffer(
      '${start.month}月${start.day}日',
    );
    if (start.hasTime) {
      stringBuffer.write(formatTimeOnly(start));
    }

    if (end == null) return stringBuffer.toString();

    final endStr = formatTimeOnly(end);
    return '${stringBuffer.toString()} --> $endStr';
  }

  static String formatFullDate(DateTime date) =>
      '${date.year}年${date.month}月${date.day}日';

  static String formatTimeOnly(DateTime date) =>
      '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
}
