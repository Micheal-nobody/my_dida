import 'package:flutter/material.dart';
import 'CalendarTimeColumn.dart';
import 'CalendarTaskArea.dart';
import 'CalendarNoTimeTaskArea.dart';
import '../../model/entity/Task.dart';

class CalendarScrollableContent extends StatefulWidget {
  final DateTime selectedDate;
  final List<DateTime> visibleDates;
  final Map<DateTime, List<Task>> tasksForDates;

  const CalendarScrollableContent({
    super.key,
    required this.selectedDate,
    required this.visibleDates,
    required this.tasksForDates,
  });

  @override
  State<CalendarScrollableContent> createState() =>
      _CalendarScrollableContentState();
}

class _CalendarScrollableContentState extends State<CalendarScrollableContent> {
  late ScrollController _scrollController;

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
    return Column(
      children: [
        // 上半部分：没有具体时间的任务区域
        CalendarNoTimeTaskArea(
          visibleDates: widget.visibleDates,
          tasksForDates: widget.tasksForDates,
        ),

        // 下半部分：可滚动的时间轴和任务区域
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              // 使用SliverToBoxAdapter包装整个内容
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 1440, // 24小时 * 60px = 1440px
                  child: Row(
                    children: [
                      // 4. 左侧时间列
                      CalendarTimeColumn(),

                      // 5. 任务显示区域
                      Expanded(
                        child: CalendarTaskArea(
                          selectedDate: widget.selectedDate,
                          visibleDates: widget.visibleDates,
                          tasksForDates: widget.tasksForDates,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
