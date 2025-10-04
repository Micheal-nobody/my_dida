import 'package:flutter/material.dart';
import 'package:my_dida/components/calendar/calendar_grid.dart';

class CustomDatePickerDialog extends StatelessWidget {
  const CustomDatePickerDialog({
    required this.onDateSelected,
    super.key,
    this.selectedDate,
  });
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  @override
  Widget build(BuildContext context) => Dialog(
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
