import 'package:flutter/material.dart';

class TaskScheduleTrigger extends StatelessWidget {
  const TaskScheduleTrigger({
    required this.text,
    required this.hasSelection,
    required this.onTap,
    super.key,
  });

  final String text;
  final bool hasSelection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: hasSelection ? Colors.orange : Colors.grey,
              fontWeight: hasSelection ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}
