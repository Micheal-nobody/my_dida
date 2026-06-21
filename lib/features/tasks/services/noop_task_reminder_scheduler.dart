import 'package:my_dida/core/logger/logger.dart';
import 'package:my_dida/features/tasks/models/task_reminder_plan.dart';

import 'task_reminder_scheduler_port.dart';

class NoopTaskReminderScheduler implements TaskReminderSchedulerPort {
  @override
  Future<void> cancelByTaskId(int taskId) async {
    logger.d('NoopTaskReminderScheduler.cancelByTaskId: $taskId');
  }

  @override
  Future<void> schedule(TaskReminderPlan plan) async {
    logger.d(
      'NoopTaskReminderScheduler.schedule: taskId=${plan.taskId}, triggerAt=${plan.triggerAt.toIso8601String()}',
    );
  }
}
