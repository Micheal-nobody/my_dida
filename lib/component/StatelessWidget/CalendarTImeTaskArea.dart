import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/entity/Task.dart';
import '../../provider/BelongingBoxProvider.dart';
import '../../provider/TaskProvider.dart';
import 'CalendarTaskWithTime.dart';

class CalendarTImeTaskArea extends StatefulWidget {
  final DateTime selectedDate;
  final List<DateTime> visibleDates;
  final Map<DateTime, List<Task>> tasksForDates;

  const CalendarTImeTaskArea({
    super.key,
    required this.selectedDate,
    required this.visibleDates,
    required this.tasksForDates,
  });

  @override
  State<CalendarTImeTaskArea> createState() => _CalendarTImeTaskAreaState();
}

class _CalendarTImeTaskAreaState extends State<CalendarTImeTaskArea> {
  Offset? _lastDragPosition;
  final GlobalKey _containerKey = GlobalKey();

  // 计算每个日期列的宽度 - 与CalendarDateHeader保持一致
  double _getDateColumnWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final timeColumnWidth = 60.0; // CalendarTimeColumn的宽度
    final availableWidth = screenWidth - timeColumnWidth;
    return availableWidth / widget.visibleDates.length;
  }

  // 根据拖拽位置计算时间（使用正确的坐标转换）
  DateTime _calculateTimeFromPosition(
    Offset globalPosition,
    DateTime targetDate,
  ) {
    // 获取容器的RenderBox
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return targetDate; // 如果无法获取位置，返回原日期
    }

    // 将全局坐标转换为相对于容器的本地坐标
    final localPosition = renderBox.globalToLocal(globalPosition);

    // 计算在1440px高度中的相对位置 (0-1440)
    final relativeY = localPosition.dy.clamp(0.0, 1440.0);

    // 将位置转换为分钟 (0-1440分钟 = 24小时)
    final totalMinutes = (relativeY / 1440.0 * 1440).round();

    // 计算小时和分钟
    final hour = (totalMinutes / 60).floor();
    final minute = totalMinutes % 60;

    // 舍入到最近的15分钟间隔
    final discreteMinute = ((minute / 15).round() * 15) % 60;
    final discreteHour = minute >= 45 ? (hour + 1) % 24 : hour;

    // 创建新的DateTime，保留原日期，设置新的时间
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      discreteHour.clamp(0, 23),
      discreteMinute.clamp(0, 59),
    );
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
            // 跟踪拖拽位置（使用全局坐标）
            _lastDragPosition = details.offset;
          },
          onAccept: (Task task) async {
            if (_lastDragPosition != null) {
              // 根据最后记录的拖拽位置计算目标日期和时间
              final targetDate = _calculateTargetDate(_lastDragPosition!);
              final newTime = _calculateTimeFromPosition(
                _lastDragPosition!,
                targetDate,
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
              key: _containerKey,
              height: 1440, // 固定高度：24小时 * 60px
              decoration: BoxDecoration(
                color: candidateData.isNotEmpty
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.05),
                border: candidateData.isNotEmpty
                    ? Border.all(color: Colors.orange, width: 2)
                    : null,
              ),
              child: Stack(
                children: [
                  // 15分钟间隔网格线（细线）
                  ...List.generate(96, (index) {
                    // 24小时 * 4个15分钟间隔 = 96条线
                    return Positioned(
                      top: index * 15.0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // 小时网格线（粗线）
                  ...List.generate(24, (hourIndex) {
                    return Positioned(
                      top: hourIndex * 60.0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // 多日期任务列
                  ...widget.visibleDates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final date = entry.value;
                    final normalizedDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                    );
                    final dayTasks = widget.tasksForDates[normalizedDate] ?? [];
                    final dateColumnWidth = _getDateColumnWidth(context);

                    return Positioned(
                      left: index * dateColumnWidth,
                      top: 0,
                      width: dateColumnWidth,
                      height: 1440,
                      child: Stack(
                        children: [
                          // 有具体时间的任务
                          ...dayTasks
                              .where((task) {
                                if (task.startTime == null) return false;
                                // 排除时间为00:00的任务，这些任务在CalendarNoTimeTaskArea中显示
                                if (task.startTime!.hour == 0 &&
                                    task.startTime!.minute == 0)
                                  return false;
                                return true;
                              })
                              .map((task) {
                                final hourIndex = task.startTime!.hour;
                                final minute = task.startTime!.minute;

                                // 计算任务在列中的位置
                                final topPosition =
                                    hourIndex * 60.0 + minute.toDouble();

                                return Positioned(
                                  left: 0,
                                  top: topPosition,
                                  width: dateColumnWidth,
                                  height: 15.0,
                                  child: CalendarTaskWithTime(
                                    task: task,
                                    columnWidth: dateColumnWidth,
                                    hourIndex: hourIndex,
                                    belongingBoxProvider: belongingBoxProvider,
                                  ),
                                );
                              }),
                        ],
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
