import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/features/tasks/models/task_operation.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/features/tasks/models/check_point.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/settings/models/sidebar_config.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/operation_undo/providers/operation_stack_provider.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/repositories/task_repository.dart';
import 'package:my_dida/features/tasks/services/noop_task_reminder_scheduler.dart';
import 'package:my_dida/features/tasks/services/task_reminder_scheduler_port.dart';
import 'package:my_dida/features/tasks/services/task_reminder_service.dart';
import 'package:my_dida/features/calendar/services/task_calendar_projection_service.dart';
import 'package:my_dida/features/tasks/services/task_lifecycle_manager.dart';
import 'package:my_dida/features/tasks/services/attachment_service.dart';
import 'package:my_dida/features/operation_undo/services/operation_reverter.dart';
import 'package:my_dida/features/tasks/services/task_operation_reverter.dart';

void main() {
  late Isar isar;
  late Directory tempDir;
  late TaskRepository taskRepository;
  late OperationStackProvider operationStack;
  late TaskLifecycleManager lifecycleManager;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await getIt.reset();

    tempDir = await Directory.systemTemp.createTemp('my_dida_undo_task_test_');
    isar = await Isar.open(
      [
        TaskSchema,
        HabitSchema,
        OperationSchema,
        ChecklistSchema,
        SidebarConfigSchema,
      ],
      directory: tempDir.path,
      name: 'undo_task_test_${DateTime.now().microsecondsSinceEpoch}',
    );

    getIt.registerSingleton<Isar>(isar);
    getIt.registerSingleton<AttachmentService>(
      AttachmentServiceImpl(documentsDirectoryProvider: () async => tempDir),
    );

    taskRepository = TaskRepository();
    getIt.registerSingleton<TaskRepository>(taskRepository);

    // 注册多态还原注册器
    final registry = EntityRegistry()
      ..register(OperationTarget.task, TaskOperationReverter());
    getIt.registerSingleton<EntityRegistry>(registry);

    // 注册 OperationReverter
    getIt.registerSingleton<OperationReverter>(GenericOperationReverter());

    operationStack = OperationStackProvider();
    getIt.registerSingleton<OperationStackProvider>(operationStack);
    await operationStack.initialize();

    getIt.registerSingleton<TaskReminderSchedulerPort>(
      NoopTaskReminderScheduler(),
    );
    getIt.registerSingleton<TaskReminderService>(
      TaskReminderService(scheduler: getIt<TaskReminderSchedulerPort>()),
    );
    getIt.registerSingleton<TaskCalendarProjectionService>(
      TaskCalendarProjectionService(),
    );

    lifecycleManager = TaskLifecycleManagerImpl(
      taskRepository: taskRepository,
      taskReminderService: getIt<TaskReminderService>(),
      operationStack: operationStack,
    );
    getIt.registerSingleton<TaskLifecycleManager>(lifecycleManager);
  });

  tearDown(() async {
    await getIt.reset();
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Task Undo and Cascade Tests', () {
    test('Checkpoint operations can be recorded and fully undone', () async {
      // 1. 创建带有一个 Checkpoint 的任务
      final task = Task(
        name: 'Task with checkpoints',
        isAllDay: false,
        checkpoints: [CheckPoint(name: 'CP1', isDone: false)],
      );
      await lifecycleManager.execute(AddTask(task));

      final savedTask = (await taskRepository.selectAll()).first;
      expect(savedTask.checkpoints.length, 1);
      expect(savedTask.checkpoints.first.name, 'CP1');
      expect(savedTask.checkpoints.first.isDone, false);

      // 2. 勾选 Checkpoint 并验证是否录制 Operation
      await lifecycleManager.execute(ToggleCheckpoint(savedTask, 0, true));
      final toggledTask = await taskRepository.selectById(savedTask.id);
      expect(toggledTask!.checkpoints.first.isDone, true);
      expect(operationStack.operations.length, 2); // [Toggle, Add]
      expect(operationStack.operations.first.type, OperationType.update);

      // 3. 撤销 ToggleCheckpoint
      await operationStack.undo();
      final undoneToggleTask = await taskRepository.selectById(savedTask.id);
      expect(undoneToggleTask!.checkpoints.first.isDone, false);

      // 4. 重命名 Checkpoint 并撤销
      await lifecycleManager.execute(
        RenameCheckpoint(undoneToggleTask, 0, 'NewCP'),
      );
      final renamedTask = await taskRepository.selectById(savedTask.id);
      expect(renamedTask!.checkpoints.first.name, 'NewCP');

      await operationStack.undo();
      final undoneRenameTask = await taskRepository.selectById(savedTask.id);
      expect(undoneRenameTask!.checkpoints.first.name, 'CP1');

      // 5. 新增 Checkpoint 并撤销
      await lifecycleManager.execute(AddCheckpoint(undoneRenameTask));
      final addedTask = await taskRepository.selectById(savedTask.id);
      expect(addedTask!.checkpoints.length, 2);

      await operationStack.undo();
      final undoneAddTask = await taskRepository.selectById(savedTask.id);
      expect(undoneAddTask!.checkpoints.length, 1);

      // 6. 删除 Checkpoint 并撤销
      await lifecycleManager.execute(RemoveCheckpoint(undoneAddTask, 0));
      final removedTask = await taskRepository.selectById(savedTask.id);
      expect(removedTask!.checkpoints.isEmpty, true);

      await operationStack.undo();
      final undoneRemoveTask = await taskRepository.selectById(savedTask.id);
      expect(undoneRemoveTask!.checkpoints.length, 1);
      expect(undoneRemoveTask.checkpoints.first.name, 'CP1');
    });

    test(
      'Delete subtask operation and its relation can be fully undone',
      () async {
        // 1. 创建父任务
        final parent = Task(name: 'Parent Task', isAllDay: false);
        await lifecycleManager.execute(AddTask(parent));
        final savedParent = (await taskRepository.selectAll()).first;

        // 2. 创建子任务
        final childId =
            await lifecycleManager.execute(
                  CreateSubTask(savedParent, name: 'Sub Task'),
                )
                as int;

        final reloadedParent = await taskRepository.selectById(savedParent.id);
        expect(reloadedParent!.subTaskIds, contains(childId));

        final savedChild = await taskRepository.selectById(childId);
        expect(savedChild!.parentTaskId, savedParent.id);

        // 3. 删除子任务
        // 操作栈在删除子任务前包含：[CreateSubTask, AddParent]
        final operationsBefore = List.from(operationStack.operations);

        await lifecycleManager.execute(DeleteSubTask(reloadedParent, childId));

        // 删除后，父任务 subTaskIds 不包含子任务 ID，且子任务从数据库被物理删除
        final parentAfterDelete = await taskRepository.selectById(
          savedParent.id,
        );
        expect(parentAfterDelete!.subTaskIds, isNot(contains(childId)));

        final childAfterDelete = await taskRepository.selectById(childId);
        expect(childAfterDelete, isNull);

        // 检查 Operation 栈。DeleteSubTask 应该录制了 OperationType.delete
        expect(operationStack.operations.length, operationsBefore.length + 1);
        expect(operationStack.operations.first.type, OperationType.delete);
        expect(operationStack.operations.first.targetId, childId);

        // 4. 撤销删除子任务
        await operationStack.undo();

        // 撤销后，子任务应该被插回，且父任务的 subTaskIds 应该恢复连回
        final childAfterUndo = await taskRepository.selectById(childId);
        expect(childAfterUndo, isNotNull);
        expect(childAfterUndo!.parentTaskId, savedParent.id);

        final parentAfterUndo = await taskRepository.selectById(savedParent.id);
        expect(parentAfterUndo!.subTaskIds, contains(childId));
      },
    );
  });
}
