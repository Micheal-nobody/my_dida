import 'package:flutter/material.dart';
import '../../model/entity/Task.dart';
import 'CalendarTimeGrid.dart';
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

                // 分离有具体时间和没有具体时间的任务
                final tasksWithTime = dayTasks
                    .where((task) => task.startTime != null)
                    .toList();
                final tasksWithoutTime = dayTasks
                    .where((task) => task.startTime == null)
                    .toList();

                return Positioned(
                  left:
                      index * 100.0 +
                      60, // 60px for time column, 100px per date column
                  width: 100.0,
                  child: SizedBox(
                    height: 1440,
                    child: Stack(
                      children: [
                        // 没有具体时间的任务（显示在顶部）
                        ...tasksWithoutTime.map(
                          (task) => CalendarTaskWithoutTime(task: task),
                        ),

                        // 有具体时间的任务
                        ...tasksWithTime.map(
                          (task) => CalendarTaskWithTime(task: task),
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
