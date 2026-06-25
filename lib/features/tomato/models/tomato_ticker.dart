import 'dart:async';

enum TomatoStatus { focus, shortBreak, longBreak, idle }

abstract class TomatoEvent {}

/// 计时滴答事件，携带当前剩余秒数
class TomatoTickEvent extends TomatoEvent {
  TomatoTickEvent(this.remainingSeconds);
  final int remainingSeconds;
}

/// 专注完成事件
class TomatoFocusCompleteEvent extends TomatoEvent {
  TomatoFocusCompleteEvent({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  });
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
}

/// 休息（短休/长休）完成事件
class TomatoBreakCompleteEvent extends TomatoEvent {
  TomatoBreakCompleteEvent({required this.startTime, required this.endTime});
  final DateTime startTime;
  final DateTime endTime;
}

/// 放弃专注事件
class TomatoAbandonEvent extends TomatoEvent {
  TomatoAbandonEvent({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  });
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
}

/// 状态流转事件
class TomatoStatusChangedEvent extends TomatoEvent {
  TomatoStatusChangedEvent(this.oldStatus, this.newStatus);
  final TomatoStatus oldStatus;
  final TomatoStatus newStatus;
}

/// 纯 Dart 领域类，封装番茄钟倒计时状态机和时流规则，不依赖任何 Flutter 与 I/O 库
class TomatoTicker {
  TomatoTicker({
    int focusMinutes = 25,
    int shortBreakMinutes = 5,
    int longBreakMinutes = 15,
    int longBreakInterval = 4,
    bool autoStartBreak = true,
    bool autoStartFocus = false,
    bool autoCompletedTask = false,
    DateTime Function()? currentTimeProvider,
  }) : _focusMinutes = focusMinutes,
       _shortBreakMinutes = shortBreakMinutes,
       _longBreakMinutes = longBreakMinutes,
       _longBreakInterval = longBreakInterval,
       _autoStartBreak = autoStartBreak,
       _autoStartFocus = autoStartFocus,
       _autoCompletedTask = autoCompletedTask,
       _currentTimeProvider = currentTimeProvider ?? DateTime.now {
    _duration = _focusMinutes * 60;
    _totalDuration = _focusMinutes * 60;
  }

  final DateTime Function() _currentTimeProvider;
  final StreamController<TomatoEvent> _eventController =
      StreamController<TomatoEvent>.broadcast(sync: true);

  Stream<TomatoEvent> get eventStream => _eventController.stream;

  // 状态变量
  int _duration = 25 * 60;
  int _totalDuration = 25 * 60;
  TomatoStatus _status = TomatoStatus.idle;
  bool _isRunning = false;
  bool _isPaused = false;
  int _completedTomatoCount = 0;
  DateTime? _startTime;

  // 配置属性
  int _focusMinutes;
  int _shortBreakMinutes;
  int _longBreakMinutes;
  int _longBreakInterval;
  bool _autoStartBreak;
  bool _autoStartFocus;
  bool _autoCompletedTask;

  // 属性暴露
  int get duration => _duration;

  int get totalDuration => _totalDuration;

  TomatoStatus get status => _status;

  bool get isRunning => _isRunning;

  bool get isPaused => _isPaused;

  int get completedTomatoCount => _completedTomatoCount;

  DateTime? get startTime => _startTime;

  int get focusMinutes => _focusMinutes;

  int get shortBreakMinutes => _shortBreakMinutes;

  int get longBreakMinutes => _longBreakMinutes;

  int get longBreakInterval => _longBreakInterval;

  bool get autoStartBreak => _autoStartBreak;

  bool get autoStartFocus => _autoStartFocus;

  bool get autoCompletedTask => _autoCompletedTask;

  void selectFocus() {
    if (_isRunning) return;
    _updateStatus(TomatoStatus.idle);
    _duration = _focusMinutes * 60;
    _totalDuration = _focusMinutes * 60;
  }

  void selectShortBreak() {
    if (_isRunning) return;
    _updateStatus(TomatoStatus.shortBreak);
    _duration = _shortBreakMinutes * 60;
    _totalDuration = _shortBreakMinutes * 60;
  }

  void selectLongBreak() {
    if (_isRunning) return;
    _updateStatus(TomatoStatus.longBreak);
    _duration = _longBreakMinutes * 60;
    _totalDuration = _longBreakMinutes * 60;
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _isPaused = false;
    _startTime = _currentTimeProvider();

    if (_status == TomatoStatus.idle) {
      _updateStatus(TomatoStatus.focus);
      _duration = _focusMinutes * 60;
      _totalDuration = _focusMinutes * 60;
    }
  }

  void pause() {
    if (!_isRunning || _isPaused) return;
    _isPaused = true;
  }

  void resume() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
  }

  void abandon() {
    final endTime = _currentTimeProvider();
    final startT = _startTime;

    if (_status == TomatoStatus.focus && startT != null) {
      final elapsedSeconds = endTime.difference(startT).inSeconds;
      final durationMins = (elapsedSeconds / 60)
          .clamp(0.0, _focusMinutes.toDouble())
          .round();
      _eventController.add(
        TomatoAbandonEvent(
          startTime: startT,
          endTime: endTime,
          durationMinutes: durationMins,
        ),
      );
    }
    _reset();
  }

  void skipBreak() {
    if (_status == TomatoStatus.shortBreak ||
        _status == TomatoStatus.longBreak) {
      _reset();
    }
  }

  /// 外部滴答驱动，用于时间流失
  void tick([int seconds = 1]) {
    if (!_isRunning || _isPaused) return;

    if (_duration > seconds) {
      _duration -= seconds;
      _eventController.add(TomatoTickEvent(_duration));
    } else {
      _duration = 0;
      _eventController.add(TomatoTickEvent(0));
      _onTimeComplete();
    }
  }

  void _onTimeComplete() {
    _isRunning = false;
    _isPaused = false;
    final endTime = _currentTimeProvider();

    if (_status == TomatoStatus.focus) {
      final startT =
          _startTime ?? endTime.subtract(Duration(minutes: _focusMinutes));
      _eventController.add(
        TomatoFocusCompleteEvent(
          startTime: startT,
          endTime: endTime,
          durationMinutes: _focusMinutes,
        ),
      );

      _completedTomatoCount++;

      if (_completedTomatoCount >= _longBreakInterval) {
        _updateStatus(TomatoStatus.longBreak);
        _duration = _longBreakMinutes * 60;
        _totalDuration = _longBreakMinutes * 60;
        _completedTomatoCount = 0;
      } else {
        _updateStatus(TomatoStatus.shortBreak);
        _duration = _shortBreakMinutes * 60;
        _totalDuration = _shortBreakMinutes * 60;
      }

      if (_autoStartBreak) {
        start();
      }
    } else {
      _eventController.add(
        TomatoBreakCompleteEvent(
          startTime:
              _startTime ??
              endTime.subtract(Duration(minutes: _totalDuration ~/ 60)),
          endTime: endTime,
        ),
      );

      _updateStatus(TomatoStatus.idle);
      _duration = _focusMinutes * 60;
      _totalDuration = _focusMinutes * 60;

      if (_autoStartFocus) {
        start();
      }
    }
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
    if (focusMin != null) _focusMinutes = focusMin;
    if (shortMin != null) _shortBreakMinutes = shortMin;
    if (longMin != null) _longBreakMinutes = longMin;
    if (interval != null) _longBreakInterval = interval;
    if (autoBreak != null) _autoStartBreak = autoBreak;
    if (autoFocus != null) _autoStartFocus = autoFocus;
    if (autoComp != null) _autoCompletedTask = autoComp;
    _reset();
  }

  void _updateStatus(TomatoStatus newStatus) {
    if (_status != newStatus) {
      final old = _status;
      _status = newStatus;
      _eventController.add(TomatoStatusChangedEvent(old, newStatus));
    }
  }

  void _reset() {
    _isRunning = false;
    _isPaused = false;
    _updateStatus(TomatoStatus.idle);
    _duration = _focusMinutes * 60;
    _totalDuration = _focusMinutes * 60;
    _startTime = null;
  }

  void dispose() {
    _eventController.close();
  }
}
