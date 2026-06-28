import 'package:flutter/material.dart';
import 'package:my_dida/core/constants/app_constants.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/core/utils/time_utils.dart';
import 'package:my_dida/features/calendar/widgets/calendar_widgets/calendar_entry_card.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/habits/widgets/habit_check_in_dialog.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/pages/task_detail_page.dart';
import 'package:provider/provider.dart';

Color getTaskColor(BuildContext context, Task task) {
  final checklistProvider = Provider.of<ChecklistProvider>(
    context,
    listen: false,
  );
  final checklist = checklistProvider.allCheckLists.firstWhere(
    (item) => item.id == task.checklistId,
    orElse: () => AppConstants.defaultCheckList,
  );
  return checklist.color;
}

class CalendarTimedTaskEntry extends StatelessWidget {
  const CalendarTimedTaskEntry({
    required this.task,
    required this.columnWidth,
    required this.entryHeight,
    super.key,
  });

  final Task task;
  final double columnWidth;
  final double entryHeight;

  @override
  Widget build(BuildContext context) {
    if (task.startTime == null) {
      return const SizedBox.shrink();
    }

    final taskColor = getTaskColor(context, task);

    Widget buildCard({
      required Color backgroundColor,
      required VoidCallback onPressed,
      Color? borderColor,
    }) => SizedBox(
      width: columnWidth,
      height: entryHeight,
      child: CalendarEntryCard(
        text: task.name,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        onPressed: onPressed,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        opacity: task.isDone ? 0.4 : 1,
      ),
    );

    return Draggable<Task>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: buildCard(
          backgroundColor: taskColor.withValues(alpha: 0.9),
          onPressed: () {},
        ),
      ),
      childWhenDragging: buildCard(
        backgroundColor: taskColor.withValues(alpha: 0.3),
        borderColor: taskColor,
        onPressed: () {},
      ),
      child: buildCard(
        backgroundColor: taskColor.withValues(alpha: 0.8),
        onPressed: () {
          TaskDetailPage.show(context, task);
        },
      ),
    );
  }
}

class CalendarTimedHabitEntry extends StatelessWidget {
  const CalendarTimedHabitEntry({
    required this.habit,
    required this.columnWidth,
    super.key,
  });

  final Habit habit;
  final double columnWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: columnWidth,
    child: CalendarEntryCard(
      text: habit.name,
      backgroundColor: context.theme.primary.withValues(alpha: 0.8),
      onPressed: () {
        HabitCheckInDialog.show(context: context, habit: habit);
      },
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    ),
  );
}

class CalendarAllDayTaskEntry extends StatelessWidget {
  const CalendarAllDayTaskEntry({
    required this.task,
    required this.columnWidth,
    required this.stackIndex,
    required this.availableHeight,
    required this.displayedCount,
    required this.isCrossDay,
    required this.entryHeight,
    this.left = 0,
    this.width,
    super.key,
  });

  final Task task;
  final double columnWidth;
  final int stackIndex;
  final double availableHeight;
  final int displayedCount;
  final bool isCrossDay;
  final double left;
  final double? width;
  final double entryHeight;

  @override
  Widget build(BuildContext context) {
    final taskColor = getTaskColor(context, task);

    if (isCrossDay) {
      return Positioned(
        left: left,
        top: stackIndex * entryHeight,
        width: width ?? columnWidth,
        height: entryHeight,
        child: CalendarEntryCard(
          text: task.name,
          backgroundColor: taskColor.withValues(alpha: 0.9),
          onPressed: () {
            TaskDetailPage.show(context, task);
          },
          padding: const EdgeInsets.symmetric(horizontal: 6),
          borderRadius: 6,
          alignment: Alignment.centerLeft,
          textStyle: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          opacity: task.isDone ? 0.4 : 1,
        ),
      );
    }

    final taskCount = displayedCount.clamp(1, 6);
    const taskSpacing = 1.0;
    final totalSpacing = (taskCount - 1) * taskSpacing;
    final taskHeight = (availableHeight - totalSpacing) / taskCount;
    final topPosition = stackIndex * (taskHeight + taskSpacing);

    Widget buildCard({
      required Color backgroundColor,
      required VoidCallback onPressed,
      Color? borderColor,
    }) => SizedBox(
      width: width ?? columnWidth,
      height: taskHeight,
      child: CalendarEntryCard(
        text: task.name,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        onPressed: onPressed,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        useFittedBox: true,
        opacity: task.isDone ? 0.4 : 1,
      ),
    );

    return Positioned(
      top: topPosition,
      left: left,
      width: width ?? columnWidth,
      height: taskHeight,
      child: Draggable<Task>(
        data: task,
        feedback: Material(
          color: Colors.transparent,
          child: buildCard(
            backgroundColor: taskColor.withValues(alpha: 0.9),
            onPressed: () {},
          ),
        ),
        childWhenDragging: buildCard(
          backgroundColor: taskColor.withValues(alpha: 0.3),
          borderColor: taskColor,
          onPressed: () {},
        ),
        child: buildCard(
          backgroundColor: taskColor.withValues(alpha: 0.8),
          onPressed: () {
            TaskDetailPage.show(context, task);
          },
        ),
      ),
    );
  }
}

class CalendarAllDayHabitEntry extends StatelessWidget {
  const CalendarAllDayHabitEntry({
    required this.habit,
    required this.columnWidth,
    required this.stackIndex,
    required this.availableHeight,
    required this.displayedCount,
    required this.entryHeight,
    super.key,
  });

  final Habit habit;
  final double columnWidth;
  final int stackIndex;
  final double availableHeight;
  final int displayedCount;
  final double entryHeight;

  @override
  Widget build(BuildContext context) {
    final topPosition = stackIndex * entryHeight;
    if (topPosition + entryHeight > availableHeight) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      top: topPosition,
      width: columnWidth,
      height: entryHeight,
      child: CalendarEntryCard(
        text: habit.name,
        backgroundColor: context.theme.primary.withValues(alpha: 0.8),
        onPressed: () {
          HabitCheckInDialog.show(context: context, habit: habit);
        },
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        borderRadius: 6,
        alignment: Alignment.centerLeft,
        textStyle: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class CalendarGridDay extends StatelessWidget {
  const CalendarGridDay({
    required this.date,
    required this.isSelected,
    required this.tasks,
    required this.allDayTasks,
    super.key,
  });

  final DateTime date;
  final bool isSelected;
  final List<Task> tasks;
  final List<Task> allDayTasks;

  @override
  Widget build(BuildContext context) {
    final totalTasks = [...tasks, ...allDayTasks];

    final colors = <Color>{};
    for (final task in totalTasks) {
      colors.add(getTaskColor(context, task));
      if (colors.length >= 3) break;
    }

    final isToday = date.isToday();
    final colorTheme = context.theme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? colorTheme.primary
                  : (isToday
                        ? colorTheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent),
            ),
            child: Center(
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  color: isSelected
                      ? colorTheme.textOnPrimary
                      : (isToday ? colorTheme.primary : colorTheme.textPrimary),
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: colors
                .map(
                  (color) => Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
