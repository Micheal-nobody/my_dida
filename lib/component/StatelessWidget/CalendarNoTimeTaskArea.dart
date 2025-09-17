import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/entity/Task.dart';
import '../../provider/BelongingBoxProvider.dart';
import '../../provider/TaskProvider.dart';
import 'CalendarTaskWithoutTime.dart';

class CalendarNoTimeTaskArea extends StatefulWidget {
  final List<DateTime> visibleDates;
  final Map<DateTime, List<Task>> tasksForDates;
  final DateTime selectedDate;

  const CalendarNoTimeTaskArea({
    super.key,
    required this.visibleDates,
    required this.tasksForDates,
    required this.selectedDate,
  });

  @override
  State<CalendarNoTimeTaskArea> createState() => _CalendarNoTimeTaskAreaState();
}

class _CalendarNoTimeTaskAreaState extends State<CalendarNoTimeTaskArea> {
  Offset? _lastDragPosition;

  // 计算每个日期列的宽度 - 与CalendarDateHeader保持一致
  double _getDateColumnWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final timeColumnWidth = 60.0; // CalendarTimeColumn的宽度
    final availableWidth = screenWidth - timeColumnWidth;
    return availableWidth / widget.visibleDates.length;
  }

  // 根据拖拽位置计算目标日期
  DateTime _calculateTargetDate(Offset position) {
    final screenWidth = MediaQuery.of(context).size.width;
    final timeColumnWidth = 60.0;
    final availableWidth = screenWidth - timeColumnWidth;
    final dateColumnWidth = availableWidth / widget.visibleDates.length;

    // 计算拖拽位置对应的日期列索引
    final relativeX = position.dx - timeColumnWidth;
    final columnIndex = (relativeX / dateColumnWidth).floor().clamp(
      0,
      widget.visibleDates.length - 1,
    );

    return widget.visibleDates[columnIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BelongingBoxProvider, TaskProvider>(
      builder: (context, belongingBoxProvider, taskProvider, child) {
        return DragTarget<Task>(
          onMove: (DragTargetDetails<Task> details) {
            // 跟踪拖拽位置
            _lastDragPosition = details.offset;
          },
          onAccept: (Task task) async {
            if (_lastDragPosition != null) {
              // 根据最后记录的拖拽位置计算目标日期
              final targetDate = _calculateTargetDate(_lastDragPosition!);

              // 创建新的时间，设置为00:00（全天任务）
              final newTime = DateTime(
                targetDate.year,
                targetDate.month,
                targetDate.day,
                0, // 小时设为0
                0, // 分钟设为0
              );

              // 更新任务的开始时间
              await taskProvider.updateStartTime(task, newTime);
            }
          },
          onWillAccept: (Task? task) {
            // 允许接受任何任务
            return task != null;
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              height: 120, // 固定高度，足够显示最多6个任务
              decoration: BoxDecoration(
                color: candidateData.isNotEmpty
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: candidateData.isNotEmpty
                        ? Colors.blue
                        : Colors.grey.withValues(alpha: 0.3),
                    width: candidateData.isNotEmpty ? 2.0 : 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 左侧时间列占位
                  SizedBox(width: 60),
                  // 多日期任务列
                  ...widget.visibleDates.map((date) {
                    final normalizedDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                    );
                    final dayTasks = widget.tasksForDates[normalizedDate] ?? [];
                    final dateColumnWidth = _getDateColumnWidth(context);

                    // 获取没有具体时间的任务
                    final noTimeTasks = dayTasks.where((task) {
                      return task.startTime == null ||
                          (task.startTime!.hour == 0 &&
                              task.startTime!.minute == 0);
                    }).toList();

                    return Expanded(
                      child: Container(
                        height: 120,
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // 动态计算可用高度
                            final availableHeight = constraints.maxHeight;
                            return ClipRect(
                              child: Stack(
                                children: [
                                  ...noTimeTasks
                                      .take(6)
                                      .toList()
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) => CalendarTaskWithoutTime(
                                          task: entry.value,
                                          columnWidth:
                                              dateColumnWidth - 8, // 减去padding
                                          taskIndex: entry.key,
                                          availableHeight: availableHeight,
                                          belongingBoxProvider:
                                              belongingBoxProvider,
                                        ),
                                      ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
