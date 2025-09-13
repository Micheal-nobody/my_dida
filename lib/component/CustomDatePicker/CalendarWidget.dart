import 'package:flutter/material.dart';
import 'package:my_dida/component/CustomTimePicker.dart';
import 'package:my_dida/component/SelectionRow.dart';

import 'CustomRepeatPicker.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateChanged;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _currentMonth;
  TimeOfDay? _selectedTime;
  String _selectedRepeat = '无';

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );
    final firstDayWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    return Column(
      children: [
        // Month header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(
                    _currentMonth.year,
                    _currentMonth.month - 1,
                  );
                });
              },
            ),
            Text(
              '${_currentMonth.month}月',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(
                    _currentMonth.year,
                    _currentMonth.month + 1,
                  );
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Weekday headers
        Row(
          children: ['一', '二', '三', '四', '五', '六', '日']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        ...List.generate(6, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - firstDayWeekday + 2;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }

              final dayDate = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                dayNumber,
              );
              final isSelected =
                  widget.selectedDate != null &&
                  widget.selectedDate!.year == dayDate.year &&
                  widget.selectedDate!.month == dayDate.month &&
                  widget.selectedDate!.day == dayDate.day;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onDateChanged(dayDate);
                  },
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.red : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),

        const SizedBox(height: 24),

        // Time selection section
        SelectionRow(
          icon: Icons.access_time,
          label: '时间',
          value: _selectedTime != null
              ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
              : '无',
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => CustomTimePicker(
                initialTime: _selectedTime ?? TimeOfDay.now(),
                onTimeSelected: (time) {
                  setState(() {
                    _selectedTime = time;
                  });
                },
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Repeat selection section
        SelectionRow(
          icon: Icons.repeat,
          label: '重复',
          value: _selectedRepeat,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => CustomRepeatPicker(
                selectedRepeat: _selectedRepeat,
                onRepeatSelected: (repeat) {
                  setState(() {
                    _selectedRepeat = repeat;
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
