import 'dart:async';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/logger/logger.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/repositories/task_repository.dart';

class ActiveReminderManager {
  ActiveReminderManager({TaskRepository? taskRepository})
    : _taskRepository = taskRepository ?? getIt<TaskRepository>();

  final TaskRepository _taskRepository;

  final StreamController<Task> _activeTriggerController =
      StreamController<Task>.broadcast();
  Stream<Task> get activeTriggers => _activeTriggerController.stream;

  Timer? _checkTimer;
  final Set<String> _remindedKeys = {}; // Stores "taskId_triggerTimeIso"
  final Map<int, DateTime> _snoozedReminders = {}; // taskId -> nextTriggerTime

  void snooze(int taskId, Duration duration) {
    _snoozedReminders[taskId] = DateTime.now().add(duration);
  }

  void startForegroundCheck({
    Duration checkInterval = const Duration(minutes: 1),
  }) {
    _checkTimer?.cancel();
    _remindedKeys.clear();
    _snoozedReminders.clear();

    // Mark all existing past reminders as already reminded
    _markPastRemindersAsReminded(DateTime.now());

    _checkTimer = Timer.periodic(checkInterval, (timer) {
      _checkReminders();
    });
  }

  void stopForegroundCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  Future<void> _markPastRemindersAsReminded(DateTime now) async {
    try {
      final tasks = await _taskRepository.getActiveReminderTasks();
      for (final task in tasks) {
        if (task.startTime != null && !task.isAllDay) {
          final offsets = task.reminderOffsets.isNotEmpty
              ? task.reminderOffsets
              : (task.reminderOffsetMinutes != null ? [task.reminderOffsetMinutes!] : <int>[]);
          for (final offset in offsets) {
            final triggerAt = task.startTime!
                .subtract(Duration(minutes: offset))
                .toLocal();
            if (triggerAt.isBefore(now)) {
              _remindedKeys.add('${task.id}_${triggerAt.toIso8601String()}');
            }
          }
        }
      }
    } on Exception catch (e) {
      logger.w('Failed to mark past reminders as reminded: $e');
    }
  }

  Future<void> _checkReminders() async {
    try {
      final tasks = await _taskRepository.getActiveReminderTasks();
      final now = DateTime.now();

      // Check normal reminders
      for (final task in tasks) {
        if (task.startTime != null && !task.isAllDay) {
          final offsets = task.reminderOffsets.isNotEmpty
              ? task.reminderOffsets
              : (task.reminderOffsetMinutes != null ? [task.reminderOffsetMinutes!] : <int>[]);
          
          for (final offset in offsets) {
            final triggerAt = task.startTime!
                .subtract(Duration(minutes: offset))
                .toLocal();
            final key = '${task.id}_${triggerAt.toIso8601String()}';
            final alreadyReminded = _remindedKeys.contains(key);
            if ((now.isAfter(triggerAt) || now.isAtSameMomentAs(triggerAt)) &&
                !alreadyReminded) {
              _remindedKeys.add(key);
              _activeTriggerController.add(task);
            }
          }
        }
      }

      // Check snoozed reminders
      final List<int> triggeredSnoozes = [];
      _snoozedReminders.forEach((taskId, triggerAt) {
        if (now.isAfter(triggerAt) || now.isAtSameMomentAs(triggerAt)) {
          triggeredSnoozes.add(taskId);
        }
      });

      for (final taskId in triggeredSnoozes) {
        _snoozedReminders.remove(taskId);
        final task = await _taskRepository.selectById(taskId);
        if (task != null && !task.isDone) {
          _activeTriggerController.add(task);
        }
      }
    } on Exception catch (e) {
      logger.w('Failed to check reminders: $e');
    }
  }

  void dispose() {
    stopForegroundCheck();
    _activeTriggerController.close();
  }
}
