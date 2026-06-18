import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/task_reminder_plan.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:my_dida/services/task_reminder_scheduler_port.dart';

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
  group('TaskProvider (原 TaskService 逻辑)', () {
    late TaskTestHarness harness;
    late RecordingTaskReminderScheduler scheduler;

    setUp(() async {
      scheduler = RecordingTaskReminderScheduler();
      harness = await TaskTestHarness.create(taskReminderScheduler: scheduler);
    });

    tearDown(() async {
      await harness.dispose();
    });

    test('createTask validates input and links parent/subtask', () async {
      final provider = harness.createProvider();
      await Future.delayed(Duration.zero);

      expect(
        () => provider.addTask(Task(name: '   ', isAllDay: false)),
        throwsA(isA<Exception>()),
      );

      final parent = await provider.addTask(Task(
        name: 'Parent',
        isAllDay: false,
        checklistId: 1,
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentTasks, isNotEmpty);

      final child = await provider.addTask(Task(
        name: 'Child',
        isAllDay: false,
        parentTaskId: parent.id,
        checklistId: 1,
      ));

      final reloadedParent = await harness.taskRepository.selectById(parent.id);
      expect(child.parentTaskId, parent.id);
      expect(reloadedParent?.subTaskIds, contains(child.id));
    });

    test('createTask schedules reminder when configuration is valid', () async {
      final provider = harness.createProvider();
      final startTime = DateTime.now().add(const Duration(days: 2));

      final task = await provider.addTask(Task(
        name: 'Reminder',
        isAllDay: false,
        checklistId: 1,
        startTime: startTime,
        notificationEnabled: true,
        reminderOffsetMinutes: 30,
      ));

      expect(task.notificationEnabled, isTrue);
      expect(task.reminderOffsetMinutes, 30);
      expect(scheduler.scheduledPlans, hasLength(1));
      expect(scheduler.scheduledPlans.single.taskId, task.id);
      expect(
        scheduler.scheduledPlans.single.triggerAt,
        startTime.subtract(const Duration(minutes: 30)),
      );
    });

    test('deleteTask removes subtree and cleans parent reference', () async {
      final provider = harness.createProvider();

      final parent = await provider.addTask(Task(
        name: 'Parent',
        isAllDay: false,
        checklistId: 1,
      ));
      final child = await provider.addTask(Task(
        name: 'Child',
        isAllDay: false,
        parentTaskId: parent.id,
        checklistId: 1,
      ));

      await provider.deleteTask(child);

      final reloadedParent = await harness.taskRepository.selectById(parent.id);
      final deletedChild = await harness.taskRepository.selectById(child.id);
      expect(deletedChild, isNull);
      expect(reloadedParent?.subTaskIds, isNot(contains(child.id)));
      expect(scheduler.canceledTaskIds, contains(child.id));
    });

    test('copyTask copies nested subtasks', () async {
      final provider = harness.createProvider();

      final parent = await provider.addTask(Task(
        name: 'Parent',
        isAllDay: false,
        checklistId: 1,
      ));
      await provider.addTask(Task(
        name: 'Child',
        isAllDay: false,
        parentTaskId: parent.id,
        checklistId: 1,
      ));

      await provider.copyTask(parent);

      final allTasks = await harness.taskRepository.selectAll();
      final copiedParent =
          allTasks.firstWhere((task) => task.name == 'Parent (副本)');
      final copiedChild =
          allTasks.firstWhere((task) => task.name == 'Child (副本)');

      expect(copiedParent.subTaskIds, contains(copiedChild.id));
      expect(copiedChild.parentTaskId, copiedParent.id);
    });

    test('updateTaskReminder can disable and cancel an existing reminder',
        () async {
      final provider = harness.createProvider();
      final startTime = DateTime.now().add(const Duration(days: 2));

      final task = await provider.addTask(Task(
        name: 'Reminder',
        isAllDay: false,
        checklistId: 1,
        startTime: startTime,
        notificationEnabled: true,
        reminderOffsetMinutes: 15,
      ));

      await provider.updateTaskReminder(task, enabled: false);

      expect(task.notificationEnabled, isFalse);
      expect(task.reminderOffsetMinutes, isNull);
      expect(scheduler.canceledTaskIds, contains(task.id));
    });

    test('clearTaskSchedule clears reminder config and cancels reminder',
        () async {
      final provider = harness.createProvider();
      final startTime = DateTime.now().add(const Duration(days: 2));

      final task = await provider.addTask(Task(
        name: 'Scheduled',
        isAllDay: false,
        checklistId: 1,
        startTime: startTime,
        notificationEnabled: true,
        reminderOffsetMinutes: 20,
      ));

      await provider.clearTaskSchedule(task);

      final reloaded = await harness.taskRepository.selectById(task.id);
      expect(reloaded?.startTime, isNull);
      expect(reloaded?.rrule, isNull);
      expect(reloaded?.notificationEnabled, isFalse);
      expect(reloaded?.reminderOffsetMinutes, isNull);
      expect(scheduler.canceledTaskIds, contains(task.id));
    });

    test(
        'completing recurring task cancels current reminder and schedules next task',
        () async {
      final provider = harness.createProvider();
      final startTime = DateTime.now().add(const Duration(days: 2));

      final currentTask = await provider.addTask(Task(
        name: 'Recurring',
        isAllDay: false,
        checklistId: 1,
        startTime: startTime,
        notificationEnabled: true,
        reminderOffsetMinutes: 10,
        rrule: 'FREQ=DAILY',
      ));

      final initialScheduleCount = scheduler.scheduledPlans.length;
      await provider.updateTaskIsDone(currentTask, true);

      final allTasks = await harness.taskRepository.selectAll();
      final nextTask =
          allTasks.where((task) => task.id != currentTask.id).single;

      expect(scheduler.canceledTaskIds, contains(currentTask.id));
      expect(scheduler.scheduledPlans.length,
          greaterThan(initialScheduleCount));
      expect(
        scheduler.scheduledPlans.any((plan) => plan.taskId == nextTask.id),
        isTrue,
      );
      expect(nextTask.notificationEnabled, isTrue);
      expect(nextTask.reminderOffsetMinutes, 10);
    });
  });
}
