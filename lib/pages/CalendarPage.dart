import 'package:flutter/material.dart';
import 'package:my_dida/component/CustomFloatingActionButton.dart';
import 'package:my_dida/component/StatelessWidget/CalendarDateHeader.dart';
import 'package:my_dida/component/StatelessWidget/CalendarScrollableContent.dart';
import 'package:my_dida/component/CustomDatePicker/CalendarWidget.dart';
import 'package:my_dida/component/CustomDatePicker/TimeSlotTabWidget.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/repository/TaskRepository.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  int _dateRange = 7; // 7-day view by default
  Map<DateTime, List<Task>> _tasksForDates = {};
  final TaskRepository _taskRepository = TaskRepository();

  // For demonstrating the new widget classes
  DateTime? _calendarSelectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isAllDay = false;

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
    final Map<DateTime, List<Task>> tasksMap = {};

    for (final date in _visibleDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final tasks = await _taskRepository.getTasksForDate(normalizedDate);
      tasksMap[normalizedDate] = tasks;
    }

    setState(() {
      _tasksForDates = tasksMap;
    });
  }

  void _showCalendarWidget() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '选择日期',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CalendarWidget(
                  selectedDate: _calendarSelectedDate,
                  onDateChanged: (date) {
                    setState(() {
                      _calendarSelectedDate = date;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeSlotWidget() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '时间段设置',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TimeSlotTabWidget(
                  selectedDate: _calendarSelectedDate,
                  startTime: _startTime,
                  endTime: _endTime,
                  isAllDay: _isAllDay,
                  onDateChanged: (date) {
                    setState(() {
                      _calendarSelectedDate = date;
                    });
                  },
                  onTimeChanged: (start, end) {
                    setState(() {
                      _startTime = start;
                      _endTime = end;
                    });
                  },
                  onAllDayChanged: (isAllDay) {
                    setState(() {
                      _isAllDay = isAllDay;
                    });
                  },
                  onSwitchToDateTab: () {
                    // This would switch to date tab in a full implementation
                    Navigator.pop(context);
                    _showCalendarWidget();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Demo buttons for the new widget classes
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.orange),
            onPressed: _showCalendarWidget,
            tooltip: 'Calendar Widget Demo',
          ),
          IconButton(
            icon: Icon(Icons.access_time, color: Colors.blue),
            onPressed: _showTimeSlotWidget,
            tooltip: 'Time Slot Widget Demo',
          ),
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
  }
}
