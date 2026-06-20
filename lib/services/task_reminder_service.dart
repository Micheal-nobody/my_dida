import 'package:my_dida/config/locator.dart';
import 'package:my_dida/core/errors/exceptions.dart';
import 'package:my_dida/core/validators/task_validator.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/task_reminder_plan.dart';
import 'package:my_dida/services/task_reminder_scheduler_port.dart';

class TaskReminderService {
  TaskReminderService({TaskReminderSchedulerPort? scheduler})
    : _scheduler = scheduler ?? getIt<TaskReminderSchedulerPort>();

  final TaskReminderSchedulerPort _scheduler;

  void validateTaskReminderConfiguration({
    required bool notificationEnabled,
    required int? reminderOffsetMinutes,
    required DateTime? startTime,
    required bool isAllDay,
  }) {
    TaskValidator.validateTaskReminderConfiguration(
      notificationEnabled: notificationEnabled,
      reminderOffsetMinutes: reminderOffsetMinutes,
      startTime: startTime,
      isAllDay: isAllDay,
    );
  }

  /// 核心命令式高杠杆 API：同步任务的本地提醒状态
  Future<void> syncReminder(Task task, {DateTime? now}) async {
    final plan = _buildPlan(task, now: now);
    if (plan == null) {
      await _scheduler.cancelByTaskId(task.id);
    } else {
      await _scheduler.schedule(plan);
    }
  }

  /// 核心命令式高杠杆 API：取消指定任务的本地提醒
  Future<void> cancelReminder(int taskId) async {
    await _scheduler.cancelByTaskId(taskId);
  }

  TaskReminderPlan? _buildPlan(Task task, {DateTime? now}) {
    if (!_hasSchedulableReminder(task)) {
      return null;
    }

    try {
      validateTaskReminderConfiguration(
        notificationEnabled: task.notificationEnabled,
        reminderOffsetMinutes: task.reminderOffsetMinutes,
        startTime: task.startTime,
        isAllDay: task.isAllDay,
      );
    } on ValidationException {
      return null;
    }

    final triggerAt = task.startTime!.subtract(
      Duration(minutes: task.reminderOffsetMinutes!),
    );
    final comparisonTime = now ?? DateTime.now();
    if (!triggerAt.isAfter(comparisonTime)) {
      return null;
    }

    return TaskReminderPlan(
      taskId: task.id,
      triggerAt: triggerAt,
      title: task.name,
      body: task.description.trim().isEmpty ? null : task.description.trim(),
    );
  }

  bool _hasSchedulableReminder(Task task) =>
      task.notificationEnabled &&
      !task.isDone &&
      !task.isAllDay &&
      task.startTime != null &&
      task.reminderOffsetMinutes != null;
}
