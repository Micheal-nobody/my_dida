import 'package:flutter/material.dart';
import '../../model/entity/Task.dart';

class CalendarTaskWithoutTime extends StatelessWidget {
  final Task task;
  final double columnWidth;
  final int taskIndex;

  const CalendarTaskWithoutTime({
    super.key,
    required this.task,
    required this.columnWidth,
    required this.taskIndex,
  });

  @override
  Widget build(BuildContext context) {
    // 计算任务在顶部区域的位置（最多6个任务，垂直排列）
    final taskHeight = 20.0; // 任务高度
    final taskSpacing = 2.0; // 任务间距
    final topPosition = taskIndex * (taskHeight + taskSpacing);

    // 任务宽度为列宽，高度为CalendarTimeColumn两个数字之间间隔的1/4
    // CalendarTimeColumn每个时间间隔是60px，所以1/4是15px
    final taskWidth = columnWidth;
    final taskHeightActual = 15.0; // 1/4 of 60px

    return Positioned(
      top: topPosition,
      left: 0,
      width: taskWidth,
      height: taskHeightActual,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          task.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
