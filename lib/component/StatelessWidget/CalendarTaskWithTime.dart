import 'package:flutter/material.dart';
import '../../model/entity/Task.dart';

class CalendarTaskWithTime extends StatelessWidget {
  final Task task;
  final double columnWidth;
  final int hourIndex;

  const CalendarTaskWithTime({
    super.key,
    required this.task,
    required this.columnWidth,
    required this.hourIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (task.startTime == null) return Container();

    int startMinute = task.startTime!.minute;

    // 计算任务在当前小时行中的垂直位置（基于分钟）
    // 每小时60px，每分钟1px
    double topPosition = startMinute.toDouble();

    // 任务宽度为列宽，高度为CalendarTimeColumn两个数字之间间隔的1/4
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
