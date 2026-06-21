class TaskReminderPlan {
  const TaskReminderPlan({
    required this.taskId,
    required this.triggerAt,
    required this.title,
    this.body,
  });

  final int taskId;
  final DateTime triggerAt;
  final String title;
  final String? body;
}
