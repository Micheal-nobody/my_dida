// No Flutter imports needed

import 'package:my_dida/features/tasks/models/repeat_pattern.dart';

class RRuleUtil {
  // Cache for memorizing RRule calculations
  static final Map<String, List<DateTime>> _rruleCache = {};
  static const int _maxCacheSize = 100;

  // Clear cache when it gets too large
  static void _clearCacheIfNeeded() {
    if (_rruleCache.length > _maxCacheSize) {
      _rruleCache.clear();
    }
  }

  // Generate cache key for memoization
  static String _generateCacheKey(
    DateTime startTime,
    String rrule,
    int count,
  ) => '${startTime.millisecondsSinceEpoch}_${rrule}_$count';

  /// Generate next [count] occurrence dates starting from [startTime]
  /// according to the given iCal RRULE string (supports common fields).
  ///
  /// Supported:
  /// - FREQ: DAILY, WEEKLY, MONTHLY, YEARLY
  /// - INTERVAL
  /// - BYDAY (for WEEKLY) e.g. MO,TU
  /// - BYMONTHDAY (for MONTHLY/YEARLY)
  /// - BYMONTH (for YEARLY)
  static List<DateTime> nextOccurrences(
    DateTime startTime,
    String rrule,
    int count,
  ) {
    final normalizedRrule = rrule.toUpperCase().startsWith('FREQ=')
        ? 'RRULE:$rrule'
        : rrule;

    if (normalizedRrule == 'CUSTOM:EBBINGHAUS') {
      final cacheKey = _generateCacheKey(startTime, normalizedRrule, count);
      if (_rruleCache.containsKey(cacheKey)) {
        return _rruleCache[cacheKey]!;
      }
      _clearCacheIfNeeded();

      final results = <DateTime>[];
      final normalizedStart = DateTime(
        startTime.year,
        startTime.month,
        startTime.day,
      );
      const offsets = [1, 2, 4, 7, 15, 30];
      for (final offset in offsets) {
        results.add(normalizedStart.add(Duration(days: offset)));
        if (results.length >= count) break;
      }
      _rruleCache[cacheKey] = results;
      return results;
    }

    if (normalizedRrule == 'CUSTOM:WORKDAY') {
      final cacheKey = _generateCacheKey(startTime, normalizedRrule, count);
      if (_rruleCache.containsKey(cacheKey)) {
        return _rruleCache[cacheKey]!;
      }
      _clearCacheIfNeeded();

      final results = <DateTime>[];
      DateTime cursor = DateTime(
        startTime.year,
        startTime.month,
        startTime.day,
      );
      while (results.length < count) {
        if (cursor.weekday >= 1 && cursor.weekday <= 5) {
          results.add(cursor);
        }
        cursor = cursor.add(const Duration(days: 1));
      }
      _rruleCache[cacheKey] = results;
      return results;
    }

    if (!normalizedRrule.startsWith('RRULE:')) return const [];

    // Check cache first
    final cacheKey = _generateCacheKey(startTime, normalizedRrule, count);
    if (_rruleCache.containsKey(cacheKey)) {
      return _rruleCache[cacheKey]!;
    }

    _clearCacheIfNeeded();
    final rule = normalizedRrule.replaceFirst('RRULE:', '');
    final parts = <String, String>{};
    for (final kv in rule.split(';')) {
      if (kv.contains('=')) {
        final pair = kv.split('=');
        parts[pair[0]] = pair[1];
      }
    }

    final String? freq = parts['FREQ'];
    final int interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
    final List<String> byday = (parts['BYDAY'] ?? '')
        .split(',')
        .where((e) => e.isNotEmpty)
        .toList();
    final int? byMonthDay = int.tryParse(parts['BYMONTHDAY'] ?? '');
    final int? byMonth = int.tryParse(parts['BYMONTH'] ?? '');

    final List<DateTime> results = [];

    DateTime cursor = startTime;

    bool addIfSameDay(DateTime d) {
      final normalized = DateTime(d.year, d.month, d.day);
      if (results.isEmpty || !results.last.isAtSameMomentAs(normalized)) {
        results.add(normalized);
      }
      return results.length >= count;
    }

    switch (freq) {
      case 'DAILY':
        while (results.length < count) {
          if (addIfSameDay(cursor)) break;
          cursor = cursor.add(Duration(days: interval));
        }
        break;
      case 'WEEKLY':
        // If BYDAY is specified, use it; otherwise fallback to the weekday of startTime
        final List<int> weekdays = byday.isNotEmpty
            ? byday
                  .map(_weekdayCodeToDart)
                  .where((w) => w != null)
                  .cast<int>()
                  .toList()
            : [startTime.weekday];
        // Sort weekdays for stable order Mon..Sun
        weekdays.sort();

        // Start from the week of startTime
        DateTime weekAnchor = _startOfWeek(cursor);
        while (results.length < count) {
          for (final w in weekdays) {
            final candidate = weekAnchor.add(Duration(days: w - 1));
            if (!candidate.isBefore(startTime)) {
              if (addIfSameDay(candidate)) break;
            }
          }
          if (results.length >= count) break;
          weekAnchor = weekAnchor.add(Duration(days: 7 * interval));
        }
        break;
      case 'MONTHLY':
        // Use BYMONTHDAY if provided, otherwise the day of startTime
        final int dom = byMonthDay ?? startTime.day;
        DateTime monthCursor = DateTime(cursor.year, cursor.month, dom);
        // If the first candidate is before startTime, move forward
        if (monthCursor.isBefore(startTime)) {
          monthCursor = DateTime(cursor.year, cursor.month + interval, dom);
        }
        while (results.length < count) {
          // Handle overflow days (e.g., Feb 30) by clamping to last day of month
          final clamped = _safeDate(monthCursor.year, monthCursor.month, dom);
          if (!clamped.isBefore(startTime)) {
            if (addIfSameDay(clamped)) break;
          }
          monthCursor = DateTime(
            monthCursor.year,
            monthCursor.month + interval,
            dom,
          );
        }
        break;
      case 'YEARLY':
        final int month = byMonth ?? startTime.month;
        final int domY = byMonthDay ?? startTime.day;
        DateTime yearCursor = DateTime(cursor.year, month, domY);
        if (yearCursor.isBefore(startTime)) {
          yearCursor = DateTime(cursor.year + interval, month, domY);
        }
        while (results.length < count) {
          final clamped = _safeDate(yearCursor.year, month, domY);
          if (!clamped.isBefore(startTime)) {
            if (addIfSameDay(clamped)) break;
          }
          yearCursor = DateTime(yearCursor.year + interval, month, domY);
        }
        break;
      default:
        return const [];
    }

    // Cache the results before returning
    _rruleCache[cacheKey] = results;
    return results;
  }

  // Optimized method for getting occurrences within a specific date range
  static List<DateTime> getOccurrencesInRange(
    DateTime startTime,
    String rrule,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final normalizedRrule = rrule.toUpperCase().startsWith('FREQ=')
        ? 'RRULE:$rrule'
        : rrule;
    if (!normalizedRrule.startsWith('RRULE:')) return const [];

    // Generate more occurrences than needed, then filter
    // This is more efficient than generating all possible occurrences
    final maxOccurrences = _calculateMaxOccurrencesNeeded(
      rangeStart,
      rangeEnd,
      normalizedRrule,
    );
    final allOccurrences = nextOccurrences(
      startTime,
      normalizedRrule,
      maxOccurrences,
    );

    return allOccurrences
        .where((date) => !date.isBefore(rangeStart) && !date.isAfter(rangeEnd))
        .toList();
  }

  // Calculate reasonable maximum occurrences needed for a date range
  static int _calculateMaxOccurrencesNeeded(
    DateTime rangeStart,
    DateTime rangeEnd,
    String rrule,
  ) {
    final daysDifference = rangeEnd.difference(rangeStart).inDays;

    if (rrule.contains('FREQ=DAILY')) {
      return daysDifference + 1;
    } else if (rrule.contains('FREQ=WEEKLY')) {
      return (daysDifference / 7).ceil() * 7 + 7; // Add buffer
    } else if (rrule.contains('FREQ=MONTHLY')) {
      return (daysDifference / 30).ceil() + 2; // Add buffer
    } else if (rrule.contains('FREQ=YEARLY')) {
      return (daysDifference / 365).ceil() + 1;
    }

    return daysDifference + 1; // Default fallback
  }

  // Clear cache manually if needed
  static void clearCache() {
    _rruleCache.clear();
  }

  static String optionKeyFromSelection(String selection) {
    final v = selection;
    if (!v.startsWith('RRULE:')) return v; // 已是中文标签，例如“无”
    if (v.contains('FREQ=DAILY')) return '每天';
    if (v.contains('FREQ=WEEKLY') && v.contains('BYDAY=MO,TU,WE,TH,FR')) {
      return '每周工作日 (周一至周五)';
    }
    if (v.contains('FREQ=WEEKLY')) return '每周（选择星期）';
    if (v.contains('FREQ=MONTHLY')) return '每月（选择日）';
    if (v.contains('FREQ=YEARLY')) return '每年（选择月日）';
    return '自定义（频率与间隔）';
  }

  static String humanize(String rrule) {
    return RepeatPattern.parse(rrule).toReadableString(null);
  }

  static String _weekdayCodeToCN(String code) {
    const map = {
      'MO': '周一',
      'TU': '周二',
      'WE': '周三',
      'TH': '周四',
      'FR': '周五',
      'SA': '周六',
      'SU': '周日',
    };
    return map[code] ?? code;
  }

  // Convert iCal weekday code (MO..SU) to Dart weekday int (Mon=1..Sun=7)
  static int? _weekdayCodeToDart(String code) {
    switch (code) {
      case 'MO':
        return DateTime.monday; // 1
      case 'TU':
        return DateTime.tuesday; // 2
      case 'WE':
        return DateTime.wednesday; // 3
      case 'TH':
        return DateTime.thursday; // 4
      case 'FR':
        return DateTime.friday; // 5
      case 'SA':
        return DateTime.saturday; // 6
      case 'SU':
        return DateTime.sunday; // 7
      default:
        return null;
    }
  }

  // Get the Monday of the week for the given date
  static DateTime _startOfWeek(DateTime date) {
    final int diff = date.weekday - DateTime.monday; // 0 for Monday
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: diff));
  }

  // Safely create a date; if day exceeds last day of month, clamp it
  static DateTime _safeDate(int year, int month, int day) {
    final int lastDay = DateTime(year, month + 1, 0).day;
    final int clamped = day > lastDay ? lastDay : (day < 1 ? 1 : day);
    return DateTime(year, month, clamped);
  }
}
