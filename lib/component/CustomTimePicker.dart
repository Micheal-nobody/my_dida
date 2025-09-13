import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;

  const CustomTimePicker({
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              children: [
                const Text(
                  '时间',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(Icons.access_time, color: Colors.grey[400], size: 20),
              ],
            ),
            const SizedBox(height: 20),

            // Time picker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hours
                SizedBox(
                  width: 80,
                  height: 120,
                  child: ListWheelScrollView.useDelegate(
                    controller: _hourController,
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      _selectedHour = index;
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        final hour = index.toString().padLeft(2, '0');
                        final isSelected = index == _selectedHour;
                        return Center(
                          child: Text(
                            hour,
                            style: TextStyle(
                              fontSize: isSelected ? 24 : 18,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                          ),
                        );
                      },
                      childCount: 24,
                    ),
                  ),
                ),

                const Text(
                  ':',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                // Minutes
                SizedBox(
                  width: 80,
                  height: 120,
                  child: ListWheelScrollView.useDelegate(
                    controller: _minuteController,
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      _selectedMinute = index;
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        final minute = index.toString().padLeft(2, '0');
                        final isSelected = index == _selectedMinute;
                        return Center(
                          child: Text(
                            minute,
                            style: TextStyle(
                              fontSize: isSelected ? 24 : 18,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                          ),
                        );
                      },
                      childCount: 60,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '取消',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    widget.onTimeSelected(
                      TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '确定',
                    style: TextStyle(color: Colors.black87),
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
