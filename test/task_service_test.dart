import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/task_reminder_plan.dart';
import 'package:my_dida/services/task_reminder_scheduler_port.dart';
import 'package:my_dida/services/task_service.dart';

import 'test_support/task_test_harness.dart';

class RecordingTaskReminderScheduler implements TaskReminderSchedulerPort {
  final List<TaskReminderPlan> scheduledPlans = [];
  final List<int> canceledTaskIds = [];

  @override
  Future<void> cancelByTaskId(int taskId) async {
    canceledTaskIds.add(taskId);
  }

  @override
  Future<void> schedule(TaskReminderPlan plan) async {
    scheduledPlans.add(plan);
  }
}

void main() {
  group('TaskService', () {
    late TaskTestHarness harness;
    late TaskService service;
    late RecordingTaskReminderScheduler scheduler;

    setUp(() async {
      scheduler = RecordingTaskReminderScheduler();
      harness = await TaskTestHarness.create(taskReminderScheduler: scheduler);
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

      final reloadedParent = await harness.taskRepository.selectById(parent.id);
      expect(child.parentTaskId, parent.id);
      expect(reloadedParent?.subTaskIds, contains(child.id));
    });

    test('createTask schedules reminder when configuration is valid', () async {
      final startTime = DateTime.now().add(const Duration(days: 2));

      final task = await service.createTask(
        name: 'Reminder',
        checklistId: 1,
        startTime: startTime,
        notificationEnabled: true,
        reminderOffsetMinutes: 30,
      );

      expect(task.notificationEnabled, isTrue);
      expect(task.reminderOffsetMinutes, 30);
      expect(scheduler.scheduledPlans, hasLength(1));
      expect(scheduler.scheduledPlans.single.taskId, task.id);
      expect(
        scheduler.scheduledPlans.single.triggerAt,
        startTime.subtract(const Duration(minutes: 30)),
      );
    });

    test('createTask rejects invalid reminder configurations', () async {
      expect(
        () => service.createTask(
          name: 'No Start Time',
          checklistId: 1,
          notificationEnabled: true,
          reminderOffsetMinutes: 10,
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        () => service.createTask(
          name: 'All Day',
          checklistId: 1,
          isAllDay: true,
          startTime: DateTime.now().add(const Duration(days: 1)),
          notificationEnabled: true,
          reminderOffsetMinutes: 10,
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        () => service.createTask(
          name: 'Out of Range',
          checklistId: 1,
          startTime: DateTime.now().add(const Duration(days: 1)),
          notificationEnabled: true,
          reminderOffsetMinutes: 10081,
        ),
        throwsA(isA<Exception>()),
      );
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

      final reloadedParent = await harness.taskRepository.selectById(parent.id);
      final deletedChild = await harness.taskRepository.selectById(child.id);
      expect(deletedChild, isNull);
      expect(reloadedParent?.subTaskIds, isNot(contains(child.id)));
      expect(scheduler.canceledTaskIds, contains(child.id));
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

      final allTasks = await harness.taskRepository.selectAll();
      final copiedParent = allTasks.firstWhere((task) => task.name == 'Parent (副本)');
      final copiedChild = allTasks.firstWhere((task) => task.name == 'Child (副本)');

      expect(copiedParent.subTaskIds, contains(copiedChild.id));
      expect(copiedChild.parentTaskId, copiedParent.id);
    });

    test('updateTaskReminder can disable and cancel an existing reminder', () async {
      final task = await service.createTask(
        name: 'Reminder',
        checklistId: 1,
        startTime: DateTime.now().add(const Duration(days: 2)),
        notificationEnabled: true,
        reminderOffsetMinutes: 15,
      );

      await service.updateTaskReminder(task, enabled: false);

      expect(task.notificationEnabled, isFalse);
      expect(task.reminderOffsetMinutes, isNull);
      expect(scheduler.canceledTaskIds, contains(task.id));
    });

    test('clearTaskSchedule clears reminder config and cancels reminder', () async {
      final task = await service.createTask(
        name: 'Scheduled',
        checklistId: 1,
        startTime: DateTime.now().add(const Duration(days: 2)),
        notificationEnabled: true,
        reminderOffsetMinutes: 20,
      );

      await service.clearTaskSchedule(task);

      final reloaded = await harness.taskRepository.selectById(task.id);
      expect(reloaded?.startTime, isNull);
      expect(reloaded?.rrule, isNull);
      expect(reloaded?.notificationEnabled, isFalse);
      expect(reloaded?.reminderOffsetMinutes, isNull);
      expect(scheduler.canceledTaskIds, contains(task.id));
    });

    test('completing recurring task cancels current reminder and schedules next task', () async {
      final currentTask = await service.createTask(
        name: 'Recurring',
        checklistId: 1,
        startTime: DateTime.now().add(const Duration(days: 2)),
        notificationEnabled: true,
        reminderOffsetMinutes: 10,
        rrule: 'FREQ=DAILY',
      );

      final initialScheduleCount = scheduler.scheduledPlans.length;
      await service.updateTaskCompletion(currentTask, true);

      final allTasks = await harness.taskRepository.selectAll();
      final nextTask = allTasks.where((task) => task.id != currentTask.id).single;

      expect(scheduler.canceledTaskIds, contains(currentTask.id));
      expect(scheduler.scheduledPlans.length, greaterThan(initialScheduleCount));
      expect(
        scheduler.scheduledPlans.any((plan) => plan.taskId == nextTask.id),
        isTrue,
      );
      expect(nextTask.notificationEnabled, isTrue);
      expect(nextTask.reminderOffsetMinutes, 10);
    });
  });
}
