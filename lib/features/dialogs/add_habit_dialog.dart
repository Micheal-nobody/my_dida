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

class AddHabitDialog extends BaseFormDialog {
  const AddHabitDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddHabitDialog());
  }

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends BaseFormDialogState<AddHabitDialog> {
  final _nameController = TextEditingController();
  String _selectedIcon = 'star';
  late TimeOfDay _selectedTime;
  int _checkInCount = 1;

  @override
  String get dialogTitle => '创建新习惯';

  @override
  String get confirmButtonText => '创建';

  @override
  void initState() {
    super.initState();
    // 初始化为当前北京时间
    final now = DateTimeUtils.nowBeijing();
    _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
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

    final habit = Habit(
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      remindTime: DateTimeUtils.createDateTime(now, _selectedTime),
      checkInCount: _checkInCount,
      currentCheckInCount: 0,
      startDate: now,
      totalCheckInCount: 0,
      longestContinuousCheckInDays: 0,
    );

    await habitProvider.addHabit(habit);
    showSuccess('习惯"${habit.name}"创建成功！');
  }
}
