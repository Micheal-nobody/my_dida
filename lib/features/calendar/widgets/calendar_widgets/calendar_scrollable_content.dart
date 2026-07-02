import 'package:flutter/material.dart';
import 'package:my_dida/features/calendar/providers/calendar_page_provider.dart';
import 'package:my_dida/features/calendar/widgets/calendar_widgets/future_tasks_area.dart';
import 'package:my_dida/features/calendar/widgets/calendar_widgets/virtualized_calendar_time_area.dart';
import 'package:provider/provider.dart';

class CalendarScrollableContent extends StatefulWidget {
  const CalendarScrollableContent({
    required this.timeAreaHeight,
    this.onDragPreviewChanged,
    this.onScrollOffsetChanged,
    this.hours,
    super.key,
  });

  final double timeAreaHeight;
  final ValueChanged<DateTime?>? onDragPreviewChanged;
  final ValueChanged<double>? onScrollOffsetChanged;
  final List<int>? hours;

  @override
  State<CalendarScrollableContent> createState() =>
      _CalendarScrollableContentState();
}

class _CalendarScrollableContentState extends State<CalendarScrollableContent> {
  late ScrollController _scrollController;

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
    final calendarProvider = context.watch<CalendarPageProvider>();
    final selectedDate = calendarProvider.selectedDate;
    final futureTasks = calendarProvider.futureTasks;

    return GestureDetector(
      onPanEnd: (details) {
        final horizontalVelocity = details.velocity.pixelsPerSecond.dx;
        final verticalVelocity = details.velocity.pixelsPerSecond.dy;
        if (horizontalVelocity.abs() <= verticalVelocity.abs()) {
          return;
        }

        if (horizontalVelocity > 80) {
          calendarProvider.setSelectedDate(
            selectedDate.subtract(const Duration(days: 1)),
          );
        } else if (horizontalVelocity < -80) {
          calendarProvider.setSelectedDate(
            selectedDate.add(const Duration(days: 1)),
          );
        }
      },
      child: Column(
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
                          onDragPreviewChanged:
                              widget.onDragPreviewChanged ?? (_) {},
                          timeAreaHeight: widget.timeAreaHeight,
                          hours: widget.hours,
                        ),
                      ),
                      FutureTasksArea(futureTasks: futureTasks),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
