import 'package:flutter/material.dart';
import 'CalendarTimeColumn.dart';
import 'CalendarTaskArea.dart';
import '../../model/entity/Task.dart';

//TODO：上半部分有bug，只显示一个任务（所有任务重叠到一起了）
//TODO：上半部分动态统一边界，以当前显示的日期中 没有具体时间的任务最多的一个日期 为宽度上限
//TODO：主要内容区域分两部分：上半部分显示没有具体时间的任务（最多显示5个，宽度默认，多余的不显示），下半部分显示有具体时间的任务
//TODO：实现拖动排序！！！！（听起来就很难！）
class CalendarScrollableContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 4. 左侧时间列
        const CalendarTimeColumn(),

        // 5. 任务显示区域
        Expanded(
          child: CalendarTaskArea(
            selectedDate: selectedDate,
            visibleDates: visibleDates,
            tasksForDates: tasksForDates,
          ),
        ),
      ],
    );
  }
}
