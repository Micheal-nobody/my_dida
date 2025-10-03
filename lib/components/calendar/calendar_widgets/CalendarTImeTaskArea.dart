import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/entity/Habit.dart';
import '../../../model/entity/Task.dart';
import '../../../provider/BelongingBoxProvider.dart';
import '../../../provider/TaskProvider.dart';
import 'CalendarHabitWithTime.dart';
import 'CalendarTaskWithTime.dart';

class CalendarTImeTaskArea extends StatefulWidget {
  const CalendarTImeTaskArea({
    required this.selectedDate,
    required this.visibleDates,
    required this.tasksForDates,
    required this.habitsForDates,
    required this.rruleHasMore,
    required this.onLoadMoreRRule,
    super.key,
  });

  final DateTime selectedDate;
  final List<DateTime> visibleDates;
  final Map<DateTime, List<Task>> tasksForDates;
  final Map<DateTime, List<Habit>> habitsForDates;
  final Map<DateTime, bool> rruleHasMore;
  final void Function(DateTime date) onLoadMoreRRule;

  @override
  State<CalendarTImeTaskArea> createState() => _CalendarTImeTaskAreaState();
}

class _CalendarTImeTaskAreaState extends State<CalendarTImeTaskArea> {
  Offset? _lastDragPosition;
  final GlobalKey _containerKey = GlobalKey();

  // 计算每个日期列的宽度 - 与CalendarDateHeader保持一致
  double _getDateColumnWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const timeColumnWidth = 60.0; // CalendarTimeColumn的宽度
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
    const timeColumnWidth = 60.0;
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
  Widget build(BuildContext context) => Selector<TaskProvider, List<Task>>(
    selector: (_, taskProvider) => taskProvider.tasks,
    builder: (context, tasks, child) => DragTarget<Task>(
      onMove: (details) {
        // 跟踪拖拽位置（使用全局坐标）
        _lastDragPosition = details.offset;
      },
      onAcceptWithDetails: (details) async {
        if (_lastDragPosition != null) {
          // 根据最后记录的拖拽位置计算目标日期和时间
          final targetDate = _calculateTargetDate(_lastDragPosition!);
          final newTime = _calculateTimeFromPosition(
            _lastDragPosition!,
            targetDate,
          );

          // 更新任务的开始时间
          final taskProvider = Provider.of<TaskProvider>(
            context,
            listen: false,
          );
          await taskProvider.updateStartTime(details.data, newTime);
        }
      },
      // 允许接受任何任务
      onWillAcceptWithDetails: (details) => true,
      builder: (context, candidateData, rejectedData) => Container(
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
            // 24小时 * 4个15分钟间隔 = 96条线
            ...List.generate(
              96,
              (index) => Positioned(
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
              ),
            ),

            // 小时网格线（粗线）
            ...List.generate(
              24,
              (hourIndex) => Positioned(
                top: hourIndex * 60.0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 多日期任务列
            ...widget.visibleDates.asMap().entries.map((entry) {
              final index = entry.key;
              final date = entry.value;
              final normalizedDate = DateTime(date.year, date.month, date.day);
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
                          if (task.startTime == null) {
                            return false;
                          }
                          // 排除时间为00:00的任务，这些任务在CalendarNoTimeTaskArea中显示
                          if (task.startTime!.hour == 0 &&
                              task.startTime!.minute == 0) {
                            return false;
                          }
                          // 安全判断：如果存在结束时间，且不在同一天或结束时间不大于开始时间，则视为跨日/无效，交由无时间区域处理
                          // 或者如果任务持续时间超过24小时，也交由无时间区域处理
                          if (task.endTime != null) {
                            final st = task.startTime!;
                            final et = task.endTime!;
                            final sameDay =
                                st.year == et.year &&
                                st.month == et.month &&
                                st.day == et.day;

                            // 检查是否跨日
                            final isCrossDay = !sameDay || !et.isAfter(st);

                            // 检查是否超过24小时
                            final duration = et.difference(st);
                            final isOver24Hours = duration.inHours > 24;

                            if (isCrossDay || isOver24Hours) {
                              return false;
                            }
                          }
                          return true;
                        })
                        .map((task) {
                          final hourIndex = task.startTime!.hour;
                          final minute = task.startTime!.minute;

                          // 计算任务在列中的位置
                          final topPosition =
                              hourIndex * 60.0 + minute.toDouble();

                          // 计算高度：若同日且有结束时间，则根据持续时长（分钟）映射到像素；否则给最小高度
                          final DateTime? et = task.endTime;
                          double heightPx = 15.0;
                          if (et != null && et.isAfter(task.startTime!)) {
                            final bool sameDay =
                                task.startTime!.year == et.year &&
                                task.startTime!.month == et.month &&
                                task.startTime!.day == et.day;
                            if (sameDay) {
                              final durationMinutes = et
                                  .difference(task.startTime!)
                                  .inMinutes;
                              heightPx = durationMinutes
                                  .clamp(15, 1440)
                                  .toDouble();
                            }
                          }

                          return Positioned(
                            left: 0,
                            top: topPosition,
                            width: dateColumnWidth,
                            height: heightPx,
                            child: CalendarTaskWithTime(
                              task: task,
                              columnWidth: dateColumnWidth,
                              hourIndex: hourIndex,
                              belongingBoxProvider:
                                  Provider.of<BelongingBoxProvider>(
                                    context,
                                    listen: false,
                                  ),
                            ),
                          );
                        }),

                    // 有具体时间的习惯
                    ...(() {
                      final dayHabits =
                          widget.habitsForDates[normalizedDate] ?? [];
                      return dayHabits
                          .where(
                            (habit) =>
                                // 只渲染有具体时间的习惯（不是00:00）
                                habit.remindTime.hour != 0 ||
                                habit.remindTime.minute != 0,
                          )
                          .map((habit) {
                            final hourIndex = habit.remindTime.hour;
                            final minute = habit.remindTime.minute;

                            // 计算习惯在列中的位置
                            final topPosition =
                                hourIndex * 60.0 + minute.toDouble();

                            return Positioned(
                              left: 0,
                              top: topPosition,
                              width: dateColumnWidth,
                              height: 15.0, // 固定高度
                              child: CalendarHabitWithTime(
                                habit: habit,
                                columnWidth: dateColumnWidth,
                                hourIndex: hourIndex,
                              ),
                            );
                          });
                    })(),

                    // 加载更多重复任务按钮（固定在列底部靠下位置）
                    if (widget.rruleHasMore[normalizedDate] == true)
                      Positioned(
                        left: 6,
                        right: 6,
                        bottom: 6,
                        child: SizedBox(
                          height: 28,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              backgroundColor: Colors.orange.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(color: Colors.orange),
                              ),
                            ),
                            onPressed: () {
                              widget.onLoadMoreRRule(normalizedDate);
                            },
                            icon: const Icon(Icons.expand_more, size: 16),
                            label: const Text(
                              '加载更多',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}
