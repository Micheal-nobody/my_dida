import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/services/active_reminder_manager.dart';
import 'test_support/task_test_harness.dart';

void main() {
  group('ActiveReminderManager Foreground Checker Tests', () {
    late TaskTestHarness harness;
    late ActiveReminderManager reminderManager;

    setUp(() async {
      harness = await TaskTestHarness.create();
      reminderManager = getIt<ActiveReminderManager>();
    });

    tearDown(() async {
      reminderManager.stopForegroundCheck();
      await harness.dispose();
    });

    test('should ignore past reminders on startForegroundCheck', () async {
      final provider = harness.createProvider();

      // Create a task whose reminder time is in the past (e.g. 10 minutes ago)
      final startTime = DateTime.now().subtract(const Duration(minutes: 10));
      await provider.execute(
        AddTask(
          Task(
            name: 'Past Task',
            isAllDay: false,
            startTime: startTime,
            notificationEnabled: true,
            reminderOffsetMinutes: 5, // reminder was 15 minutes ago
          ),
        ),
      );

      // Start foreground check
      reminderManager.startForegroundCheck(
        checkInterval: const Duration(seconds: 5),
      );

      final emitted = <Task>[];
      final subscription = reminderManager.activeTriggers.listen(emitted.add);

      // Wait a moment for any potential timer triggers
      await Future.delayed(const Duration(milliseconds: 100));

      // Should not emit the past task
      expect(emitted, isEmpty);

      await subscription.cancel();
    });

    test(
      'should trigger reminder when triggerAt is reached (future reminder)',
      () async {
        final provider = harness.createProvider();

        // Start check first
        reminderManager.startForegroundCheck(
          checkInterval: const Duration(seconds: 5),
        );

        final emitted = <Task>[];
        final subscription = reminderManager.activeTriggers.listen(emitted.add);

        // Create a task that triggers in the future (1 second from now)
        final startTime = DateTime.now().add(const Duration(seconds: 1));
        final task =
            await provider.execute(
                  AddTask(
                    Task(
                      name: 'Future Task',
                      isAllDay: false,
                      startTime: startTime,
                      notificationEnabled: true,
                      reminderOffsetMinutes: 0,
                    ),
                  ),
                )
                as Task;

        // Wait for 6 seconds (as timer period is 5 seconds)
        await Future.delayed(const Duration(seconds: 6));

        expect(emitted, isNotEmpty);
        expect(emitted.first.id, task.id);

        await subscription.cancel();
      },
    );

    test('should support snooze reminder', () async {
      final provider = harness.createProvider();
      reminderManager.startForegroundCheck(
        checkInterval: const Duration(seconds: 5),
      );

      final emitted = <Task>[];
      final subscription = reminderManager.activeTriggers.listen(emitted.add);

      // Create task
      final startTime = DateTime.now().add(const Duration(seconds: 1));
      final task =
          await provider.execute(
                AddTask(
                  Task(
                    name: 'Snooze Task',
                    isAllDay: false,
                    startTime: startTime,
                    notificationEnabled: true,
                    reminderOffsetMinutes: 0,
                  ),
                ),
              )
              as Task;

      // Wait for trigger
      await Future.delayed(const Duration(seconds: 6));
      expect(emitted.length, 1);

      // Snooze it for 1 second
      reminderManager.snooze(task.id, const Duration(seconds: 1));

      // Wait for snooze trigger
      await Future.delayed(const Duration(seconds: 6));
      expect(emitted.length, 2);

      await subscription.cancel();
    });
  });
}
