import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/features/tasks/models/task_reminder_plan.dart';

import 'package:my_dida/features/tasks/services/notification_service.dart';
import 'task_reminder_scheduler_port.dart';

class FlutterLocalTaskReminderScheduler implements TaskReminderSchedulerPort {
  FlutterLocalTaskReminderScheduler({NotificationService? notificationService})
    : _notificationService =
          notificationService ?? getIt<NotificationService>();

  final NotificationService _notificationService;

  @override
  Future<void> schedule(TaskReminderPlan plan) async {
    final canNotify = await _notificationService.ensureNotificationPermission();
    if (!canNotify) {
      return;
    }

    final scheduleMode = await _notificationService.resolveScheduleMode();
    await _notificationService.plugin.zonedSchedule(
      plan.taskId,
      plan.title,
      plan.body,
      _notificationService.toTzDateTime(plan.triggerAt),
      _notificationService.buildTaskReminderNotificationDetails(),
      androidScheduleMode: scheduleMode,
      payload: plan.taskId.toString(),
    );
  }

  @override
  Future<void> cancelByTaskId(int taskId) =>
      _notificationService.plugin.cancel(taskId);
}
