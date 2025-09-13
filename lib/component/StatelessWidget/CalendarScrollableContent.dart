import 'package:flutter/material.dart';
import 'CalendarTimeColumn.dart';
import 'CalendarTaskArea.dart';

class CalendarScrollableContent extends StatelessWidget {
  final DateTime selectedDate;

  const CalendarScrollableContent({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 4. 左侧时间列
        const CalendarTimeColumn(),

        // 5. 任务显示区域
        Expanded(child: CalendarTaskArea(selectedDate: selectedDate)),
      ],
    );
  }
}
