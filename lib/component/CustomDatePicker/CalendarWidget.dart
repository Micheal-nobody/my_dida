import 'package:flutter/material.dart';
import 'package:my_dida/component/CustomDatePicker/CustomTimePicker.dart';
import 'package:my_dida/component/SelectionRow.dart';
import 'package:my_dida/component/CalendarGrid.dart';

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
  TimeOfDay? _selectedTime;
  String _selectedRepeat = '无';

  @override
  void initState() {
    super.initState();
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

    return SingleChildScrollView(
      child: Column(
        children: [
          // Calendar grid
          CalendarGrid(
            selectedDate: widget.selectedDate,
            onDateSelected: widget.onDateChanged,
          ),

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
      ),
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
