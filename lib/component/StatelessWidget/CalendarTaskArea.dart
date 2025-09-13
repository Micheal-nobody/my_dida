import 'package:flutter/material.dart';
import '../../model/entity/Task.dart';
import 'CalendarTaskWithoutTime.dart';
import 'CalendarTaskWithTime.dart';

class CalendarTaskArea extends StatelessWidget {
  final DateTime selectedDate;
  final List<DateTime> visibleDates;
  final Map<DateTime, List<Task>> tasksForDates;

  const CalendarTaskArea({
    super.key,
    required this.selectedDate,
    required this.visibleDates,
    required this.tasksForDates,
  });

  // 计算每个日期列的宽度 - 与CalendarDateHeader保持一致
  double _getDateColumnWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final timeColumnWidth = 60.0; // CalendarTimeColumn的宽度
    final availableWidth = screenWidth - timeColumnWidth;
    return availableWidth / visibleDates.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1440, // 固定高度：24小时 * 60px
      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.05)),
      child: Column(
        children: List.generate(24, (hourIndex) {
          return SizedBox(
            height: 60, // 每小时60px
            child: Stack(
              children: [
                // 时间网格线
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),

                // 多日期任务列
                ...visibleDates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final date = entry.value;
                  final normalizedDate = DateTime(
                    date.year,
                    date.month,
                    date.day,
                  );
                  final dayTasks = tasksForDates[normalizedDate] ?? [];
                  final dateColumnWidth = _getDateColumnWidth(context);

                  // 获取当前小时的任务
                  List<Task> currentHourTasks = [];

                  if (hourIndex == 0) {
                    // 在第一个小时行显示没有具体时间的任务
                    currentHourTasks = dayTasks.where((task) {
                      return task.startTime == null ||
                          (task.startTime!.hour == 0 &&
                              task.startTime!.minute == 0);
                    }).toList();
                  } else {
                    // 其他小时显示有具体时间的任务
                    currentHourTasks = dayTasks.where((task) {
                      if (task.startTime == null) return false;
                      return task.startTime!.hour == hourIndex;
                    }).toList();
                  }

                  return Positioned(
                    left: index * dateColumnWidth,
                    width: dateColumnWidth,
                    child: SizedBox(
                      height: 60,
                      child: Stack(
                        children: [
                          // 当前小时的任务
                          if (hourIndex == 0)
                            // 没有具体时间的任务（显示在顶部，最多6个）
                            ...currentHourTasks
                                .take(6)
                                .toList()
                                .asMap()
                                .entries
                                .map(
                                  (entry) => CalendarTaskWithoutTime(
                                    task: entry.value,
                                    columnWidth: dateColumnWidth,
                                    taskIndex: entry.key,
                                  ),
                                )
                          else
                            // 有具体时间的任务
                            ...currentHourTasks.map(
                              (task) => CalendarTaskWithTime(
                                task: task,
                                columnWidth: dateColumnWidth,
                                hourIndex: hourIndex,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }),
      ),
    );
  }
}
