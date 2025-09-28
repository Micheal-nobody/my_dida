import 'package:flutter/material.dart';
import 'package:my_dida/component/CustomDatePicker/CustomTimePicker.dart';
import 'package:my_dida/component/SelectionRow.dart';

import '../../utils/RRuleUtil.dart';
import '../../utils/TimeUtils.dart';
import 'CustomRepeatPicker.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateChanged;
  final Function(TimeOfDay?, TimeOfDay?)? onTimeChanged;
  final Function(String?)? onRepeatChanged;
  final TimeOfDay? initialTime;
  final String? initialRRule;
  final bool isTimeOnlyDate; // 当时间部分为00:00时，是否应该显示为"无"

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.onTimeChanged,
    this.onRepeatChanged,
    this.initialTime,
    this.initialRRule,
    this.isTimeOnlyDate = false,
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
    _selectedTime = widget.initialTime;
    // Derive human selection from initial RRULE if provided
    if (widget.initialRRule != null && widget.initialRRule!.isNotEmpty) {
      _selectedRepeat = _rruleToSelection(widget.initialRRule!);
    }
  }

  @override
  void didUpdateWidget(covariant CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If initialRRule changes, re-derive selection
    if (oldWidget.initialRRule != widget.initialRRule &&
        widget.initialRRule != null &&
        widget.initialRRule!.isNotEmpty) {
      _selectedRepeat = _rruleToSelection(widget.initialRRule!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always compute display rule from current selection and base date
    final String? displayRRule = _selectedRepeat != '无'
        ? _mapSelectionToRRule(_selectedRepeat, widget.selectedDate)
        : null;
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
          value:
              _selectedTime != null &&
                  (!widget.isTimeOnlyDate &&
                      _selectedTime!.hour != 0 &&
                      _selectedTime!.minute != 0)
              ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
              : '无',
          valueColor:
              _selectedTime != null &&
                  (!widget.isTimeOnlyDate &&
                      _selectedTime!.hour != 0 &&
                      _selectedTime!.minute != 0)
              ? Colors.orange
              : null,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => CustomTimePicker(
                initialTime:
                    _selectedTime ??
                    TimeOfDay.fromDateTime(DateTime.now().toBeijingTime()),
                onTimeSelected: (time) {
                  setState(() {
                    _selectedTime = time;
                  });
                  // 调用时间变更回调
                  if (widget.onTimeChanged != null) {
                    widget.onTimeChanged!(time, null);
                  }
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
          value: RRuleUtil.humanize(displayRRule ?? ''),
          valueColor: displayRRule != null ? Colors.orange : null,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => CustomRepeatPicker(
                selectedRepeat: _selectedRepeat,
                baseDate: widget.selectedDate,
                onRepeatSelected: (repeat) {
                  setState(() {
                    _selectedRepeat = repeat;
                  });
                  if (widget.onRepeatChanged != null) {
                    final rrule = _mapSelectionToRRule(
                      repeat,
                      widget.selectedDate,
                    );
                    widget.onRepeatChanged!(rrule);
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// Map a human selection string to an iCal RRULE string using the base date
String? _mapSelectionToRRule(String selection, DateTime? baseDate) {
  if (selection == '无') return null;
  if (selection == '每天') return 'RRULE:FREQ=DAILY';
  // 每周 (周X)
  if (selection.startsWith('每周')) {
    // Workdays special case handled below
    if (selection.startsWith('每周工作日')) {
      return 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
    }
    final DateTime d = baseDate ?? DateTime.now();
    const codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    final code = codes[(d.weekday - 1).clamp(0, 6)];
    return 'RRULE:FREQ=WEEKLY;BYDAY=$code';
  }
  if (selection.startsWith('每月')) {
    final DateTime d = baseDate ?? DateTime.now();
    return 'RRULE:FREQ=MONTHLY;BYMONTHDAY=${d.day}';
  }
  if (selection.startsWith('每年')) {
    final DateTime d = baseDate ?? DateTime.now();
    return 'RRULE:FREQ=YEARLY;BYMONTH=${d.month};BYMONTHDAY=${d.day}';
  }
  if (selection.startsWith('每周工作日')) {
    return 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
  }
  // Unsupported/custom rules can be implemented later
  return null;
}

// Map a simple RRULE back to the human selection used by the picker
String _rruleToSelection(String rrule) {
  if (rrule.contains('FREQ=DAILY')) return '每天';
  if (rrule.contains('FREQ=WEEKLY') && rrule.contains('BYDAY=MO,TU,WE,TH,FR')) {
    return '每周工作日';
  }
  if (rrule.contains('FREQ=WEEKLY')) return '每周';
  if (rrule.contains('FREQ=MONTHLY')) return '每月';
  if (rrule.contains('FREQ=YEARLY')) return '每年';
  return '无';
}
