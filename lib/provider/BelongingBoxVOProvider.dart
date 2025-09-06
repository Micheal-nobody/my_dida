import 'package:flutter/cupertino.dart';
import 'package:my_dida/model/entity/BelongingBox.dart';
import 'package:my_dida/repository/BelongingBoxRepository.dart';

import '../locator/locator.dart';
import '../model/vo/BelongingBoxVO.dart';

class BelongingBoxProvider extends ChangeNotifier {

  // List<Task> _tasks = [];

  /// 注入 Repository
  final BelongingBoxRepository _belongingBoxRepository;
  BelongingBoxProvider()
    : _belongingBoxRepository = locator<BelongingBoxRepository>();

  /// 常用函数：
  Future<void> addTask(String title) async {

  }


  BelongingBox convertToEntity(BelongingBoxVO vo){
    return BelongingBox(name: vo.name)
      ..id = vo.id
      ..colorValue = vo.color.value
      ..taskIds = [ for (var task in vo.tasks) task.id ];
  }

  BelongingBoxVO convertToVO(BelongingBox entity){
    return BelongingBoxVO(
      id: entity.id,
      name: entity.name,
      color: Color(entity.colorValue),
    );
  }
}
