import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_dida/components/calendar/calendar_widgets/CalendarDateHeader.dart';
import 'package:my_dida/components/calendar/calendar_widgets/CalendarNoTimeTaskArea.dart';
import 'package:my_dida/components/calendar/calendar_widgets/CalendarScrollableContent.dart';
import 'package:my_dida/components/common/CustomFloatingActionButton.dart';
import 'package:my_dida/components/dialogs/DatePickerDialog.dart';
import 'package:my_dida/model/entity/Habit.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/model/vo/task_calendar_view_data.dart';
import 'package:my_dida/provider/habit_provider.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:my_dida/utils/PerformanceMonitor.dart';
import 'package:my_dida/utils/RRuleUtil.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final DateTime _currentDate;
  late DateTime _selectedDate;
  int _dateRange = 3; // 3-day view by default
  Map<DateTime, List<Task>> _tasksForDates = {};
  Map<DateTime, List<Task>> _futureTasks = {}; // 未来任务
  Map<DateTime, List<Habit>> _habitsForDates = {}; // 习惯数据
  late TaskProvider _taskProvider;
  late HabitProvider _habitProvider;

  // 每个日期的重复任务分页限制（每次 +5）
  final Map<DateTime, int> _rruleBatchLimit = {};

  // 每个日期是否还有更多重复任务
  final Map<DateTime, bool> _rruleHasMore = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentDate = now;
    _selectedDate = now;
    _taskProvider = Provider.of<TaskProvider>(context, listen: false);
    _habitProvider = Provider.of<HabitProvider>(context, listen: false);
    _loadTasksForVisibleDates();

    // 添加TaskProvider监听器
    _taskProvider.addListener(_onTaskProviderChanged);
    // 添加HabitProvider监听器
    _habitProvider.addListener(_onTaskProviderChanged);
  }

  @override
  void dispose() {
    _taskProvider.removeListener(_onTaskProviderChanged);
    _habitProvider.removeListener(_onTaskProviderChanged);
    super.dispose();
  }

  void _onTaskProviderChanged() {
    // 当TaskProvider发生变化时，重新加载任务数据
    _loadTasksForVisibleDates();
  }

  List<DateTime> get _visibleDates {
    final List<DateTime> dates = [];
    // 从选中的日期开始显示
    final DateTime startDate = _selectedDate;

    for (int i = 0; i < _dateRange; i++) {
      dates.add(startDate.add(Duration(days: i)));
    }
    return dates;
  }

  Future<void> _loadTasksForVisibleDates() async {
    await PerformanceMonitor.timeAsyncOperation('calendar_load_tasks', () async {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      final habitsMap = <DateTime, List<Habit>>{};

      final visibleDates = _visibleDates;
      if (visibleDates.isEmpty) return;

      final taskViewData = await PerformanceMonitor.timeAsyncOperation(
        'load_calendar_task_view',
        () => _taskProvider.loadCalendarTaskViewData(
          visibleDates: visibleDates,
          rruleBatchLimit: _rruleBatchLimit,
        ),
      );

      await PerformanceMonitor.timeAsyncOperation(
        'load_all_habits',
        habitProvider.loadAllHabits,
      );
      final allHabits = habitProvider.habits;

      for (final date in visibleDates) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final List<Habit> habitsForDate = [];

        for (final habit in allHabits) {
          // 检查习惯是否应该在当前日期显示
          bool shouldShowToday = false;

          if (habit.rrule != null && habit.rrule!.isNotEmpty) {
            // 使用习惯的startDate作为起始时间
            final startTime = DateTime(
              habit.startDate.year,
              habit.startDate.month,
              habit.startDate.day,
              habit.remindTime.hour,
              habit.remindTime.minute,
            );

            // Optimized: Use range-based RRule method for habits too
            final rangeStart = normalizedDate;
            final rangeEnd = normalizedDate.add(const Duration(days: 1));
            final occurrences = PerformanceMonitor.timeOperation(
              'rrule_habit_processing',
              () => RRuleUtil.getOccurrencesInRange(
                startTime,
                habit.rrule!,
                rangeStart,
                rangeEnd,
              ),
            );

            // 如果当前日期在发生日期中，则应该显示
            shouldShowToday = occurrences.any(
              (d) => d.isAtSameMomentAs(normalizedDate),
            );
          } else {
            // 如果没有rrule，每天都显示
            shouldShowToday = true;
          }

          if (shouldShowToday) {
            // 检查习惯是否已完成，已完成的不渲染
            final isCompleted = habitProvider.isTodayCompleted(habit);
            if (!isCompleted) {
              habitsForDate.add(habit);
            }
          }
        }

        habitsMap[normalizedDate] = habitsForDate;
      }

      setState(() {
        _applyTaskViewData(taskViewData);
        _habitsForDates = habitsMap;
      });
    });

    // Print performance report in debug mode
    PerformanceMonitor.printReport();
  }

  void _loadMoreRRuleForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final current = _rruleBatchLimit[normalizedDate] ?? 5;
    _rruleBatchLimit[normalizedDate] = current + 5;
    _loadTasksForVisibleDates();
  }

  void _applyTaskViewData(TaskCalendarViewData taskViewData) {
    _tasksForDates = taskViewData.tasksForDates;
    _futureTasks = taskViewData.futureTasks;
    _rruleHasMore
      ..clear()
      ..addAll(taskViewData.rruleHasMore);
    for (final date in _visibleDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      _rruleBatchLimit.putIfAbsent(normalizedDate, () => 5);
    }
  }

  void _showDatePicker() {
    showDialog(
      context: context,
      builder: (context) => CustomDatePickerDialog(
        selectedDate: _selectedDate,
        onDateSelected: (date) {
          setState(() {
            _selectedDate = date;
          });
          _loadTasksForVisibleDates();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    // 1. AppBar 区域：左侧是当前月份
    appBar: AppBar(
      title: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = _currentDate;
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
          tooltip: '刷新',
          icon: Icon(Icons.refresh, color: Colors.grey[600]),
          onPressed: _loadTasksForVisibleDates,
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
        const SizedBox(width: 8),
        IconButton(
          tooltip: '选择日期',
          icon: Icon(Icons.calendar_today, color: Colors.grey[600]),
          onPressed: _showDatePicker,
        ),
        const SizedBox(width: 16),
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

        // 根据 isAllDay 判断是否显示无具体时间任务区域；
        // 若 isAllDay 为 true，则显示在无具体时间任务区域，并且具体时间区域不再显示
        // 3. 无具体时间任务区域（固定在顶部；isAllDay 视为无具体时间）
        CalendarNoTimeTaskArea(
          visibleDates: _visibleDates,
          tasksForDates: _tasksForDates,
          habitsForDates: _habitsForDates,
          selectedDate: _selectedDate,
        ),

        // 4. 主要内容区域
        Expanded(
          child: GestureDetector(
            onPanEnd: (details) {
              // 检测水平拖动
              if (details.velocity.pixelsPerSecond.dx.abs() >
                  details.velocity.pixelsPerSecond.dy.abs()) {
                // 水平拖动速度大于垂直拖动速度
                if (details.velocity.pixelsPerSecond.dx > 80) {
                  // 向右拖动，减去1天
                  setState(() {
                    _selectedDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    );
                  });
                  _loadTasksForVisibleDates();
                } else if (details.velocity.pixelsPerSecond.dx < -80) {
                  // 向左拖动，加上1天
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                  _loadTasksForVisibleDates();
                }
              }
            },
            child: CalendarScrollableContent(
              selectedDate: _selectedDate,
              visibleDates: _visibleDates,
              tasksForDates: _tasksForDates,
              habitsForDates: _habitsForDates,
              futureTasks: _futureTasks,
              rruleHasMore: _rruleHasMore,
              onLoadMoreRRule: _loadMoreRRuleForDate,
            ),
          ),
        ),
      ],
    ),

    // 3. FloatingActionButton：用于添加任务
    floatingActionButton: const CustomFloatingActionButton(),
  );
}
