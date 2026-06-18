import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/model/entity/habit.dart';
import 'package:my_dida/model/entity/operation.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/checklist_vo.dart';
import 'package:my_dida/provider/operation_stack_provider.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:my_dida/repository/task_repository.dart';
import 'package:my_dida/services/noop_task_reminder_scheduler.dart';
import 'package:my_dida/services/task_reminder_scheduler_port.dart';
import 'package:my_dida/services/task_reminder_service.dart';

class TaskTestHarness {
  TaskTestHarness._(this.isar, this.tempDir);

  final Isar isar;
  final Directory tempDir;

  TaskRepository get taskRepository => getIt<TaskRepository>();
  OperationStackProvider get operationStack => getIt<OperationStackProvider>();
  TaskReminderSchedulerPort get taskReminderScheduler =>
      getIt<TaskReminderSchedulerPort>();

  /// 创建一个可直接运行的 TaskProvider，内联了原 TaskService 的业务逻辑
  TaskProvider createProvider({
    int checklistId = 1,
    String checklistName = '收集箱',
  }) {
    return TaskProvider(
      ChecklistVO(id: checklistId, name: checklistName),
      taskRepository: getIt<TaskRepository>(),
      operationStack: getIt<OperationStackProvider>(),
      taskReminderService: getIt<TaskReminderService>(),
      taskReminderScheduler: getIt<TaskReminderSchedulerPort>(),
    );
  }

  static Future<TaskTestHarness> create({
    TaskReminderSchedulerPort? taskReminderScheduler,
  }) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await getIt.reset();

    final tempDir = await Directory.systemTemp.createTemp('my_dida_task_test_');
    final isar = await Isar.open(
      [TaskSchema, HabitSchema, OperationSchema],
      directory: tempDir.path,
      name: 'task_test_${DateTime.now().microsecondsSinceEpoch}',
    );

    getIt
      ..registerSingleton<Isar>(isar)
      ..registerSingleton<TaskRepository>(TaskRepository())
      ..registerSingleton<OperationStackProvider>(OperationStackProvider())
      ..registerSingleton<TaskReminderService>(TaskReminderService())
      ..registerSingleton<TaskReminderSchedulerPort>(
        taskReminderScheduler ?? NoopTaskReminderScheduler(),
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
