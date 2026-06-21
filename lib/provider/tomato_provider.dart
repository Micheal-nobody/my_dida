import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/model/entity/checklist.dart';
import 'package:my_dida/model/entity/custom_tomato.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/entity/tomato_record.dart';
import 'package:my_dida/model/domain/tomato_ticker.dart';
import 'package:my_dida/repository/custom_tomato_repository.dart';
import 'package:my_dida/repository/tomato_record_repository.dart';
import 'package:my_dida/services/notification_service.dart';
import 'package:my_dida/repository/task_repository.dart';

export 'package:my_dida/model/domain/tomato_ticker.dart'
    show
        TomatoStatus,
        TomatoEvent,
        TomatoTickEvent,
        TomatoFocusCompleteEvent,
        TomatoBreakCompleteEvent,
        TomatoAbandonEvent,
        TomatoStatusChangedEvent;

class TomatoProvider with ChangeNotifier {
  TomatoProvider({
    TomatoRecordRepository? tomatoRecordRepository,
    CustomTomatoRepository? customTomatoRepository,
    TaskRepository? taskRepository,
    NotificationService? notificationService,
    TomatoTicker? ticker,
  }) : _tomatoRecordRepository =
           tomatoRecordRepository ?? getIt<TomatoRecordRepository>(),
       _customTomatoRepository =
           customTomatoRepository ?? getIt<CustomTomatoRepository>(),
       _taskRepository = taskRepository ?? getIt<TaskRepository>(),
       _notificationService =
           notificationService ?? getIt<NotificationService>() {
    _ticker = ticker ?? TomatoTicker();
    _tickerSubscription = _ticker.eventStream.listen(_handleTomatoEvent);
    loadCustomTomatoes();
  }

  final TomatoRecordRepository _tomatoRecordRepository;
  final CustomTomatoRepository _customTomatoRepository;
  final TaskRepository _taskRepository;
  final NotificationService _notificationService;

  late final TomatoTicker _ticker;
  StreamSubscription<TomatoEvent>? _tickerSubscription;
  Timer? _timer;
  Task? _associatedTask;
  CustomTomato? _activeCustomTomato;
  List<CustomTomato> _customTomatoes = [];
  bool _isDisposed = false;

  // 1. 完全对外的属性代理，兼容现有 UI 获取状态
  int get duration => _ticker.duration;
  int get totalDuration => _ticker.totalDuration;
  TomatoStatus get status => _ticker.status;
  bool get isRunning => _ticker.isRunning;
  bool get isPaused => _ticker.isPaused;
  int get completedTomatoCount => _ticker.completedTomatoCount;
  DateTime? get startTime => _ticker.startTime;
  Task? get associatedTask => _associatedTask;
  CustomTomato? get activeCustomTomato => _activeCustomTomato;
  List<CustomTomato> get customTomatoes => _customTomatoes;

  // 配置项代理
  int get focusMinutes => _ticker.focusMinutes;
  int get shortBreakMinutes => _ticker.shortBreakMinutes;
  int get longBreakMinutes => _ticker.longBreakMinutes;
  int get longBreakInterval => _ticker.longBreakInterval;
  bool get autoStartBreak => _ticker.autoStartBreak;
  bool get autoStartFocus => _ticker.autoStartFocus;
  bool get autoCompletedTask => _ticker.autoCompletedTask;

  // 允许在设置面板读取和修改，重置时代理到底层 Ticker
  set focusMinutes(int val) => updateSettings(focusMin: val);
  set shortBreakMinutes(int val) => updateSettings(shortMin: val);
  set longBreakMinutes(int val) => updateSettings(longMin: val);
  set longBreakInterval(int val) => updateSettings(interval: val);
  set autoStartBreak(bool val) => updateSettings(autoBreak: val);
  set autoStartFocus(bool val) => updateSettings(autoFocus: val);
  set autoCompletedTask(bool val) => updateSettings(autoComp: val);

  String get statusText {
    switch (status) {
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

  // 2. 核心的事件监听器，用于集中处理 I/O 副作用
  Future<void> _handleTomatoEvent(TomatoEvent event) async {
    if (event is TomatoTickEvent) {
      notifyListeners();
    } else if (event is TomatoStatusChangedEvent) {
      notifyListeners();
    } else if (event is TomatoFocusCompleteEvent) {
      _stopTimer();

      // 副作用：保存专注成功记录至 Isar
      final record = TomatoRecord(
        taskId: _associatedTask?.id,
        customTomatoId: _activeCustomTomato?.id,
        taskName: _activeCustomTomato != null ? _activeCustomTomato!.name : _associatedTask?.name,
        categoryName: _activeCustomTomato != null ? '自定义番茄钟' : await _getChecklistName(_associatedTask?.checklistId),
        startTime: event.startTime,
        endTime: event.endTime,
        durationMinutes: event.durationMinutes,
        isCompleted: true,
      );
      await _tomatoRecordRepository.insert(record);

      // 副作用：自动完成关联任务
      if (autoCompletedTask && _associatedTask != null) {
        await _taskRepository.updateTaskIsDone(_associatedTask!, true);
        _associatedTask = null;
      }

      // 副作用：本地推送通知弹出
      await _sendNotification('专注完成！', '太棒了，您完成了一个番茄钟。');

      // 重启计时驱动（若 autoStartBreak 开启，_ticker.isRunning 将在 _onTimeComplete 内自动设为 true）
      if (_ticker.isRunning) {
        _startTimer();
      }
      notifyListeners();
    } else if (event is TomatoBreakCompleteEvent) {
      _stopTimer();

      // 副作用：本地推送通知弹出
      await _sendNotification('休息结束！', '是时候开始新一轮的专注了。');

      if (_ticker.isRunning) {
        _startTimer();
      }
      notifyListeners();
    } else if (event is TomatoAbandonEvent) {
      _stopTimer();

      // 副作用：保存未完成记录至 Isar
      final record = TomatoRecord(
        taskId: _associatedTask?.id,
        customTomatoId: _activeCustomTomato?.id,
        taskName: _activeCustomTomato != null ? _activeCustomTomato!.name : _associatedTask?.name,
        categoryName: _activeCustomTomato != null ? '自定义番茄钟' : await _getChecklistName(_associatedTask?.checklistId),
        startTime: event.startTime,
        endTime: event.endTime,
        durationMinutes: event.durationMinutes,
        isCompleted: false,
      );
      await _tomatoRecordRepository.insert(record);
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _ticker.tick(1);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // 3. 兼容现有界面的方法代理
  void start() {
    _ticker.start();
    _startTimer();
    notifyListeners();
  }

  void pause() {
    _ticker.pause();
    _stopTimer();
    notifyListeners();
  }

  void resume() {
    _ticker.resume();
    _startTimer();
    notifyListeners();
  }

  Future<void> abandon() async {
    _ticker
        .abandon(); // 内部抛出 TomatoAbandonEvent，在 _handleTomatoEvent 中执行 Isar 副作用
  }

  void skipBreak() {
    _ticker.skipBreak();
    _stopTimer();
    notifyListeners();
  }

  void selectFocus() {
    _ticker.selectFocus();
    notifyListeners();
  }

  void selectShortBreak() {
    _ticker.selectShortBreak();
    notifyListeners();
  }

  void selectLongBreak() {
    _ticker.selectLongBreak();
    notifyListeners();
  }

  void setAssociatedTask(Task? task) {
    _associatedTask = task;
    if (task != null) {
      _activeCustomTomato = null;
      _ticker.updateSettings(focusMin: 25);
    }
    notifyListeners();
  }

  Future<void> loadCustomTomatoes() async {
    _customTomatoes = await _customTomatoRepository.getAll();
    notifyListeners();
  }

  Future<void> addCustomTomato(String name, int focusMinutes) async {
    final tomato = CustomTomato(name: name, focusMinutes: focusMinutes);
    await _customTomatoRepository.insert(tomato);
    await loadCustomTomatoes();
  }

  Future<void> deleteCustomTomato(int id) async {
    if (_activeCustomTomato?.id == id) {
      _activeCustomTomato = null;
      _ticker.updateSettings(focusMin: 25);
    }
    await _customTomatoRepository.deleteById(id);
    await loadCustomTomatoes();
  }

  void setActiveCustomTomato(CustomTomato? tomato) {
    _activeCustomTomato = tomato;
    if (tomato != null) {
      _ticker.updateSettings(focusMin: tomato.focusMinutes);
      _associatedTask = null;
    } else {
      _ticker.updateSettings(focusMin: 25);
    }
    notifyListeners();
  }

  Future<int> getCustomTomatoTodayMinutes(int customTomatoId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final records = await _tomatoRecordRepository.getRecordsInPeriod(start, end);
    int total = 0;
    for (var r in records) {
      if (r.customTomatoId == customTomatoId && r.isCompleted) {
        total += r.durationMinutes;
      }
    }
    return total;
  }

  Future<Map<String, dynamic>> getCustomTomatoTotalStats(int customTomatoId) async {
    final records = await _tomatoRecordRepository.selectAll();
    int completedCount = 0;
    int totalMinutes = 0;
    for (var r in records) {
      if (r.customTomatoId == customTomatoId && r.isCompleted) {
        completedCount++;
        totalMinutes += r.durationMinutes;
      }
    }
    return {
      'completedCount': completedCount,
      'totalMinutes': totalMinutes,
    };
  }

  void updateSettings({
    int? focusMin,
    int? shortMin,
    int? longMin,
    int? interval,
    bool? autoBreak,
    bool? autoFocus,
    bool? autoComp,
  }) {
    _stopTimer();
    _ticker.updateSettings(
      focusMin: focusMin,
      shortMin: shortMin,
      longMin: longMin,
      interval: interval,
      autoBreak: autoBreak,
      autoFocus: autoFocus,
      autoComp: autoComp,
    );
    notifyListeners();
  }

  // 数据库相关的方法保持不变 (例如 getSummaryData、getWeeklyRecords 等方法)
  Future<Map<String, dynamic>> getSummaryData(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final records = await _tomatoRecordRepository.getRecordsInPeriod(
      start,
      end,
    );

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

  Future<List<TomatoRecord>> getWeeklyRecords(DateTime date) async {
    final start = date.subtract(Duration(days: date.weekday - 1));
    final weekStart = DateTime(start.year, start.month, start.day);
    final end = weekStart.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
    return _tomatoRecordRepository.getRecordsInPeriod(weekStart, end);
  }

  Future<List<TomatoRecord>> getMonthlyRecords(DateTime date) async {
    final start = DateTime(date.year, date.month, 1);
    final nextMonth = date.month == 12
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    final end = nextMonth.subtract(const Duration(seconds: 1));
    return _tomatoRecordRepository.getRecordsInPeriod(start, end);
  }

  Future<List<TomatoRecord>> getAllRecords() async {
    return _tomatoRecordRepository.selectAll();
  }

  Future<void> deleteRecord(int id) async {
    await _tomatoRecordRepository.deleteById(id);
    notifyListeners();
  }

  Future<String?> _getChecklistName(int? checklistId) async {
    if (checklistId == null) return null;
    try {
      final isar = getIt<Isar>();
      final checklist = await isar.collection<Checklist>().get(checklistId);
      return checklist?.name;
    } catch (_) {
      return null;
    }
  }

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
      await _notificationService.plugin.show(888, title, body, details);
    } catch (e) {
      // 忽略通知发送失败
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopTimer();
    _tickerSubscription?.cancel();
    _ticker.dispose();
    super.dispose();
  }
}
