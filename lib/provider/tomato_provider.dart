import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/model/entity/checklist.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/entity/tomato_record.dart';
import 'package:my_dida/repository/tomato_record_repository.dart';
import 'package:my_dida/services/notification_service.dart';
import 'package:my_dida/repository/task_repository.dart';

enum TomatoStatus { focus, shortBreak, longBreak, idle }

class TomatoProvider with ChangeNotifier {
  TomatoProvider({
    TomatoRecordRepository? tomatoRecordRepository,
    TaskRepository? taskRepository,
    NotificationService? notificationService,
  }) : _tomatoRecordRepository = tomatoRecordRepository ?? getIt<TomatoRecordRepository>(),
       _taskRepository = taskRepository ?? getIt<TaskRepository>(),
       _notificationService = notificationService ?? getIt<NotificationService>();

  final TomatoRecordRepository _tomatoRecordRepository;
  final TaskRepository _taskRepository;
  final NotificationService _notificationService;

  Timer? _timer;

  // 状态变量
  int _duration = 25 * 60;
  int _totalDuration = 25 * 60;
  TomatoStatus _status = TomatoStatus.idle;
  bool _isRunning = false;
  bool _isPaused = false;
  Task? _associatedTask;
  int _completedTomatoCount = 0; // 当前循环周期的番茄数
  DateTime? _startTime;

  // 设置参数
  int focusMinutes = 25;
  int shortBreakMinutes = 5;
  int longBreakMinutes = 15;
  int longBreakInterval = 4;
  bool autoStartBreak = true;
  bool autoStartFocus = false;
  bool autoCompletedTask = false; // 专注结束自动将关联任务设为已完成

  // 暴露属性
  int get duration => _duration;
  int get totalDuration => _totalDuration;
  TomatoStatus get status => _status;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  Task? get associatedTask => _associatedTask;
  int get completedTomatoCount => _completedTomatoCount;
  DateTime? get startTime => _startTime;

  String get statusText {
    switch (_status) {
      case TomatoStatus.focus:
        return '专注中';
      case TomatoStatus.shortBreak:
        return '短休中';
      case TomatoStatus.longBreak:
        return '长休中';
      case TomatoStatus.idle:
        return '准备专注';
    }
  }

  // 切换到专注时长
  void selectFocus() {
    if (_isRunning) return;
    _status = TomatoStatus.idle;
    _duration = focusMinutes * 60;
    _totalDuration = focusMinutes * 60;
    notifyListeners();
  }

  // 切换到短休时长
  void selectShortBreak() {
    if (_isRunning) return;
    _status = TomatoStatus.shortBreak;
    _duration = shortBreakMinutes * 60;
    _totalDuration = shortBreakMinutes * 60;
    notifyListeners();
  }

  // 切换到长休时长
  void selectLongBreak() {
    if (_isRunning) return;
    _status = TomatoStatus.longBreak;
    _duration = longBreakMinutes * 60;
    _totalDuration = longBreakMinutes * 60;
    notifyListeners();
  }

  // 关联任务
  void setAssociatedTask(Task? task) {
    _associatedTask = task;
    notifyListeners();
  }

  // 开始计时
  void start() {
    if (_isRunning) return;

    _timer?.cancel();
    _isRunning = true;
    _isPaused = false;
    _startTime = DateTime.now();

    if (_status == TomatoStatus.idle) {
      _status = TomatoStatus.focus;
      _duration = focusMinutes * 60;
      _totalDuration = focusMinutes * 60;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_duration > 0) {
        _duration--;
        notifyListeners();
      } else {
        _onTimeComplete();
      }
    });

    notifyListeners();
  }

  // 暂停计时
  void pause() {
    if (!_isRunning || _isPaused) return;
    _timer?.cancel();
    _isPaused = true;
    notifyListeners();
  }

  // 继续计时
  void resume() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_duration > 0) {
        _duration--;
        notifyListeners();
      } else {
        _onTimeComplete();
      }
    });

    notifyListeners();
  }

  // 放弃番茄钟
  Future<void> abandon() async {
    _timer?.cancel();
    final endTime = DateTime.now();

    // 如果是专注状态，写入已放弃记录
    if (_status == TomatoStatus.focus && _startTime != null) {
      final record = TomatoRecord(
        taskId: _associatedTask?.id,
        taskName: _associatedTask?.name,
        categoryName: await _getChecklistName(_associatedTask?.checklistId),
        startTime: _startTime!,
        endTime: endTime,
        durationMinutes: ((endTime.difference(_startTime!).inSeconds) / 60).clamp(0, focusMinutes).round(),
        isCompleted: false,
      );
      await _tomatoRecordRepository.insert(record);
    }

    _resetTimer();
  }

  // 跳过休息
  void skipBreak() {
    if (_status == TomatoStatus.shortBreak || _status == TomatoStatus.longBreak) {
      _resetTimer();
    }
  }

  // 获取特定天数的番茄总数和总时长
  Future<Map<String, dynamic>> getSummaryData(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final records = await _tomatoRecordRepository.getRecordsInPeriod(start, end);

    int completedCount = 0;
    int totalMinutes = 0;
    for (var r in records) {
      if (r.isCompleted) {
        completedCount++;
        totalMinutes += r.durationMinutes;
      }
    }
    return {
      'completedCount': completedCount,
      'totalMinutes': totalMinutes,
      'records': records,
    };
  }

  // 获取特定周的专注记录
  Future<List<TomatoRecord>> getWeeklyRecords(DateTime date) async {
    final start = date.subtract(Duration(days: date.weekday - 1));
    final weekStart = DateTime(start.year, start.month, start.day);
    final end = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return _tomatoRecordRepository.getRecordsInPeriod(weekStart, end);
  }

  // 获取特定月份的专注记录
  Future<List<TomatoRecord>> getMonthlyRecords(DateTime date) async {
    final start = DateTime(date.year, date.month, 1);
    final nextMonth = date.month == 12 ? DateTime(date.year + 1, 1, 1) : DateTime(date.year, date.month + 1, 1);
    final end = nextMonth.subtract(const Duration(seconds: 1));
    return _tomatoRecordRepository.getRecordsInPeriod(start, end);
  }

  // 获取历史所有专注记录
  Future<List<TomatoRecord>> getAllRecords() async {
    return _tomatoRecordRepository.selectAll();
  }

  // 删除某条专注记录
  Future<void> deleteRecord(int id) async {
    await _tomatoRecordRepository.deleteById(id);
    notifyListeners();
  }

  // 重置设置值
  void updateSettings({
    int? focusMin,
    int? shortMin,
    int? longMin,
    int? interval,
    bool? autoBreak,
    bool? autoFocus,
    bool? autoComp,
  }) {
    if (focusMin != null) focusMinutes = focusMin;
    if (shortMin != null) shortBreakMinutes = shortMin;
    if (longMin != null) longBreakMinutes = longMin;
    if (interval != null) longBreakInterval = interval;
    if (autoBreak != null) autoStartBreak = autoBreak;
    if (autoFocus != null) autoStartFocus = autoFocus;
    if (autoComp != null) autoCompletedTask = autoComp;

    _resetTimer();
  }

  // 内部：计时结束逻辑
  Future<void> _onTimeComplete() async {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    final endTime = DateTime.now();

    if (_status == TomatoStatus.focus) {
      // 写入成功记录到数据库
      final record = TomatoRecord(
        taskId: _associatedTask?.id,
        taskName: _associatedTask?.name,
        categoryName: await _getChecklistName(_associatedTask?.checklistId),
        startTime: _startTime ?? endTime.subtract(Duration(minutes: focusMinutes)),
        endTime: endTime,
        durationMinutes: focusMinutes,
        isCompleted: true,
      );
      await _tomatoRecordRepository.insert(record);

      _completedTomatoCount++;

      // 如果勾选了自动完成关联任务
      if (autoCompletedTask && _associatedTask != null) {
        await _taskRepository.updateTaskIsDone(_associatedTask!, true);
        _associatedTask = null;
      }

      // 弹出本地通知
      await _sendNotification('专注完成！', '太棒了，您完成了一个番茄钟。');

      // 切换到休息状态
      if (_completedTomatoCount >= longBreakInterval) {
        _status = TomatoStatus.longBreak;
        _duration = longBreakMinutes * 60;
        _totalDuration = longBreakMinutes * 60;
        _completedTomatoCount = 0; // 重置循环
      } else {
        _status = TomatoStatus.shortBreak;
        _duration = shortBreakMinutes * 60;
        _totalDuration = shortBreakMinutes * 60;
      }

      if (autoStartBreak) {
        start();
      }
    } else {
      // 休息结束
      await _sendNotification('休息结束！', '是时候开始新一轮的专注了。');

      _status = TomatoStatus.idle;
      _duration = focusMinutes * 60;
      _totalDuration = focusMinutes * 60;

      if (autoStartFocus) {
        start();
      }
    }

    notifyListeners();
  }

  // 获取清单名称快照
  Future<String?> _getChecklistName(int? checklistId) async {
    if (checklistId == null) return null;
    try {
      final isar = getIt<Isar>();
      final checklist = await isar.checklists.get(checklistId);
      return checklist?.name;
    } catch (_) {
      return null;
    }
  }

  // 发送本地推送通知
  Future<void> _sendNotification(String title, String body) async {
    try {
      final details = const NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro_reminders',
          '番茄钟提醒',
          channelDescription: '番茄工作法阶段流转提醒',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      );
      await _notificationService.plugin.show(
        888,
        title,
        body,
        details,
      );
    } catch (e) {
      // 忽略通知发送失败
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    _status = TomatoStatus.idle;
    _duration = focusMinutes * 60;
    _totalDuration = focusMinutes * 60;
    _startTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
