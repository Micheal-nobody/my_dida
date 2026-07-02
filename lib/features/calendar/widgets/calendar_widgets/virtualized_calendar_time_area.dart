import 'package:flutter/material.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/core/utils/time_utils.dart';
import 'package:my_dida/features/calendar/providers/calendar_page_provider.dart';
import 'package:my_dida/features/calendar/widgets/calendar_entry_widgets.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:provider/provider.dart';

/// Virtualized calendar_page time area that only renders visible hours for better performance
class VirtualizedCalendarTimeArea extends StatefulWidget {
  const VirtualizedCalendarTimeArea({
    required this.onDragPreviewChanged,
    required this.timeAreaHeight,
    this.hours,
    super.key,
  });

  final ValueChanged<DateTime?> onDragPreviewChanged;
  final double timeAreaHeight;
  final List<int>? hours;

  @override
  State<VirtualizedCalendarTimeArea> createState() =>
      _VirtualizedCalendarTimeAreaState();
}

class _VirtualizedCalendarTimeAreaState
    extends State<VirtualizedCalendarTimeArea> {
  final GlobalKey _containerKey = GlobalKey();

  static const int _snapGranularityMinutes = 15;
  static const double _timedEntryHeight = 15.0;
  DateTime? _dragPreviewTime;

  double get _hourHeight {
    final activeHoursCount = widget.hours?.length ?? 24;
    return widget.timeAreaHeight / activeHoursCount;
  }

  @override
  void dispose() {
    widget.onDragPreviewChanged(null);
    super.dispose();
  }

  double _getDateColumnWidth(double availableWidth, int visibleDatesCount) =>
      availableWidth / visibleDatesCount;

  DateTime _calculateTimeFromPosition(
    Offset globalPosition,
    DateTime targetDate,
    List<int> activeHours,
  ) {
    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return targetDate;
    }

    final localPosition = renderBox.globalToLocal(globalPosition);
    final relativeY = localPosition.dy.clamp(0.0, widget.timeAreaHeight);

    final totalActiveMinutes = activeHours.length * 60;
    final mappedMinutes =
        ((relativeY / widget.timeAreaHeight) * totalActiveMinutes).round();

    final snappedMinutes =
        ((mappedMinutes / _snapGranularityMinutes).round() *
                _snapGranularityMinutes)
            .clamp(0, totalActiveMinutes - 1);

    final hourIndex = (snappedMinutes ~/ 60).clamp(0, activeHours.length - 1);
    final minute = snappedMinutes % 60;
    final hour = activeHours[hourIndex];

    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );
  }

  DateTime _calculateTargetDate(Offset position, List<DateTime> visibleDates) {
    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return visibleDates.first;
    }

    final localPosition = renderBox.globalToLocal(position);
    final dateColumnWidth = renderBox.size.width / visibleDates.length;
    final relativeX = localPosition.dx;
    final columnIndex = (relativeX / dateColumnWidth).floor().clamp(
      0,
      visibleDates.length - 1,
    );
    return visibleDates[columnIndex];
  }

  void _updateDragPreview(Offset globalPosition, List<DateTime> visibleDates, List<int> activeHours) {
    final targetDate = _calculateTargetDate(globalPosition, visibleDates);
    final previewTime = _calculateTimeFromPosition(globalPosition, targetDate, activeHours);
    if (_dragPreviewTime == previewTime) {
      return;
    }

    setState(() {
      _dragPreviewTime = previewTime;
    });
    widget.onDragPreviewChanged(previewTime);
  }

  void _clearDragPreview() {
    if (_dragPreviewTime == null) {
      return;
    }
    setState(() {
      _dragPreviewTime = null;
    });
    widget.onDragPreviewChanged(null);
  }

  List<DateTime> _getReorderedVisibleDates(
    List<DateTime> visibleDates,
    DateTime selectedDate,
  ) {
    final dates = List<DateTime>.from(visibleDates);
    final indexOfSelected = dates.indexWhere(
      (date) => date.isSameDay(selectedDate),
    );
    if (indexOfSelected <= 0) {
      return dates;
    }

    final selected = dates.removeAt(indexOfSelected);
    return [selected, ...dates];
  }


  @override
  Widget build(BuildContext context) {
    final calendarProvider = context.watch<CalendarPageProvider>();
    final selectedDate = calendarProvider.selectedDate;
    final visibleDates = _getReorderedVisibleDates(calendarProvider.visibleDates, selectedDate);
    final tasksForDates = calendarProvider.tasksForDates;
    final habitsForDates = calendarProvider.habitsForDates;
    final colorTheme = context.theme;

    return Selector<TaskProvider, List<Task>>(
      selector: (_, taskProvider) => taskProvider.tasks,
      builder: (context, _, child) {
        final activeHours = widget.hours ?? List<int>.generate(24, (i) => i);
        double? previewLineTop;
        if (_dragPreviewTime != null) {
          final hourIndex = activeHours.indexOf(_dragPreviewTime!.hour);
          if (hourIndex != -1) {
            final previewTop =
                (hourIndex * _hourHeight) +
                (_dragPreviewTime!.minute / 60) * _hourHeight;
            previewLineTop = (previewTop - 1).clamp(
              0.0,
              widget.timeAreaHeight - 2,
            );
          }
        }

        return DragTarget<Task>(
          onMove: (details) {
            _updateDragPreview(details.offset, visibleDates, activeHours);
          },
          onLeave: (_) => _clearDragPreview(),
          onAcceptWithDetails: (details) async {
            if (_dragPreviewTime != null) {
              final taskProvider = Provider.of<TaskProvider>(
                context,
                listen: false,
              );
              await taskProvider.execute(
                UpdateStartTime(details.data, _dragPreviewTime, isAllDay: false),
              );
            }
            _clearDragPreview();
          },
          onWillAcceptWithDetails: (details) => true,
          builder: (context, candidateData, rejectedData) => LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              return Container(
                key: _containerKey,
                height: widget.timeAreaHeight,
                decoration: BoxDecoration(
                  color: candidateData.isNotEmpty
                      ? colorTheme.primary.withValues(alpha: 0.1)
                      : null,
                ),
                child: Stack(
                  children: [
                    Column(
                      children: List.generate(activeHours.length, (index) {
                        final actualHour = activeHours[index];
                        return _buildHourRow(
                          actualHour,
                          availableWidth,
                          visibleDates,
                          tasksForDates,
                          habitsForDates,
                        );
                      }),
                    ),
                    if (candidateData.isNotEmpty && previewLineTop != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: previewLineTop,
                        child: IgnorePointer(
                          child: Container(height: 2, color: colorTheme.primary),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHourRow(
    int hourIndex,
    double availableWidth,
    List<DateTime> visibleDates,
    Map<DateTime, List<Task>> tasksForDates,
    Map<DateTime, List<Habit>> habitsForDates,
  ) {
    final dateColumnWidth = _getDateColumnWidth(availableWidth, visibleDates.length);

    return SizedBox(
      height: _hourHeight,
      child: Row(
        children: visibleDates.map((date) {
          final normalizedDate = DateTime(date.year, date.month, date.day);

          return SizedBox(
            width: dateColumnWidth,
            child: _buildDateColumn(
              normalizedDate,
              hourIndex,
              dateColumnWidth,
              tasksForDates,
              habitsForDates,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateColumn(
    DateTime date,
    int hourIndex,
    double columnWidth,
    Map<DateTime, List<Task>> tasksForDates,
    Map<DateTime, List<Habit>> habitsForDates,
  ) {
    final tasksForDate = tasksForDates[date] ?? [];
    final habitsForDate = habitsForDates[date] ?? [];

    final tasksForHour = tasksForDate.where((task) {
      if (task.startTime == null || task.isAllDay) {
        return false;
      }
      return task.startTime!.hour == hourIndex;
    }).toList();

    final habitsForHour = habitsForDate
        .where((habit) => habit.remindTime.hour == hourIndex)
        .toList();

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: context.theme.border.withValues(alpha: 0.5)),
              bottom: BorderSide(color: context.theme.border.withValues(alpha: 0.5)),
            ),
          ),
        ),
        ...tasksForHour.asMap().entries.map((entry) {
          final taskIndex = entry.key;
          final task = entry.value;

          return Positioned(
            top: taskIndex * 20.0,
            left: 2,
            right: 2,
            child: CalendarTimedTaskEntry(
              task: task,
              columnWidth: columnWidth - 4,
              entryHeight: _timedEntryHeight,
            ),
          );
        }),
        ...habitsForHour.asMap().entries.map((entry) {
          final habitIndex = entry.key;
          final habit = entry.value;

          return Positioned(
            top: (tasksForHour.length + habitIndex) * 20.0,
            left: 2,
            right: 2,
            child: CalendarTimedHabitEntry(
              habit: habit,
              columnWidth: columnWidth - 4,
            ),
          );
        }),
      ],
    );
  }
}
