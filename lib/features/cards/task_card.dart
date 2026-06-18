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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        // 任务完成状态
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: task.isDone,
            onChanged: onToggleDone,
            activeColor: Colors.blue,
            side: const BorderSide(color: Colors.grey),
          ),
        ),

        // 任务名称
        title: Text(
          task.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task.isDone
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
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
