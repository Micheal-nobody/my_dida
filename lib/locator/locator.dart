import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:my_dida/model/IsarTest.dart';
import 'package:my_dida/model/entity/BelongingBox.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:path_provider/path_provider.dart';

import '../repository/IsarTestRepository.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  /// 初始化并注册 Isar 实例
  final isar = await initializeIsar();
  locator.registerSingleton<Isar>(isar);

  // 注册数据库操作服务
  locator.registerSingleton<IsarTestRepository>(IsarTestRepository());
}

Future<Isar> initializeIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [IsarTestSchema,TaskSchema,BelongingBoxSchema],
    directory: dir.path,
  );
  return isar;
}