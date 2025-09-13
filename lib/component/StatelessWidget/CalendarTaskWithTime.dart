import 'package:flutter/material.dart';
import '../../model/entity/Task.dart';

class CalendarTaskWithTime extends StatelessWidget {
  final Task task;

  const CalendarTaskWithTime({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    if (task.startTime == null) return Container();

    int startHour = task.startTime!.hour;
    int startMinute = task.startTime!.minute;

    // 计算任务开始位置（相对于顶部）
    double topPosition =
        (startHour * 60 + startMinute) * (60 / 60); // 60px per hour

    // 计算任务高度
    double taskHeight;
    if (task.endTime != null) {
      int endHour = task.endTime!.hour;
      int endMinute = task.endTime!.minute;
      taskHeight =
          ((endHour * 60 + endMinute) - (startHour * 60 + startMinute)) *
          (60 / 60);
    } else {
      // 如果没有结束时间，使用默认高度（1/4小时）
      taskHeight = 15; // 15px = 1/4 hour
    }

    return Positioned(
      top: topPosition,
      left: 8,
      right: 8,
      height: taskHeight,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          task.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
