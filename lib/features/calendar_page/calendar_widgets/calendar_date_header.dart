import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/task.dart';

class CalendarDateHeader extends StatefulWidget {
  const CalendarDateHeader({
    required this.selectedDate,
    required this.onDateSelected,
    required this.dateRange,
    super.key,
    this.tasksForDates = const {},
  });

  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final int dateRange; // 3 for 3-day view, 7 for 7-day view
  final Map<DateTime, List<Task>> tasksForDates;

  @override
  State<CalendarDateHeader> createState() => _CalendarDateHeaderState();
}

class _CalendarDateHeaderState extends State<CalendarDateHeader> {
  @override
  Widget build(BuildContext context) {
    // 构建日期序列：当前选中 -> 选中+1 -> ... -> 选中+(dateRange-1)
    final List<DateTime> dates = [];
    for (int i = 0; i < widget.dateRange; i++) {
      dates.add(widget.selectedDate.add(Duration(days: i)));
    }
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // 左侧时间列区域（包含昨天按钮和时间列）
          SizedBox(
            width: 60, // CalendarTimeColumn的宽度
            child: Column(
              children: [
                // 昨天按钮 - 与日期列样式保持一致，位于CalendarTimeColumn正上方
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final yesterday = widget.selectedDate.subtract(
                        const Duration(days: 1),
                      );
                      widget.onDateSelected(yesterday);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getWeekdayName(
                            widget.selectedDate
                                .subtract(const Duration(days: 1))
                                .weekday,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${widget.selectedDate.subtract(const Duration(days: 1)).day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 时间列占位
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 日期列
          ...dates.map((date) {
            final bool isSelected = _isSameDay(date, widget.selectedDate);
            final String weekday = _getWeekdayName(date.weekday);

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
                    const SizedBox(height: 4),
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
                              decoration: const BoxDecoration(
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
          }),
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
