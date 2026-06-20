import 'package:flutter/material.dart';
import 'package:my_dida/features/calendar_page/calendar_entry_builders.dart';
import 'package:my_dida/features/calendar_page/calendar_widgets/calendar_scrollable_content.dart';
import 'package:my_dida/model/entity/habit.dart';
import 'package:my_dida/model/entity/task.dart';

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
    required this.timeAreaHeight,
    required this.timedTaskEntryBuilder,
    required this.timedHabitEntryBuilder,
    this.onDragPreviewChanged,
    this.onScrollOffsetChanged,
    this.hours,
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
  final double timeAreaHeight;
  final CalendarTimedTaskEntryBuilder timedTaskEntryBuilder;
  final CalendarTimedHabitEntryBuilder timedHabitEntryBuilder;
  final ValueChanged<DateTime?>? onDragPreviewChanged;
  final ValueChanged<double>? onScrollOffsetChanged;
  final List<int>? hours;

  @override
  Widget build(BuildContext context) => GestureDetector(
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
      timeAreaHeight: timeAreaHeight,
      timedTaskEntryBuilder: timedTaskEntryBuilder,
      timedHabitEntryBuilder: timedHabitEntryBuilder,
      onDragPreviewChanged: onDragPreviewChanged,
      onScrollOffsetChanged: onScrollOffsetChanged,
      hours: hours,
    ),
  );
}
