import 'package:flutter/cupertino.dart';
import 'package:my_dida/repository/BelongingBoxRepository.dart';

import '../locator/locator.dart';

class BelongingBoxProvider extends ChangeNotifier {

  // List<Task> _tasks = [];

  /// 注入 Repository
  final BelongingBoxRepository _belongingBoxRepository;
  BelongingBoxProvider()
    : _belongingBoxRepository = locator<BelongingBoxRepository>();

  /// 常用函数：
  Future<void> addTask(String title) async {

  }
}
