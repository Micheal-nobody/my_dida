import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/features/tasks/models/repeat_pattern.dart';
import 'package:my_dida/shared/widgets/datetime/custom_date_time_picker.dart';

void main() {
  group('CustomDateTimePickerValue Tests', () {
    test(
      'cleared factory constructor should return null for all date and time fields',
      () {
        final cleared = CustomDateTimePickerValue.cleared();

        expect(cleared.selectedDate, isNull);
        expect(cleared.startTime, isNull);
        expect(cleared.endTime, isNull);
        expect(cleared.startDate, isNull);
        expect(cleared.endDate, isNull);
        expect(cleared.isAllDay, isFalse);
        expect(cleared.rrule, const RepeatPattern.none());
        expect(cleared.isTimeOnlyDate, isFalse);
        expect(cleared.reminderOffsets, isEmpty);
        expect(cleared.notificationEnabled, isFalse);
      },
    );

    test('copyWith should copy properties correctly', () {
      final value = CustomDateTimePickerValue.cleared();
      final now = DateTime.now();

      final updated = value.copyWith(selectedDate: now, isAllDay: true);

      expect(updated.selectedDate, now);
      expect(updated.isAllDay, isTrue);
      // Other fields should remain null/default
      expect(updated.startTime, isNull);
      expect(updated.startDate, isNull);
    });
  });
}
