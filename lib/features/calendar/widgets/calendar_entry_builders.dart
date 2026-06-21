import 'package:flutter/material.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/tasks/models/task.dart';

typedef CalendarTimedTaskEntryBuilder =
    Widget Function(
      BuildContext context, {
      required Task task,
      required double columnWidth,
    });

typedef CalendarTimedHabitEntryBuilder =
    Widget Function(
      BuildContext context, {
      required Habit habit,
      required double columnWidth,
    });

typedef CalendarAllDayTaskEntryBuilder =
    Widget Function(
      BuildContext context, {
      required Task task,
      required double columnWidth,
      required int stackIndex,
      required double availableHeight,
      required int displayedCount,
      required bool isCrossDay,
      double left,
      double? width,
    });

typedef CalendarAllDayHabitEntryBuilder =
    Widget Function(
      BuildContext context, {
      required Habit habit,
      required double columnWidth,
      required int stackIndex,
      required double availableHeight,
      required int displayedCount,
    });
