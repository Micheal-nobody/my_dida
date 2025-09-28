import 'package:flutter/material.dart';
import 'CalendarTimeColumn.dart';
import 'CalendarTImeTaskArea.dart';
import 'CalendarNoTimeTaskArea.dart';
import '../../model/entity/Task.dart';

class CalendarScrollableContent extends StatefulWidget {
  final DateTime selectedDate;
  final List<DateTime> visibleDates;
  final Map<DateTime, List<Task>> tasksForDates;
  final Map<DateTime, bool> rruleHasMore;
  final void Function(DateTime date) onLoadMoreRRule;

  const CalendarScrollableContent({
    super.key,
    required this.selectedDate,
    required this.visibleDates,
    required this.tasksForDates,
    required this.rruleHasMore,
    required this.onLoadMoreRRule,
  });

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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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
                    // 已实现：如果endTime - startTime > 24小时，则仅显示在CalendarNoTimeTaskArea（高度与CalendarNoTimeTaskArea中的任务数量一致，宽度根据endTime - startTime的天数确定），不显示在CalendarTImeTaskArea
                    // 顶部：没有具体时间（或时间为00:00）的任务区域
                    CalendarNoTimeTaskArea(
                      visibleDates: reorderedVisibleDates,
                      tasksForDates: widget.tasksForDates,
                      selectedDate: widget.selectedDate,
                    ),

                    // 下方：24小时时间轴 + 任务区域
                    SizedBox(
                      height: 1440, // 24小时 * 60px = 1440px
                      child: Row(
                        children: [
                          // 4. 左侧时间列
                          CalendarTimeColumn(),

                          // 5. 任务显示区域（不再包含00:00任务）
                          Expanded(
                            child: CalendarTImeTaskArea(
                              selectedDate: widget.selectedDate,
                              visibleDates: reorderedVisibleDates,
                              tasksForDates: widget.tasksForDates,
                              rruleHasMore: widget.rruleHasMore,
                              onLoadMoreRRule: widget.onLoadMoreRRule,
                            ),
                          ),
                        ],
                      ),
                    ),
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
