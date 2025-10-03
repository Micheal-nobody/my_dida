import 'package:flutter/material.dart';

class CalendarTimeGrid extends StatelessWidget {
  const CalendarTimeGrid({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      24,
      (index) => Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
      ),
    ),
  );
}
