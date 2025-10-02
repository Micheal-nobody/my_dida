import 'package:flutter/material.dart';
import '../../model/entity/Habit.dart';
import '../HabitCheckInDialog.dart';

class CalendarHabitWithTime extends StatelessWidget {
  final Habit habit;
  final double columnWidth;
  final int hourIndex;

  const CalendarHabitWithTime({
    super.key,
    required this.habit,
    required this.columnWidth,
    required this.hourIndex,
  });

  @override
  Widget build(BuildContext context) {
    const habitColor = Colors.orange;

    return GestureDetector(
      onTap: () {
        HabitCheckInDialog.show(context: context, habit: habit);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: habitColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          habit.name,
          style: TextStyle(
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
