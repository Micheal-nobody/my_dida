import 'package:flutter/material.dart';
import '../../model/entity/Task.dart';

class CalendarTaskWithoutTime extends StatelessWidget {
  final Task task;
  final double columnWidth;
  final int taskIndex;
  final double availableHeight;

  const CalendarTaskWithoutTime({
    super.key,
    required this.task,
    required this.columnWidth,
    required this.taskIndex,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context) {
    // 动态计算任务在顶部区域的位置（最多6个任务，垂直排列）
    final taskCount = 6; // 最大任务数
    final taskSpacing = 1.0; // 任务间距
    final totalSpacing = (taskCount - 1) * taskSpacing; // 总间距
    final taskHeight = (availableHeight - totalSpacing) / taskCount; // 每个任务高度
    final topPosition = taskIndex * (taskHeight + taskSpacing);

    // 任务宽度为列宽
    final taskWidth = columnWidth;
    final taskHeightActual = taskHeight; // 使用计算出的高度

    return Positioned(
      top: topPosition,
      left: 0,
      width: taskWidth,
      height: taskHeightActual,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
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
      ),
    );
  }
}
