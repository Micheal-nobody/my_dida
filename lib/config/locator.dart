import 'package:get_it/get_it.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/constants/app_constants.dart';
import 'package:my_dida/model/entity/checklist.dart';
import 'package:my_dida/model/entity/Habit.dart';
import 'package:my_dida/model/entity/Operation.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/provider/operation_stack_provider.dart';
import 'package:my_dida/repository/task_repository.dart';
import 'package:my_dida/repository/checklist_repository.dart';
import 'package:my_dida/repository/habit_repository.dart';
import 'package:my_dida/services/task_service.dart';
import 'package:path_provider/path_provider.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  /// 初始化并注册 Isar 实例
  final isar = await initializeIsar();
  locator.registerSingleton<Isar>(isar);

  await ensureDefaultBelongingBox(isar);

  // 注册数据库操作服务
  locator.registerSingleton<TaskRepository>(TaskRepository());
  locator.registerSingleton<ChecklistRepository>(ChecklistRepository());
  locator.registerSingleton<HabitRepository>(HabitRepository());

  // 注册操作栈管理器
  locator.registerSingleton<OperationStackProvider>(OperationStackProvider());

  // 注册业务逻辑服务
  locator.registerSingleton<TaskService>(TaskService());

  logger.i('初始化 Isar 完成！');
}

Future<void> ensureDefaultBelongingBox(Isar isar) async {
  final defaultBox = await isar.checklists.get(
    AppConstants.defaultCheckListId,
  );
  if (defaultBox != null) {
    return;
  }

  final existingDefaultBox =
      await isar.checklists.filter().nameEqualTo('收集箱').findFirst();
  if (existingDefaultBox != null) {
    logger.w('已存在名为“收集箱”的归属盒子，但默认 ID 缺失，跳过重复初始化。');
    return;
  }

  await isar.writeTxn(() async {
    final box = Checklist(name: '收集箱')
      ..id = AppConstants.defaultCheckListId;
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
  ], directory: dir.path);
}
