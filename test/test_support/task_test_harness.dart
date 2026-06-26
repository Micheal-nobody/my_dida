import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/features/calendar/services/task_calendar_projection_service.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/features/checklist/models/checklist_vo.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';
import 'package:my_dida/features/operation_undo/providers/operation_stack_provider.dart';
import 'package:my_dida/features/settings/models/sidebar_config.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/repositories/task_repository.dart';
import 'package:my_dida/features/tasks/services/active_reminder_manager.dart';
import 'package:my_dida/features/tasks/services/attachment_service.dart';
import 'package:my_dida/features/tasks/services/noop_task_reminder_scheduler.dart';
import 'package:my_dida/features/tasks/services/task_lifecycle_manager.dart';
import 'package:my_dida/features/tasks/services/task_reminder_scheduler_port.dart';
import 'package:my_dida/features/tasks/services/task_reminder_service.dart';

class TaskTestHarness {
  TaskTestHarness._(this.isar, this.tempDir);

  final Isar isar;
  final Directory tempDir;

  TaskRepository get taskRepository => getIt<TaskRepository>();
  OperationStackProvider get operationStack => getIt<OperationStackProvider>();
  TaskReminderSchedulerPort get taskReminderScheduler =>
      getIt<TaskReminderSchedulerPort>();

  /// 创建一个可直接运行的 TaskProvider
  TaskProvider createProvider({
    int checklistId = 1,
    String checklistName = '收集箱',
  }) => TaskProvider(
    ChecklistVO(id: checklistId, name: checklistName),
    taskRepository: getIt<TaskRepository>(),
  );

  static Future<TaskTestHarness> create({
    TaskReminderSchedulerPort? taskReminderScheduler,
  }) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await getIt.reset();

    final tempDir = await Directory.systemTemp.createTemp('my_dida_task_test_');
    final isar = await Isar.open(
      [
        TaskSchema,
        HabitSchema,
        OperationSchema,
        ChecklistSchema,
        SidebarConfigSchema,
      ],
      directory: tempDir.path,
      name: 'task_test_${DateTime.now().microsecondsSinceEpoch}',
    );

    getIt
      ..registerSingleton<Isar>(isar)
      ..registerSingleton<AttachmentService>(
        AttachmentServiceImpl(documentsDirectoryProvider: () async => tempDir),
      )
      ..registerSingleton<TaskRepository>(TaskRepository())
      ..registerSingleton<OperationStackProvider>(OperationStackProvider())
      ..registerSingleton<TaskReminderSchedulerPort>(
        taskReminderScheduler ?? NoopTaskReminderScheduler(),
      )
      ..registerSingleton<TaskReminderService>(
        TaskReminderService(scheduler: getIt<TaskReminderSchedulerPort>()),
      )
      ..registerSingleton<ActiveReminderManager>(
        ActiveReminderManager(taskRepository: getIt<TaskRepository>()),
      )
      ..registerSingleton<TaskCalendarProjectionService>(
        TaskCalendarProjectionService(),
      )
      ..registerSingleton<TaskLifecycleManager>(
        TaskLifecycleManagerImpl(
          taskRepository: getIt<TaskRepository>(),
          taskReminderService: getIt<TaskReminderService>(),
          operationStack: getIt<OperationStackProvider>(),
        ),
      );

    return TaskTestHarness._(isar, tempDir);
  }

  Future<void> dispose() async {
    await getIt.reset();
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}
