import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/model/entity/Habit.dart';
import 'package:my_dida/model/entity/Operation.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/provider/operation_stack_provider.dart';
import 'package:my_dida/repository/task_repository.dart';
import 'package:my_dida/services/task_service.dart';

class TaskTestHarness {
  TaskTestHarness._(this.isar, this.tempDir);

  final Isar isar;
  final Directory tempDir;

  TaskRepository get taskRepository => getIt<TaskRepository>();
  TaskService get taskService => getIt<TaskService>();
  OperationStackProvider get operationStack => getIt<OperationStackProvider>();

  static Future<TaskTestHarness> create() async {
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
      ..registerSingleton<TaskService>(TaskService());

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
