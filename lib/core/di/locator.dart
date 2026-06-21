import 'package:get_it/get_it.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/core/logger/logger.dart';
import 'package:my_dida/core/constants/app_constants.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/habits/models/habit_check_in_record.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/settings/models/sidebar_config.dart';
import 'package:my_dida/features/calendar/models/calendar_page_config.dart';
import 'package:my_dida/features/tomato/models/custom_tomato.dart';
import 'package:my_dida/features/tomato/models/tomato_record.dart';
import 'package:my_dida/features/operation_undo/providers/operation_stack_provider.dart';
import 'package:my_dida/features/checklist/repositories/checklist_repository.dart';
import 'package:my_dida/features/habits/repositories/habit_repository.dart';
import 'package:my_dida/features/habits/repositories/habit_check_in_record_repository.dart';
import 'package:my_dida/features/tasks/repositories/task_repository.dart';
import 'package:my_dida/features/tomato/repositories/tomato_record_repository.dart';
import 'package:my_dida/features/tomato/repositories/custom_tomato_repository.dart';
import 'package:my_dida/features/tasks/services/flutter_local_task_reminder_scheduler.dart';
import 'package:my_dida/features/tasks/services/notification_service.dart';
import 'package:my_dida/features/operation_undo/services/operation_reverter.dart';
import 'package:my_dida/features/calendar/services/task_calendar_projection_service.dart';
import 'package:my_dida/features/tasks/services/task_reminder_scheduler_port.dart';
import 'package:my_dida/features/tasks/services/task_notification_navigation_service.dart';
import 'package:my_dida/features/tasks/services/task_reminder_service.dart';
import 'package:my_dida/features/tasks/services/task_lifecycle_manager.dart';
import 'package:my_dida/features/habits/services/habit_lifecycle_manager.dart';
import 'package:my_dida/features/checklist/services/checklist_lifecycle_manager.dart';
import 'package:my_dida/features/settings/providers/sidebar_config_provider.dart';
import 'package:my_dida/features/tasks/services/task_operation_reverter.dart';
import 'package:my_dida/features/habits/services/habit_operation_reverter.dart';
import 'package:my_dida/core/config/app_config.dart';
import 'package:path_provider/path_provider.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupLocator(AppConfig config) async {
  // 注册全局环境配置
  getIt.registerSingleton<AppConfig>(config);

  /// 初始化并注册 Isar 实例
  final isar = await initializeIsar(config);
  getIt.registerSingleton<Isar>(isar);

  await ensureDefaultChecklist(isar);

  // 注册数据库操作服务
  getIt
    ..registerSingleton<AppMessageService>(AppMessageService())
    ..registerSingleton<SidebarConfigProvider>(SidebarConfigProvider())
    ..registerSingleton<TaskNotificationNavigationService>(
      TaskNotificationNavigationService(),
    )
    ..registerSingleton<NotificationService>(NotificationService())
    ..registerSingleton<TaskRepository>(TaskRepository())
    ..registerSingleton<ChecklistRepository>(ChecklistRepository())
    ..registerSingleton<HabitRepository>(HabitRepository())
    ..registerSingleton<TomatoRecordRepository>(TomatoRecordRepository())
    ..registerSingleton<CustomTomatoRepository>(CustomTomatoRepository())
    ..registerSingleton<HabitCheckInRecordRepository>(
      HabitCheckInRecordRepository(),
    )
    // 注册多态实体还原注册器并绑定各领域撤销实现
    ..registerSingleton<EntityRegistry>(
      EntityRegistry()
        ..register(OperationTarget.task, TaskOperationReverter())
        ..register(OperationTarget.habit, HabitOperationReverter()),
    )
    // 注册泛化撤销实例适配器（取代原本两个 instanceName 子类）
    ..registerSingleton<OperationReverter>(GenericOperationReverter())
    // 注册操作栈管理器
    ..registerSingleton<OperationStackProvider>(OperationStackProvider())
    ..registerSingleton<TaskReminderSchedulerPort>(
      FlutterLocalTaskReminderScheduler(),
    )
    ..registerSingleton<TaskReminderService>(
      TaskReminderService(scheduler: getIt<TaskReminderSchedulerPort>()),
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
    )
    ..registerSingleton<HabitLifecycleManager>(
      HabitLifecycleManagerImpl(
        habitRepository: getIt<HabitRepository>(),
        operationStack: getIt<OperationStackProvider>(),
      ),
    )
    ..registerSingleton<ChecklistLifecycleManager>(
      ChecklistLifecycleManagerImpl(
        checklistRepository: getIt<ChecklistRepository>(),
        messageService: getIt<AppMessageService>(),
      ),
    );

  logger.i('初始化 Isar 完成！');
}

Future<void> ensureDefaultChecklist(Isar isar) async {
  final defaultBox = await isar.checklists.get(
    AppConstants.defaultCheckList.id,
  );
  if (defaultBox != null) {
    return;
  }

  final existingDefaultBox = await isar.checklists
      .where()
      .nameEqualTo('收集箱')
      .findFirst();
  if (existingDefaultBox != null) {
    logger.w('已存在名为“收集箱”的清单，但默认 ID 缺失，跳过重复初始化。');
    return;
  }

  await isar.writeTxn(() async {
    final box = Checklist(name: '收集箱')..id = AppConstants.defaultCheckList.id;
    await isar.checklists.put(box);
  });
}

Future<Isar> initializeIsar(AppConfig config) async {
  final dir = await getApplicationDocumentsDirectory();
  // During Hot Restart, a native Isar instance may still be alive.
  // Reuse the existing instance if it's already open to avoid lock waits.
  if (Isar.instanceNames.isNotEmpty) {
    final existing = Isar.getInstance(config.dbName);
    if (existing != null) {
      return existing;
    }
  }

  return Isar.open(
    [
      TaskSchema,
      ChecklistSchema,
      HabitSchema,
      OperationSchema,
      SidebarConfigSchema,
      TomatoRecordSchema,
      CalendarPageConfigSchema,
      HabitCheckInRecordSchema,
      CustomTomatoSchema,
    ],
    directory: dir.path,
    name: config.dbName,
  );
}
