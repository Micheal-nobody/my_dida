import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_dida/constants/app_constants.dart';
import 'package:my_dida/features/calendar_page/calendar_all_day_task_section.dart';
import 'package:my_dida/features/calendar_page/calendar_time_task_section.dart';
import 'package:my_dida/features/calendar_page/calendar_widgets/calendar_date_header.dart';
import 'package:my_dida/features/calendar_page/calendar_widgets/calendar_entry_card.dart';
import 'package:my_dida/features/dialogs/habit_check_in_dialog.dart';
import 'package:my_dida/features/task_detail/task_detail_page.dart';
import 'package:my_dida/model/entity/habit.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/task_calendar_view_data.dart';
import 'package:my_dida/provider/checklist_provider.dart';
import 'package:my_dida/provider/habit_provider.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:my_dida/shared/common/custom_floating_action_button.dart';
import 'package:my_dida/shared/widgets/datetime/custom_date_picker_dialog.dart';
import 'package:my_dida/shared/widgets/datetime/time_axis_column.dart';
import 'package:my_dida/utils/PerformanceMonitor.dart';
import 'package:my_dida/utils/RRuleUtil.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const double _timeAxisWidth = 60.0;
  static const double _timeAxisGap = 8.0;
  static const double _timeAreaHeight = 1440.0;
  static const double _timeAxisSpacerHeight = 4000.0;
  static const double _timedEntryHeight = 15.0;
  static const double _allDayEntryHeight = 28.0;

  late final DateTime _currentDate;
  late DateTime _selectedDate;
  int _dateRange = 3;
  Map<DateTime, List<Task>> _tasksForDates = {};
  Map<DateTime, List<Task>> _allDayTasksForDates = {};
  List<Task> _crossDayTasks = [];
  Map<DateTime, int> _crossDayTaskCountForDates = {};
  Map<DateTime, List<Task>> _futureTasks = {};
  Map<DateTime, List<Habit>> _habitsForDates = {};
  DateTime? _dragPreviewTime;
  double _timeContentScrollOffset = 0;
  late TaskProvider _taskProvider;
  late HabitProvider _habitProvider;

  final Map<DateTime, int> _rruleBatchLimit = {};
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
    _taskProvider.addListener(_onTaskProviderChanged);
    _habitProvider.addListener(_onTaskProviderChanged);
  }

  @override
  void dispose() {
    _taskProvider.removeListener(_onTaskProviderChanged);
    _habitProvider.removeListener(_onTaskProviderChanged);
    super.dispose();
  }

  void _onTaskProviderChanged() {
    _loadTasksForVisibleDates();
  }

  List<DateTime> get _visibleDates {
    final dates = <DateTime>[];
    final startDate = _selectedDate;

    for (var index = 0; index < _dateRange; index++) {
      dates.add(startDate.add(Duration(days: index)));
    }
    return dates;
  }

  Future<void> _loadTasksForVisibleDates() async {
    await PerformanceMonitor.timeAsyncOperation(
      'calendar_load_tasks',
      () async {
        final habitProvider = Provider.of<HabitProvider>(
          context,
          listen: false,
        );
        final habitsMap = <DateTime, List<Habit>>{};
        final visibleDates = _visibleDates;
        if (visibleDates.isEmpty) {
          return;
        }

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
          final habitsForDate = <Habit>[];

          for (final habit in allHabits) {
            var shouldShowToday = false;

            if (habit.rrule != null && habit.rrule!.isNotEmpty) {
              final startTime = DateTime(
                habit.startDate.year,
                habit.startDate.month,
                habit.startDate.day,
                habit.remindTime.hour,
                habit.remindTime.minute,
              );
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
              shouldShowToday = occurrences.any(
                (occurrence) => occurrence.isAtSameMomentAs(normalizedDate),
              );
            } else {
              shouldShowToday = true;
            }

            if (shouldShowToday && !habitProvider.isTodayCompleted(habit)) {
              habitsForDate.add(habit);
            }
          }

          habitsMap[normalizedDate] = habitsForDate;
        }

        setState(() {
          _applyTaskViewData(taskViewData);
          _habitsForDates = habitsMap;
        });
      },
    );

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
    _allDayTasksForDates = taskViewData.allDayTasksForDates;
    _crossDayTasks = taskViewData.crossDayTasks;
    _crossDayTaskCountForDates = taskViewData.crossDayTaskCountForDates;
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
        onDateSelected: _setSelectedDate,
      ),
    );
  }

  void _setSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadTasksForVisibleDates();
  }

  void _handleDragPreviewChanged(DateTime? previewTime) {
    if (_dragPreviewTime == previewTime) {
      return;
    }

    setState(() {
      _dragPreviewTime = previewTime;
    });
  }

  void _handleTimeContentScrollOffsetChanged(double offset) {
    if ((_timeContentScrollOffset - offset).abs() < 0.5) {
      return;
    }

    setState(() {
      _timeContentScrollOffset = offset;
    });
  }

  Color _getTaskColor(BuildContext context, Task task) {
    final checklistProvider = Provider.of<ChecklistProvider>(
      context,
      listen: false,
    );
    final checklist = checklistProvider.allCheckLists.firstWhere(
      (item) => item.id == task.checklistId,
      orElse: () => AppConstants.defaultCheckList,
    );
    return checklist.color;
  }

  Widget _buildTimedTaskEntry(
    BuildContext context, {
    required Task task,
    required double columnWidth,
  }) {
    if (task.startTime == null) {
      return const SizedBox.shrink();
    }

    final taskColor = _getTaskColor(context, task);

    Widget buildCard({
      required Color backgroundColor,
      Color? borderColor,
      required VoidCallback onPressed,
    }) => SizedBox(
      width: columnWidth,
      height: _timedEntryHeight,
      child: CalendarEntryCard(
        text: task.name,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        onPressed: onPressed,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        opacity: task.isDone ? 0.4 : 1,
      ),
    );

    return Draggable<Task>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: buildCard(
          backgroundColor: taskColor.withValues(alpha: 0.9),
          onPressed: () {},
        ),
      ),
      childWhenDragging: buildCard(
        backgroundColor: taskColor.withValues(alpha: 0.3),
        borderColor: taskColor,
        onPressed: () {},
      ),
      child: buildCard(
        backgroundColor: taskColor.withValues(alpha: 0.8),
        onPressed: () {
          TaskDetailPage.show(context, task);
        },
      ),
    );
  }

  Widget _buildTimedHabitEntry(
    BuildContext context, {
    required Habit habit,
    required double columnWidth,
  }) => SizedBox(
    width: columnWidth,
    child: CalendarEntryCard(
      text: habit.name,
      backgroundColor: Colors.orange.withValues(alpha: 0.8),
      onPressed: () {
        HabitCheckInDialog.show(context: context, habit: habit);
      },
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    ),
  );

  Widget _buildAllDayTaskEntry(
    BuildContext context, {
    required Task task,
    required double columnWidth,
    required int stackIndex,
    required double availableHeight,
    required int displayedCount,
    required bool isCrossDay,
    double left = 0,
    double? width,
  }) {
    final taskColor = _getTaskColor(context, task);

    if (isCrossDay) {
      return Positioned(
        left: left,
        top: stackIndex * _allDayEntryHeight,
        width: width ?? columnWidth,
        height: _allDayEntryHeight,
        child: CalendarEntryCard(
          text: task.name,
          backgroundColor: taskColor.withValues(alpha: 0.9),
          onPressed: () {
            TaskDetailPage.show(context, task);
          },
          padding: const EdgeInsets.symmetric(horizontal: 6),
          borderRadius: 6,
          alignment: Alignment.centerLeft,
          textStyle: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          opacity: task.isDone ? 0.4 : 1,
        ),
      );
    }

    final taskCount = displayedCount.clamp(1, 6);
    const taskSpacing = 1.0;
    final totalSpacing = (taskCount - 1) * taskSpacing;
    final taskHeight = (availableHeight - totalSpacing) / taskCount;
    final topPosition = stackIndex * (taskHeight + taskSpacing);

    Widget buildCard({
      required Color backgroundColor,
      Color? borderColor,
      required VoidCallback onPressed,
    }) => SizedBox(
      width: width ?? columnWidth,
      height: taskHeight,
      child: CalendarEntryCard(
        text: task.name,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        onPressed: onPressed,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        useFittedBox: true,
        opacity: task.isDone ? 0.4 : 1,
      ),
    );

    return Positioned(
      top: topPosition,
      left: left,
      width: width ?? columnWidth,
      height: taskHeight,
      child: Draggable<Task>(
        data: task,
        feedback: Material(
          color: Colors.transparent,
          child: buildCard(
            backgroundColor: taskColor.withValues(alpha: 0.9),
            onPressed: () {},
          ),
        ),
        childWhenDragging: buildCard(
          backgroundColor: taskColor.withValues(alpha: 0.3),
          borderColor: taskColor,
          onPressed: () {},
        ),
        child: buildCard(
          backgroundColor: taskColor.withValues(alpha: 0.8),
          onPressed: () {
            TaskDetailPage.show(context, task);
          },
        ),
      ),
    );
  }

  Widget _buildAllDayHabitEntry(
    BuildContext context, {
    required Habit habit,
    required double columnWidth,
    required int stackIndex,
    required double availableHeight,
    required int displayedCount,
  }) {
    final topPosition = stackIndex * _allDayEntryHeight;
    if (topPosition + _allDayEntryHeight > availableHeight) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      top: topPosition,
      width: columnWidth,
      height: _allDayEntryHeight,
      child: CalendarEntryCard(
        text: habit.name,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        onPressed: () {
          HabitCheckInDialog.show(context: context, habit: habit);
        },
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        borderRadius: 6,
        alignment: Alignment.centerLeft,
        textStyle: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTimeAxisViewport() => ClipRect(
    child: IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, -_timeContentScrollOffset),
        child: Column(
          children: [
            TimeAxisColumn(
              width: _timeAxisWidth,
              previewTime: _dragPreviewTime,
            ),
            const SizedBox(height: _timeAxisSpacerHeight),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
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
        CalendarDateHeader(
          selectedDate: _selectedDate,
          dateRange: _dateRange,
          tasksForDates: _tasksForDates,
          onDateSelected: _setSelectedDate,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: _timeAxisWidth),
            const SizedBox(width: _timeAxisGap),
            Expanded(
              child: CalendarAllDayTaskSection(
                visibleDates: _visibleDates,
                habitsForDates: _habitsForDates,
                allDayTasksForDates: _allDayTasksForDates,
                crossDayTasks: _crossDayTasks,
                crossDayTaskCountForDates: _crossDayTaskCountForDates,
                allDayTaskEntryBuilder: _buildAllDayTaskEntry,
                allDayHabitEntryBuilder: _buildAllDayHabitEntry,
              ),
            ),
          ],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: _timeAxisWidth, child: _buildTimeAxisViewport()),
              const SizedBox(width: _timeAxisGap),
              Expanded(
                child: CalendarTimeTaskSection(
                  selectedDate: _selectedDate,
                  visibleDates: _visibleDates,
                  tasksForDates: _tasksForDates,
                  habitsForDates: _habitsForDates,
                  futureTasks: _futureTasks,
                  rruleHasMore: _rruleHasMore,
                  onLoadMoreRRule: _loadMoreRRuleForDate,
                  onDateChanged: _setSelectedDate,
                  timeAreaHeight: _timeAreaHeight,
                  timedTaskEntryBuilder: _buildTimedTaskEntry,
                  timedHabitEntryBuilder: _buildTimedHabitEntry,
                  onDragPreviewChanged: _handleDragPreviewChanged,
                  onScrollOffsetChanged: _handleTimeContentScrollOffsetChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    floatingActionButton: const CustomFloatingActionButton(),
  );
}
