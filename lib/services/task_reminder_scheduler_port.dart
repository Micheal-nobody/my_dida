import 'package:my_dida/model/vo/task_reminder_plan.dart';

abstract class TaskReminderSchedulerPort {
  Future<void> schedule(TaskReminderPlan plan);

  Future<void> cancelByTaskId(int taskId);
}
