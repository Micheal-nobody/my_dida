import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/entity/Habit.dart';
import '../../../model/entity/Task.dart';
import '../../../provider/checklist_provider.dart';
import '../../../provider/task_provider.dart';
import 'CalendarHabitWithTime.dart';
import 'CalendarTaskWithTime.dart';

/// Virtualized calendar time area that only renders visible hours for better performance
class VirtualizedCalendarTimeArea extends StatefulWidget {
  const VirtualizedCalendarTimeArea({
    required this.selectedDate,
    required this.visibleDates,
    required this.tasksForDates,
    required this.habitsForDates,
    required this.rruleHasMore,
    required this.onLoadMoreRRule,
    super.key,
  });
  final DateTime selectedDate;
  final List<DateTime> visibleDates;
  final Map<DateTime, List<Task>> tasksForDates;
  final Map<DateTime, List<Habit>> habitsForDates;
  final Map<DateTime, bool> rruleHasMore;
  final void Function(DateTime date) onLoadMoreRRule;

  @override
  State<VirtualizedCalendarTimeArea> createState() =>
      _VirtualizedCalendarTimeAreaState();
}

class _VirtualizedCalendarTimeAreaState
    extends State<VirtualizedCalendarTimeArea> {
  final ScrollController _scrollController = ScrollController();
  Offset? _lastDragPosition;
  final GlobalKey _containerKey = GlobalKey();

  // Performance optimization: Only render hours that are likely to be visible
  static const int _hoursPerScreen = 12; // Approximate hours visible on screen
  static const int _bufferHours =
      2; // Buffer hours above and below visible area
  static const double _hourHeight = 60.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Calculate which hours should be rendered based on scroll position
  List<int> _getVisibleHours() {
    if (!_scrollController.hasClients) {
      // If not scrolled yet, show morning hours (6 AM to 6 PM)
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

  // Calculate date column width
  double _getDateColumnWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const timeColumnWidth = 60.0;
    final availableWidth = screenWidth - timeColumnWidth;
    return availableWidth / widget.visibleDates.length;
  }

  // Calculate time from drag position
  DateTime _calculateTimeFromPosition(
    Offset globalPosition,
    DateTime targetDate,
  ) {
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return targetDate;

    final localPosition = renderBox.globalToLocal(globalPosition);
    final relativeY = localPosition.dy.clamp(0.0, 1440.0);
    final totalMinutes = (relativeY / 1440.0 * 1440).round();
    final hour = (totalMinutes / 60).floor();
    final minute = totalMinutes % 60;
    final discreteMinute = ((minute / 15).round() * 15) % 60;
    final discreteHour = minute >= 45 ? (hour + 1) % 24 : hour;

    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      discreteHour.clamp(0, 23),
      discreteMinute.clamp(0, 59),
    );
  }

  // Calculate target date from drag position
  DateTime _calculateTargetDate(Offset position) {
    final screenWidth = MediaQuery.of(context).size.width;
    const timeColumnWidth = 60.0;
    final availableWidth = screenWidth - timeColumnWidth;
    final dateColumnWidth = availableWidth / widget.visibleDates.length;
    final relativeX = position.dx - timeColumnWidth;
    final columnIndex = (relativeX / dateColumnWidth).floor().clamp(
      0,
      widget.visibleDates.length - 1,
    );
    return widget.visibleDates[columnIndex];
  }

  @override
  Widget build(BuildContext context) => Selector<TaskProvider, List<Task>>(
    selector: (_, taskProvider) => taskProvider.tasks,
    builder: (context, tasks, child) => DragTarget<Task>(
      onMove: (details) {
        _lastDragPosition = details.offset;
      },
      onAcceptWithDetails: (details) async {
        if (_lastDragPosition != null) {
          final targetDate = _calculateTargetDate(_lastDragPosition!);
          final newTime = _calculateTimeFromPosition(
            _lastDragPosition!,
            targetDate,
          );
          final taskProvider = Provider.of<TaskProvider>(
            context,
            listen: false,
          );
          await taskProvider.updateStartTime(details.data, newTime);
        }
      },
      onWillAcceptWithDetails: (details) => true,
      builder: (context, candidateData, rejectedData) => Container(
        key: _containerKey,
        height: 1440, // 24 hours * 60px
        decoration: BoxDecoration(
          color: candidateData.isNotEmpty
              ? Colors.orange.withValues(alpha: 0.1)
              : null,
        ),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: 24, // 24 hours
          itemExtent: _hourHeight,
          itemBuilder: (context, hourIndex) {
            // Only build widgets for visible hours
            final visibleHours = _getVisibleHours();
            if (!visibleHours.contains(hourIndex)) {
              return const SizedBox(height: _hourHeight);
            }

            return _buildHourRow(hourIndex);
          },
        ),
      ),
    ),
  );

  Widget _buildHourRow(int hourIndex) {
    final dateColumnWidth = _getDateColumnWidth(context);

    return SizedBox(
      height: _hourHeight,
      child: Row(
        children: widget.visibleDates.asMap().entries.map((entry) {
          final dateIndex = entry.key;
          final date = entry.value;
          final normalizedDate = DateTime(date.year, date.month, date.day);

          return SizedBox(
            width: dateColumnWidth,
            child: _buildDateColumn(
              normalizedDate,
              dateIndex,
              hourIndex,
              dateColumnWidth,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateColumn(
    DateTime date,
    int dateIndex,
    int hourIndex,
    double columnWidth,
  ) {
    final tasksForDate = widget.tasksForDates[date] ?? [];
    final habitsForDate = widget.habitsForDates[date] ?? [];

    // Filter tasks and habits for this specific hour
    final tasksForHour = tasksForDate.where((task) {
      if (task.startTime == null) return false;
      return task.startTime!.hour == hourIndex;
    }).toList();

    final habitsForHour = habitsForDate
        .where((habit) => habit.remindTime.hour == hourIndex)
        .toList();

    return Stack(
      children: [
        // Background grid
        Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
        ),

        // Tasks for this hour
        ...tasksForHour.asMap().entries.map((entry) {
          final taskIndex = entry.key;
          final task = entry.value;
          final belongingBoxProvider = Provider.of<ChecklistProvider>(
            context,
            listen: false,
          );

          return Positioned(
            top: taskIndex * 20.0, // Stack tasks vertically
            left: 2,
            right: 2,
            child: CalendarTaskWithTime(
              task: task,
              columnWidth: columnWidth - 4,
              hourIndex: hourIndex,
              belongingBoxProvider: belongingBoxProvider,
            ),
          );
        }),

        // Habits for this hour
        ...habitsForHour.asMap().entries.map((entry) {
          final habitIndex = entry.key;
          final habit = entry.value;

          return Positioned(
            top: (tasksForHour.length + habitIndex) * 20.0,
            left: 2,
            right: 2,
            child: CalendarHabitWithTime(
              habit: habit,
              columnWidth: columnWidth - 4,
              hourIndex: hourIndex,
            ),
          );
        }),
      ],
    );
  }
}
