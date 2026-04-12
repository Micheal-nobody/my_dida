import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/entity/Habit.dart';
import '../../../model/entity/Task.dart';
import '../../../provider/checklist_provider.dart';
import '../../../provider/task_provider.dart';
import '../../task_detail/TaskDetailPage.dart';
import 'CalendarHabitWithoutTime.dart';
import 'CalendarTaskWithoutTime.dart';

class CalendarNoTimeTaskArea extends StatefulWidget {
  const CalendarNoTimeTaskArea({
    required this.visibleDates,
    required this.tasksForDates,
    required this.habitsForDates,
    required this.selectedDate,
    super.key,
  });
  final List<DateTime> visibleDates;
  final Map<DateTime, List<Task>> tasksForDates;
  final Map<DateTime, List<Habit>> habitsForDates;
  final DateTime selectedDate;

  @override
  State<CalendarNoTimeTaskArea> createState() => _CalendarNoTimeTaskAreaState();
}

class _CalendarNoTimeTaskAreaState extends State<CalendarNoTimeTaskArea> {
  Offset? _lastDragPosition;
  static const double _spanBarHeight = 28.0; // 与单项任务高度一致

  // 动态计算高度：基于所有可见日期的无具体时间任务、习惯和跨天任务数量
  double _calculateDynamicHeight(TaskProvider taskProvider) {
    // 统计所有可见日期的无时间任务
    final allNoTimeTasks = <Task>[];
    final allNoTimeHabits = <Habit>[];

    for (final date in widget.visibleDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final dayTasks = widget.tasksForDates[normalizedDate] ?? [];
      final dayHabits = widget.habitsForDates[normalizedDate] ?? [];

      // 统计无时间任务（包含全天任务）
      final noTimeTasks = dayTasks.where((task) {
        if (task.isAllDay) return true;
        if (task.startTime == null) return true;
        final isZeroTime =
            task.startTime!.hour == 0 && task.startTime!.minute == 0;
        return isZeroTime;
      }).toList();
      allNoTimeTasks.addAll(noTimeTasks);

      // 统计无时间习惯（remindTime为00:00的习惯）
      final noTimeHabits = dayHabits
          .where(
            (habit) =>
                habit.remindTime.hour == 0 && habit.remindTime.minute == 0,
          )
          .toList();
      allNoTimeHabits.addAll(noTimeHabits);
    }

    // 获取所有跨天任务（从TaskProvider）
    final crossDayTasks = _getAllCrossDayTasksFromAllTasks(taskProvider);

    // 总数量 = 无时间任务 + 无时间习惯 + 跨天任务
    final totalCount =
        allNoTimeTasks.length + allNoTimeHabits.length + crossDayTasks.length;

    if (totalCount == 0) return 0;

    // 仅为实际显示的数量分配高度（最多显示6个）
    final displayedCount = totalCount.clamp(0, 6);
    const itemHeight = 28.0;
    const padding = 16.0;
    final calculatedHeight = displayedCount * itemHeight + padding;
    return calculatedHeight;
  }

  // 计算每个日期列的宽度 - 与CalendarDateHeader保持一致
  double _getDateColumnWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const timeColumnWidth = 60.0; // CalendarTimeColumn的宽度
    final availableWidth = screenWidth - timeColumnWidth;
    return availableWidth / widget.visibleDates.length;
  }

  // 渲染跨天任务（从所有任务中获取）
  List<Widget> _renderCrossDayTasksFromAllTasks(TaskProvider taskProvider) {
    final crossDayTasks = _getAllCrossDayTasksFromAllTasks(taskProvider);

    return crossDayTasks.asMap().entries.map((entry) {
      final taskIndex = entry.key;
      final task = entry.value;

      return _buildCrossDayTask(task, taskIndex, context);
    }).toList();
  }

  // 计算特定日期的跨天任务数量
  int _getCrossDayTaskCountForDate(DateTime date, TaskProvider taskProvider) {
    int count = 0;
    for (final task in _getAllCrossDayTasksFromAllTasks(taskProvider)) {
      final st = task.startTime!;
      final et = task.endTime!;
      final stDate = DateTime(st.year, st.month, st.day);
      final etDate = DateTime(et.year, et.month, et.day);

      // 检查当前日期是否在任务范围内
      if (!date.isBefore(stDate) && !date.isAfter(etDate)) {
        count++;
      }
    }
    return count;
  }

  // 获取任务颜色
  Color _getTaskColor(Task task, ChecklistProvider belongingBoxProvider) {
    // Find the belonging box for this task
    final belongingBox = belongingBoxProvider.allBelongingBoxes.firstWhere(
      (box) => box.id == task.belongingBoxId,
      orElse: () => ChecklistProvider.defaultBelongingBox,
    );
    return belongingBox.color;
  }

  // 构建单个跨天任务
  Widget _buildCrossDayTask(Task task, int taskIndex, BuildContext context) {
    final st = task.startTime!;
    final et = task.endTime!;
    final stDate = DateTime(st.year, st.month, st.day);
    final etDate = DateTime(et.year, et.month, et.day);

    // 计算任务在可见日期中的范围
    final visibleDates = widget.visibleDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList();
    final startIndex = visibleDates.indexWhere((d) => !d.isBefore(stDate));
    final endIndex = visibleDates.lastIndexWhere((d) => !d.isAfter(etDate));

    if (startIndex == -1 || endIndex == -1 || endIndex < startIndex) {
      return const SizedBox.shrink();
    }

    // 计算任务的位置和大小
    const timeColumnWidth = 60.0;
    final dateColumnWidth =
        (MediaQuery.of(context).size.width - timeColumnWidth) /
        widget.visibleDates.length;
    final leftPosition = timeColumnWidth + startIndex * dateColumnWidth;
    final taskWidth = (endIndex - startIndex + 1) * dateColumnWidth;
    final topPosition = taskIndex * _spanBarHeight;

    return Consumer<ChecklistProvider>(
      builder: (context, belongingBoxProvider, child) {
        final taskColor = _getTaskColor(task, belongingBoxProvider);

        return Positioned(
          left: leftPosition,
          top: topPosition,
          width: taskWidth,
          height: _spanBarHeight,
          child: GestureDetector(
            onTap: () {
              TaskDetailPage.show(context, task);
            },
            child: Container(
              decoration: BoxDecoration(
                color: taskColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                task.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
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

  // 获取所有跨天任务（从TaskProvider获取所有任务，然后检查是否与可见日期重叠）
  List<Task> _getAllCrossDayTasksFromAllTasks(TaskProvider taskProvider) {
    final crossDayTasks = <Task>[];
    final allTasks = taskProvider.tasks;

    for (final task in allTasks) {
      if (task.startTime == null || task.endTime == null) continue;

      final st = task.startTime!;
      final et = task.endTime!;
      final sameDay =
          st.year == et.year && st.month == et.month && st.day == et.day;

      // 检查是否跨日或超过24小时
      final isCrossDay = !sameDay && et.isAfter(st);
      final duration = et.difference(st);
      final isOver24Hours = duration.inHours > 24; // 改为 > 24，排除正好24小时的任务

      if (isCrossDay || isOver24Hours) {
        // 检查任务的时间范围是否与任何可见日期重叠
        final stDate = DateTime(st.year, st.month, st.day);
        final etDate = DateTime(et.year, et.month, et.day);

        final visibleDates = widget.visibleDates
            .map((d) => DateTime(d.year, d.month, d.day))
            .toList();

        // 获取可见日期的范围
        final firstVisibleDate = visibleDates.first;
        final lastVisibleDate = visibleDates.last;

        // 检查任务是否与可见日期范围重叠
        final hasOverlap =
            !stDate.isAfter(lastVisibleDate) &&
            !etDate.isBefore(firstVisibleDate);

        if (hasOverlap && !crossDayTasks.any((t) => t.id == task.id)) {
          crossDayTasks.add(task);
        }
      }
    }

    return crossDayTasks;
  }

  @override
  Widget build(
    BuildContext context,
  ) => Consumer2<ChecklistProvider, TaskProvider>(
    builder: (context, belongingBoxProvider, taskProvider, child) =>
        DragTarget<Task>(
          onMove: (details) {
            // 跟踪拖拽位置
            _lastDragPosition = details.offset;
          },
          onAcceptWithDetails: (details) async {
            final task = details.data;
            if (_lastDragPosition != null) {
              // 根据最后记录的拖拽位置计算目标日期
              final targetDate = _calculateTargetDate(_lastDragPosition!);

              // 创建新的时间，设置为00:00（全天任务）
              final newTime = DateTime(
                targetDate.year,
                targetDate.month,
                targetDate.day,
              );

              // 更新任务的开始时间
              await taskProvider.updateStartTime(task, newTime);
            }
          },
          onWillAcceptWithDetails: (details) => true,
          builder: (context, candidateData, rejectedData) {
            final dynamicHeight = _calculateDynamicHeight(taskProvider);

            // 如果没有任务且不在拖拽状态，不显示容器
            if (dynamicHeight == 0 && candidateData.isEmpty) {
              return const SizedBox.shrink();
            }

            return AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Container(
                height: dynamicHeight, // 动态高度基于任务数量
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
                child: Stack(
                  children: [
                    // 跨天任务 - 在顶层渲染单个大任务
                    ..._renderCrossDayTasksFromAllTasks(taskProvider),

                    // 日期列容器
                    Row(
                      children: [
                        // 左侧时间列占位
                        const SizedBox(width: 60),
                        // 多日期任务列
                        ...widget.visibleDates.map((date) {
                          final normalizedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                          final dayTasks =
                              widget.tasksForDates[normalizedDate] ?? [];
                          final dateColumnWidth = _getDateColumnWidth(context);

                          // 获取没有具体时间的任务（包含全天任务）
                          final noTimeTasks = dayTasks
                              .where(
                                (task) =>
                                    task.isAllDay ||
                                    task.startTime == null ||
                                    (task.startTime!.hour == 0 &&
                                        task.startTime!.minute == 0),
                              )
                              .toList();

                          // 获取没有具体时间的习惯
                          final dayHabits =
                              widget.habitsForDates[normalizedDate] ?? [];
                          final noTimeHabits = dayHabits
                              .where(
                                (habit) =>
                                    habit.remindTime.hour == 0 &&
                                    habit.remindTime.minute == 0,
                              )
                              .toList();

                          // 跨天任务现在在顶层单独渲染，这里不再处理
                          final displayedCountForColumn =
                              (noTimeTasks.length + noTimeHabits.length).clamp(
                                0,
                                6,
                              );

                          return Expanded(
                            child: Container(
                              height: dynamicHeight,
                              padding: const EdgeInsets.symmetric(
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
                                        // 非跨天任务，需要从跨天任务下方开始计算位置
                                        ...noTimeTasks
                                            .take(6)
                                            .toList()
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                              // 计算跨天任务的数量，用于调整非跨天任务的位置
                                              final crossDayTaskCount =
                                                  _getCrossDayTaskCountForDate(
                                                    normalizedDate,
                                                    taskProvider,
                                                  );

                                              return CalendarTaskWithoutTime(
                                                task: entry.value,
                                                columnWidth:
                                                    dateColumnWidth -
                                                    8, // 减去padding
                                                taskIndex:
                                                    crossDayTaskCount +
                                                    entry.key, // 从跨天任务下方开始
                                                availableHeight:
                                                    availableHeight,
                                                belongingBoxProvider:
                                                    belongingBoxProvider,
                                                displayedCount:
                                                    displayedCountForColumn +
                                                    crossDayTaskCount, // 包含跨天任务数量
                                              );
                                            }),

                                        // 无时间习惯，需要在任务之后渲染
                                        ...noTimeHabits
                                            .take(
                                              6 - noTimeTasks.length,
                                            ) // 确保总数不超过6
                                            .toList()
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                              // 计算跨天任务和无时间任务的数量，用于调整习惯的位置
                                              final crossDayTaskCount =
                                                  _getCrossDayTaskCountForDate(
                                                    normalizedDate,
                                                    taskProvider,
                                                  );

                                              return CalendarHabitWithoutTime(
                                                habit: entry.value,
                                                columnWidth:
                                                    dateColumnWidth -
                                                    8, // 减去padding
                                                habitIndex:
                                                    crossDayTaskCount +
                                                    noTimeTasks.length +
                                                    entry
                                                        .key, // 从跨天任务和无时间任务之后开始
                                                availableHeight:
                                                    availableHeight,
                                                displayedCount:
                                                    displayedCountForColumn +
                                                    crossDayTaskCount, // 包含跨天任务数量
                                              );
                                            }),
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
                  ],
                ),
              ),
            );
          },
        ),
  );
}
