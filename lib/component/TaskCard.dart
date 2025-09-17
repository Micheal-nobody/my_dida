import 'package:flutter/material.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/model/vo/BelongingBoxVO.dart';
import 'package:my_dida/component/TaskDetailPage.dart';
import 'package:provider/provider.dart';

import '../model/entity/Task.dart';
import '../provider/BelongingBoxProvider.dart';
import '../provider/TaskProvider.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard(this.task, {super.key});

  @override
  Widget build(BuildContext context) {
    // 只需要调用方法，所以不需要监听
    TaskProvider taskProvider = Provider.of<TaskProvider>(
      context,
      listen: false,
    );

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            side: BorderSide(color: Colors.grey, width: 1),
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
                _getDateString(task.startTime),
                style: TextStyle(color: Colors.orange, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Selector<BelongingBoxProvider, List<BelongingBoxVO>>(
                selector: (context, provider) => provider.all_belongingBoxes,
                builder: (context, allBoxes, child) {
                  // 安全地查找BelongingBox，如果找不到则显示默认名称
                  final belongingBox = allBoxes
                      .where((element) => element.id == task.belongingBoxId)
                      .firstOrNull;

                  return Text(
                    belongingBox?.name ?? '未知收藏夹',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  );
                },
              ),
            ),
          ],
        ),


        onTap: () {
          logger.d('点击了任务：$task');
          TaskDetailPage.show(context, task);
        },
      ),
    );
  }

  // 辅助方法：获取日期字符串
  static String _getDateString(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (dateTime.isAtSameMomentAs(today)) {
      return '今天';
    } else if (dateTime.isAtSameMomentAs(tomorrow)) {
      return '明天';
    } else {
      return dateTime.toString().substring(0, 19);
    }
  }
}
