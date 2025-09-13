import 'package:flutter/material.dart';

class CalendarDateHeader extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final int dateRange; // 3 for 3-day view, 7 for 7-day view

  const CalendarDateHeader({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.dateRange = 7,
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
        children: dates.map((date) {
          bool isSelected = date.day == widget.selectedDate.day;
          String weekday = _getWeekdayName(date.weekday);

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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
