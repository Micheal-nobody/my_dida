import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/settings/providers/sidebar_config_provider.dart';
import 'package:my_dida/core/di/locator.dart';

import 'test_support/task_test_harness.dart';

Future<void> _waitForTasks(TaskProvider provider, int expectedCount) async {
  final stopwatch = Stopwatch()..start();
  while (provider.currentTasks.length != expectedCount &&
      stopwatch.elapsedMilliseconds < 2000) {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

Future<void> _waitForTaskCondition(
  TaskProvider provider,
  bool Function(List<Task> tasks) condition,
) async {
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

      await provider.execute(AddTask(task));
      final allTasksInDb = await harness.taskRepository.getAllData();
      print('DEBUG: allTasksInDb: $allTasksInDb');
      await _waitForTasks(provider, 1);
      final created = provider.currentTasks.single;

      await provider.execute(UpdateTitle(created, 'Updated'));
      await _waitForTaskCondition(
        provider,
        (tasks) => tasks.isNotEmpty && tasks.first.name == 'Updated',
      );

      expect(provider.currentTasks.single.name, 'Updated');
    });

    test('pure isar watch test', () async {
      final repo = harness.taskRepository;
      final list = <List<Task>>[];
      final sub = repo.watchByChecklistId(1).listen((event) {
        list.add(event);
      });

      await Future.delayed(Duration.zero);

      await repo.addTask(
        Task(name: 'Test Task', checklistId: 1, isAllDay: false),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      print('DEBUG: Pure watch events count: ${list.length}, events: $list');
      await sub.cancel();
    });

    test(
      'loadCalendarTaskViewData returns grouped tasks and future tasks',
      () async {
        await Future.delayed(Duration.zero);

        await provider.execute(
          AddTask(
            Task(
              name: 'Visible',
              isAllDay: false,
              startTime: DateTime(2026, 4, 12, 9),
              checklistId: 1,
            ),
          ),
        );
        await provider.execute(
          AddTask(
            Task(
              name: 'Future',
              isAllDay: false,
              startTime: DateTime(2026, 4, 20, 9),
              checklistId: 1,
            ),
          ),
        );

        final data = await provider.loadCalendarTaskViewData(
          visibleDates: [DateTime(2026, 4, 12)],
          rruleBatchLimit: {DateTime(2026, 4, 12): 5},
        );

        expect(
          data.tasksForDates[DateTime(2026, 4, 12)]?.map((task) => task.name),
          contains('Visible'),
        );
        expect(
          data.futureTasks.values
              .expand((tasks) => tasks)
              .map((task) => task.name),
          contains('Future'),
        );
      },
    );

    test('SidebarConfigProvider manages settings correctly', () async {
      // Register SidebarConfigProvider in harness GetIt since it's not automatically there
      getIt.registerSingleton<SidebarConfigProvider>(SidebarConfigProvider());
      final configProvider = getIt<SidebarConfigProvider>();

      expect(configProvider.config.theme, 'system');
      expect(configProvider.config.showProfile, true);

      await configProvider.updateTheme('dark');
      await configProvider.updateModuleVisibility(
        showProfile: false,
        showSearch: false,
      );

      expect(configProvider.config.theme, 'dark');
      expect(configProvider.config.showProfile, false);
      expect(configProvider.config.showSearch, false);
    });

    test('TaskProvider getSmartListCounts and smart list filters', () async {
      await Future.delayed(Duration.zero);

      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      // Add a today task
      await provider.execute(
        AddTask(
          Task(
            name: 'Today Task',
            isAllDay: false,
            startTime: now,
            checklistId: 1,
          ),
        ),
      );

      // Add a tomorrow task
      await provider.execute(
        AddTask(
          Task(
            name: 'Tomorrow Task',
            isAllDay: false,
            startTime: tomorrow,
            checklistId: 1,
          ),
        ),
      );

      final counts = await provider.getSmartListCounts();

      expect(counts[-1], 1); // Today
      expect(counts[-2], 1); // Tomorrow
      expect(counts[1], 2); // Inbox (since both are checklistId = 1)
      expect(counts[-4], 2); // All

      // Toggle done on Today Task
      final tasks = await harness.taskRepository.getAllData();
      final todayTask = tasks.firstWhere((t) => t.name == 'Today Task');
      await provider.execute(UpdateTaskIsDone(todayTask, true));

      final counts2 = await provider.getSmartListCounts();
      expect(counts2[-1], 0); // Today now has 0 incomplete
      expect(counts2[-5], 1); // Completed has 1 task

      // Delete tomorrow task (enters Trash)
      final tomorrowTask = tasks.firstWhere((t) => t.name == 'Tomorrow Task');
      await provider.execute(DeleteTask(tomorrowTask));

      final counts3 = await provider.getSmartListCounts();
      expect(counts3[-2], 0); // Tomorrow now has 0
      expect(counts3[-6], 1); // Trash has 1 task (deleted task operation)
    });
  });
}
