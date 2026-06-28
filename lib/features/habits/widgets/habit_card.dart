import 'package:flutter/material.dart';
import 'package:my_dida/core/constants/icon_constants.dart';
import 'package:my_dida/core/utils/time_formatter.dart';
import 'package:my_dida/features/habits/models/habit.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    required this.habit,
    required this.progress,
    required this.isCompleted,
    required this.onTap,
    required this.onSkip,
    required this.onEdit,
    this.isSkipped = false,
    super.key,
  });

  final Habit habit;
  final double progress;
  final bool isCompleted;
  final bool isSkipped;
  final VoidCallback onTap;
  final VoidCallback onSkip;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: Key('habit_${habit.id}'),
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      child: const Icon(Icons.skip_next, color: Colors.white, size: 30),
    ),
    secondaryBackground: Container(
      color: Colors.blue,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.edit, color: Colors.white, size: 30),
    ),
    confirmDismiss: (direction) async {
      if (direction == DismissDirection.startToEnd) {
        onSkip();
        return false;
      } else if (direction == DismissDirection.endToStart) {
        onEdit();
        return false;
      }
      return false;
    },
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: isSkipped ? Colors.grey.withValues(alpha: 0.5) : null,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconConstants.getIconByName(habit.icon) ?? Icons.star,
              size: 24,
              color: isCompleted ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            if (isCompleted)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),

        title: Text(
          habit.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSkipped ? Colors.grey : null,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              habit.habitType == HabitType.yesNo
                  ? '${habit.currentCheckInCount}/${habit.checkInCount}'
                  : '${habit.currentValue.toStringAsFixed(0)}/${habit.targetValue?.toStringAsFixed(0) ?? 0} ${habit.unit ?? ""}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),

        trailing: Text(
          TimeFormatter.formatTimeOnly(habit.remindTime),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),

        onTap: isSkipped ? null : onTap,
      ),
    ),
  );
}
