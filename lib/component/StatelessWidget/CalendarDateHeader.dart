import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/Task.dart';

class CalendarDateHeader extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final int dateRange; // 3 for 3-day view, 7 for 7-day view
  final Map<DateTime, List<Task>> tasksForDates;

  const CalendarDateHeader({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.dateRange = 3,
    this.tasksForDates = const {},
  });

  @override
  State<CalendarDateHeader> createState() => _CalendarDateHeaderState();
}

class _CalendarDateHeaderState extends State<CalendarDateHeader> {
  @override
  Widget build(BuildContext context) {
    // 获取当前选中日期前后几天的日期
    List<DateTime> dates = [];
    int halfRange = widget.dateRange ~/ 2;
    for (int i = -halfRange; i <= halfRange; i++) {
      dates.add(widget.selectedDate.add(Duration(days: i)));
    }

    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // 预留左侧时间列的宽度
          SizedBox(width: 60), // CalendarTimeColumn的宽度
          // 日期列
          ...dates.map((date) {
            bool isSelected = date.day == widget.selectedDate.day;
            String weekday = _getWeekdayName(date.weekday);

            // Get tasks for this date (normalize date to remove time component)
            final normalizedDate = DateTime(date.year, date.month, date.day);
            final tasksForDate = widget.tasksForDates[normalizedDate] ?? [];
            final hasTasks = tasksForDate.isNotEmpty;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  widget.onDateSelected(date);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekday,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Stack(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.orange
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[800],
                              ),
                            ),
                          ),
                        ),
                        // Task indicator dot
                        if (hasTasks)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // 获取星期名称
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return '一';
      case 2:
        return '二';
      case 3:
        return '三';
      case 4:
        return '四';
      case 5:
        return '五';
      case 6:
        return '六';
      case 7:
        return '日';
      default:
        return '';
    }
  }
}
