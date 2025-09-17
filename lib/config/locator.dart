import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/model/entity/BelongingBox.dart';
import 'package:my_dida/model/entity/Habit.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/repository/BelongingBoxRepository.dart';
import 'package:my_dida/repository/TaskRepository.dart';
import 'package:my_dida/repository/HabitRepository.dart';
import 'package:path_provider/path_provider.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  logger.i("开始初始化 Isar ...");

  /// 初始化并注册 Isar 实例
  final isar = await initializeIsar();
  locator.registerSingleton<Isar>(isar);

  // 注册数据库操作服务
  locator.registerSingleton<TaskRepository>(TaskRepository());
  locator.registerSingleton<BelongingBoxRepository>(BelongingBoxRepository());
  locator.registerSingleton<HabitRepository>(HabitRepository());

  logger.i("初始化 Isar 完成！");
}

Future<Isar> initializeIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    TaskSchema,
    BelongingBoxSchema,
    HabitSchema,
  ], directory: dir.path);

  return isar;
}
