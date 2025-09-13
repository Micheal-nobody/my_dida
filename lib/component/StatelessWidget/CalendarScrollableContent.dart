import 'package:flutter/material.dart';
import 'CalendarTimeColumn.dart';
import 'CalendarTaskArea.dart';
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
    return Row(
      children: [
        // 4. 左侧时间列
        CalendarTimeColumn(scrollController: _scrollController),

        // 5. 任务显示区域
        Expanded(
          child: CalendarTaskArea(
            selectedDate: widget.selectedDate,
            visibleDates: widget.visibleDates,
            tasksForDates: widget.tasksForDates,
            scrollController: _scrollController,
          ),
        ),
      ],
    );
  }
}
