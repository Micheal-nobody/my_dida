import 'package:flutter/material.dart';
import 'package:my_dida/component/CustomFloatingActionButton.dart';
import 'package:my_dida/component/StatelessWidget/CalendarDateHeader.dart';
import 'package:my_dida/component/StatelessWidget/CalendarScrollableContent.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/provider/TaskProvider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:my_dida/utils/RRuleUtil.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  int _dateRange = 3; // 3-day view by default
  bool _showCompleted = false; // 默认不显示已完成任务
  Map<DateTime, List<Task>> _tasksForDates = {};
  late TaskProvider _taskProvider;
  // 每个日期的重复任务分页限制（每次 +5）
  final Map<DateTime, int> _rruleBatchLimit = {};
  // 每个日期是否还有更多重复任务
  final Map<DateTime, bool> _rruleHasMore = {};

  @override
  void initState() {
    super.initState();
    _taskProvider = Provider.of<TaskProvider>(context, listen: false);
    _loadTasksForVisibleDates();

    // 添加TaskProvider监听器
    _taskProvider.addListener(_onTaskProviderChanged);
  }

  @override
  void dispose() {
    _taskProvider.removeListener(_onTaskProviderChanged);
    super.dispose();
  }

  void _onTaskProviderChanged() {
    // 当TaskProvider发生变化时，重新加载任务数据
    _loadTasksForVisibleDates();
  }

  List<DateTime> get _visibleDates {
    List<DateTime> dates = [];
    for (int i = 0; i < _dateRange; i++) {
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

    // 预计算可见日期（标准化到 00:00）
    // 预计算可见日期（标准化到 00:00）
    // 保留为未来扩展使用（如窗口外预取）；当前逻辑不直接使用
    // final List<DateTime> visibleDates = _visibleDates
    //     .map((d) => DateTime(d.year, d.month, d.day))
    //     .toList();

    for (final date in _visibleDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // 1) 非重复任务（rrule == null）
      final List<Task> baseTasksForDate = allTasks.where((task) {
        if (task.rrule != null && task.rrule!.isNotEmpty) return false;
        if (task.startTime == null) {
          // 无时间任务显示在今天列
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

      // 2) 重复任务（根据 rrule 展开，仅将发生在可见日期集合中的加入）
      final List<Task> rruleTasksForDate = [];
      for (final task in allTasks) {
        if (task.rrule == null || task.rrule!.isEmpty) continue;
        // 没有起始时间则无法展开
        if (task.startTime == null) continue;

        // 生成一定数量的后续发生日期，然后筛选出命中可见日期的
        // 这里使用一个保守上限（例如 365 次），考虑到我们只筛选可见日期（最多 7 天），性能可接受
        final occurrences = RRuleUtil.nextOccurrences(
          task.startTime!,
          task.rrule!,
          365,
        );

        // 如果当前 normalizedDate 在 occurrences 里，则将此任务实例化到该日期
        if (occurrences.any((d) => d.isAtSameMomentAs(normalizedDate))) {
          final DateTime instanceStart = DateTime(
            normalizedDate.year,
            normalizedDate.month,
            normalizedDate.day,
            task.startTime!.hour,
            task.startTime!.minute,
          );
          // 复制一个任务实例用于渲染（使用相同 id，不改数据库）
          final Task instance = Task(
            name: task.name,
            description: task.description,
            isDone: task.isDone,
            checkpoints: task.checkpoints,
            startTime: instanceStart,
            endTime: task.endTime,
            parentTaskId: task.parentTaskId,
            subTaskIds: task.subTaskIds,
            belongingBoxId: task.belongingBoxId,
            rrule: task.rrule,
          )..id = task.id;
          rruleTasksForDate.add(instance);
        }
      }

      // 3) 过滤是否展示已完成任务
      List<Task> combined = [...baseTasksForDate, ...rruleTasksForDate];
      if (!_showCompleted) {
        combined = combined.where((t) => !t.isDone).toList();
      }

      // 4) 对重复任务应用分页：每个日期最多显示 _rruleBatchLimit[date] 个重复任务
      final int limit = _rruleBatchLimit[normalizedDate] ?? 5;
      final List<Task> nonRRule = combined
          .where((t) => t.rrule == null || t.rrule!.isEmpty)
          .toList();
      final List<Task> rruleOnly = combined
          .where((t) => t.rrule != null && t.rrule!.isNotEmpty)
          .toList();

      // 排序以获得稳定显示（先按时间）
      nonRRule.sort((a, b) {
        final aT = a.startTime ?? DateTime(0);
        final bT = b.startTime ?? DateTime(0);
        return aT.compareTo(bT);
      });
      rruleOnly.sort((a, b) {
        final aT = a.startTime ?? DateTime(0);
        final bT = b.startTime ?? DateTime(0);
        return aT.compareTo(bT);
      });

      final bool hasMore = rruleOnly.length > limit;
      _rruleHasMore[normalizedDate] = hasMore;
      _rruleBatchLimit.putIfAbsent(normalizedDate, () => 5);

      final List<Task> paged = [...nonRRule, ...rruleOnly.take(limit)];

      tasksMap[normalizedDate] = paged;
    }

    setState(() {
      _tasksForDates = tasksMap;
    });
  }

  void _loadMoreRRuleForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final current = _rruleBatchLimit[normalizedDate] ?? 5;
    _rruleBatchLimit[normalizedDate] = current + 5;
    _loadTasksForVisibleDates();
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
          IconButton(
            tooltip: _showCompleted ? '隐藏已完成任务' : '显示已完成任务',
            icon: Icon(
              _showCompleted ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _showCompleted = !_showCompleted;
              });
              _loadTasksForVisibleDates();
            },
          ),
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
              rruleHasMore: _rruleHasMore,
              onLoadMoreRRule: _loadMoreRRuleForDate,
            ),
          ),
        ],
      ),

      // 3. FloatingActionButton：用于添加任务
      floatingActionButton: CustomFloatingActionButton(),
    );
  }
}
