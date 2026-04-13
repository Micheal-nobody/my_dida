import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/services/task_service.dart';

import 'test_support/task_test_harness.dart';

void main() {
  group('TaskService', () {
    late TaskTestHarness harness;
    late TaskService service;

    setUp(() async {
      harness = await TaskTestHarness.create();
      service = harness.taskService;
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('createTask validates input and links parent/subtask', () async {
      expect(
        () => service.createTask(name: '   '),
        throwsA(isA<Exception>()),
      );

      final parent = await service.createTask(
        name: 'Parent',
        checklistId: 1,
      );
      final child = await service.createTask(
        name: 'Child',
        parentTaskId: parent.id,
        checklistId: 1,
      );

      final reloadedParent = await harness.taskRepository.getById(parent.id);
      expect(child.parentTaskId, parent.id);
      expect(reloadedParent?.subTaskIds, contains(child.id));
    });

    test('deleteTask removes subtree and cleans parent reference', () async {
      final parent = await service.createTask(
        name: 'Parent',
        checklistId: 1,
      );
      final child = await service.createTask(
        name: 'Child',
        parentTaskId: parent.id,
        checklistId: 1,
      );

      await service.deleteTask(child);

      final reloadedParent = await harness.taskRepository.getById(parent.id);
      final deletedChild = await harness.taskRepository.getById(child.id);
      expect(deletedChild, isNull);
      expect(reloadedParent?.subTaskIds, isNot(contains(child.id)));
    });

    test('copyTask copies nested subtasks', () async {
      final parent = await service.createTask(
        name: 'Parent',
        checklistId: 1,
      );
      final child = await service.createTask(
        name: 'Child',
        parentTaskId: parent.id,
        checklistId: 1,
      );

      await service.copyTask(parent);

      final allTasks = await harness.taskRepository.getAll();
      final copiedParent = allTasks.firstWhere((task) => task.name == 'Parent (副本)');
      final copiedChild = allTasks.firstWhere((task) => task.name == 'Child (副本)');

      expect(copiedParent.subTaskIds, contains(copiedChild.id));
      expect(copiedChild.parentTaskId, copiedParent.id);
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

      final data = service.buildCalendarTaskViewData(
        tasks: recurringTasks,
        visibleDates: [DateTime(2026, 4, 13)],
        rruleBatchLimit: {DateTime(2026, 4, 13): 5},
      );

      expect(data.tasksForDates[DateTime(2026, 4, 13)]?.length, 5);
      expect(data.rruleHasMore[DateTime(2026, 4, 13)], isTrue);
    });
  });
}
