import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/core/utils/time_formatter.dart';

void main() {
  group('TimeFormatter Tests', () {
    final now = DateTime(2026, 7, 2, 10, 30); // 2026-07-02 10:30

    test('formatRelativeDate - today', () {
      final date = DateTime(2026, 7, 2, 15, 0);
      expect(TimeFormatter.formatRelativeDate(date, now: now), '今天');
    });

    test('formatRelativeDate - tomorrow', () {
      final date = DateTime(2026, 7, 3, 9, 0);
      expect(TimeFormatter.formatRelativeDate(date, now: now), '明天');
    });

    test('formatRelativeDate - day after tomorrow (includeDayAfterTomorrow = false)', () {
      final date = DateTime(2026, 7, 4, 9, 0);
      expect(TimeFormatter.formatRelativeDate(date, now: now), '7月4日');
    });

    test('formatRelativeDate - day after tomorrow (includeDayAfterTomorrow = true)', () {
      final date = DateTime(2026, 7, 4, 9, 0);
      expect(TimeFormatter.formatRelativeDate(date, now: now, includeDayAfterTomorrow: true), '后天');
    });

    test('formatRelativeDate - other date in the same year', () {
      final date = DateTime(2026, 7, 5, 9, 0);
      expect(TimeFormatter.formatRelativeDate(date, now: now), '7月5日');
    });

    test('formatRelativeDate - date in another year', () {
      // Current implementation returns 'M月d日' regardless of year.
      // Wait, is this intended or should it include the year?
      // Let's verify what the current code does:
      // return '${dateTime.month}月${dateTime.day}日';
      // Yes, it returns M月d日.
      final date = DateTime(2027, 1, 1, 9, 0);
      expect(TimeFormatter.formatRelativeDate(date, now: now), '1月1日');
    });

    test('formatTaskDate - null', () {
      expect(TimeFormatter.formatTaskDate(null, now: now), '');
    });

    test('formatTaskDate - today with time', () {
      // DateTime(2026, 7, 2, 15, 30) hasTime since hour = 15 != 0
      final date = DateTime(2026, 7, 2, 15, 30);
      expect(TimeFormatter.formatTaskDate(date, now: now), '今天,15:30');
    });

    test('formatTaskDate - today without time (hour = 0, minute = 0)', () {
      final date = DateTime(2026, 7, 2, 0, 0);
      expect(TimeFormatter.formatTaskDate(date, now: now), '今天');
    });

    test('formatTaskDateTime', () {
      final date = DateTime(2026, 7, 2, 15, 30);
      expect(TimeFormatter.formatTaskDateTime(date), '07-02 15:30');
    });

    test('formatDateTimeRange - all day', () {
      final date = DateTime(2026, 7, 2);
      expect(
        TimeFormatter.formatDateTimeRange(
          date,
          isAllDay: true,
          now: now,
        ),
        '今天',
      );
    });

    test('formatDateTimeRange - with start time only', () {
      final date = DateTime(2026, 7, 2);
      expect(
        TimeFormatter.formatDateTimeRange(
          date,
          isAllDay: false,
          startTime: const TimeOfDay(hour: 9, minute: 15),
          now: now,
        ),
        '今天 09:15',
      );
    });

    test('formatDateTimeRange - with start and end time', () {
      final date = DateTime(2026, 7, 2);
      expect(
        TimeFormatter.formatDateTimeRange(
          date,
          isAllDay: false,
          startTime: const TimeOfDay(hour: 9, minute: 15),
          endTime: const TimeOfDay(hour: 10, minute: 30),
          now: now,
        ),
        '今天 09:15-10:30',
      );
    });

    test('formatFullDateTimeRange - today all day', () {
      final date = DateTime(2026, 7, 2);
      expect(
        TimeFormatter.formatFullDateTimeRange(
          date,
          isAllDay: true,
          now: now,
        ),
        '今天, 7月2日',
      );
    });

    test('formatFullDateTimeRange - today with start and end time', () {
      final date = DateTime(2026, 7, 2);
      expect(
        TimeFormatter.formatFullDateTimeRange(
          date,
          isAllDay: false,
          startTime: const TimeOfDay(hour: 9, minute: 15),
          endTime: const TimeOfDay(hour: 10, minute: 30),
          now: now,
        ),
        '今天, 7月2日 09:15-10:30',
      );
    });

    test('formatFullDateTimeRange - tomorrow with start time', () {
      final date = DateTime(2026, 7, 3);
      expect(
        TimeFormatter.formatFullDateTimeRange(
          date,
          isAllDay: false,
          startTime: const TimeOfDay(hour: 9, minute: 15),
          now: now,
        ),
        '明天, 7月3日 09:15',
      );
    });

    test('formatFullDateTimeRange - other day with start and end time', () {
      final date = DateTime(2026, 7, 5);
      expect(
        TimeFormatter.formatFullDateTimeRange(
          date,
          isAllDay: false,
          startTime: const TimeOfDay(hour: 9, minute: 15),
          endTime: const TimeOfDay(hour: 10, minute: 30),
          now: now,
        ),
        '7月5日 09:15-10:30',
      );
    });

    test('formatTaskDateTimeRange - start only, has time', () {
      // 2026-07-02 15:30. Start hasTime is true.
      final start = DateTime(2026, 7, 2, 15, 30);
      expect(
        TimeFormatter.formatTaskDateTimeRange(start, null),
        '7月2日15:30',
      );
    });

    test('formatTaskDateTimeRange - start only, no time', () {
      final start = DateTime(2026, 7, 2, 0, 0);
      expect(
        TimeFormatter.formatTaskDateTimeRange(start, null),
        '7月2日',
      );
    });

    test('formatTaskDateTimeRange - start and end', () {
      final start = DateTime(2026, 7, 2, 15, 30);
      final end = DateTime(2026, 7, 2, 16, 0);
      expect(
        TimeFormatter.formatTaskDateTimeRange(start, end),
        '7月2日15:30 --> 16:00',
      );
    });

    test('formatFullDate', () {
      final date = DateTime(2026, 7, 2);
      expect(TimeFormatter.formatFullDate(date), '2026年7月2日');
    });

    test('formatTimeOnly', () {
      final date = DateTime(2026, 7, 2, 9, 5);
      expect(TimeFormatter.formatTimeOnly(date), '09:05');
    });
  });
}
