import 'package:flutter/material.dart';
import 'package:my_dida/component/CalendarGrid.dart';

class CustomDatePickerDialog extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const CustomDatePickerDialog({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Calendar grid
            CalendarGrid(
              selectedDate: selectedDate,
              onDateSelected: (date) {
                onDateSelected(date);
                Navigator.of(context).pop();
              },
            ),

            const SizedBox(height: 16),

            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }
}
