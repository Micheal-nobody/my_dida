import 'package:flutter/material.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/utils/time_formatter.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/services/active_reminder_manager.dart';
import 'package:provider/provider.dart';

class TaskRemindDialog extends StatelessWidget {
  const TaskRemindDialog({required this.task, super.key});

  final Task task;

  static void show(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskRemindDialog(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '任务提醒',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Task Name
          Text(
            task.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Time
          if (task.startTime != null)
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '时间: ${TimeFormatter.formatTaskDate(task.startTime, now: now)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.description, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.description,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    getIt<ActiveReminderManager>().snooze(
                      task.id,
                      const Duration(minutes: 15),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('稍后提醒'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('我知道了'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final taskProvider = Provider.of<TaskProvider>(
                      context,
                      listen: false,
                    );
                    await taskProvider.execute(UpdateTaskIsDone(task, true));
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('完成'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
