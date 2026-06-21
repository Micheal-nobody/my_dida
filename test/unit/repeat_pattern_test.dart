import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/features/tasks/models/repeat_pattern.dart';

void main() {
  group('RepeatPattern Value Object Tests', () {
    test('Constructors and properties', () {
      const none = RepeatPattern.none();
      expect(none.type, RepeatType.none);
      expect(none.isNone, isTrue);
      expect(none.toRRuleString(), isNull);

      const daily = RepeatPattern.daily(3);
      expect(daily.type, RepeatType.daily);
      expect(daily.interval, 3);
      expect(daily.toRRuleString(), 'RRULE:FREQ=DAILY;INTERVAL=3');

      const weekly = RepeatPattern.weekly([1, 3, 5], 2);
      expect(weekly.type, RepeatType.weekly);
      expect(weekly.weekdays, [1, 3, 5]);
      expect(weekly.interval, 2);
      expect(
        weekly.toRRuleString(),
        'RRULE:FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR',
      );

      const monthly = RepeatPattern.monthly(15, 1);
      expect(monthly.type, RepeatType.monthly);
      expect(monthly.dayOfMonth, 15);
      expect(
        monthly.toRRuleString(),
        'RRULE:FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=15',
      );

      const yearly = RepeatPattern.yearly(10, 20, 1);
      expect(yearly.type, RepeatType.yearly);
      expect(yearly.month, 10);
      expect(yearly.dayOfMonth, 20);
      expect(
        yearly.toRRuleString(),
        'RRULE:FREQ=YEARLY;INTERVAL=1;BYMONTH=10;BYMONTHDAY=20',
      );

      const ebbinghaus = RepeatPattern.ebbinghaus();
      expect(ebbinghaus.type, RepeatType.ebbinghaus);
      expect(ebbinghaus.isEbbinghaus, isTrue);
      expect(ebbinghaus.toRRuleString(), 'CUSTOM:EBBINGHAUS');

      const workday = RepeatPattern.workday();
      expect(workday.type, RepeatType.workday);
      expect(workday.isWorkday, isTrue);
      expect(workday.toRRuleString(), 'CUSTOM:WORKDAY');
    });

    test('Parsing RRule strings', () {
      expect(RepeatPattern.parse(null), const RepeatPattern.none());
      expect(RepeatPattern.parse(''), const RepeatPattern.none());
      expect(
        RepeatPattern.parse('CUSTOM:EBBINGHAUS'),
        const RepeatPattern.ebbinghaus(),
      );
      expect(
        RepeatPattern.parse('custom:workday'),
        const RepeatPattern.workday(),
      );

      final parsedDaily = RepeatPattern.parse('RRULE:FREQ=DAILY;INTERVAL=2');
      expect(parsedDaily.type, RepeatType.daily);
      expect(parsedDaily.interval, 2);

      final parsedWeekly = RepeatPattern.parse(
        'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,FR',
      );
      expect(parsedWeekly.type, RepeatType.weekly);
      expect(parsedWeekly.weekdays, [1, 5]);
      expect(parsedWeekly.interval, 1);

      final parsedMonthly = RepeatPattern.parse(
        'FREQ=MONTHLY;INTERVAL=3;BYMONTHDAY=28',
      );
      expect(parsedMonthly.type, RepeatType.monthly);
      expect(parsedMonthly.dayOfMonth, 28);
      expect(parsedMonthly.interval, 3);
    });

    test('Human readable descriptions (toReadableString)', () {
      expect(const RepeatPattern.none().toReadableString(null), '无');
      expect(
        const RepeatPattern.ebbinghaus().toReadableString(null),
        '艾宾浩斯记忆法',
      );
      expect(const RepeatPattern.workday().toReadableString(null), '法定工作日');
      expect(const RepeatPattern.daily(1).toReadableString(null), '每天');
      expect(const RepeatPattern.daily(5).toReadableString(null), '每 5 天');

      expect(
        const RepeatPattern.weekly([1, 2, 3, 4, 5], 1).toReadableString(null),
        '每周工作日 (周一至周五)',
      );
      expect(
        const RepeatPattern.weekly([1, 3], 1).toReadableString(null),
        '每周（周一、周三）',
      );

      final baseDate = DateTime(2026, 6, 21); // Sunday (7)
      expect(
        const RepeatPattern.weekly([], 1).toReadableString(baseDate),
        '每周 (周日)',
      );
      expect(
        const RepeatPattern.monthly(null, 1).toReadableString(baseDate),
        '每月（21 日）',
      );
      expect(
        const RepeatPattern.yearly(null, null, 1).toReadableString(baseDate),
        '每年（6 月 21 日）',
      );
    });

    test('Equality and HashCode', () {
      expect(const RepeatPattern.daily(1), const RepeatPattern.daily(1));
      expect(
        const RepeatPattern.daily(1) == const RepeatPattern.daily(2),
        isFalse,
      );
      expect(
        const RepeatPattern.weekly([1, 2]),
        const RepeatPattern.weekly([1, 2]),
      );
      expect(
        const RepeatPattern.weekly([1, 2]) ==
            const RepeatPattern.weekly([2, 1]),
        isFalse,
      );
      expect(
        const RepeatPattern.ebbinghaus(),
        const RepeatPattern.ebbinghaus(),
      );
    });

    test('nextOccurrenceAfter for Ebbinghaus', () {
      final start = DateTime(2026, 6, 20, 9, 0); // Saturday
      const ebbinghaus = RepeatPattern.ebbinghaus();

      // Check occurrences strictly after the start (anchor = start)
      // Ebbinghaus offsets: 1, 2, 4, 7, 15, 30 days
      expect(
        ebbinghaus.nextOccurrenceAfter(start, start),
        DateTime(2026, 6, 21, 9, 0), // +1 day
      );

      expect(
        ebbinghaus.nextOccurrenceAfter(start, DateTime(2026, 6, 21, 10, 0)),
        DateTime(2026, 6, 22, 9, 0), // +2 days
      );

      expect(
        ebbinghaus.nextOccurrenceAfter(start, DateTime(2026, 6, 23, 9, 0)),
        DateTime(2026, 6, 24, 9, 0), // +4 days
      );

      expect(
        ebbinghaus.nextOccurrenceAfter(start, DateTime(2026, 7, 10, 9, 0)),
        DateTime(2026, 7, 20, 9, 0), // +30 days
      );

      expect(
        ebbinghaus.nextOccurrenceAfter(start, DateTime(2026, 7, 21, 9, 0)),
        isNull,
      );
    });

    test('nextOccurrenceAfter for Workday', () {
      final start = DateTime(2026, 6, 19, 9, 0); // Friday
      const workday = RepeatPattern.workday();

      // Next occurrence after Friday should skip Sat (20th), Sun (21st) and fall on Mon (22nd)
      expect(
        workday.nextOccurrenceAfter(start, start),
        DateTime(2026, 6, 22, 9, 0),
      );

      // Next occurrence after Monday (22nd) should fall on Tuesday (23rd)
      expect(
        workday.nextOccurrenceAfter(start, DateTime(2026, 6, 22, 9, 0)),
        DateTime(2026, 6, 23, 9, 0),
      );
    });
  });
}
