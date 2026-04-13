import 'package:flutter/material.dart';

import 'repeat_picker_utils.dart';

class CustomRepeatPicker extends StatefulWidget {
  const CustomRepeatPicker({
    required this.selectedRepeat,
    super.key,
    this.baseDate,
  });

  static Future<String?> show({
    required BuildContext context,
    required String selectedRepeat,
    DateTime? baseDate,
  }) => showDialog<String>(
    context: context,
    builder: (context) => CustomRepeatPicker(
      selectedRepeat: selectedRepeat,
      baseDate: baseDate,
    ),
  );

  final String selectedRepeat;
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
    final repeatOptions = buildRepeatOptions(widget.baseDate);

    return Dialog(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '重复',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
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
                  if (index == 4 || index == 7)
                    const Divider(height: 1, color: Colors.grey),
                ],
              );
            }),
            const SizedBox(height: 20),
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
                    Navigator.pop(context, _currentSelection);
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
