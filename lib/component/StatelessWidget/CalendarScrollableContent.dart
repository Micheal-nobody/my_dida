import 'package:flutter/material.dart';
import 'CalendarTimeColumn.dart';
import 'CalendarTaskArea.dart';
import '../../model/entity/Task.dart';

class CalendarScrollableContent extends StatelessWidget {
  final DateTime selectedDate;
  final List<DateTime> visibleDates;
  final Map<DateTime, List<Task>> tasksForDates;

  const CalendarScrollableContent({
    super.key,
    required this.selectedDate,
    required this.visibleDates,
    required this.tasksForDates,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 4. 左侧时间列
        const CalendarTimeColumn(),

        // 5. 任务显示区域
        Expanded(
          child: CalendarTaskArea(
            selectedDate: selectedDate,
            visibleDates: visibleDates,
            tasksForDates: tasksForDates,
          ),
        ),
      ],
    );
  }
}
