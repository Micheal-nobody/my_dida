import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/calendar/models/calendar_page_config.dart';
import 'package:my_dida/features/calendar/providers/calendar_page_provider.dart';
import 'package:my_dida/features/calendar/widgets/calendar_all_day_task_section.dart';
import 'package:my_dida/features/calendar/widgets/calendar_entry_widgets.dart';
import 'package:my_dida/features/calendar/widgets/calendar_visible_range_dialog.dart';
import 'package:my_dida/features/calendar/widgets/calendar_widgets/calendar_date_header.dart';
import 'package:my_dida/features/calendar/widgets/calendar_widgets/calendar_scrollable_content.dart';
import 'package:my_dida/features/calendar/widgets/calendar_widgets/calendar_task_list_bottom.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/widgets/add_task_bottom_sheet.dart';
import 'package:my_dida/shared/widgets/datetime/calendar_grid.dart';
import 'package:my_dida/shared/widgets/datetime/custom_date_picker_dialog.dart';
import 'package:my_dida/shared/widgets/datetime/time_axis_column.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const double _timeAxisWidth = 60.0;
  static const double _timeAxisGap = 8.0;

  DateTime? _dragPreviewTime;
  double _timeContentScrollOffset = 0;

  void _showDatePicker(DateTime selectedDate, CalendarPageProvider provider) {
    showDialog(
      context: context,
      builder: (context) => CustomDatePickerDialog(
        selectedDate: selectedDate,
        onDateSelected: provider.setSelectedDate,
      ),
    );
  }

  List<Task> _getSelectedDateTasks(
    DateTime selectedDate,
    CalendarPageProvider provider,
  ) {
    final normalizedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final tasks = provider.tasksForDates[normalizedDate] ?? [];
    final allDayTasks = provider.allDayTasksForDates[normalizedDate] ?? [];
    return [...allDayTasks, ...tasks];
  }

  Widget _buildCalendarDay(
    BuildContext context,
    DateTime date,
    bool isSelected,
  ) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final provider = Provider.of<CalendarPageProvider>(context, listen: false);

    return CalendarGridDay(
      date: date,
      isSelected: isSelected,
      tasks: provider.tasksForDates[normalizedDate] ?? [],
      allDayTasks: provider.allDayTasksForDates[normalizedDate] ?? [],
    );
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

  List<int> _getActiveHours(CalendarPageProvider provider) {
    final config = provider.config;
    if (!config.isTimeFolded) {
      return List.generate(24, (i) => i);
    }

    final activeHours = <int>{};
    for (final date in provider.visibleDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final tasks = provider.tasksForDates[normalizedDate] ?? [];
      for (final task in tasks) {
        if (task.startTime != null && !task.isAllDay) {
          activeHours.add(task.startTime!.hour);
        }
      }
      final habits = provider.habitsForDates[normalizedDate] ?? [];
      for (final habit in habits) {
        activeHours.add(habit.remindTime.hour);
      }
    }

    if (activeHours.isEmpty) {
      return List.generate(10, (i) => 9 + i);
    }

    final sorted = activeHours.toList()..sort();
    return sorted;
  }

  Widget _buildTimeAxisViewport(List<int> activeHours) => ClipRect(
    child: IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, -_timeContentScrollOffset),
        child: OverflowBox(
          minHeight: 0.0,
          maxHeight: activeHours.length * 60.0,
          alignment: Alignment.topCenter,
          child: TimeAxisColumn(
            previewTime: _dragPreviewTime,
            hours: activeHours,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final calendarPageProvider = Provider.of<CalendarPageProvider>(context);
    final config = calendarPageProvider.config;
    final selectedDate = calendarPageProvider.selectedDate;
    final activeHours = _getActiveHours(calendarPageProvider);
    final dynamicTimeAreaHeight = activeHours.length * 60.0;

    final colorTheme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showDatePicker(selectedDate, calendarPageProvider),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('yyyy年M月').format(selectedDate),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorTheme.textPrimary,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: colorTheme.textSecondary),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: Icon(Icons.refresh, color: colorTheme.textSecondary),
            onPressed: calendarPageProvider.loadCalendarData,
          ),
          IconButton(
            tooltip: '视图模式',
            icon: Icon(
              config.viewMode == CalendarViewMode.month
                  ? Icons.view_module
                  : (config.viewMode == CalendarViewMode.week
                        ? Icons.view_week
                        : Icons.view_day),
              color: colorTheme.textSecondary,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          '切换日历视图',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.view_module,
                          color: colorTheme.primary,
                        ),
                        title: const Text('月视图'),
                        trailing: config.viewMode == CalendarViewMode.month
                            ? Icon(Icons.check, color: colorTheme.primary)
                            : null,
                        onTap: () {
                          calendarPageProvider.updateConfig(
                            viewMode: CalendarViewMode.month,
                          );
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.view_week,
                          color: colorTheme.primary,
                        ),
                        title: const Text('周视图 (7天)'),
                        trailing: config.viewMode == CalendarViewMode.week
                            ? Icon(Icons.check, color: colorTheme.primary)
                            : null,
                        onTap: () {
                          calendarPageProvider.updateConfig(
                            viewMode: CalendarViewMode.week,
                          );
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.view_day,
                          color: colorTheme.primary,
                        ),
                        title: const Text('3天视图'),
                        trailing: config.viewMode == CalendarViewMode.threeDay
                            ? Icon(Icons.check, color: colorTheme.primary)
                            : null,
                        onTap: () {
                          calendarPageProvider.updateConfig(
                            viewMode: CalendarViewMode.threeDay,
                          );
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorTheme.textSecondary),
            onSelected: (value) {
              if (value == 'visible_range') {
                CalendarVisibleRangeDialog.show(context);
              } else if (value == 'show_completed') {
                calendarPageProvider.updateConfig(
                  showCompletedTasks: !config.showCompletedTasks,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'visible_range',
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: colorTheme.textSecondary),
                    const SizedBox(width: 8),
                    const Text('显示范围'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'show_completed',
                child: Row(
                  children: [
                    Icon(
                      config.showCompletedTasks
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: colorTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    const Text('显示已完成任务'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: config.viewMode == CalendarViewMode.month
          ? Column(
              children: [
                CalendarGrid(
                  selectedDate: selectedDate,
                  showHeader: false,
                  onDateSelected: calendarPageProvider.setSelectedDate,
                  dayBuilder: _buildCalendarDay,
                ),
                GestureDetector(
                  onTap: () {
                    calendarPageProvider.updateConfig(
                      isTimeFolded: !config.isTimeFolded,
                    );
                  },
                  child: Container(
                    height: 12,
                    width: double.infinity,
                    color: colorTheme.surface,
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorTheme.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CalendarTaskListBottom(
                    selectedDate: selectedDate,
                    tasks: _getSelectedDateTasks(
                      selectedDate,
                      calendarPageProvider,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                CalendarDateHeader(
                  selectedDate: selectedDate,
                  dateRange: config.viewMode == CalendarViewMode.week ? 7 : 3,
                  tasksForDates: calendarPageProvider.tasksForDates,
                  onDateSelected: calendarPageProvider.setSelectedDate,
                ),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: _timeAxisWidth),
                    SizedBox(width: _timeAxisGap),
                    Expanded(child: CalendarAllDayTaskSection()),
                  ],
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _timeAxisWidth,
                        child: _buildTimeAxisViewport(activeHours),
                      ),
                      const SizedBox(width: _timeAxisGap),
                      Expanded(
                        child: CalendarScrollableContent(
                          timeAreaHeight: dynamicTimeAreaHeight,
                          onDragPreviewChanged: _handleDragPreviewChanged,
                          onScrollOffsetChanged:
                              _handleTimeContentScrollOffsetChanged,
                          hours: activeHours,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorTheme.primary,
        child: Icon(Icons.add, color: colorTheme.textOnPrimary),
        onPressed: () {
          AddTaskBottomSheet.show(
            context: context,
            initTask: Task(name: '', isAllDay: true, startTime: selectedDate),
          );
        },
      ),
    );
  }
}
