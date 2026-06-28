import 'package:flutter/material.dart';
import 'package:my_dida/core/utils/time_utils.dart';

class TimeFormatter {
  static String formatRelativeDate(DateTime dateTime, {DateTime? now, bool includeDayAfterTomorrow = false}) {
    final currentTime = now ?? DateTime.now();
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));

    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateOnly.isAtSameMomentAs(today)) {
      return '今天';
    } else if (dateOnly.isAtSameMomentAs(tomorrow)) {
      return '明天';
    } else if (includeDayAfterTomorrow && dateOnly.isAtSameMomentAs(dayAfterTomorrow)) {
      return '后天';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }

  static String formatTaskDate(DateTime? dateTime, {DateTime? now}) {
    if (dateTime == null) return '';
    final relativeDate = formatRelativeDate(dateTime, now: now);
    if (dateTime.hasTime()) {
      return '$relativeDate,${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    return relativeDate;
  }

  static String formatTaskDateTime(DateTime dateTime) =>
      "${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

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
      final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      if (endTime != null) {
        final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
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
    final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
    final tomorrow = today.add(const Duration(days: 1));

    final dateOnly = DateTime(date.year, date.month, date.day);
    String relativeStr = '';
    if (dateOnly.isAtSameMomentAs(today)) {
      relativeStr = '今天, ';
    } else if (dateOnly.isAtSameMomentAs(tomorrow)) {
      relativeStr = '明天, ';
    }

    final String dateStr = '${date.month}月${date.day}日';
    String timeStr = '';

    if (!isAllDay && startTime != null) {
      final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      if (endTime != null) {
        final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
        timeStr = ' $startStr-$endStr';
      } else {
        timeStr = ' $startStr';
      }
    }

    return '$relativeStr$dateStr$timeStr';
  }

  static String formatTaskDateTimeRange(DateTime? start, DateTime? end) {
    if (start == null) return '未设置时间';
    if (end != null) {
      if (start.hour == 0 && start.minute == 0) {
        return '${start.month}月${start.day}日';
      } else {
        final startStr =
            "${start.month}月${start.day}日 ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
        final endStr =
            "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}";
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

  static String formatFullDate(DateTime date) =>
      '${date.year}年${date.month}月${date.day}日';

  static String formatTimeOnly(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
