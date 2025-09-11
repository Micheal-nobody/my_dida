import 'package:flutter/cupertino.dart';
import 'package:my_dida/model/entity/BelongingBox.dart';
import 'package:my_dida/repository/BelongingBoxRepository.dart';

import '../config/locator.dart';
import '../config/logger.dart';
import '../model/vo/BelongingBoxVO.dart';
import '../model/vo/TaskVO.dart';

///1、记录todoList页面当前所属收藏夹
class BelongingBoxProvider extends ChangeNotifier {

  List<BelongingBoxVO> all_belongingBoxes = [];
  BelongingBoxVO get cur_belongingBox => _currentBelongingBox;

  // 一个默认的收藏夹
  static BelongingBoxVO default_belongingBox = BelongingBoxVO(id: -1, name: "今天");


  /// 注入 Repository，设置默认收藏夹为 “今天”
  BelongingBoxVO _currentBelongingBox;
  final BelongingBoxRepository _belongingBoxRepository;
  BelongingBoxProvider()
    : _belongingBoxRepository = locator<BelongingBoxRepository>(),
      _currentBelongingBox = default_belongingBox{
    loadAllBelongingBoxes();
  }


  /// 获取所有的收藏夹
  Future<List<BelongingBoxVO>> loadAllBelongingBoxes() async {
    List<BelongingBox> belongingBoxes = await _belongingBoxRepository.getAll();
    all_belongingBoxes = [
      for (var belongingBox in belongingBoxes) convertToVO(belongingBox)
    ];

    notifyListeners();
    return all_belongingBoxes;
  }


  //region 看起来不是很有用的convert
  BelongingBox convertToEntity(BelongingBoxVO vo) {
    return BelongingBox(name: vo.name)
      ..id = vo.id
      ..colorValue = vo.color.toARGB32()
      ..taskIds = vo.taskIds;
  }

  BelongingBoxVO convertToVO(BelongingBox entity) {
    return BelongingBoxVO(
      id: entity.id,
      name: entity.name,
      color: Color(entity.colorValue),
      taskIds: entity.taskIds
    );
  }
  //endregion

  void updateCurBelongingBox(BelongingBoxVO belongingBox) {
    logger.i("updateCurBelongingBox 更新了 cur_belongingBox ！！");
    _currentBelongingBox = belongingBox;
    notifyListeners();
  }
}