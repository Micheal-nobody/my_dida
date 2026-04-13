import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_constants.dart';
import '../../../model/entity/Task.dart';
import '../../../provider/checklist_provider.dart';
import '../../../provider/task_provider.dart';
import '../../task_detail/task_detail_page.dart';

class FutureTasksArea extends StatefulWidget {
  const FutureTasksArea({required this.futureTasks, super.key});

  final Map<DateTime, List<Task>> futureTasks;

  @override
  State<FutureTasksArea> createState() => _FutureTasksAreaState();
}

class _FutureTasksAreaState extends State<FutureTasksArea> {
  @override
  Widget build(BuildContext context) {
    if (widget.futureTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Consumer2<ChecklistProvider, TaskProvider>(
      builder: (context, belongingBoxProvider, taskProvider, child) =>
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  '未来任务',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),

                // 未来任务列表
                ...widget.futureTasks.entries.map((entry) {
                  final date = entry.key;
                  final tasks = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 日期标题
                        Text(
                          _formatDate(date),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 任务列表
                        ...tasks.map(
                          (task) =>
                              _buildFutureTask(task, belongingBoxProvider),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
    );
  }

  Widget _buildFutureTask(Task task, ChecklistProvider belongingBoxProvider) {
    // 获取任务颜色
    final belongingBox = belongingBoxProvider.allCheckLists.firstWhere(
      (box) => box.id == task.belongingBoxId,
      orElse: () => AppConstants.defaultCheckList,
    );
    final taskColor = belongingBox.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            TaskDetailPage.show(context, task);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: taskColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: taskColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                // 任务颜色指示器
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: taskColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),

                // 任务信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      if (task.startTime != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(task.startTime!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 完成状态指示器
                if (task.isDone)
                  Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));

    if (date.isAtSameMomentAs(today)) {
      return '今天';
    } else if (date.isAtSameMomentAs(tomorrow)) {
      return '明天';
    } else if (date.isAtSameMomentAs(dayAfterTomorrow)) {
      return '后天';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
