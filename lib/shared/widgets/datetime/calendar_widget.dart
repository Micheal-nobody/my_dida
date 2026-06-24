import 'package:flutter/material.dart';
import 'package:my_dida/features/tasks/models/repeat_pattern.dart';
import 'package:my_dida/shared/widgets/selection_row.dart';
import 'package:my_dida/core/utils/time_utils.dart';

import 'calendar_grid.dart';
import 'custom_repeat_picker.dart';
import 'custom_time_picker.dart';
import 'repeat_picker_utils.dart';

class CalendarWidgetValue {
  const CalendarWidgetValue({
    required this.selectedDate,
    required this.selectedTime,
    required this.rrule,
    required this.isTimeOnlyDate,
  });

  static const Object _sentinel = Object();

  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final RepeatPattern rrule;
  final bool isTimeOnlyDate;

  CalendarWidgetValue copyWith({
    Object? selectedDate = _sentinel,
    Object? selectedTime = _sentinel,
    Object? rrule = _sentinel,
    bool? isTimeOnlyDate,
  }) => CalendarWidgetValue(
    selectedDate: identical(selectedDate, _sentinel)
        ? this.selectedDate
        : selectedDate as DateTime?,
    selectedTime: identical(selectedTime, _sentinel)
        ? this.selectedTime
        : selectedTime as TimeOfDay?,
    rrule: identical(rrule, _sentinel) ? this.rrule : rrule as RepeatPattern,
    isTimeOnlyDate: isTimeOnlyDate ?? this.isTimeOnlyDate,
  );
}

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({
    required this.initialValue,
    required this.onChanged,
    super.key,
  });

  final CalendarWidgetValue initialValue;
  final ValueChanged<CalendarWidgetValue> onChanged;

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late CalendarWidgetValue _value;
  late String _selectedRepeat;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _selectedRepeat = rruleToSelection(_value.rrule);
  }

  @override
  void didUpdateWidget(covariant CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
      _selectedRepeat = rruleToSelection(_value.rrule);
    }
  }

  void _updateValue(CalendarWidgetValue newValue) {
    setState(() {
      _value = newValue;
    });
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final RepeatPattern displayRRule = _selectedRepeat != '无'
        ? mapSelectionToRepeatPattern(_selectedRepeat, _value.selectedDate)
        : const RepeatPattern.none();

    return SingleChildScrollView(
      child: Column(
        children: [
          CalendarGrid(
            selectedDate: _value.selectedDate,
            onDateSelected: (date) {
              _updateValue(
                _value.copyWith(selectedDate: date, rrule: _value.rrule),
              );
            },
          ),
          const SizedBox(height: 24),
          SelectionRow(
            icon: Icons.access_time,
            label: '时间',
            value: _value.selectedTime != null && !_value.isTimeOnlyDate
                ? '${_value.selectedTime!.hour.toString().padLeft(2, '0')}:${_value.selectedTime!.minute.toString().padLeft(2, '0')}'
                : '无',
            valueColor: _value.selectedTime != null && !_value.isTimeOnlyDate
                ? Colors.orange
                : null,
            onTap: () async {
              final pickedTime = await CustomTimePicker.show(
                context: context,
                initialTime:
                    _value.selectedTime ??
                    TimeOfDay.fromDateTime(DateTime.now().toBeijingTime()),
              );
              if (pickedTime == null) {
                return;
              }
              _updateValue(
                _value.copyWith(
                  selectedTime: pickedTime,
                  rrule: _value.rrule,
                  isTimeOnlyDate: false,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SelectionRow(
            icon: Icons.repeat,
            label: '重复',
            value: displayRRule.toReadableString(_value.selectedDate),
            valueColor: !displayRRule.isNone ? Colors.orange : null,
            onTap: () async {
              final repeat = await CustomRepeatPicker.show(
                context: context,
                selectedRepeat: _selectedRepeat,
                baseDate: _value.selectedDate,
              );
              if (repeat == null) {
                return;
              }
              final rrule = mapSelectionToRepeatPattern(
                repeat,
                _value.selectedDate,
              );
              setState(() {
                _selectedRepeat = repeat;
              });
              _updateValue(_value.copyWith(rrule: rrule));
            },
          ),
        ],
      ),
    );
  }
}
