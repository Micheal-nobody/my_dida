import 'package:flutter/material.dart';

class CustomRepeatPicker extends StatefulWidget {
  const CustomRepeatPicker({
    required this.selectedRepeat,
    required this.onRepeatSelected,
    super.key,
    this.baseDate,
  });
  final String selectedRepeat;
  final Function(String) onRepeatSelected;
  final DateTime? baseDate;

  @override
  State<CustomRepeatPicker> createState() => _CustomRepeatPickerState();
}

class _CustomRepeatPickerState extends State<CustomRepeatPicker> {
  late String _currentSelection;

  @override
  void initState() {
    super.initState();
    _currentSelection = widget.selectedRepeat;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? baseDate = widget.baseDate;

    String weekdayCn(int weekday) {
      const names = ['一', '二', '三', '四', '五', '六', '日'];
      // DateTime.weekday: Monday=1..Sunday=7
      return names[(weekday - 1).clamp(0, 6)];
    }

    String weeklyLabel() {
      if (baseDate == null) return '每周';
      return '每周 (周${weekdayCn(baseDate.weekday)})';
    }

    String monthlyLabel() {
      if (baseDate == null) return '每月';
      return '每月 (${baseDate.day}日)';
    }

    String yearlyLabel() {
      if (baseDate == null) return '每年';
      return '每年 (${baseDate.month}月${baseDate.day}日)';
    }

    // 根据当前任务的 startTime/选择的日期动态构建
    final repeatOptions = [
      '无',
      '每天',
      weeklyLabel(),
      monthlyLabel(),
      yearlyLabel(),
      '每周工作日 (周一至周五)',
      '法定工作日',
      '艾宾浩斯记忆法',
      '自定义重复',
    ];

    return Dialog(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              '重复',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Options list
            ...repeatOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = option == _currentSelection;

              return Column(
                children: [
                  ListTile(
                    title: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.orange : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.orange)
                        : null,
                    onTap: () {
                      setState(() {
                        _currentSelection = option;
                      });
                    },
                  ),
                  if (index == 4 ||
                      index == 7) // Add dividers after specific items
                    const Divider(height: 1, color: Colors.grey),
                ],
              );
            }),

            const SizedBox(height: 20),

            // Actions: Cancel & Confirm
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '取消',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    widget.onRepeatSelected(_currentSelection);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '确定',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
