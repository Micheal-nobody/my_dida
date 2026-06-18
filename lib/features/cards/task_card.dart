import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/utils/TimeUtils.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.checklistName,
    this.onToggleDone,
    this.onTap,
    super.key,
  });

  final Task task;
  final String checklistName;
  final void Function(bool?)? onToggleDone;
  final VoidCallback? onTap;

  // 辅助方法：获取优先级颜色
  static Color _getPriorityColor(int priority) {
    switch (priority) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final priorityColor = _getPriorityColor(task.priority);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        // 任务完成状态，复选框边框颜色与优先级一致
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: task.isDone,
            onChanged: onToggleDone,
            activeColor: Colors.blue,
            side: BorderSide(color: priorityColor, width: 2),
          ),
        ),

        // 任务名称
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: task.isDone
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
            if (task.tags.isNotEmpty)
              ...task.tags.map((tag) => Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  )),
          ],
        ),

        // 任务时间、所属收藏夹
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _getDateString(task.startTime, now: now),
                style: const TextStyle(color: Colors.orange, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                checklistName,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),

        onTap: onTap,
      ),
    );
  }

  // 辅助方法：获取日期字符串
  static String _getDateString(DateTime? dateTime, {DateTime? now}) {
    if (dateTime == null) return '';

    final currentTime = now ?? DateTime.now();
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final tomorrow = today.add(const Duration(days: 1));

    if (dateTime.isAtSameMomentAs(today)) {
      if (dateTime.hasTime()) {
        return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      return '今天';
    } else if (dateTime.isAtSameMomentAs(tomorrow)) {
      if (dateTime.hasTime()) {
        return '明天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      return '明天';
    } else {
      if (dateTime.hasTime()) {
        return '${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      return '${dateTime.month}月${dateTime.day}日';
    }
  }
}
