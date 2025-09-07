import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:my_dida/model/IsarTest.dart';
import 'package:my_dida/model/entity/BelongingBox.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/repository/BelongingBoxRepository.dart';
import 'package:my_dida/repository/TaskRepository.dart';
import 'package:path_provider/path_provider.dart';

import '../repository/IsarTestRepository.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  /// 初始化并注册 Isar 实例
  final isar = await initializeIsar();
  locator.registerSingleton<Isar>(isar);

  // 注册数据库操作服务
  locator.registerSingleton<IsarTestRepository>(IsarTestRepository());
  locator.registerSingleton<TaskRepository>(TaskRepository());
  locator.registerSingleton<BelongingBoxRepository>(BelongingBoxRepository());
}

Future<Isar> initializeIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [IsarTestSchema,TaskSchema,BelongingBoxSchema],
    directory: dir.path,
  );

  /// 初始化数据
  isar.writeTxnSync(() {
    /// 如果没有收集箱则创建一个
    if (isar.belongingBoxs.countSync() == 0) {
      isar.belongingBoxs.putSync(BelongingBox(name: '收集箱'));
    }

    if (isar.tasks.countSync() == 0) {
      for(var i = 0; i < 10; i++){
        isar.tasks.putSync(Task(name: '任务 $i'));
      }
    }
  });

  return isar;
}