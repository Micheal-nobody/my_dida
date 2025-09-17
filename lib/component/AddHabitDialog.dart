import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/entity/Habit.dart';
import '../provider/HabitProvider.dart';
import 'CustomDatePicker/CustomTimePicker.dart';

class AddHabitDialog extends StatefulWidget {
  const AddHabitDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddHabitDialog());
  }

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = 'star';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _checkInCount = 1;

  final List<Map<String, dynamic>> _icons = [
    {'name': 'star', 'icon': Icons.star, 'label': '星星'},
    {'name': 'brush', 'icon': Icons.brush, 'label': '刷牙'},
    {'name': 'fitness', 'icon': Icons.fitness_center, 'label': '健身'},
    {'name': 'book', 'icon': Icons.book, 'label': '阅读'},
    {'name': 'water', 'icon': Icons.water_drop, 'label': '喝水'},
    {'name': 'sleep', 'icon': Icons.bedtime, 'label': '睡觉'},
    {'name': 'food', 'icon': Icons.restaurant, 'label': '吃饭'},
    {'name': 'meditation', 'icon': Icons.self_improvement, 'label': '冥想'},
    {'name': 'walk', 'icon': Icons.directions_walk, 'label': '散步'},
    {'name': 'music', 'icon': Icons.music_note, 'label': '音乐'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建新习惯'),
      content: SizedBox(
        width: double.maxFinite,
        height:
            MediaQuery.of(context).size.height *
            0.6, // Limit height to 60% of screen
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 习惯名称
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '习惯名称',
                    hintText: '请输入习惯名称',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入习惯名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 图标选择
                const Text('选择图标', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _icons.map((iconData) {
                    final isSelected = _selectedIcon == iconData['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIcon = iconData['name'];
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          iconData['icon'],
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 提醒时间
                Row(
                  children: [
                    const Text('提醒时间: '),
                    TextButton(
                      onPressed: _selectTime,
                      child: Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 打卡次数
                Row(
                  children: [
                    const Text('每日打卡次数: '),
                    Expanded(
                      child: Slider(
                        value: _checkInCount.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _checkInCount.toString(),
                        onChanged: (value) {
                          setState(() {
                            _checkInCount = value.round();
                          });
                        },
                      ),
                    ),
                    Text(
                      _checkInCount.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(onPressed: _createHabit, child: const Text('创建')),
      ],
    );
  }

  Future<void> _selectTime() async {
    showDialog(
      context: context,
      builder: (context) => CustomTimePicker(
        initialTime: _selectedTime,
        onTimeSelected: (TimeOfDay time) {
          setState(() {
            _selectedTime = time;
          });
        },
      ),
    );
  }

  void _createHabit() {
    if (_formKey.currentState!.validate()) {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);

      final habit = Habit(
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        remindTime: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        checkInCount: _checkInCount,
        currentCheckInCount: 0,
        startDate: DateTime.now(),
        totalCheckInCount: 0,
        longestContinuousCheckInDays: 0,
      );

      habitProvider.addHabit(habit);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('习惯"${habit.name}"创建成功！')));
    }
  }
}
