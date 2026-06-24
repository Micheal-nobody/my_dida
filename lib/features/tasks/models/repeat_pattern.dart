import 'package:flutter/foundation.dart';
import 'package:my_dida/core/utils/rrule_util.dart';

enum RepeatType { none, daily, weekly, monthly, yearly, ebbinghaus, workday }

class RepeatPattern {
  final RepeatType type;
  final int interval;
  final List<int> weekdays; // Mon=1..Sun=7
  final int? dayOfMonth;
  final int? month;

  const RepeatPattern._({
    required this.type,
    this.interval = 1,
    this.weekdays = const [],
    this.dayOfMonth,
    this.month,
  });

  const RepeatPattern.none()
    : type = RepeatType.none,
      interval = 1,
      weekdays = const [],
      dayOfMonth = null,
      month = null;

  const RepeatPattern.daily([this.interval = 1])
    : type = RepeatType.daily,
      weekdays = const [],
      dayOfMonth = null,
      month = null;

  const RepeatPattern.weekly(this.weekdays, [this.interval = 1])
    : type = RepeatType.weekly,
      dayOfMonth = null,
      month = null;

  const RepeatPattern.monthly(this.dayOfMonth, [this.interval = 1])
    : type = RepeatType.monthly,
      weekdays = const [],
      month = null;

  const RepeatPattern.yearly(this.month, this.dayOfMonth, [this.interval = 1])
    : type = RepeatType.yearly,
      weekdays = const [];

  const RepeatPattern.ebbinghaus()
    : type = RepeatType.ebbinghaus,
      interval = 1,
      weekdays = const [],
      dayOfMonth = null,
      month = null;

  const RepeatPattern.workday()
    : type = RepeatType.workday,
      interval = 1,
      weekdays = const [],
      dayOfMonth = null,
      month = null;

  bool get isNone => type == RepeatType.none;

  bool get isEbbinghaus => type == RepeatType.ebbinghaus;

  bool get isWorkday => type == RepeatType.workday;

  /// Parse from standard RRule string or CUSTOM string
  factory RepeatPattern.parse(String? rruleStr) {
    if (rruleStr == null || rruleStr.trim().isEmpty) {
      return const RepeatPattern.none();
    }

    final String clean = rruleStr.trim().toUpperCase();

    if (clean == 'CUSTOM:EBBINGHAUS') {
      return const RepeatPattern.ebbinghaus();
    }
    if (clean == 'CUSTOM:WORKDAY') {
      return const RepeatPattern.workday();
    }

    final String rule = clean.startsWith('RRULE:')
        ? clean.replaceFirst('RRULE:', '')
        : clean;

    final Map<String, String> parts = {};
    for (final kv in rule.split(';')) {
      if (kv.contains('=')) {
        final pair = kv.split('=');
        parts[pair[0]] = pair[1];
      }
    }

    final String? freq = parts['FREQ'];
    final int interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;

    switch (freq) {
      case 'DAILY':
        return RepeatPattern.daily(interval);
      case 'WEEKLY':
        final List<String> byday = (parts['BYDAY'] ?? '')
            .split(',')
            .where((e) => e.isNotEmpty)
            .toList();
        final List<int> weekdays = byday
            .map((code) {
              switch (code) {
                case 'MO':
                  return 1;
                case 'TU':
                  return 2;
                case 'WE':
                  return 3;
                case 'TH':
                  return 4;
                case 'FR':
                  return 5;
                case 'SA':
                  return 6;
                case 'SU':
                  return 7;
                default:
                  return null;
              }
            })
            .whereType<int>()
            .toList();
        return RepeatPattern.weekly(weekdays, interval);
      case 'MONTHLY':
        final int? byMonthDay = int.tryParse(parts['BYMONTHDAY'] ?? '');
        return RepeatPattern.monthly(byMonthDay ?? 1, interval);
      case 'YEARLY':
        final int? byMonth = int.tryParse(parts['BYMONTH'] ?? '');
        final int? byMonthDay = int.tryParse(parts['BYMONTHDAY'] ?? '');
        return RepeatPattern.yearly(byMonth ?? 1, byMonthDay ?? 1, interval);
      default:
        return const RepeatPattern.none();
    }
  }

  /// Serialize to string for saving to DB
  String? toRRuleString() {
    switch (type) {
      case RepeatType.none:
        return null;
      case RepeatType.ebbinghaus:
        return 'CUSTOM:EBBINGHAUS';
      case RepeatType.workday:
        return 'CUSTOM:WORKDAY';
      case RepeatType.daily:
        return 'RRULE:FREQ=DAILY;INTERVAL=$interval';
      case RepeatType.weekly:
        final codes = weekdays
            .map((w) {
              switch (w) {
                case 1:
                  return 'MO';
                case 2:
                  return 'TU';
                case 3:
                  return 'WE';
                case 4:
                  return 'TH';
                case 5:
                  return 'FR';
                case 6:
                  return 'SA';
                case 7:
                  return 'SU';
                default:
                  return '';
              }
            })
            .where((e) => e.isNotEmpty)
            .join(',');
        return 'RRULE:FREQ=WEEKLY;INTERVAL=$interval;BYDAY=$codes';
      case RepeatType.monthly:
        return 'RRULE:FREQ=MONTHLY;INTERVAL=$interval;BYMONTHDAY=$dayOfMonth';
      case RepeatType.yearly:
        return 'RRULE:FREQ=YEARLY;INTERVAL=$interval;BYMONTH=$month;BYMONTHDAY=$dayOfMonth';
    }
  }

  /// Chinese readable description
  String toReadableString(DateTime? baseDate) {
    switch (type) {
      case RepeatType.none:
        return '无';
      case RepeatType.ebbinghaus:
        return '艾宾浩斯记忆法';
      case RepeatType.workday:
        return '法定工作日';
      case RepeatType.daily:
        return interval == 1 ? '每天' : '每 $interval 天';
      case RepeatType.weekly:
        if (weekdays.isEmpty) {
          final int defaultWd = baseDate?.weekday ?? DateTime.now().weekday;
          return '每周 (${_weekdayToCN(defaultWd)})';
        }
        if (listEquals(weekdays, [1, 2, 3, 4, 5])) {
          return '每周工作日 (周一至周五)';
        }
        final cn = weekdays.map(_weekdayToCN).join('、');
        return interval == 1 ? '每周（$cn）' : '每 $interval 周（$cn）';
      case RepeatType.monthly:
        final int dom = dayOfMonth ?? baseDate?.day ?? DateTime.now().day;
        return interval == 1 ? '每月（$dom 日）' : '每 $interval 月（$dom 日）';
      case RepeatType.yearly:
        final int m = month ?? baseDate?.month ?? DateTime.now().month;
        final int dom = dayOfMonth ?? baseDate?.day ?? DateTime.now().day;
        return interval == 1 ? '每年（$m 月 $dom 日）' : '每 $interval 年（$m 月 $dom 日）';
    }
  }

  /// Compute the next occurrence strictly after `anchor`
  DateTime? nextOccurrenceAfter(DateTime startTime, DateTime anchor) {
    if (isNone) return null;

    final normalizedStart = DateTime(
      startTime.year,
      startTime.month,
      startTime.day,
    );
    final normalizedAnchor = DateTime(anchor.year, anchor.month, anchor.day);

    if (isEbbinghaus) {
      // Ebbinghaus offsets: 1, 2, 4, 7, 15, 30 days
      const offsets = [1, 2, 4, 7, 15, 30];
      for (final offset in offsets) {
        final occurrence = normalizedStart.add(Duration(days: offset));
        if (occurrence.isAfter(normalizedAnchor)) {
          return DateTime(
            occurrence.year,
            occurrence.month,
            occurrence.day,
            startTime.hour,
            startTime.minute,
          );
        }
      }
      return null;
    }

    if (isWorkday) {
      // Mon-Fri skipping Sat/Sun
      DateTime cursor = normalizedAnchor.add(const Duration(days: 1));
      while (cursor.weekday == DateTime.saturday ||
          cursor.weekday == DateTime.sunday) {
        cursor = cursor.add(const Duration(days: 1));
      }
      return DateTime(
        cursor.year,
        cursor.month,
        cursor.day,
        startTime.hour,
        startTime.minute,
      );
    }

    // Standard RRules - delegate to RRuleUtil
    final rruleStr = toRRuleString();
    if (rruleStr == null) return null;

    final occurrences = RRuleUtil.nextOccurrences(startTime, rruleStr, 50);
    for (final occurrence in occurrences) {
      if (occurrence.isAfter(normalizedAnchor)) {
        return DateTime(
          occurrence.year,
          occurrence.month,
          occurrence.day,
          startTime.hour,
          startTime.minute,
        );
      }
    }

    // Fallback if not found in first 50
    final nextCandidate = anchor.add(const Duration(days: 1));
    final more = RRuleUtil.nextOccurrences(nextCandidate, rruleStr, 1);
    if (more.isNotEmpty) {
      return DateTime(
        more.first.year,
        more.first.month,
        more.first.day,
        startTime.hour,
        startTime.minute,
      );
    }

    return null;
  }

  String _weekdayToCN(int weekday) {
    switch (weekday) {
      case 1:
        return '周一';
      case 2:
        return '周二';
      case 3:
        return '周三';
      case 4:
        return '周四';
      case 5:
        return '周五';
      case 6:
        return '周六';
      case 7:
        return '周日';
      default:
        return '';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatPattern &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          interval == other.interval &&
          listEquals(weekdays, other.weekdays) &&
          dayOfMonth == other.dayOfMonth &&
          month == other.month;

  @override
  int get hashCode =>
      type.hashCode ^
      interval.hashCode ^
      weekdays.hashCode ^
      dayOfMonth.hashCode ^
      month.hashCode;
}
