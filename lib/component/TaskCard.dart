import 'package:flutter/material.dart';
import 'package:my_dida/model/vo/BelongingBoxVO.dart';
import 'package:provider/provider.dart';

import '../model/entity/Task.dart';
import '../provider/BelongingBoxProvider.dart';
import '../provider/TaskProvider.dart';
class TaskCard extends StatelessWidget {
  // 在 TaskCard.dart 中添加新的构建方法
  final Task task;

  const TaskCard(this.task, {super.key});

  @override
  Widget build(BuildContext context) {

    // 只需要调用方法，所以不需要监听
    TaskProvider taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        // 任务完成状态
        leading: Container(
          width: 24,
          height: 24,
          child: Checkbox(
            value: task.isDone,
            onChanged: (value) {
              // TODO: 处理任务完成状态改变
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
            Text(
              _getDateString(task.startTime),
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),

            Selector<BelongingBoxProvider, List<BelongingBoxVO>>(
              selector: (context, provider) => provider.all_belongingBoxes,
              builder: (context, all_boxes, child) {
                return Text(
                  all_boxes.firstWhere((element) => element.id == task.belongingBoxId).name,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                );
              },
            ),
          ],
        ),

        onTap: () {
          // TODO: 处理任务点击事件
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
