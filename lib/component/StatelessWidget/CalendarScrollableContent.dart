import 'package:flutter/material.dart';
import 'CalendarTimeColumn.dart';
import 'CalendarTImeTaskArea.dart';
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
  int? _cachedNoTimeTasksCount;
  Map<DateTime, List<Task>>? _cachedTasksForDates;

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

  int _getNoTimeTasksCount() {
    // 如果tasksForDates没有变化，返回缓存的结果
    if (_cachedTasksForDates == widget.tasksForDates &&
        _cachedNoTimeTasksCount != null) {
      return _cachedNoTimeTasksCount!;
    }

    int count = 0;
    for (final tasks in widget.tasksForDates.values) {
      count += tasks.where((task) {
        return task.startTime == null ||
            (task.startTime!.hour == 0 && task.startTime!.minute == 0);
      }).length;
    }

    // 缓存结果
    _cachedNoTimeTasksCount = count;
    _cachedTasksForDates = widget.tasksForDates;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    // 计算没有具体时间的任务数量
    final noTimeTasksCount = _getNoTimeTasksCount();

    return Column(
      children: [
        // 上半部分：没有具体时间的任务区域 - 使用AnimatedContainer确保高度变化有动画
        if (noTimeTasksCount > 0)
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: CalendarNoTimeTaskArea(
              visibleDates: widget.visibleDates,
              tasksForDates: widget.tasksForDates,
              selectedDate: widget.selectedDate,
            ),
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
                        child: CalendarTImeTaskArea(
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
