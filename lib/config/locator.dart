import 'package:get_it/get_it.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/constants/app_constants.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/model/entity/checklist.dart';
import 'package:my_dida/model/entity/habit.dart';
import 'package:my_dida/model/entity/operation.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/entity/sidebar_config.dart';
import 'package:my_dida/provider/operation_stack_provider.dart';
import 'package:my_dida/repository/checklist_repository.dart';
import 'package:my_dida/repository/habit_repository.dart';
import 'package:my_dida/repository/task_repository.dart';
import 'package:my_dida/services/flutter_local_task_reminder_scheduler.dart';
import 'package:my_dida/services/notification_service.dart';
import 'package:my_dida/services/operation_reverter.dart';
import 'package:my_dida/services/task_calendar_projection_service.dart';
import 'package:my_dida/services/task_reminder_scheduler_port.dart';
import 'package:my_dida/services/task_notification_navigation_service.dart';
import 'package:my_dida/services/task_reminder_service.dart';
import 'package:my_dida/services/task_lifecycle_manager.dart';
import 'package:my_dida/provider/sidebar_config_provider.dart';
import 'package:path_provider/path_provider.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupLocator() async {
  /// 初始化并注册 Isar 实例
  final isar = await initializeIsar();
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
    // 注册多态实体还原注册器并注册实体工厂
    ..registerSingleton<EntityRegistry>(EntityRegistry()
      ..register<Task>(
        OperationTarget.task,
        (json) => Task.fromJson(json),
        getIt<TaskRepository>(),
      )
      ..register<Habit>(
        OperationTarget.habit,
        (json) => Habit.fromJson(json),
        getIt<HabitRepository>(),
      ),
    )
    // 注册泛化撤销实例适配器（取代原本两个 instanceName 子类）
    ..registerSingleton<OperationReverter>(GenericOperationReverter())
    // 注册操作栈管理器
    ..registerSingleton<OperationStackProvider>(OperationStackProvider())
    ..registerSingleton<TaskReminderService>(TaskReminderService())
    ..registerSingleton<TaskReminderSchedulerPort>(
      FlutterLocalTaskReminderScheduler(),
    )
    ..registerSingleton<TaskCalendarProjectionService>(
      TaskCalendarProjectionService(),
    )
    ..registerSingleton<TaskLifecycleManager>(TaskLifecycleManagerImpl(
      taskRepository: getIt<TaskRepository>(),
      taskReminderService: getIt<TaskReminderService>(),
      taskReminderScheduler: getIt<TaskReminderSchedulerPort>(),
      operationStack: getIt<OperationStackProvider>(),
    ));

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

Future<Isar> initializeIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  // During Hot Restart, a native Isar instance may still be alive.
  // Reuse the existing instance if it's already open to avoid lock waits.
  if (Isar.instanceNames.isNotEmpty) {
    final existing = Isar.getInstance();
    if (existing != null) {
      return existing;
    }
  }

  return Isar.open([
    TaskSchema,
    ChecklistSchema,
    HabitSchema,
    OperationSchema,
    SidebarConfigSchema,
  ], directory: dir.path);
}
