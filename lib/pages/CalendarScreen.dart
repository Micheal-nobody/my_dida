import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../provider/TodosProvider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CalendarScreenState();
  }
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List> events = {
    // 用于存储特定日期的事件
    // 例如：DateTime(2025, 7, 15) 对应的事件为 ['团队会议']
    DateTime(2025, 7, 15): ['团队会议'],
    DateTime(2025, 7, 20): ['医生预约', '生日派对'],
  };
  final List<String> _chineseWeekdays = [
    '星期日',
    '星期一',
    '星期二',
    '星期三',
    '星期四',
    '星期五',
    '星期六',
  ];

  @override
  Widget build(BuildContext context) {
    // 使用 Provider 来获取 TodosProvider 实例
    final todosProvider = context.watch<TodosProvider>();

    // 使用 TableCalendar 组件来显示日
    return TableCalendar(
      focusedDay: _focusedDay,
      // 当前聚焦的日期
      firstDay: DateTime(2025),
      lastDay: DateTime(2026),

      // 日历格式（如月视图、周视图等）
      calendarFormat: _format,
      onFormatChanged: (format) => setState(() => _format = format),

      // selectedDayPredicate 用于判断某个日期是否被选中，会在TableCalendar内部调用
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          todosProvider.cur_date = selectedDay; // 更新当前日期
          print("SelectedDay = $_selectedDay");
        });
      },

      /// onPageChanged 用于监听日历页面的变化
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },

      // eventLoader 用于加载特定日期的事件，day参数表示当前选中的日期
      eventLoader: (day) {
        /// entries 是一个方法，用于获取 Map 中的所有键值对
        return todosProvider.all_todos.entries
            .where((entry) => isSameDay(entry.key, day)) // 筛选出匹配的键值对
            .map((entry) => entry.value) // 获取匹配日期的事件列表
            .expand((e) => e) // 扩展事件列表，将嵌套的列表转换为单一列表
            .toList();
      },

      //? calendarBuilders 用于自定义日历的外观
      calendarBuilders: CalendarBuilders(
        // dowBuilder 用于自定义星期几的显示
        dowBuilder: (context, day) {
          // 自定义星期几的显示
          return Center(child: Text('${_chineseWeekdays[day.day % 7]}'));
        },

        //? markerBuilder 用于在特定日期上显示标记,day 参数表示当前日期，events 参数表示该日期的eventLoader返回的列表
        markerBuilder: (context, day, events) {
          if(events.isEmpty) return const SizedBox.shrink();

          return Positioned(
            bottom: 1, // bottom 表示child的底部位置为父组件的底部
            right: 1,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${events.length}',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}
