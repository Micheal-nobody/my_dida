import 'package:flutter/material.dart';

import '../../../model/entity/Task.dart';
import '../../../provider/checklist_provider.dart';
import '../../task_detail/TaskDetailPage.dart';

class CalendarTaskWithTime extends StatelessWidget {
  const CalendarTaskWithTime({
    required this.task,
    required this.columnWidth,
    required this.hourIndex,
    required this.belongingBoxProvider,
    super.key,
  });

  final Task task;
  final double columnWidth;
  final int hourIndex;
  final ChecklistProvider belongingBoxProvider;

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
    if (task.startTime == null) {
      return Container();
    }

    // 任务宽度为列宽，高度为CalendarTimeColumn两个数字之间间隔的1/4
    final taskWidth = columnWidth;
    const taskHeightActual = 15.0; // 1/4 of 60px

    final taskColor = _getTaskColor();

    return Draggable<Task>(
      data: task,
      feedback: Opacity(
        opacity: task.isDone ? 0.4 : 1.0,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: taskWidth,
            height: taskHeightActual,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: taskColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
            ),
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
      childWhenDragging: Opacity(
        opacity: task.isDone ? 0.4 : 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: taskColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: taskColor),
          ),
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
      child: GestureDetector(
        onTap: () {
          TaskDetailPage.show(context, task);
        },
        child: Opacity(
          opacity: task.isDone ? 0.4 : 1.0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: taskColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
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
    );
  }
}
