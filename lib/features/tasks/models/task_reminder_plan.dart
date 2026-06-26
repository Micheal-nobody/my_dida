class TaskReminderPlan {
  const TaskReminderPlan({
    required this.taskId,
    required this.triggerAt,
    required this.title,
    this.body,
    this.notificationId,
  });

  final int taskId;
  final DateTime triggerAt;
  final String title;
  final String? body;
  final int? notificationId;
}
