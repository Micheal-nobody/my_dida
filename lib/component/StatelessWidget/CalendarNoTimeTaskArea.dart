import 'package:flutter/material.dart';
import '../../model/entity/Task.dart';
import 'CalendarTaskWithoutTime.dart';

class CalendarNoTimeTaskArea extends StatelessWidget {
  final List<DateTime> visibleDates;
  final Map<DateTime, List<Task>> tasksForDates;

  const CalendarNoTimeTaskArea({
    super.key,
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
      height: 120, // 固定高度，足够显示最多6个任务
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // 左侧时间列占位
          SizedBox(width: 60),
          // 多日期任务列
          ...visibleDates.map((date) {
            final normalizedDate = DateTime(date.year, date.month, date.day);
            final dayTasks = tasksForDates[normalizedDate] ?? [];
            final dateColumnWidth = _getDateColumnWidth(context);

            // 获取没有具体时间的任务
            final noTimeTasks = dayTasks.where((task) {
              return task.startTime == null ||
                  (task.startTime!.hour == 0 && task.startTime!.minute == 0);
            }).toList();

            return Expanded(
              child: Container(
                height: 120,
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 动态计算可用高度
                    final availableHeight = constraints.maxHeight;
                    return ClipRect(
                      child: Stack(
                        children: [
                          // 显示没有具体时间的任务（最多6个）
                          ...noTimeTasks
                              .take(6)
                              .toList()
                              .asMap()
                              .entries
                              .map(
                                (entry) => CalendarTaskWithoutTime(
                                  task: entry.value,
                                  columnWidth: dateColumnWidth - 8, // 减去padding
                                  taskIndex: entry.key,
                                  availableHeight: availableHeight,
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
  }
}
