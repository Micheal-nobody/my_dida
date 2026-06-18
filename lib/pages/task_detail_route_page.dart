import 'package:flutter/material.dart';
import 'package:my_dida/features/task_detail/task_detail_page.dart';

class TaskDetailRoutePage extends StatelessWidget {
  const TaskDetailRoutePage({required this.taskId, super.key});

  final int taskId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('任务详情')),
    body: TaskDetailPage(taskId, useSafeArea: false),
  );
}
