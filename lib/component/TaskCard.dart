import 'package:flutter/material.dart';
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
            Text(
              _getDateString(task.startTime),
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),

            Selector<BelongingBoxProvider, List<BelongingBoxVO>>(
              selector: (context, provider) => provider.all_belongingBoxes,
              builder: (context, allBoxes, child) {
                return Text(
                  allBoxes
                      .firstWhere(
                        (element) => element.id == task.belongingBoxId,
                      )
                      .name,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                );
              },
            ),
          ],
        ),

        onTap: () {
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (BuildContext context) {
              return DraggableScrollableSheet(
                expand: false,
                // 仅两种可见状态：默认 0.6 和 全屏 1.0
                initialChildSize: 0.6,
                minChildSize: 0.6,
                maxChildSize: 1.0,
                snap: true, // snap 开启后，snapSizes 设置可切换状态
                snapSizes: const [0.6, 1.0],
                builder: (context, scrollController) {
                  final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.only(bottom: bottomInset),
                      child: MediaQuery.removeViewInsets(
                        removeBottom: true,
                        context: context,
                        child: TaskDetailPage(
                          task.id,
                          scrollController: scrollController,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
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
