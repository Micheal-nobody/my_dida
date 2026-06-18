import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/checklist_vo.dart';
import 'package:my_dida/provider/task_provider.dart';

import 'test_support/task_test_harness.dart';

void main() {
  group('TaskProvider', () {
    late TaskTestHarness harness;
    late TaskProvider provider;

    setUp(() async {
      harness = await TaskTestHarness.create();
      provider = harness.createProvider();
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('mutation methods refresh currentTasks', () async {
      final task = Task(
        name: 'Original',
        isAllDay: false,
        startTime: DateTime(2026, 4, 12, 9),
        checklistId: 1,
      );

      await provider.addTask(task);

      await provider.addTask(task);
      final created = provider.currentTasks.single;

      await provider.updateTitle(created, 'Updated');

      expect(provider.currentTasks.single.name, 'Updated');
    });

    test('loadCalendarTaskViewData returns grouped tasks and future tasks', () async {
      await provider.addTask(
        Task(
          name: 'Visible',
          isAllDay: false,
          startTime: DateTime(2026, 4, 12, 9),
          checklistId: 1,
        ),
      );
      await provider.addTask(
        Task(
          name: 'Future',
          isAllDay: false,
          startTime: DateTime(2026, 4, 20, 9),
          checklistId: 1,
        ),
      );

      final data = await provider.loadCalendarTaskViewData(
        visibleDates: [DateTime(2026, 4, 12)],
        rruleBatchLimit: {DateTime(2026, 4, 12): 5},
      );

      expect(data.tasksForDates[DateTime(2026, 4, 12)]?.map((task) => task.name), contains('Visible'));
      expect(data.futureTasks.values.expand((tasks) => tasks).map((task) => task.name), contains('Future'));
    });
  });
}
