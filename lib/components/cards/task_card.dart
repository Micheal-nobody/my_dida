import 'package:flutter/material.dart';
import 'package:my_dida/components/task_detail/TaskDetailPage.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/model/vo/checklist_vo.dart';
import 'package:my_dida/utils/TimeUtils.dart';
import 'package:provider/provider.dart';

import '../../model/entity/Task.dart';
import '../../provider/checklist_provider.dart';
import '../../provider/task_provider.dart';

class TaskCard extends StatelessWidget {
  const TaskCard(this.task, {super.key});
  final Task task;

  @override
  Widget build(BuildContext context) {
    // 只需要调用方法，所以不需要监听
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final now = DateTime.now(); // 组件顶层调用一次并复用

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        // 任务完成状态
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: task.isDone,
            onChanged: (value) {
              taskProvider.updateTaskIsDone(task, value!);
            },
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
              child: Selector<ChecklistProvider, List<ChecklistVO>>(
                selector: (context, provider) => provider.allBelongingBoxes,
                builder: (context, allBoxes, child) {
                  // 安全地查找BelongingBox，如果找不到则显示默认名称
                  final belongingBox = allBoxes
                      .where((element) => element.id == task.belongingBoxId)
                      .firstOrNull;

                  return Text(
                    belongingBox?.name ?? '未知收藏夹',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  );
                },
              ),
            ),
          ],
        ),

        onTap: () {
          logger.i('点击了任务：$task');
          TaskDetailPage.show(context, task);
        },
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
