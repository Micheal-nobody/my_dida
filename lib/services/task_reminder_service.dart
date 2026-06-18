import 'package:my_dida/core/errors/exceptions.dart';
import 'package:my_dida/core/validators/task_validator.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/task_reminder_plan.dart';

class TaskReminderService {
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

  TaskReminderPlan? buildPlan(Task task, {DateTime? now}) {
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

  bool shouldCancel(Task task, {DateTime? now}) =>
      buildPlan(task, now: now) == null;

  bool _hasSchedulableReminder(Task task) =>
      task.notificationEnabled &&
      !task.isDone &&
      !task.isAllDay &&
      task.startTime != null &&
      task.reminderOffsetMinutes != null;
}
