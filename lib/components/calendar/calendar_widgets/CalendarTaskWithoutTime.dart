import 'package:flutter/material.dart';

import '../../../model/entity/Task.dart';
import '../../../provider/checklist_provider.dart';
import '../../task_detail/TaskDetailPage.dart';

class CalendarTaskWithoutTime extends StatelessWidget {
  const CalendarTaskWithoutTime({
    required this.task,
    required this.columnWidth,
    required this.taskIndex,
    required this.availableHeight,
    required this.belongingBoxProvider,
    required this.displayedCount,
    super.key,
  });

  final Task task;
  final double columnWidth;
  final int taskIndex;
  final double availableHeight;
  final ChecklistProvider belongingBoxProvider;
  final int displayedCount;

  Color _getTaskColor() {
    // Find the belonging box for this task
    final belongingBox = belongingBoxProvider.allBelongingBoxes.firstWhere(
      (box) => box.id == task.belongingBoxId,
      orElse: () => ChecklistProvider.defaultBelongingBox,
    );
    return belongingBox.color;
  }

  @override
  Widget build(BuildContext context) {
    // 动态计算任务在顶部区域的位置（基于实际显示数量，最多6个）
    final taskCount = displayedCount.clamp(1, 6);
    const taskSpacing = 1.0; // 任务间距
    final totalSpacing = (taskCount - 1) * taskSpacing; // 总间距
    final taskHeight = (availableHeight - totalSpacing) / taskCount; // 每个任务高度
    final topPosition = taskIndex * (taskHeight + taskSpacing);

    // 任务宽度为列宽
    final taskWidth = columnWidth;
    final taskHeightActual = taskHeight; // 使用计算出的高度

    final taskColor = _getTaskColor();

    return Positioned(
      top: topPosition,
      left: 0,
      width: taskWidth,
      height: taskHeightActual,
      child: Draggable<Task>(
        data: task,
        feedback: Opacity(
          opacity: task.isDone ? 0.4 : 1.0,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: taskWidth,
              height: taskHeightActual,
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: taskColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  task.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: task.isDone ? 0.4 : 1.0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: taskColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: taskColor),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                task.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ),
        child: GestureDetector(
          onTap: () {
            TaskDetailPage.show(context, task);
          },
          child: Opacity(
            opacity: task.isDone ? 0.4 : 1.0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: taskColor.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  task.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
