import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/errors/exceptions.dart';
import 'package:my_dida/core/utils/markdown_utils.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/models/task_reminder_plan.dart';
import 'package:my_dida/features/tasks/services/task_reminder_scheduler_port.dart';
import 'package:my_dida/features/tasks/validators/task_validator.dart';

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
    await _scheduler.cancelByTaskId(task.id);
    if (!task.notificationEnabled || task.isDone || task.isAllDay || task.startTime == null) {
      return;
    }

    final plans = _buildPlans(task, now: now);
    for (final plan in plans) {
      await _scheduler.schedule(plan);
    }
  }

  /// 核心命令式高杠杆 API：取消指定任务的本地提醒
  Future<void> cancelReminder(int taskId) async {
    await _scheduler.cancelByTaskId(taskId);
  }

  List<TaskReminderPlan> _buildPlans(Task task, {DateTime? now}) {
    final List<TaskReminderPlan> plans = [];
    final comparisonTime = now ?? DateTime.now();

    final offsets = task.reminderOffsets.isNotEmpty
        ? task.reminderOffsets
        : (task.reminderOffsetMinutes != null ? [task.reminderOffsetMinutes!] : <int>[]);

    for (int i = 0; i < offsets.length; i++) {
      final offset = offsets[i];
      try {
        validateTaskReminderConfiguration(
          notificationEnabled: task.notificationEnabled,
          reminderOffsetMinutes: offset,
          startTime: task.startTime,
          isAllDay: task.isAllDay,
        );
      } on ValidationException {
        continue;
      }

      final triggerAt = task.startTime!.subtract(
        Duration(minutes: offset),
      );
      if (!triggerAt.isAfter(comparisonTime)) {
        continue;
      }

      // 通知栏无法渲染 Markdown，剥离标记后降级展示纯文本
      final plainBody = MarkdownUtils.stripMarkdown(task.description).trim();
      plans.add(TaskReminderPlan(
        taskId: task.id,
        triggerAt: triggerAt,
        title: task.name,
        body: plainBody.isEmpty ? null : plainBody,
        notificationId: task.id * 10 + i,
      ));
    }
    return plans;
  }
}
