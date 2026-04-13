import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'custom_repeat_picker.dart';
import 'repeat_picker_utils.dart';

class TimeSlotTabValue {
  static const Object _sentinel = Object();

  const TimeSlotTabValue({
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.startDate,
    required this.endDate,
    required this.isAllDay,
    required this.rrule,
  });

  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isAllDay;
  final String? rrule;

  TimeSlotTabValue copyWith({
    Object? selectedDate = _sentinel,
    Object? startTime = _sentinel,
    Object? endTime = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
    bool? isAllDay,
    Object? rrule = _sentinel,
  }) => TimeSlotTabValue(
    selectedDate: identical(selectedDate, _sentinel)
        ? this.selectedDate
        : selectedDate as DateTime?,
    startTime: identical(startTime, _sentinel)
        ? this.startTime
        : startTime as TimeOfDay?,
    endTime: identical(endTime, _sentinel)
        ? this.endTime
        : endTime as TimeOfDay?,
    startDate: identical(startDate, _sentinel)
        ? this.startDate
        : startDate as DateTime?,
    endDate: identical(endDate, _sentinel)
        ? this.endDate
        : endDate as DateTime?,
    isAllDay: isAllDay ?? this.isAllDay,
    rrule: identical(rrule, _sentinel) ? this.rrule : rrule as String?,
  );
}

class TimeSlotTabWidget extends StatefulWidget {
  const TimeSlotTabWidget({
    required this.initialValue,
    required this.onChanged,
    super.key,
  });

  final TimeSlotTabValue initialValue;
  final ValueChanged<TimeSlotTabValue> onChanged;

  @override
  State<TimeSlotTabWidget> createState() => _TimeSlotTabWidgetState();
}

class _TimeSlotTabWidgetState extends State<TimeSlotTabWidget> {
  late TimeSlotTabValue _value;
  late String _repeatSelection;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _repeatSelection = rruleToSelection(_value.rrule);
  }

  @override
  void didUpdateWidget(TimeSlotTabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
      _repeatSelection = rruleToSelection(_value.rrule);
    }
  }

  void _updateValue(TimeSlotTabValue newValue) {
    setState(() {
      _value = newValue;
    });
    widget.onChanged(newValue);
  }

  String _getDuration() {
    if (_value.startTime != null &&
        _value.endTime != null &&
        _value.startDate != null &&
        _value.endDate != null) {
      final startDateTime = DateTime(
        _value.startDate!.year,
        _value.startDate!.month,
        _value.startDate!.day,
        _value.startTime!.hour,
        _value.startTime!.minute,
      );

      final endDateTime = DateTime(
        _value.endDate!.year,
        _value.endDate!.month,
        _value.endDate!.day,
        _value.endTime!.hour,
        _value.endTime!.minute,
      );

      final duration = endDateTime.difference(startDateTime);
      if (duration.isNegative) {
        return '时间无效';
      }

      final days = duration.inDays;
      final hours = duration.inHours % 24;
      final minutes = duration.inMinutes % 60;

      final List<String> parts = [];
      if (days > 0) parts.add('$days天');
      if (hours > 0) parts.add('$hours小时');
      if (minutes > 0) parts.add('$minutes分钟');
      if (parts.isEmpty) return '0分钟';
      return parts.join();
    }
    return '';
  }

  Widget _buildDateTimeWheel({required bool isStart}) {
    final DateTime? currentDate = isStart ? _value.startDate : _value.endDate;
    final DateTime base = currentDate ?? _value.selectedDate ?? DateTime.now();
    final TimeOfDay? initialTime = isStart ? _value.startTime : _value.endTime;
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
        use24hFormat: true,
        initialDateTime: initialDateTime,
        onDateTimeChanged: (dt) {
          final DateTime pickedDateOnly = DateTime(dt.year, dt.month, dt.day);
          DateTime? startDate = _value.startDate;
          DateTime? endDate = _value.endDate;
          if (isStart) {
            startDate = pickedDateOnly;
          } else {
            endDate = pickedDateOnly;
          }

          final TimeOfDay pickedTime = TimeOfDay(
            hour: dt.hour,
            minute: dt.minute,
          );
          TimeOfDay? start = _value.startTime;
          TimeOfDay? end = _value.endTime;

          if (isStart) {
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
            start = pickedTime;
          } else {
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
            end = pickedTime;
          }

          _updateValue(
            _value.copyWith(
              startDate: startDate,
              endDate: endDate,
              startTime: start,
              endTime: end,
              rrule: _value.rrule,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 20),
      const Row(
        children: [Text('开始时间', style: TextStyle(fontWeight: FontWeight.bold))],
      ),
      const SizedBox(height: 8),
      _buildDateTimeWheel(isStart: true),
      const SizedBox(height: 16),
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
      Row(
        children: [
          const Text('全天'),
          const Spacer(),
          Switch(
            value: _value.isAllDay,
            onChanged: (v) {
              _updateValue(
                _value.copyWith(
                  isAllDay: v,
                  startTime: v ? null : _value.startTime,
                  endTime: v ? null : _value.endTime,
                  rrule: _value.rrule,
                ),
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 20),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final repeat = await CustomRepeatPicker.show(
            context: context,
            selectedRepeat: _repeatSelection,
            baseDate: _value.selectedDate,
          );
          if (repeat == null) {
            return;
          }
          final rrule = mapSelectionToRRule(repeat, _value.selectedDate);
          setState(() {
            _repeatSelection = repeat;
          });
          _updateValue(_value.copyWith(rrule: rrule));
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
