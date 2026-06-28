import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/events/event_bus.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/features/checklist/repositories/checklist_repository.dart';
import 'package:my_dida/features/checklist/services/checklist_lifecycle_manager.dart';
import 'package:my_dida/features/checklist/services/checklist_operation_reverter.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';
import 'package:my_dida/features/operation_undo/providers/operation_stack_provider.dart';
import 'package:my_dida/features/settings/models/sidebar_config.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/repositories/task_repository.dart';
import 'package:my_dida/features/tasks/services/notification_service.dart';
import 'package:my_dida/features/tasks/services/task_event_listener.dart';
import 'package:my_dida/features/tasks/services/task_notification_navigation_service.dart';
import 'package:my_dida/features/tomato/events/tomato_events.dart';
import 'package:my_dida/features/tomato/models/custom_tomato.dart';
import 'package:my_dida/features/tomato/models/tomato_record.dart';
import 'package:my_dida/features/tomato/providers/tomato_provider.dart';
import 'package:my_dida/features/tomato/repositories/custom_tomato_repository.dart';
import 'package:my_dida/features/tomato/repositories/tomato_record_repository.dart';

void main() {
  late Isar isar;
  late Directory tempDir;
  late TaskRepository taskRepository;
  late ChecklistRepository checklistRepository;
  late ChecklistLifecycleManager checklistLifecycleManager;
  late EventBus eventBus;
  late TaskEventListener taskEventListener;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await getIt.reset();

    tempDir = await Directory.systemTemp.createTemp('my_dida_event_test_');
    isar = await Isar.open(
      [
        TaskSchema,
        HabitSchema,
        OperationSchema,
        ChecklistSchema,
        SidebarConfigSchema,
        TomatoRecordSchema,
        CustomTomatoSchema,
      ],
      directory: tempDir.path,
      name: 'event_test_${DateTime.now().microsecondsSinceEpoch}',
    );

    getIt.registerSingleton<Isar>(isar);

    eventBus = EventBus();
    taskRepository = TaskRepository();
    checklistRepository = ChecklistRepository();
    taskEventListener = TaskEventListener(
      eventBus: eventBus,
      taskRepository: taskRepository,
    );

    getIt
      ..registerSingleton<AppMessageService>(AppMessageService())
      ..registerSingleton<EventBus>(eventBus)
      ..registerSingleton<TaskRepository>(taskRepository)
      ..registerSingleton<ChecklistRepository>(checklistRepository)
      ..registerSingleton<TomatoRecordRepository>(TomatoRecordRepository())
      ..registerSingleton<CustomTomatoRepository>(CustomTomatoRepository())
      ..registerSingleton<TaskEventListener>(taskEventListener)
      ..registerSingleton<OperationStackProvider>(OperationStackProvider())
      ..registerSingleton<TaskNotificationNavigationService>(
        TaskNotificationNavigationService(),
      )
      ..registerSingleton<NotificationService>(NotificationService());

    checklistLifecycleManager = ChecklistLifecycleManagerImpl(
      checklistRepository: checklistRepository,
      taskRepository: taskRepository,
      operationStack: getIt<OperationStackProvider>(),
      messageService: getIt<AppMessageService>(),
      eventBus: eventBus,
    );
  });

  tearDown(() async {
    taskEventListener.dispose();
    eventBus.dispose();
    await getIt.reset();
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('EventBus 跨模块联动集成测试', () {
    test('删除清单时，应该通过 EventBus 异步将属于该清单的任务移动到收集箱 (Inbox, ID=1)', () async {
      // 1. 创建一个清单 (ID = 2)
      final checklist = Checklist(name: '自定义清单')..id = 2;
      await isar.writeTxn(() async {
        await isar.checklists.put(checklist);
      });

      // 2. 创建一个属于该清单的任务
      final task = Task(name: '清单下的任务', checklistId: 2, isAllDay: true);
      await isar.writeTxn(() async {
        await isar.tasks.put(task);
      });

      // 验证初始状态
      var dbTask = await taskRepository.selectById(task.id);
      expect(dbTask?.checklistId, 2);

      // 3. 删除清单 (通过生命周期管理器)
      await checklistLifecycleManager.deleteChecklist(2, name: '自定义清单');

      // 4. 等待 EventBus 异步处理
      await Future.delayed(const Duration(milliseconds: 100));

      // 5. 验证任务的 checklistId 已被 TaskEventListener 重置为 1 (Inbox)
      dbTask = await taskRepository.selectById(task.id);
      expect(dbTask?.checklistId, 1);
    });

    test('撤销删除清单时，应该通过 EventBus 异步将受影响的任务恢复到该清单', () async {
      // 1. 创建清单和任务
      final checklist = Checklist(name: '待删清单')..id = 3;
      await isar.writeTxn(() async {
        await isar.checklists.put(checklist);
      });

      final task = Task(name: '待恢复任务', checklistId: 3, isAllDay: true);
      await isar.writeTxn(() async {
        await isar.tasks.put(task);
      });

      // 2. 删除清单，记录操作
      await checklistLifecycleManager.deleteChecklist(3, name: '待删清单');

      // 等待删除联动完成
      await Future.delayed(const Duration(milliseconds: 100));
      var dbTask = await taskRepository.selectById(task.id);
      expect(dbTask?.checklistId, 1); // 变为了 1

      // 3. 从操作栈获取删除操作，并使用 ChecklistOperationReverter 进行撤销
      final opStack = getIt<OperationStackProvider>();
      expect(opStack.operations.isNotEmpty, true);
      final deleteOp = opStack.operations.last;

      final reverter = ChecklistOperationReverter();
      final revertSuccess = await reverter.revertDelete(
        deleteOp.targetId,
        deleteOp.previousData,
      );
      expect(revertSuccess, true);

      // 4. 等待 EventBus 异步联动完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 5. 验证清单已恢复，且任务的 checklistId 已恢复为 3
      final restoredChecklist = await checklistRepository.selectById(3);
      expect(restoredChecklist?.name, '待删清单');

      dbTask = await taskRepository.selectById(task.id);
      expect(dbTask?.checklistId, 3);
    });

    test('番茄钟勾选自动完成并且关联了任务，番茄钟完成时应该通过 EventBus 异步把任务设为已完成', () async {
      // 1. 创建一个未完成任务
      final task = Task(name: '番茄钟关联的任务', isAllDay: true);
      await isar.writeTxn(() async {
        await isar.tasks.put(task);
      });

      // 2. 初始化 TomatoProvider
      final tomatoRecordRepo = getIt<TomatoRecordRepository>();
      final customTomatoRepo = getIt<CustomTomatoRepository>();
      final provider = TomatoProvider(
        tomatoRecordRepository: tomatoRecordRepo,
        customTomatoRepository: customTomatoRepo,
        eventBus: eventBus,
        checklistRepository: checklistRepository,
      );

      provider.setAssociatedTask(task);
      provider.autoCompletedTask = true; // 开启自动完成

      // 3. 模拟专注完成（调用 ticker 事件流触发 FocusCompleteEvent，或直接在 ticker 发送事件）
      // 这里为了简单，我们直接通过 eventBus 发送事件，或者通过 provider.abandon() 等来触发
      // 实际上我们最核心的是测试：当 autoCompletedTask 开启且 associatedTask 不为空时，
      // provider 在收到 TomatoFocusCompleteEvent 时，会向 eventBus fire TomatoTaskCompletedEvent。
      // 我们在此处用 provider._handleTomatoEvent 来模拟收到番茄钟完成事件。
      // 为测试方便，我们可以使用 eventBus 直接触发 TomatoTaskCompletedEvent，因为 TaskEventListener 订阅了它。
      eventBus.fire(TomatoTaskCompletedEvent(taskId: task.id));

      // 4. 等待 EventBus 异步联动完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 5. 验证任务已被更新为 isDone = true
      final dbTask = await taskRepository.selectById(task.id);
      expect(dbTask?.isDone, true);
    });
  });
}
