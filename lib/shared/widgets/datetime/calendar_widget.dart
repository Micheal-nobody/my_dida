import 'package:flutter/material.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/core/utils/time_utils.dart';
import 'package:my_dida/features/tasks/models/repeat_pattern.dart';
import 'package:my_dida/shared/widgets/datetime/calendar_grid.dart';
import 'package:my_dida/shared/widgets/datetime/custom_repeat_picker.dart';
import 'package:my_dida/shared/widgets/datetime/custom_time_picker.dart';
import 'package:my_dida/shared/widgets/datetime/repeat_picker_utils.dart';
import 'package:my_dida/shared/widgets/selection_row.dart';

class CalendarWidgetValue {
  const CalendarWidgetValue({
    required this.selectedDate,
    required this.selectedTime,
    required this.rrule,
    required this.isTimeOnlyDate,
    this.reminderOffsets = const [],
    this.notificationEnabled = false,
  });

  static const Object _sentinel = Object();

  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final RepeatPattern rrule;
  final bool isTimeOnlyDate;
  final List<int> reminderOffsets;
  final bool notificationEnabled;

  CalendarWidgetValue copyWith({
    Object? selectedDate = _sentinel,
    Object? selectedTime = _sentinel,
    Object? rrule = _sentinel,
    bool? isTimeOnlyDate,
    List<int>? reminderOffsets,
    bool? notificationEnabled,
  }) => CalendarWidgetValue(
    selectedDate: identical(selectedDate, _sentinel)
        ? this.selectedDate
        : selectedDate as DateTime?,
    selectedTime: identical(selectedTime, _sentinel)
        ? this.selectedTime
        : selectedTime as TimeOfDay?,
    rrule: identical(rrule, _sentinel) ? this.rrule : rrule as RepeatPattern,
    isTimeOnlyDate: isTimeOnlyDate ?? this.isTimeOnlyDate,
    reminderOffsets: reminderOffsets ?? this.reminderOffsets,
    notificationEnabled: notificationEnabled ?? this.notificationEnabled,
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

  String _getReminderOptionLabel(int offset) {
    if (offset == 0) return '任务开始时';
    if (offset == 5) return '提前 5 分钟';
    if (offset == 15) return '提前 15 分钟';
    if (offset == 30) return '提前 30 分钟';
    if (offset == 60) return '提前 1 小时';
    if (offset == 120) return '提前 2 小时';
    if (offset == 1440) return '提前 1 天';
    return '提前 $offset 分钟';
  }

  Future<List<int>?> _showMultiReminderDialog(
    BuildContext context,
    List<int> currentOffsets,
  ) async {
    final List<Map<String, dynamic>> options = [
      {'label': '任务开始时', 'value': 0},
      {'label': '提前 5 分钟', 'value': 5},
      {'label': '提前 15 分钟', 'value': 15},
      {'label': '提前 30 分钟', 'value': 30},
      {'label': '提前 1 小时', 'value': 60},
      {'label': '提前 2 小时', 'value': 120},
      {'label': '提前 1 天', 'value': 1440},
    ];

    final List<int> tempSelected = List.from(currentOffsets);

    final colorTheme = context.theme;

    return showDialog<List<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('提醒时间'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((opt) {
                final int val = opt['value'];
                final bool isChecked = tempSelected.contains(val);
                return CheckboxListTile(
                  title: Text(opt['label']),
                  value: isChecked,
                  activeColor: colorTheme.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (checked) {
                    setDialogState(() {
                      if (checked == true) {
                        if (!tempSelected.contains(val)) {
                          tempSelected.add(val);
                        }
                      } else {
                        tempSelected.remove(val);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                tempSelected.sort();
                Navigator.pop(context, tempSelected);
              },
              child: Text(
                '确定',
                style: TextStyle(color: colorTheme.dialogConfirm),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RepeatPattern displayRRule = _selectedRepeat != '无'
        ? mapSelectionToRepeatPattern(_selectedRepeat, _value.selectedDate)
        : const RepeatPattern.none();

    final bool isTimeSelected =
        _value.selectedTime != null && !_value.isTimeOnlyDate;
    final bool isRepeatSelected = !displayRRule.isNone;
    final bool isReminderSelected =
        _value.notificationEnabled && _value.reminderOffsets.isNotEmpty;

    final colorTheme = context.theme;

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
            dayBuilder: (context, dayDate, isSelected) {
              final now = DateTime.now().toBeijingTime();
              final isToday =
                  dayDate.year == now.year &&
                  dayDate.month == now.month &&
                  dayDate.day == now.day;
              return Container(
                height: 30,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? colorTheme.selectedColor
                      : (isToday
                            ? colorTheme.selectedColor.withValues(alpha: 0.6)
                            : Colors.transparent),
                ),
                child: Center(
                  child: Text(
                    dayDate.day.toString(),
                    style: TextStyle(
                      color: (isSelected || isToday)
                          ? colorTheme.textOnPrimary
                          : colorTheme.textPrimary,
                      fontWeight: (isSelected || isToday)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
          SelectionRow(
            icon: Icons.access_time,
            label: '时间',
            value: isTimeSelected
                ? '${_value.selectedTime!.hour.toString().padLeft(2, '0')}:${_value.selectedTime!.minute.toString().padLeft(2, '0')}'
                : '无',
            valueColor: isTimeSelected ? colorTheme.selectedColor : null,
            isSelected: isTimeSelected,
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
              final newReminderOffsets = _value.reminderOffsets.isNotEmpty
                  ? _value.reminderOffsets
                  : [0];
              _updateValue(
                _value.copyWith(
                  selectedTime: pickedTime,
                  rrule: _value.rrule,
                  isTimeOnlyDate: false,
                  reminderOffsets: newReminderOffsets,
                  notificationEnabled: true,
                ),
              );
            },
          ),
          SelectionRow(
            icon: Icons.notifications_active_outlined,
            label: '提醒',
            value: isReminderSelected
                ? _value.reminderOffsets.map(_getReminderOptionLabel).join(', ')
                : '无',
            valueColor: isReminderSelected ? colorTheme.selectedColor : null,
            isSelected: isReminderSelected,
            onTap: () async {
              final selected = await _showMultiReminderDialog(
                context,
                _value.reminderOffsets,
              );
              if (selected != null) {
                _updateValue(
                  _value.copyWith(
                    reminderOffsets: selected,
                    notificationEnabled: selected.isNotEmpty,
                  ),
                );
              }
            },
          ),
          SelectionRow(
            icon: Icons.repeat,
            label: '重复',
            value: displayRRule.toReadableString(_value.selectedDate),
            valueColor: isRepeatSelected ? colorTheme.selectedColor : null,
            isSelected: isRepeatSelected,
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
