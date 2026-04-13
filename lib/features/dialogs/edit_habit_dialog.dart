import 'package:flutter/material.dart';
import 'package:my_dida/utils/TimeUtils.dart';
import 'package:provider/provider.dart';

import '../../constants/icon_constants.dart';
import '../../core/validators/form_validators.dart';
import '../../model/entity/Habit.dart';
import '../../provider/habit_provider.dart';
import '../../shared/common/base_form_dialog.dart';
import '../../shared/common/common_widgets.dart';
import '../../shared/widgets/datetime/custom_time_picker.dart';

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

      // 提醒时间
      CommonWidgets.buildTimeSelector(
        selectedTime: _selectedTime,
        onTap: _selectTime,
        label: '提醒时间',
      ),
      CommonWidgets.buildSpacing(),

      // 打卡次数
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
    final updatedHabit = Habit(
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      remindTime: DateTimeUtils.createDateTime(now, _selectedTime),
      checkInCount: _checkInCount,
      currentCheckInCount: widget.habit.currentCheckInCount,
      startDate: widget.habit.startDate,
      totalCheckInCount: widget.habit.totalCheckInCount,
      longestContinuousCheckInDays: widget.habit.longestContinuousCheckInDays,
    )

    // Set the id to match the original habit
    ..id = widget.habit.id;

    await habitProvider.updateHabit(updatedHabit);
    showSuccess('习惯"${updatedHabit.name}"更新成功！');
  }
}
