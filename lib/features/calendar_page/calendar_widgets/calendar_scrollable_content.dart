import 'package:flutter/material.dart';
import 'package:my_dida/features/calendar_page/calendar_entry_builders.dart';
import 'package:my_dida/features/calendar_page/calendar_widgets/future_tasks_area.dart';
import 'package:my_dida/features/calendar_page/calendar_widgets/virtualized_calendar_time_area.dart';
import 'package:my_dida/model/entity/habit.dart';
import 'package:my_dida/model/entity/task.dart';

class CalendarScrollableContent extends StatefulWidget {
  const CalendarScrollableContent({
    required this.selectedDate,
    required this.visibleDates,
    required this.tasksForDates,
    required this.habitsForDates,
    required this.futureTasks,
    required this.rruleHasMore,
    required this.onLoadMoreRRule,
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
  final double timeAreaHeight;
  final CalendarTimedTaskEntryBuilder timedTaskEntryBuilder;
  final CalendarTimedHabitEntryBuilder timedHabitEntryBuilder;
  final ValueChanged<DateTime?>? onDragPreviewChanged;
  final ValueChanged<double>? onScrollOffsetChanged;
  final List<int>? hours;

  @override
  State<CalendarScrollableContent> createState() =>
      _CalendarScrollableContentState();
}

class _CalendarScrollableContentState extends State<CalendarScrollableContent> {
  late ScrollController _scrollController;

  List<DateTime> _getReorderedVisibleDates() {
    final dates = List<DateTime>.from(widget.visibleDates);
    final indexOfSelected = dates.indexWhere(
      (date) => _isSameDay(date, widget.selectedDate),
    );
    if (indexOfSelected <= 0) {
      return dates;
    }

    final selected = dates.removeAt(indexOfSelected);
    return [selected, ...dates];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _handleScrollChanged() {
    widget.onScrollOffsetChanged?.call(_scrollController.offset);
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScrollChanged);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScrollChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reorderedVisibleDates = _getReorderedVisibleDates();
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(
                      height: widget.timeAreaHeight,
                      child: VirtualizedCalendarTimeArea(
                        selectedDate: widget.selectedDate,
                        visibleDates: reorderedVisibleDates,
                        tasksForDates: widget.tasksForDates,
                        habitsForDates: widget.habitsForDates,
                        rruleHasMore: widget.rruleHasMore,
                        onLoadMoreRRule: widget.onLoadMoreRRule,
                        onDragPreviewChanged:
                            widget.onDragPreviewChanged ?? (_) {},
                        timeAreaHeight: widget.timeAreaHeight,
                        timedTaskEntryBuilder: widget.timedTaskEntryBuilder,
                        timedHabitEntryBuilder: widget.timedHabitEntryBuilder,
                        hours: widget.hours,
                      ),
                    ),
                    FutureTasksArea(futureTasks: widget.futureTasks),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
