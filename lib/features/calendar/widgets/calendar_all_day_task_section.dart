import 'package:flutter/material.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/calendar/providers/calendar_page_provider.dart';
import 'package:my_dida/features/calendar/widgets/calendar_entry_widgets.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:provider/provider.dart';

class CalendarAllDayTaskSection extends StatefulWidget {
  const CalendarAllDayTaskSection({super.key});

  @override
  State<CalendarAllDayTaskSection> createState() =>
      _CalendarAllDayTaskSectionState();
}

class _CalendarAllDayTaskSectionState extends State<CalendarAllDayTaskSection> {
  Offset? _lastDragPosition;
  final GlobalKey _containerKey = GlobalKey();
  static const double _spanBarHeight = 28.0;
  static const double _allDayEntryHeight = 28.0;

  double _calculateDynamicHeight(
    List<DateTime> visibleDates,
    Map<DateTime, List<Task>> allDayTasksForDates,
    Map<DateTime, List<Habit>> habitsForDates,
    List<Task> crossDayTasks,
  ) {
    var allNoTimeHabitsCount = 0;
    var allNoTimeTasksCount = 0;

    for (final date in visibleDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      allNoTimeTasksCount += allDayTasksForDates[normalizedDate]?.length ?? 0;
      allNoTimeHabitsCount += (habitsForDates[normalizedDate] ?? [])
          .where(
            (habit) =>
                habit.remindTime.hour == 0 && habit.remindTime.minute == 0,
          )
          .length;
    }

    final totalCount =
        allNoTimeTasksCount + allNoTimeHabitsCount + crossDayTasks.length;
    if (totalCount == 0) {
      return 0;
    }

    final displayedCount = totalCount.clamp(0, 6);
    const itemHeight = 28.0;
    const padding = 16.0;
    return displayedCount * itemHeight + padding;
  }

  double _getDateColumnWidth(double availableWidth, int visibleDatesCount) =>
      availableWidth / visibleDatesCount;

  List<Widget> _renderCrossDayTasks(
    double availableWidth,
    List<DateTime> visibleDates,
    List<Task> crossDayTasks,
  ) =>
      crossDayTasks.asMap().entries.map((entry) {
        final taskIndex = entry.key;
        final task = entry.value;
        return _buildCrossDayTask(
          task,
          taskIndex,
          availableWidth,
          visibleDates,
          crossDayTasks.length,
        );
      }).toList();

  Widget _buildCrossDayTask(
    Task task,
    int taskIndex,
    double availableWidth,
    List<DateTime> visibleDates,
    int crossDayTasksCount,
  ) {
    final startTime = task.startTime!;
    final endTime = task.endTime!;
    final startDate = DateTime(startTime.year, startTime.month, startTime.day);
    final endDate = DateTime(endTime.year, endTime.month, endTime.day);
    final normalizedVisibleDates = visibleDates
        .map((date) => DateTime(date.year, date.month, date.day))
        .toList();
    final startIndex = normalizedVisibleDates.indexWhere(
      (date) => !date.isBefore(startDate),
    );
    final endIndex = normalizedVisibleDates.lastIndexWhere(
      (date) => !date.isAfter(endDate),
    );

    if (startIndex == -1 || endIndex == -1 || endIndex < startIndex) {
      return const SizedBox.shrink();
    }

    final dateColumnWidth = _getDateColumnWidth(
      availableWidth,
      visibleDates.length,
    );
    final leftPosition = startIndex * dateColumnWidth;
    final taskWidth = (endIndex - startIndex + 1) * dateColumnWidth;

    return CalendarAllDayTaskEntry(
      task: task,
      columnWidth: taskWidth,
      width: taskWidth,
      left: leftPosition,
      stackIndex: taskIndex,
      availableHeight: _spanBarHeight,
      displayedCount: crossDayTasksCount.clamp(1, 6),
      isCrossDay: true,
      entryHeight: _allDayEntryHeight,
    );
  }

  DateTime _calculateTargetDate(
    Offset globalPosition,
    List<DateTime> visibleDates,
  ) {
    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return visibleDates.first;
    }

    final localPosition = renderBox.globalToLocal(globalPosition);
    final dateColumnWidth = renderBox.size.width / visibleDates.length;
    final relativeX = localPosition.dx;
    final columnIndex = (relativeX / dateColumnWidth).floor().clamp(
      0,
      visibleDates.length - 1,
    );
    return visibleDates[columnIndex];
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = context.watch<CalendarPageProvider>();
    final colorTheme = context.theme;
    final visibleDates = calendarProvider.visibleDates;
    final habitsForDates = calendarProvider.habitsForDates;
    final allDayTasksForDates = calendarProvider.allDayTasksForDates;
    final crossDayTasks = calendarProvider.crossDayTasks;
    final crossDayTaskCountForDates = calendarProvider.crossDayTaskCountForDates;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) => LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final dateColumnWidth = _getDateColumnWidth(
            availableWidth,
            visibleDates.length,
          );

          return DragTarget<Task>(
            onMove: (details) {
              _lastDragPosition = details.offset;
            },
            onAcceptWithDetails: (details) async {
              if (_lastDragPosition == null) {
                return;
              }

              final targetDate = _calculateTargetDate(
                _lastDragPosition!,
                visibleDates,
              );
              final newTime = DateTime(
                targetDate.year,
                targetDate.month,
                targetDate.day,
              );
              await taskProvider.execute(
                UpdateStartTime(details.data, newTime, isAllDay: true),
              );
            },
            onWillAcceptWithDetails: (details) => true,
            builder: (context, candidateData, rejectedData) {
              final dynamicHeight = _calculateDynamicHeight(
                visibleDates,
                allDayTasksForDates,
                habitsForDates,
                crossDayTasks,
              );
              if (dynamicHeight == 0 && candidateData.isEmpty) {
                return const SizedBox.shrink();
              }

              return AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Container(
                  key: _containerKey,
                  height: dynamicHeight,
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? colorTheme.primary.withValues(alpha: 0.1)
                        : colorTheme.primary.withValues(alpha: 0.05),
                    border: Border(
                      bottom: BorderSide(
                        color: candidateData.isNotEmpty
                            ? colorTheme.primary
                            : colorTheme.border.withValues(alpha: 0.3),
                        width: candidateData.isNotEmpty ? 2.0 : 1.0,
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      ..._renderCrossDayTasks(
                        availableWidth,
                        visibleDates,
                        crossDayTasks,
                      ),
                      Row(
                        children: visibleDates.map((date) {
                          final normalizedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                          final noTimeTasks =
                              allDayTasksForDates[normalizedDate] ?? [];
                          final noTimeHabits =
                              (habitsForDates[normalizedDate] ?? [])
                                  .where(
                                    (habit) =>
                                        habit.remindTime.hour == 0 &&
                                        habit.remindTime.minute == 0,
                                  )
                                  .toList();
                          final displayedCountForColumn =
                              (noTimeTasks.length + noTimeHabits.length).clamp(
                                0,
                                6,
                              );
                          final crossDayTaskCount =
                              crossDayTaskCountForDates[normalizedDate] ?? 0;

                          return Expanded(
                            child: Container(
                              height: dynamicHeight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final availableHeight = constraints.maxHeight;
                                  return ClipRect(
                                    child: Stack(
                                      children: [
                                        ...noTimeTasks
                                            .take(6)
                                            .toList()
                                            .asMap()
                                            .entries
                                            .map(
                                              (
                                                entry,
                                              ) => CalendarAllDayTaskEntry(
                                                task: entry.value,
                                                columnWidth: dateColumnWidth - 8,
                                                stackIndex:
                                                    crossDayTaskCount + entry.key,
                                                availableHeight: availableHeight,
                                                displayedCount:
                                                    displayedCountForColumn +
                                                    crossDayTaskCount,
                                                isCrossDay: false,
                                                entryHeight: _allDayEntryHeight,
                                              ),
                                            ),
                                        ...noTimeHabits
                                            .take(6 - noTimeTasks.length)
                                            .toList()
                                            .asMap()
                                            .entries
                                            .map(
                                              (
                                                entry,
                                              ) => CalendarAllDayHabitEntry(
                                                habit: entry.value,
                                                columnWidth: dateColumnWidth - 8,
                                                stackIndex:
                                                    crossDayTaskCount +
                                                    noTimeTasks.length +
                                                    entry.key,
                                                availableHeight: availableHeight,
                                                displayedCount:
                                                    displayedCountForColumn +
                                                    crossDayTaskCount,
                                                entryHeight: _allDayEntryHeight,
                                              ),
                                            ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
