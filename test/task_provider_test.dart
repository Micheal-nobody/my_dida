import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/checklist_vo.dart';
import 'package:my_dida/provider/task_provider.dart';

import 'test_support/task_test_harness.dart';

Future<void> _waitForTasks(TaskProvider provider, int expectedCount) async {
  final stopwatch = Stopwatch()..start();
  while (provider.currentTasks.length != expectedCount &&
      stopwatch.elapsedMilliseconds < 2000) {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

Future<void> _waitForTaskCondition(
    TaskProvider provider, bool Function(List<Task> tasks) condition) async {
  final stopwatch = Stopwatch()..start();
  while (!condition(provider.currentTasks) &&
      stopwatch.elapsedMilliseconds < 2000) {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

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
      await Future.delayed(Duration.zero);

      final task = Task(
        name: 'Original',
        isAllDay: false,
        startTime: DateTime(2026, 4, 12, 9),
        checklistId: 1,
      );

      await provider.addTask(task);
      final allTasksInDb = await harness.taskRepository.getAllData();
      print('DEBUG: allTasksInDb: $allTasksInDb');
      await _waitForTasks(provider, 1);
      final created = provider.currentTasks.single;

      await provider.updateTitle(created, 'Updated');
      await _waitForTaskCondition(
          provider, (tasks) => tasks.isNotEmpty && tasks.first.name == 'Updated');

      expect(provider.currentTasks.single.name, 'Updated');
    });

    test('pure isar watch test', () async {
      final repo = harness.taskRepository;
      final list = <List<Task>>[];
      final sub = repo.watchByChecklistId(1).listen((event) {
        list.add(event);
      });

      await Future.delayed(Duration.zero);

      await repo.addTask(Task(name: 'Test Task', checklistId: 1, isAllDay: false));
      await Future.delayed(const Duration(milliseconds: 100));

      print('DEBUG: Pure watch events count: ${list.length}, events: $list');
      await sub.cancel();
    });

    test('loadCalendarTaskViewData returns grouped tasks and future tasks', () async {
      await Future.delayed(Duration.zero);

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
