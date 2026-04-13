import 'package:flutter/material.dart';

import '../../../model/entity/Habit.dart';
import '../../dialogs/habit_check_in_dialog.dart';

class CalendarHabitWithTime extends StatelessWidget {
  const CalendarHabitWithTime({
    required this.habit,
    required this.columnWidth,
    required this.hourIndex,
    super.key,
  });

  final Habit habit;
  final double columnWidth;
  final int hourIndex;

  @override
  Widget build(BuildContext context) {
    const habitColor = Colors.orange;

    return GestureDetector(
      onTap: () {
        HabitCheckInDialog.show(context: context, habit: habit);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: habitColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          habit.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
