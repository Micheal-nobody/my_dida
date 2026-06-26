import 'package:flutter/material.dart';
import 'package:my_dida/core/constants/icon_constants.dart';
import 'package:my_dida/core/utils/time_utils.dart';
import 'package:my_dida/core/validators/form_validators.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:my_dida/features/tasks/models/repeat_pattern.dart';
import 'package:my_dida/shared/widgets/base_form_dialog.dart';
import 'package:my_dida/shared/widgets/common_widgets.dart';
import 'package:my_dida/shared/widgets/datetime/custom_repeat_picker.dart';
import 'package:my_dida/shared/widgets/datetime/custom_time_picker.dart';
import 'package:my_dida/shared/widgets/datetime/repeat_picker_utils.dart';
import 'package:provider/provider.dart';

class EditHabitDialog extends BaseFormDialog {
  const EditHabitDialog({required this.habit, super.key});

  final Habit habit;

  static void show(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (context) => EditHabitDialog(habit: habit),
    );
  }

  @override
  State<EditHabitDialog> createState() => _EditHabitDialogState();
}

class _EditHabitDialogState extends BaseFormDialogState<EditHabitDialog> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late TimeOfDay _selectedTime;
  late int _checkInCount;
  late String _habitType;
  late String? _unit;
  late double _targetValue;
  late RepeatPattern _rrule;

  @override
  String get dialogTitle => '编辑习惯';

  @override
  String get confirmButtonText => '保存';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit.name);
    _selectedIcon = widget.habit.icon;

    // 如果 remindTime 的时间部分全为 0，则初始化为当前北京时间，否则使用 remindTime
    if (widget.habit.remindTime.hour == 0 &&
        widget.habit.remindTime.minute == 0) {
      final now = DateTimeUtils.nowBeijing();
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
    } else {
      _selectedTime = TimeOfDay.fromDateTime(widget.habit.remindTime);
    }

    _checkInCount = widget.habit.checkInCount;
    _habitType = widget.habit.habitType;
    _unit = widget.habit.unit;
    _targetValue = widget.habit.targetValue ?? 1.0;
    _rrule = widget.habit.rrule;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget buildFormContent(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // 习惯名称
      CommonWidgets.buildTextFormField(
        controller: _nameController,
        labelText: '习惯名称',
        validator: FormValidators.name,
      ),
      CommonWidgets.buildSpacing(),

      // 图标选择
      const Text('选择图标', style: TextStyle(fontSize: 16)),
      CommonWidgets.buildSpacing(height: 8),
      CommonWidgets.buildIconSelector(
        icons: IconConstants.habitIcons,
        selectedIcon: _selectedIcon,
        onIconSelected: (icon) {
          setState(() {
            _selectedIcon = icon;
          });
        },
      ),
      CommonWidgets.buildSpacing(),

      // 习惯类型
      DropdownButtonFormField<String>(
        initialValue: _habitType,
        decoration: const InputDecoration(labelText: '习惯类型'),
        items: const [
          DropdownMenuItem(value: 'yesNo', child: Text('是/否打卡')),
          DropdownMenuItem(value: 'count', child: Text('数值打卡')),
          DropdownMenuItem(value: 'duration', child: Text('时长打卡')),
        ],
        onChanged: (val) {
          if (val == null) return;
          setState(() {
            _habitType = val;
            if (_habitType == 'duration') {
              _unit = '分钟';
              _targetValue = 60.0;
            } else if (_habitType == 'yesNo') {
              _unit = null;
              _targetValue = 1.0;
            } else {
              _unit = '毫升';
              _targetValue = 2000.0;
            }
          });
        },
      ),
      CommonWidgets.buildSpacing(),

      if (_habitType == 'count') ...[
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _targetValue.toStringAsFixed(0),
                decoration: const InputDecoration(labelText: '目标数值'),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  setState(() {
                    _targetValue = double.tryParse(val) ?? 1.0;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _unit ?? '毫升',
                decoration: const InputDecoration(labelText: '单位 (如: 毫升、页)'),
                onChanged: (val) {
                  setState(() {
                    _unit = val.isEmpty ? null : val;
                  });
                },
              ),
            ),
          ],
        ),
        CommonWidgets.buildSpacing(),
      ],

      if (_habitType == 'duration') ...[
        TextFormField(
          initialValue: _targetValue.toStringAsFixed(0),
          decoration: const InputDecoration(labelText: '目标时长 (分钟)'),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            setState(() {
              _targetValue = double.tryParse(val) ?? 60.0;
            });
          },
        ),
        CommonWidgets.buildSpacing(),
      ],

      // 提醒时间
      CommonWidgets.buildTimeSelector(
        selectedTime: _selectedTime,
        onTap: _selectTime,
        label: '提醒时间',
      ),
      CommonWidgets.buildSpacing(),

      // 重复频次
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('重复频次', style: TextStyle(fontSize: 15)),
        subtitle: Text(_rrule.toReadableString(DateTime.now())),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () async {
          final selection = await CustomRepeatPicker.show(
            context: context,
            selectedRepeat: rruleToSelection(_rrule),
            baseDate: DateTime.now(),
          );
          if (selection != null) {
            setState(() {
              _rrule = mapSelectionToRepeatPattern(selection, DateTime.now());
            });
          }
        },
      ),
      CommonWidgets.buildSpacing(),

      // 打卡次数
      if (_habitType == 'yesNo')
        CommonWidgets.buildNumberSlider(
          label: '每日打卡次数',
          value: _checkInCount,
          min: 1,
          max: 10,
          onChanged: (value) {
            setState(() {
              _checkInCount = value;
            });
          },
        ),
    ],
  );

  Future<void> _selectTime() async {
    final selectedTime = await CustomTimePicker.show(
      context: context,
      initialTime: _selectedTime,
    );
    if (selectedTime == null) {
      return;
    }
    setState(() {
      _selectedTime = selectedTime;
    });
  }

  @override
  Future<void> onConfirm() async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final now = DateTime.now();

    // Create updated habit with same id
    final updatedHabit =
        Habit(
            name: _nameController.text.trim(),
            icon: _selectedIcon,
            remindTime: DateTimeUtils.createDateTime(now, _selectedTime),
            checkInCount: _habitType == 'yesNo' ? _checkInCount : 1,
            currentCheckInCount: widget.habit.currentCheckInCount,
            startDate: widget.habit.startDate,
            totalCheckInCount: widget.habit.totalCheckInCount,
            longestContinuousCheckInDays:
                widget.habit.longestContinuousCheckInDays,
            rrule: _rrule,
          )
          // Set the id to match the original habit
          ..id = widget.habit.id
          ..habitType = _habitType
          ..unit = _unit
          ..targetValue = _targetValue
          ..currentValue = widget.habit.currentValue;

    await habitProvider.updateHabit(updatedHabit);
    showSuccess('习惯"${updatedHabit.name}"更新成功！');
  }
}
