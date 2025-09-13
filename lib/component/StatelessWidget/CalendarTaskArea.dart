import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/TaskProvider.dart';
import '../../model/entity/Task.dart';
import 'CalendarTimeGrid.dart';
import 'CalendarTaskWithoutTime.dart';
import 'CalendarTaskWithTime.dart';

class CalendarTaskArea extends StatelessWidget {
  final DateTime selectedDate;

  const CalendarTaskArea({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        List<Task> tasks = taskProvider.cur_tasks;

        // 筛选出选中日期的任务
        List<Task> dayTasks = tasks.where((task) {
          // 如果有开始时间，检查是否匹配选中日期
          if (task.startTime != null) {
            return task.startTime!.year == selectedDate.year &&
                task.startTime!.month == selectedDate.month &&
                task.startTime!.day == selectedDate.day;
          }
          // 如果没有开始时间，暂时不显示（可以根据需要调整逻辑）
          return false;
        }).toList();

        // 分离有具体时间和没有具体时间的任务
        List<Task> tasksWithTime = dayTasks
            .where((task) => task.startTime != null)
            .toList();
        List<Task> tasksWithoutTime = dayTasks
            .where((task) => task.startTime == null)
            .toList();

        return Container(
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.05),
            image: DecorationImage(
              image: AssetImage('assets/calendar_bg.png'), // 如果有背景图片
              fit: BoxFit.cover,
              opacity: 0.1,
            ),
          ),
          child: SingleChildScrollView(
            child: SizedBox(
              height: 1440, // 24小时 * 60px = 1440px
              child: Stack(
                children: [
                  // 时间网格线
                  const CalendarTimeGrid(),

                  // 没有具体时间的任务（显示在顶部）
                  ...tasksWithoutTime.map(
                    (task) => CalendarTaskWithoutTime(task: task),
                  ),

                  // 有具体时间的任务
                  ...tasksWithTime.map(
                    (task) => CalendarTaskWithTime(task: task),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
