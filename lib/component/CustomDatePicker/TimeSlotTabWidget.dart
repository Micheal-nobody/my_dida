import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'CustomRepeatPicker.dart';

class TimeSlotTabWidget extends StatefulWidget {
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isAllDay;
  final Function(DateTime) onDateChanged;
  final Function(TimeOfDay?, TimeOfDay?) onTimeChanged;
  final Function(DateTime?, DateTime?)? onStartEndDateChanged;
  final Function(bool) onAllDayChanged;
  final Function(String?)? onRepeatChanged;
  final VoidCallback onSwitchToDateTab;

  const TimeSlotTabWidget({
    super.key,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onAllDayChanged,
    this.onRepeatChanged,
    required this.onSwitchToDateTab,
    this.onStartEndDateChanged,
  });

  @override
  State<TimeSlotTabWidget> createState() => _TimeSlotTabWidgetState();
}

class _TimeSlotTabWidgetState extends State<TimeSlotTabWidget> {
  String _repeatSelection = '无';
  TimeOfDay? _currentStartTime;
  TimeOfDay? _currentEndTime;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _currentStartTime = widget.startTime;
    _currentEndTime = widget.endTime;
    _startDate = widget.selectedDate;
    _endDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(TimeSlotTabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startTime != widget.startTime) {
      _currentStartTime = widget.startTime;
    }
    if (oldWidget.endTime != widget.endTime) {
      _currentEndTime = widget.endTime;
    }
    if (oldWidget.selectedDate != widget.selectedDate) {
      _startDate = widget.selectedDate;
      _endDate = widget.selectedDate;
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

  String _getDuration() {
    if (_currentStartTime != null && _currentEndTime != null) {
      final startMinutes =
          _currentStartTime!.hour * 60 + _currentStartTime!.minute;
      final endMinutes = _currentEndTime!.hour * 60 + _currentEndTime!.minute;
      final duration = endMinutes - startMinutes;
      final hours = duration ~/ 60;
      final minutes = duration % 60;

      if (hours > 0 && minutes > 0) {
        return '${hours}小时${minutes}分钟';
      } else if (hours > 0) {
        return '${hours}小时';
      } else {
        return '${minutes}分钟';
      }
    }
    return '';
  }

  Widget _buildDateTimeWheel({required bool isStart}) {
    final DateTime? currentDate = isStart ? _startDate : _endDate;
    final DateTime base = currentDate ?? widget.selectedDate ?? DateTime.now();
    final TimeOfDay? initialTime = isStart
        ? _currentStartTime
        : _currentEndTime;
    final TimeOfDay fallback = isStart
        ? const TimeOfDay(hour: 9, minute: 0)
        : const TimeOfDay(hour: 10, minute: 0);

    final DateTime initialDateTime = DateTime(
      base.year,
      base.month,
      base.day,
      (initialTime ?? fallback).hour,
      (initialTime ?? fallback).minute,
    );

    return SizedBox(
      height: 180,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.dateAndTime,
        use24hFormat: true,
        minuteInterval: 1,
        initialDateTime: initialDateTime,
        onDateTimeChanged: (dt) {
          // 1) 更新独立的日期
          final DateTime pickedDateOnly = DateTime(dt.year, dt.month, dt.day);
          if (isStart) {
            _startDate = pickedDateOnly;
          } else {
            _endDate = pickedDateOnly;
          }

          // 通知父组件日期变化
          if (widget.onStartEndDateChanged != null) {
            widget.onStartEndDateChanged!(_startDate, _endDate);
          }

          // 2) 更新时间并保持开始 < 结束
          final TimeOfDay pickedTime = TimeOfDay(
            hour: dt.hour,
            minute: dt.minute,
          );
          if (isStart) {
            TimeOfDay? end = _currentEndTime;
            if (end != null) {
              final s = pickedTime.hour * 60 + pickedTime.minute;
              final e = end.hour * 60 + end.minute;
              if (e <= s) {
                final endTotal = s + 1;
                end = TimeOfDay(
                  hour: (endTotal ~/ 60) % 24,
                  minute: endTotal % 60,
                );
              }
            }
            setState(() {
              _currentStartTime = pickedTime;
              _currentEndTime = end;
            });
            widget.onTimeChanged(pickedTime, end);
          } else {
            TimeOfDay? start = _currentStartTime;
            if (start != null) {
              final s = start.hour * 60 + start.minute;
              final e = pickedTime.hour * 60 + pickedTime.minute;
              if (e <= s) {
                final startTotal = (e - 1).clamp(0, 1439);
                start = TimeOfDay(
                  hour: (startTotal ~/ 60) % 24,
                  minute: startTotal % 60,
                );
              }
            }
            setState(() {
              _currentStartTime = start;
              _currentEndTime = pickedTime;
            });
            widget.onTimeChanged(start, pickedTime);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),

        // 开始时间（含日期）
        Row(
          children: const [
            Text('开始时间', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        _buildDateTimeWheel(isStart: true),

        const SizedBox(height: 16),

        // 结束时间（含日期）
        Row(
          children: [
            const Text('结束时间', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(_getDuration(), style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        _buildDateTimeWheel(isStart: false),

        const SizedBox(height: 20),

        // All day toggle
        Row(
          children: [
            const Text('全天'),
            const Spacer(),
            Switch(
              value: widget.isAllDay,
              onChanged: (v) {
                if (v) {
                  widget.onTimeChanged(null, null);
                }
                widget.onAllDayChanged(v);
              },
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Reminder setting
        // Row(
        //   children: [
        //     const Icon(Icons.alarm, color: Colors.grey),
        //     const Spacer(),
        //     const Text('准时 ×'),
        //   ],
        // ),
        // const SizedBox(height: 20),

        // Repeat setting
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            await showDialog(
              context: context,
              builder: (context) {
                return CustomRepeatPicker(
                  selectedRepeat: _repeatSelection,
                  baseDate: widget.selectedDate,
                  onRepeatSelected: (value) {
                    setState(() {
                      _repeatSelection = value;
                    });
                    // 通知父组件重复规则变化
                    if (widget.onRepeatChanged != null) {
                      final rrule = _mapSelectionToRRule(
                        value,
                        widget.selectedDate,
                      );
                      widget.onRepeatChanged!(rrule);
                    }
                  },
                );
              },
            );
          },
          child: Row(
            children: [
              const Icon(Icons.refresh, color: Colors.grey),
              const SizedBox(width: 12),
              const Text('重复'),
              const Spacer(),
              Text('$_repeatSelection >'),
            ],
          ),
        ),
      ],
    );
  }
}
