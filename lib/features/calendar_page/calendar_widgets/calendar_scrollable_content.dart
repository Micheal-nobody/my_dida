import 'package:flutter/material.dart';
import 'package:my_dida/shared/widgets/datetime/time_axis_column.dart';

import '../../../model/entity/Habit.dart';
import '../../../model/entity/Task.dart';
import 'future_tasks_area.dart';
import 'virtualized_calendar_time_area.dart';

class CalendarScrollableContent extends StatefulWidget {
  const CalendarScrollableContent({
    required this.selectedDate,
    required this.visibleDates,
    required this.tasksForDates,
    required this.habitsForDates,
    required this.futureTasks,
    required this.rruleHasMore,
    required this.onLoadMoreRRule,
    super.key,
  });

  final DateTime selectedDate;
  final List<DateTime> visibleDates;
  final Map<DateTime, List<Task>> tasksForDates;
  final Map<DateTime, List<Habit>> habitsForDates;
  final Map<DateTime, List<Task>> futureTasks;
  final Map<DateTime, bool> rruleHasMore;
  final void Function(DateTime date) onLoadMoreRRule;

  @override
  State<CalendarScrollableContent> createState() =>
      _CalendarScrollableContentState();
}

class _CalendarScrollableContentState extends State<CalendarScrollableContent> {
  late ScrollController _scrollController;

  List<DateTime> _getReorderedVisibleDates() {
    // Ensure the selected date is the first column, others remain in original order
    final List<DateTime> dates = List<DateTime>.from(widget.visibleDates);
    final int indexOfSelected = dates.indexWhere(
      (d) => _isSameDay(d, widget.selectedDate),
    );
    if (indexOfSelected <= 0) {
      return dates;
    }
    final DateTime selected = dates.removeAt(indexOfSelected);
    return [selected, ...dates];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 处理可见日期顺序：将当前选中的日期放置到最左侧，其余任务依次排列在右侧
    final List<DateTime> reorderedVisibleDates = _getReorderedVisibleDates();
    return Column(
      children: [
        // 可滚动的时间轴和任务区域（包含顶端的“无具体时间任务区域”）
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              // 使用SliverToBoxAdapter包装整个内容
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // 24小时时间轴 + 任务区域
                    SizedBox(
                      height: 1440, // 24小时 * 60px = 1440px
                      child: Row(
                        children: [
                          // 左侧时间列
                          const TimeAxisColumn(),

                          // 任务显示区域 - Using virtualized component for better performance
                          Expanded(
                            child: VirtualizedCalendarTimeArea(
                              selectedDate: widget.selectedDate,
                              visibleDates: reorderedVisibleDates,
                              tasksForDates: widget.tasksForDates,
                              habitsForDates: widget.habitsForDates,
                              rruleHasMore: widget.rruleHasMore,
                              onLoadMoreRRule: widget.onLoadMoreRRule,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 未来任务区域
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
