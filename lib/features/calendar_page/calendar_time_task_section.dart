import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/habit.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/features/calendar_page/calendar_widgets/calendar_scrollable_content.dart';

class CalendarTimeTaskSection extends StatelessWidget {
  const CalendarTimeTaskSection({
    required this.selectedDate,
    required this.visibleDates,
    required this.tasksForDates,
    required this.habitsForDates,
    required this.futureTasks,
    required this.rruleHasMore,
    required this.onLoadMoreRRule,
    required this.onDateChanged,
    super.key,
  });

  final DateTime selectedDate;
  final List<DateTime> visibleDates;
  final Map<DateTime, List<Task>> tasksForDates;
  final Map<DateTime, List<Habit>> habitsForDates;
  final Map<DateTime, List<Task>> futureTasks;
  final Map<DateTime, bool> rruleHasMore;
  final void Function(DateTime date) onLoadMoreRRule;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onPanEnd: (details) {
        final horizontalVelocity = details.velocity.pixelsPerSecond.dx;
        final verticalVelocity = details.velocity.pixelsPerSecond.dy;
        if (horizontalVelocity.abs() <= verticalVelocity.abs()) {
          return;
        }

        if (horizontalVelocity > 80) {
          onDateChanged(selectedDate.subtract(const Duration(days: 1)));
        } else if (horizontalVelocity < -80) {
          onDateChanged(selectedDate.add(const Duration(days: 1)));
        }
      },
      child: CalendarScrollableContent(
        selectedDate: selectedDate,
        visibleDates: visibleDates,
        tasksForDates: tasksForDates,
        habitsForDates: habitsForDates,
        futureTasks: futureTasks,
        rruleHasMore: rruleHasMore,
        onLoadMoreRRule: onLoadMoreRRule,
      ),
    ),
  );
}
