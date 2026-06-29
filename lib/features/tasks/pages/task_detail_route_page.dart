import 'package:flutter/material.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/tasks/pages/task_detail_page.dart';

class TaskDetailRoutePage extends StatelessWidget {
  const TaskDetailRoutePage({required this.taskId, super.key});

  final int taskId;

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.theme;
    return Scaffold(
      backgroundColor: colorTheme.background,
      appBar: AppBar(title: const Text('任务详情')),
      body: TaskDetailPage(taskId, useSafeArea: false),
    );
  }
}
