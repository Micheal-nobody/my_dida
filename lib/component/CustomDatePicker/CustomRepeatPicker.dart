import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomRepeatPicker extends StatefulWidget {
  final String selectedRepeat;
  final Function(String) onRepeatSelected;

  const CustomRepeatPicker({
    required this.selectedRepeat,
    required this.onRepeatSelected,
  });

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
    final repeatOptions = [
      '无',
      '每天',
      '每周 (周六)',
      '每月 (13日)',
      '每年 (9月13日)',
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
            }).toList(),

            const SizedBox(height: 20),

            // Cancel button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  widget.onRepeatSelected(_currentSelection);
                  Navigator.pop(context);
                },
                child: const Text('取消', style: TextStyle(color: Colors.orange)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
