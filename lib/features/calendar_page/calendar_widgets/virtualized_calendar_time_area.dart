import 'package:flutter/material.dart';
import 'package:my_dida/features/calendar_page/calendar_entry_builders.dart';
import 'package:my_dida/model/entity/habit.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:provider/provider.dart';

/// Virtualized calendar_page time area that only renders visible hours for better performance
class VirtualizedCalendarTimeArea extends StatefulWidget {
  const VirtualizedCalendarTimeArea({
    required this.selectedDate,
    required this.visibleDates,
    required this.tasksForDates,
    required this.habitsForDates,
    required this.rruleHasMore,
    required this.onLoadMoreRRule,
    required this.onDragPreviewChanged,
    required this.timeAreaHeight,
    required this.timedTaskEntryBuilder,
    required this.timedHabitEntryBuilder,
    super.key,
  });

  final DateTime selectedDate;
  final List<DateTime> visibleDates;
  final Map<DateTime, List<Task>> tasksForDates;
  final Map<DateTime, List<Habit>> habitsForDates;
  final Map<DateTime, bool> rruleHasMore;
  final void Function(DateTime date) onLoadMoreRRule;
  final ValueChanged<DateTime?> onDragPreviewChanged;
  final double timeAreaHeight;
  final CalendarTimedTaskEntryBuilder timedTaskEntryBuilder;
  final CalendarTimedHabitEntryBuilder timedHabitEntryBuilder;

  @override
  State<VirtualizedCalendarTimeArea> createState() =>
      _VirtualizedCalendarTimeAreaState();
}

class _VirtualizedCalendarTimeAreaState
    extends State<VirtualizedCalendarTimeArea> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _containerKey = GlobalKey();

  static const int _hoursPerScreen = 12;
  static const int _bufferHours = 2;
  static const int _minutesPerDay = 24 * 60;
  static const int _snapGranularityMinutes = 15;
  DateTime? _dragPreviewTime;

  double get _hourHeight => widget.timeAreaHeight / 24;

  @override
  void dispose() {
    widget.onDragPreviewChanged(null);
    _scrollController.dispose();
    super.dispose();
  }

  List<int> _getVisibleHours() {
    if (!_scrollController.hasClients) {
      return List.generate(12, (index) => 6 + index);
    }

    final scrollOffset = _scrollController.offset;
    final startHour = (scrollOffset / _hourHeight).floor() - _bufferHours;
    final endHour = startHour + _hoursPerScreen + (_bufferHours * 2);

    return List.generate(
      (endHour - startHour).clamp(0, 24),
      (index) => (startHour + index).clamp(0, 23),
    );
  }

  double _getDateColumnWidth(BuildContext context) {
    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    final availableWidth =
        renderBox?.size.width ?? MediaQuery.of(context).size.width;
    return availableWidth / widget.visibleDates.length;
  }

  int _calculateSnappedMinutesFromPosition(Offset globalPosition) {
    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return 0;
    }

    final localPosition = renderBox.globalToLocal(globalPosition);
    final relativeY = localPosition.dy.clamp(0.0, widget.timeAreaHeight);
    final totalMinutes = ((relativeY / widget.timeAreaHeight) * _minutesPerDay)
        .round();
    final snappedMinutes =
        ((totalMinutes / _snapGranularityMinutes).round() *
                _snapGranularityMinutes)
            .clamp(0, _minutesPerDay - _snapGranularityMinutes);
    return snappedMinutes;
  }

  DateTime _calculateTimeFromPosition(
    Offset globalPosition,
    DateTime targetDate,
  ) {
    final snappedMinutes = _calculateSnappedMinutesFromPosition(globalPosition);
    final hour = snappedMinutes ~/ 60;
    final minute = snappedMinutes % 60;

    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );
  }

  DateTime _calculateTargetDate(Offset position) {
    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return widget.visibleDates.first;
    }

    final localPosition = renderBox.globalToLocal(position);
    final dateColumnWidth = renderBox.size.width / widget.visibleDates.length;
    final relativeX = localPosition.dx;
    final columnIndex = (relativeX / dateColumnWidth).floor().clamp(
      0,
      widget.visibleDates.length - 1,
    );
    return widget.visibleDates[columnIndex];
  }

  void _updateDragPreview(Offset globalPosition) {
    final targetDate = _calculateTargetDate(globalPosition);
    final previewTime = _calculateTimeFromPosition(globalPosition, targetDate);
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

  @override
  Widget build(BuildContext context) => Selector<TaskProvider, List<Task>>(
    selector: (_, taskProvider) => taskProvider.tasks,
    builder: (context, _, child) => DragTarget<Task>(
      onMove: (details) {
        _updateDragPreview(details.offset);
      },
      onLeave: (_) => _clearDragPreview(),
      onAcceptWithDetails: (details) async {
        if (_dragPreviewTime != null) {
          final taskProvider = Provider.of<TaskProvider>(
            context,
            listen: false,
          );
          await taskProvider.updateStartTime(
            details.data,
            _dragPreviewTime,
            isAllDay: false,
          );
        }
        _clearDragPreview();
      },
      onWillAcceptWithDetails: (details) => true,
      builder: (context, candidateData, rejectedData) {
        final previewMinuteOfDay = _dragPreviewTime == null
            ? null
            : _dragPreviewTime!.hour * 60 + _dragPreviewTime!.minute;
        final previewLineTop = previewMinuteOfDay == null
            ? null
            : (((previewMinuteOfDay / _minutesPerDay) * widget.timeAreaHeight) -
                      1)
                  .clamp(0.0, widget.timeAreaHeight - 2);

        return Container(
          key: _containerKey,
          height: widget.timeAreaHeight,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? Colors.orange.withValues(alpha: 0.1)
                : null,
          ),
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                itemCount: 24,
                itemExtent: _hourHeight,
                itemBuilder: (context, hourIndex) {
                  final visibleHours = _getVisibleHours();
                  if (!visibleHours.contains(hourIndex)) {
                    return SizedBox(height: _hourHeight);
                  }

                  return _buildHourRow(hourIndex);
                },
              ),
              if (candidateData.isNotEmpty && previewLineTop != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: previewLineTop,
                  child: IgnorePointer(
                    child: Container(height: 2, color: Colors.orange),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );

  Widget _buildHourRow(int hourIndex) {
    final dateColumnWidth = _getDateColumnWidth(context);

    return SizedBox(
      height: _hourHeight,
      child: Row(
        children: widget.visibleDates.map((date) {
          final normalizedDate = DateTime(date.year, date.month, date.day);

          return SizedBox(
            width: dateColumnWidth,
            child: _buildDateColumn(normalizedDate, hourIndex, dateColumnWidth),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateColumn(DateTime date, int hourIndex, double columnWidth) {
    final tasksForDate = widget.tasksForDates[date] ?? [];
    final habitsForDate = widget.habitsForDates[date] ?? [];

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
              right: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
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
            child: widget.timedTaskEntryBuilder(
              context,
              task: task,
              columnWidth: columnWidth - 4,
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
            child: widget.timedHabitEntryBuilder(
              context,
              habit: habit,
              columnWidth: columnWidth - 4,
            ),
          );
        }),
      ],
    );
  }
}
