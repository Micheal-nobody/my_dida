import 'package:flutter/material.dart';
import 'package:my_dida/features/calendar_page/calendar_entry_builders.dart';
import 'package:my_dida/model/entity/habit.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:provider/provider.dart';

class CalendarAllDayTaskSection extends StatefulWidget {
  const CalendarAllDayTaskSection({
    required this.visibleDates,
    required this.habitsForDates,
    required this.allDayTasksForDates,
    required this.crossDayTasks,
    required this.crossDayTaskCountForDates,
    required this.allDayTaskEntryBuilder,
    required this.allDayHabitEntryBuilder,
    super.key,
  });

  final List<DateTime> visibleDates;
  final Map<DateTime, List<Habit>> habitsForDates;
  final Map<DateTime, List<Task>> allDayTasksForDates;
  final List<Task> crossDayTasks;
  final Map<DateTime, int> crossDayTaskCountForDates;
  final CalendarAllDayTaskEntryBuilder allDayTaskEntryBuilder;
  final CalendarAllDayHabitEntryBuilder allDayHabitEntryBuilder;

  @override
  State<CalendarAllDayTaskSection> createState() =>
      _CalendarAllDayTaskSectionState();
}

class _CalendarAllDayTaskSectionState extends State<CalendarAllDayTaskSection> {
  Offset? _lastDragPosition;
  final GlobalKey _containerKey = GlobalKey();
  static const double _spanBarHeight = 28.0;

  double _calculateDynamicHeight() {
    var allNoTimeHabitsCount = 0;
    var allNoTimeTasksCount = 0;

    for (final date in widget.visibleDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      allNoTimeTasksCount +=
          widget.allDayTasksForDates[normalizedDate]?.length ?? 0;
      allNoTimeHabitsCount += (widget.habitsForDates[normalizedDate] ?? [])
          .where(
            (habit) =>
                habit.remindTime.hour == 0 && habit.remindTime.minute == 0,
          )
          .length;
    }

    final totalCount =
        allNoTimeTasksCount +
        allNoTimeHabitsCount +
        widget.crossDayTasks.length;
    if (totalCount == 0) {
      return 0;
    }

    final displayedCount = totalCount.clamp(0, 6);
    const itemHeight = 28.0;
    const padding = 16.0;
    return displayedCount * itemHeight + padding;
  }

  double _getDateColumnWidth(double availableWidth) =>
      availableWidth / widget.visibleDates.length;

  List<Widget> _renderCrossDayTasks(double availableWidth) {
    return widget.crossDayTasks.asMap().entries.map((entry) {
      final taskIndex = entry.key;
      final task = entry.value;
      return _buildCrossDayTask(task, taskIndex, availableWidth);
    }).toList();
  }

  Widget _buildCrossDayTask(Task task, int taskIndex, double availableWidth) {
    final startTime = task.startTime!;
    final endTime = task.endTime!;
    final startDate = DateTime(startTime.year, startTime.month, startTime.day);
    final endDate = DateTime(endTime.year, endTime.month, endTime.day);
    final visibleDates = widget.visibleDates
        .map((date) => DateTime(date.year, date.month, date.day))
        .toList();
    final startIndex = visibleDates.indexWhere(
      (date) => !date.isBefore(startDate),
    );
    final endIndex = visibleDates.lastIndexWhere(
      (date) => !date.isAfter(endDate),
    );

    if (startIndex == -1 || endIndex == -1 || endIndex < startIndex) {
      return const SizedBox.shrink();
    }

    final dateColumnWidth = _getDateColumnWidth(availableWidth);
    final leftPosition = startIndex * dateColumnWidth;
    final taskWidth = (endIndex - startIndex + 1) * dateColumnWidth;

    return widget.allDayTaskEntryBuilder(
      context,
      task: task,
      columnWidth: taskWidth,
      width: taskWidth,
      left: leftPosition,
      stackIndex: taskIndex,
      availableHeight: _spanBarHeight,
      displayedCount: widget.crossDayTasks.length.clamp(1, 6),
      isCrossDay: true,
    );
  }

  DateTime _calculateTargetDate(Offset globalPosition) {
    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return widget.visibleDates.first;
    }

    final localPosition = renderBox.globalToLocal(globalPosition);
    final dateColumnWidth = renderBox.size.width / widget.visibleDates.length;
    final relativeX = localPosition.dx;
    final columnIndex = (relativeX / dateColumnWidth).floor().clamp(
      0,
      widget.visibleDates.length - 1,
    );
    return widget.visibleDates[columnIndex];
  }

  @override
  Widget build(BuildContext context) => Consumer<TaskProvider>(
    builder: (context, taskProvider, child) => LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final dateColumnWidth = _getDateColumnWidth(availableWidth);

        return DragTarget<Task>(
          onMove: (details) {
            _lastDragPosition = details.offset;
          },
          onAcceptWithDetails: (details) async {
            if (_lastDragPosition == null) {
              return;
            }

            final targetDate = _calculateTargetDate(_lastDragPosition!);
            final newTime = DateTime(
              targetDate.year,
              targetDate.month,
              targetDate.day,
            );
            await taskProvider.execute(UpdateStartTime(
              details.data,
              newTime,
              isAllDay: true,
            ));
          },
          onWillAcceptWithDetails: (details) => true,
          builder: (context, candidateData, rejectedData) {
            final dynamicHeight = _calculateDynamicHeight();
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
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: candidateData.isNotEmpty
                          ? Colors.blue
                          : Colors.grey.withValues(alpha: 0.3),
                      width: candidateData.isNotEmpty ? 2.0 : 1.0,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    ..._renderCrossDayTasks(availableWidth),
                    Row(
                      children: widget.visibleDates.map((date) {
                        final normalizedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                        );
                        final noTimeTasks =
                            widget.allDayTasksForDates[normalizedDate] ?? [];
                        final noTimeHabits =
                            (widget.habitsForDates[normalizedDate] ?? [])
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
                            widget.crossDayTaskCountForDates[normalizedDate] ??
                            0;

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
                                            ) => widget.allDayTaskEntryBuilder(
                                              context,
                                              task: entry.value,
                                              columnWidth: dateColumnWidth - 8,
                                              stackIndex:
                                                  crossDayTaskCount + entry.key,
                                              availableHeight: availableHeight,
                                              displayedCount:
                                                  displayedCountForColumn +
                                                  crossDayTaskCount,
                                              isCrossDay: false,
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
                                            ) => widget.allDayHabitEntryBuilder(
                                              context,
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
