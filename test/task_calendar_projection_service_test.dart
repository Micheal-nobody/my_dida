import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/services/task_calendar_projection_service.dart';

void main() {
  group('TaskCalendarProjectionService', () {
    late TaskCalendarProjectionService projectionService;

    setUp(() {
      projectionService = TaskCalendarProjectionService();
    });

    test('buildCalendarTaskViewData expands recurring tasks and paginates', () {
      final baseDate = DateTime(2026, 4, 12, 9);
      final recurringTasks = List.generate(6, (index) {
        final task = Task(
          name: 'Recurring $index',
          isAllDay: false,
          startTime: baseDate.add(Duration(minutes: index)),
          checklistId: 1,
          rrule: 'FREQ=DAILY',
        )..id = index + 1;
        return task;
      });

      final data = projectionService.buildCalendarTaskViewData(
        tasks: recurringTasks,
        visibleDates: [DateTime(2026, 4, 13)],
        rruleBatchLimit: {DateTime(2026, 4, 13): 5},
      );

      expect(data.tasksForDates[DateTime(2026, 4, 13)]?.length, 5);
      expect(data.rruleHasMore[DateTime(2026, 4, 13)], isTrue);
    });
  });
}
