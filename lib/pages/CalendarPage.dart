import 'package:flutter/material.dart';
import 'package:my_dida/component/CustomFloatingActionButton.dart';
import 'package:my_dida/component/StatelessWidget/CalendarDateHeader.dart';
import 'package:my_dida/component/StatelessWidget/CalendarScrollableContent.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/provider/TaskProvider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  int _dateRange = 3; // 3-day view by default
  Map<DateTime, List<Task>> _tasksForDates = {};

  @override
  void initState() {
    super.initState();
    _loadTasksForVisibleDates();
  }

  List<DateTime> get _visibleDates {
    List<DateTime> dates = [];
    int halfRange = _dateRange ~/ 2;
    for (int i = -halfRange; i <= halfRange; i++) {
      dates.add(_selectedDate.add(Duration(days: i)));
    }
    return dates;
  }

  Future<void> _loadTasksForVisibleDates() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final Map<DateTime, List<Task>> tasksMap = {};

    // 获取所有任务
    await taskProvider.loadAllTasks();
    final allTasks = taskProvider.tasks;

    for (final date in _visibleDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // 筛选出该日期的任务（包括有时间和无时间的任务）
      final tasksForDate = allTasks.where((task) {
        if (task.startTime == null) {
          // 没有具体时间的任务，检查是否属于当前日期
          // 这里暂时将所有无时间任务都显示在今天的列中
          // TODO: 需要根据任务的创建日期或其他字段来判断是否属于当前日期
          return normalizedDate.isAtSameMomentAs(
            DateTime.now().toLocal().copyWith(
              hour: 0,
              minute: 0,
              second: 0,
              millisecond: 0,
            ),
          );
        }
        final taskDate = DateTime(
          task.startTime!.year,
          task.startTime!.month,
          task.startTime!.day,
        );
        return taskDate.isAtSameMomentAs(normalizedDate);
      }).toList();

      tasksMap[normalizedDate] = tasksForDate;
    }

    setState(() {
      _tasksForDates = tasksMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // 当任务更新时，重新加载任务数据
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadTasksForVisibleDates();
        });

        return Scaffold(
          // 1. AppBar 区域：左侧是当前月份
          appBar: AppBar(
            title: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = DateTime.now();
                });
              },
              child: Text(
                DateFormat('M月').format(_currentDate),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  _dateRange == 7 ? Icons.view_list : Icons.view_week,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _dateRange = _dateRange == 7 ? 3 : 7;
                  });
                  _loadTasksForVisibleDates();
                },
              ),
              SizedBox(width: 8),
              Icon(Icons.more_vert, color: Colors.grey[600]),
              SizedBox(width: 16),
            ],
          ),

          body: Column(
            children: [
              // 2. Header：显示日期和对应的星期
              CalendarDateHeader(
                selectedDate: _selectedDate,
                dateRange: _dateRange,
                tasksForDates: _tasksForDates,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                  _loadTasksForVisibleDates();
                },
              ),

              // 主要内容区域
              Expanded(
                child: CalendarScrollableContent(
                  selectedDate: _selectedDate,
                  visibleDates: _visibleDates,
                  tasksForDates: _tasksForDates,
                ),
              ),
            ],
          ),

          // 3. FloatingActionButton：用于添加任务
          floatingActionButton: CustomFloatingActionButton(),
        );
      },
    );
  }
}
