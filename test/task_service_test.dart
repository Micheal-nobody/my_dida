import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/events/event_bus.dart';
import 'package:my_dida/features/tasks/models/repeat_pattern.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/models/task_reminder_plan.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/services/task_event_listener.dart';
import 'package:my_dida/features/tasks/services/task_operation_reverter.dart';
import 'package:my_dida/features/tasks/services/task_reminder_scheduler_port.dart';
import 'package:my_dida/features/tasks/services/task_reminder_service.dart';
import 'package:my_dida/features/tasks/widgets/task_date_time_picker.dart';
import 'package:my_dida/features/tomato/events/tomato_events.dart';

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
        () => provider.execute(AddTask(Task(name: '   ', isAllDay: false))),
        throwsA(isA<Exception>()),
      );

      final parent =
          await provider.execute(AddTask(Task(name: 'Parent', isAllDay: false)))
              as Task;
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentTasks, isNotEmpty);

      final child =
          await provider.execute(
                AddTask(
                  Task(name: 'Child', isAllDay: false, parentTaskId: parent.id),
                ),
              )
              as Task;

      final reloadedParent = await harness.taskRepository.selectById(parent.id);
      expect(child.parentTaskId, parent.id);
      expect(reloadedParent?.subTaskIds, contains(child.id));
    });

    test('createTask schedules reminder when configuration is valid', () async {
      final provider = harness.createProvider();
      final startTime = DateTime.now().add(const Duration(days: 2));

      final task =
          await provider.execute(
                AddTask(
                  Task(
                    name: 'Reminder',
                    isAllDay: false,
                    startTime: startTime,
                    notificationEnabled: true,
                    reminderOffsetMinutes: 30,
                  ),
                ),
              )
              as Task;

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

      final parent =
          await provider.execute(AddTask(Task(name: 'Parent', isAllDay: false)))
              as Task;
      final child =
          await provider.execute(
                AddTask(
                  Task(name: 'Child', isAllDay: false, parentTaskId: parent.id),
                ),
              )
              as Task;

      await provider.execute(DeleteTask(child));

      final reloadedParent = await harness.taskRepository.selectById(parent.id);
      final deletedChild = await harness.taskRepository.selectById(child.id);
      expect(deletedChild, isNull);
      expect(reloadedParent?.subTaskIds, isNot(contains(child.id)));
      expect(scheduler.canceledTaskIds, contains(child.id));
    });

    test('copyTask copies nested subtasks', () async {
      final provider = harness.createProvider();

      final parent =
          await provider.execute(AddTask(Task(name: 'Parent', isAllDay: false)))
              as Task;
      await provider.execute(
        AddTask(Task(name: 'Child', isAllDay: false, parentTaskId: parent.id)),
      );

      await provider.execute(CopyTask(parent));

      final allTasks = await harness.taskRepository.selectAll();
      final copiedParent = allTasks.firstWhere(
        (task) => task.name == 'Parent (副本)',
      );
      final copiedChild = allTasks.firstWhere(
        (task) => task.name == 'Child (副本)',
      );

      expect(copiedParent.subTaskIds, contains(copiedChild.id));
      expect(copiedChild.parentTaskId, copiedParent.id);
    });

    test(
      'updateTaskReminder can disable and cancel an existing reminder',
      () async {
        final provider = harness.createProvider();
        final startTime = DateTime.now().add(const Duration(days: 2));

        final task =
            await provider.execute(
                  AddTask(
                    Task(
                      name: 'Reminder',
                      isAllDay: false,
                      startTime: startTime,
                      notificationEnabled: true,
                      reminderOffsetMinutes: 15,
                    ),
                  ),
                )
                as Task;

        await provider.execute(UpdateTaskReminder(task, enabled: false));

        final reloaded = await harness.taskRepository.selectById(task.id);
        expect(reloaded?.notificationEnabled, isFalse);
        expect(reloaded?.reminderOffsetMinutes, isNull);
        expect(scheduler.canceledTaskIds, contains(task.id));
      },
    );

    test('updateTaskReminder supports multiple reminders', () async {
      final provider = harness.createProvider();
      final startTime = DateTime.now().add(const Duration(days: 2));

      final task =
          await provider.execute(
                AddTask(
                  Task(
                    name: 'Multi-Reminder Task',
                    isAllDay: false,
                    startTime: startTime,
                    notificationEnabled: true,
                    reminderOffsets: [0, 5, 15],
                  ),
                ),
              )
              as Task;

      expect(task.notificationEnabled, isTrue);
      expect(task.reminderOffsets, [0, 5, 15]);
      expect(scheduler.scheduledPlans, hasLength(3));
      expect(scheduler.scheduledPlans[0].notificationId, task.id * 10 + 0);
      expect(scheduler.scheduledPlans[1].notificationId, task.id * 10 + 1);
      expect(scheduler.scheduledPlans[2].notificationId, task.id * 10 + 2);

      // Update task reminder with new list of offsets
      await provider.execute(
        UpdateTaskReminder(task, enabled: true, reminderOffsets: [30, 60]),
      );

      final reloaded = await harness.taskRepository.selectById(task.id);
      expect(reloaded?.notificationEnabled, isTrue);
      expect(reloaded?.reminderOffsets, [30, 60]);
      expect(scheduler.canceledTaskIds, contains(task.id));
    });

    test(
      'clearTaskSchedule clears reminder config and cancels reminder',
      () async {
        final provider = harness.createProvider();
        final startTime = DateTime.now().add(const Duration(days: 2));

        final task =
            await provider.execute(
                  AddTask(
                    Task(
                      name: 'Scheduled',
                      isAllDay: false,
                      startTime: startTime,
                      notificationEnabled: true,
                      reminderOffsetMinutes: 20,
                    ),
                  ),
                )
                as Task;

        await provider.execute(ClearTaskSchedule(task));

        final reloaded = await harness.taskRepository.selectById(task.id);
        expect(reloaded?.startTime, isNull);
        expect(reloaded?.rrule.isNone, isTrue);
        expect(reloaded?.notificationEnabled, isFalse);
        expect(reloaded?.reminderOffsetMinutes, isNull);
        expect(scheduler.canceledTaskIds, contains(task.id));
      },
    );

    test(
      'completing recurring task cancels current reminder and schedules next task',
      () async {
        final provider = harness.createProvider();
        final startTime = DateTime.now().add(const Duration(days: 2));

        final currentTask =
            await provider.execute(
                  AddTask(
                    Task(
                      name: 'Recurring',
                      isAllDay: false,
                      startTime: startTime,
                      notificationEnabled: true,
                      reminderOffsetMinutes: 10,
                      rrule: RepeatPattern.parse('FREQ=DAILY'),
                    ),
                  ),
                )
                as Task;

        final initialScheduleCount = scheduler.scheduledPlans.length;
        await provider.execute(UpdateTaskIsDone(currentTask, true));

        final allTasks = await harness.taskRepository.selectAll();
        final nextTask = allTasks
            .where((task) => task.id != currentTask.id)
            .single;

        expect(scheduler.canceledTaskIds, contains(currentTask.id));
        expect(
          scheduler.scheduledPlans.length,
          greaterThan(initialScheduleCount),
        );
        expect(
          scheduler.scheduledPlans.any((plan) => plan.taskId == nextTask.id),
          isTrue,
        );
        expect(nextTask.notificationEnabled, isTrue);
        expect(nextTask.reminderOffsetMinutes, 10);
      },
    );

    test(
      'showForTask updates and persists reminder configuration correctly',
      () async {
        final provider = harness.createProvider();
        final startTime = DateTime.now().add(const Duration(days: 2));

        final task =
            await provider.execute(
                  AddTask(
                    Task(
                      name: 'Test Picker Reminder',
                      isAllDay: false,
                      startTime: startTime,
                    ),
                  ),
                )
                as Task;

        // Simulate picker workflow by constructing a TaskTimeInfo with notification enabled
        final timeInfo = TaskTimeInfo.fromTask(task);
        timeInfo.notificationEnabled = true;
        timeInfo.reminderOffsets = [15, 30];

        // Call showForTask's database-updating part manually through provider commands as showForTask does,
        // but since showForTask has context dependencies, we test the operations it invokes:
        // UpdateTimeRange, UpdateTaskReminder, and UpdateRRule.
        await provider.execute(
          UpdateTimeRange(
            task,
            timeInfo.getFinalStartTime(),
            timeInfo.getFinalEndTime(),
            isAllDay: timeInfo.isAllDay,
          ),
        );
        await provider.execute(
          UpdateTaskReminder(
            task,
            enabled: timeInfo.notificationEnabled,
            reminderOffsets: timeInfo.reminderOffsets,
          ),
        );

        final reloaded = await harness.taskRepository.selectById(task.id);
        expect(reloaded?.notificationEnabled, isTrue);
        expect(reloaded?.reminderOffsets, [15, 30]);
        // Also verify the first offset is updated to reminderOffsetMinutes
        expect(reloaded?.reminderOffsetMinutes, 15);
      },
    );

    test('TaskOperationReverter revertAdd cancels reminder and revertDelete/revertUpdate schedules reminder', () async {
      final provider = harness.createProvider();
      final startTime = DateTime.now().add(const Duration(days: 2));

      final task = await provider.execute(
        AddTask(
          Task(
            name: 'ReverTest',
            isAllDay: false,
            startTime: startTime,
            notificationEnabled: true,
            reminderOffsetMinutes: 15,
          ),
        ),
      ) as Task;

      expect(scheduler.scheduledPlans, isNotEmpty);
      final initialScheduledLength = scheduler.scheduledPlans.length;

      // 1. 测试 revertAdd 取消提醒
      final reverter = TaskOperationReverter();
      final initialCanceledLength = scheduler.canceledTaskIds.length;
      await reverter.revertAdd(task.id);
      expect(scheduler.canceledTaskIds.length, initialCanceledLength + 1);
      expect(scheduler.canceledTaskIds.last, task.id);

      // 2. 测试 revertDelete 恢复提醒
      final taskJson = jsonEncode(task.toJson());
      await reverter.revertDelete(task.id, taskJson);
      expect(scheduler.scheduledPlans.length, initialScheduledLength + 1);
      expect(scheduler.scheduledPlans.last.taskId, task.id);

      // 3. 测试 revertUpdate 恢复/修改提醒
      final updatedTask = task.copyWith(name: 'Updated ReverTest');
      final updatedTaskJson = jsonEncode(updatedTask.toJson());
      await reverter.revertUpdate(task.id, updatedTaskJson, 'Revert update');
      expect(scheduler.scheduledPlans.length, initialScheduledLength + 2);
      expect(scheduler.scheduledPlans.last.title, 'Updated ReverTest');
    });

    test('updating task title or description syncs system reminders', () async {
      final provider = harness.createProvider();
      final startTime = DateTime.now().add(const Duration(days: 2));

      final task = await provider.execute(
        AddTask(
          Task(
            name: 'Original Title',
            description: 'Original Description',
            isAllDay: false,
            startTime: startTime,
            notificationEnabled: true,
            reminderOffsetMinutes: 15,
          ),
        ),
      ) as Task;

      expect(scheduler.scheduledPlans.last.title, 'Original Title');
      expect(scheduler.scheduledPlans.last.body, 'Original Description');

      // 1. 修改 Title，应该同步提醒
      await provider.execute(UpdateTitle(task, 'New Title'));
      expect(scheduler.scheduledPlans.last.title, 'New Title');

      // 2. 修改 Description，应该同步提醒
      await provider.execute(UpdateDescription(task, 'New Description'));
      expect(scheduler.scheduledPlans.last.body, 'New Description');
    });

    test('completing task via TomatoTaskCompletedEvent syncs reminders', () async {
      final provider = harness.createProvider();
      final startTime = DateTime.now().add(const Duration(days: 2));

      final task = await provider.execute(
        AddTask(
          Task(
            name: 'Tomato Task',
            isAllDay: false,
            startTime: startTime,
            notificationEnabled: true,
            reminderOffsetMinutes: 15,
          ),
        ),
      ) as Task;

      final initialCanceledCount = scheduler.canceledTaskIds.length;

      final eventBus = EventBus();
      final listener = TaskEventListener(
        eventBus: eventBus,
        taskRepository: harness.taskRepository,
        taskReminderService: getIt<TaskReminderService>(),
      );

      // 发送事件
      eventBus.fire(TomatoTaskCompletedEvent(taskId: task.id));

      // 等待异步处理
      await Future.delayed(const Duration(milliseconds: 50));

      expect(scheduler.canceledTaskIds.length, initialCanceledCount + 1);
      expect(scheduler.canceledTaskIds.last, task.id);

      final reloaded = await harness.taskRepository.selectById(task.id);
      expect(reloaded?.isDone, isTrue);

      listener.dispose();
    });
  });
}
