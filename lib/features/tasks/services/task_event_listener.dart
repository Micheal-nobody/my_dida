import 'dart:async';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/events/event_bus.dart';
import 'package:my_dida/features/checklist/events/checklist_events.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/repositories/task_repository.dart';
import 'package:my_dida/features/tasks/services/task_reminder_service.dart';
import 'package:my_dida/features/tomato/events/tomato_events.dart';

class TaskEventListener {
  TaskEventListener({
    EventBus? eventBus,
    TaskRepository? taskRepository,
    TaskReminderService? taskReminderService,
  }) : _eventBus = eventBus ?? getIt<EventBus>(),
       _taskRepository = taskRepository ?? getIt<TaskRepository>(),
       _taskReminderService =
           taskReminderService ?? getIt<TaskReminderService>() {
    _initSubscriptions();
  }

  final EventBus _eventBus;
  final TaskRepository _taskRepository;
  final TaskReminderService _taskReminderService;
  final List<StreamSubscription> _subscriptions = [];

  void _initSubscriptions() {
    // 监听清单删除事件，将该清单下的任务移至 Inbox (ID = 1)
    _subscriptions.add(
      _eventBus.on<ChecklistDeletedEvent>().listen((event) async {
        final affectedTasks = await _taskRepository.getTasksByChecklistId(
          event.checklistId,
        );
        for (final task in affectedTasks) {
          task.checklistId = 1;
        }
        await _taskRepository.insertAll(affectedTasks);
      }),
    );

    // 监听清单恢复事件，恢复之前绑定该清单的任务
    _subscriptions.add(
      _eventBus.on<ChecklistRestoredEvent>().listen((event) async {
        if (event.affectedTaskIds.isNotEmpty) {
          final tasks = await _taskRepository.collection.getAll(
            event.affectedTaskIds,
          );
          final validTasks = tasks.whereType<Task>().toList();
          for (final task in validTasks) {
            task.checklistId = event.checklistId;
          }
          await _taskRepository.insertAll(validTasks);
        }
      }),
    );

    // 监听番茄钟自动完成任务事件
    _subscriptions.add(
      _eventBus.on<TomatoTaskCompletedEvent>().listen((event) async {
        final task = await _taskRepository.selectById(event.taskId);
        if (task != null) {
          await _taskRepository.updateTaskIsDone(task, true);
          task.isDone = true;
          await _taskReminderService.syncReminder(task);
        }
      }),
    );
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}
