import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/model/IsarTest.dart';
import 'package:my_dida/model/entity/BelongingBox.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/repository/BelongingBoxRepository.dart';
import 'package:my_dida/repository/TaskRepository.dart';
import 'package:my_dida/utils/TimeUtils.dart';
import 'package:path_provider/path_provider.dart';

import '../repository/IsarTestRepository.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {

  logger.i("开始初始化 Isar ...");

  /// 初始化并注册 Isar 实例
  final isar = await initializeIsar();
  locator.registerSingleton<Isar>(isar);

  // 注册数据库操作服务
  locator.registerSingleton<IsarTestRepository>(IsarTestRepository());
  locator.registerSingleton<TaskRepository>(TaskRepository());
  locator.registerSingleton<BelongingBoxRepository>(BelongingBoxRepository());

  logger.i("初始化 Isar 完成！");
}

Future<Isar> initializeIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    IsarTestSchema,
    TaskSchema,
    BelongingBoxSchema,
  ], directory: dir.path);

  /// 初始化数据
  await isar.writeTxn(() async {
  //   /// 清空所有数据
  //   await isar.clear();
  //
  //   /// 如果没有收集箱则创建一个
    if (await isar.belongingBoxs.count() == 0) {

      Id id = await isar.belongingBoxs.put(BelongingBox(name: '收集箱'));

      // for(var i = 0; i < 10; i++){
      //   Id id = await isar.belongingBoxs.put(BelongingBox(name: '收集箱 $i'));
      // }
    }

  //   if (await isar.tasks.count() == 0) {
  //     /// 最近7天，每天7个任务
  //     var today = DateTime.now().dateOnly; // 获取今天 00:00:00
  //     for (var i = 0; i < 7; i++) {
  //       for (var j = 1; j <= 7; j++) {
  //         Task task = Task(
  //           name: '任务 ${i} 的第 ${j} 个任务',
  //           startTime: today.add(Duration(days: i)),
  //           isDone: j % 2 == 0,
  //         );
  //         await isar.tasks.put(task);
  //       }
  //     }
  //   }
  });

  return isar;
}
