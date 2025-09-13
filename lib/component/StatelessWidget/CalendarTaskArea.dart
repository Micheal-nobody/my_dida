import 'package:flutter/material.dart';
import '../../model/entity/Task.dart';
import 'CalendarTimeGrid.dart';
import 'CalendarTaskWithoutTime.dart';
import 'CalendarTaskWithTime.dart';

class CalendarTaskArea extends StatelessWidget {
  final DateTime selectedDate;
  final List<DateTime> visibleDates;
  final Map<DateTime, List<Task>> tasksForDates;
  final ScrollController scrollController;

  const CalendarTaskArea({
    super.key,
    required this.selectedDate,
    required this.visibleDates,
    required this.tasksForDates,
    required this.scrollController,
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
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        // image: DecorationImage(
        //   image: AssetImage('assets/calendar_bg.png'), // 如果有背景图片
        //   fit: BoxFit.cover,
        //   opacity: 0.1,
        // ),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: SizedBox(
          height: 1440, // 24小时 * 60px = 1440px
          child: Stack(
            children: [
              // 时间网格线
              const CalendarTimeGrid(),

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

                // 分离有具体时间和没有具体时间的任务
                // 根据需求：如果startTime的Time部分全部为零，则渲染在顶部区域
                final tasksWithoutTime = dayTasks
                    .where(
                      (task) =>
                          task.startTime == null ||
                          (task.startTime!.hour == 0 &&
                              task.startTime!.minute == 0),
                    )
                    .toList();
                final tasksWithTime = dayTasks
                    .where(
                      (task) =>
                          task.startTime != null &&
                          !(task.startTime!.hour == 0 &&
                              task.startTime!.minute == 0),
                    )
                    .toList();

                return Positioned(
                  left:
                      index * dateColumnWidth +
                      60, // 60px for time column offset
                  width: dateColumnWidth,
                  child: SizedBox(
                    height: 1440,
                    child: Stack(
                      children: [
                        // 没有具体时间的任务（显示在顶部，最多6个）
                        ...tasksWithoutTime
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
                            ),

                        // 有具体时间的任务
                        ...tasksWithTime.map(
                          (task) => CalendarTaskWithTime(
                            task: task,
                            columnWidth: dateColumnWidth,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
