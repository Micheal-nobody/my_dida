import 'package:flutter/material.dart';

import '../../../model/entity/Habit.dart';
import '../../dialogs/habit_check_in_dialog.dart';

class CalendarHabitWithoutTime extends StatelessWidget {
  const CalendarHabitWithoutTime({
    required this.habit,
    required this.columnWidth,
    required this.habitIndex,
    required this.availableHeight,
    required this.displayedCount,
    super.key,
  });

  final Habit habit;
  final double columnWidth;
  final int habitIndex;
  final double availableHeight;
  final int displayedCount;

  @override
  Widget build(BuildContext context) {
    const habitColor = Colors.orange;
    const double habitHeight = 28.0;

    // 计算习惯的位置
    final double topPosition = habitIndex * habitHeight;

    // 如果超出可用高度，不显示
    if (topPosition + habitHeight > availableHeight) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      top: topPosition,
      width: columnWidth,
      height: habitHeight,
      child: GestureDetector(
        onTap: () {
          HabitCheckInDialog.show(context: context, habit: habit);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: habitColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            habit.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
