import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/model/entity/BelongingBox.dart';
import 'package:my_dida/model/entity/Habit.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/model/entity/Operation.dart';
import 'package:my_dida/repository/BelongingBoxRepository.dart';
import 'package:my_dida/repository/TaskRepository.dart';
import 'package:my_dida/repository/HabitRepository.dart';
import 'package:my_dida/provider/OperationStackProvider.dart';
import 'package:path_provider/path_provider.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  /// 初始化并注册 Isar 实例
  final isar = await initializeIsar();
  locator.registerSingleton<Isar>(isar);

  // 注册数据库操作服务
  locator.registerSingleton<TaskRepository>(TaskRepository());
  locator.registerSingleton<BelongingBoxRepository>(BelongingBoxRepository());
  locator.registerSingleton<HabitRepository>(HabitRepository());

  // 注册操作栈管理器
  locator.registerSingleton<OperationStackProvider>(OperationStackProvider());

  logger.i("初始化 Isar 完成！");
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

  return await Isar.open([
    TaskSchema,
    BelongingBoxSchema,
    HabitSchema,
    OperationSchema,
  ], directory: dir.path);
}
