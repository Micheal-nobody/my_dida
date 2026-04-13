import 'package:flutter/material.dart';

import 'calendar_grid.dart';

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
          CalendarGrid(
            selectedDate: selectedDate,
            onDateSelected: (date) {
              onDateSelected(date);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 16),
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
