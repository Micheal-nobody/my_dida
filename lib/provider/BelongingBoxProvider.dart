import 'package:flutter/cupertino.dart';
import 'package:my_dida/model/entity/BelongingBox.dart';
import 'package:my_dida/repository/BelongingBoxRepository.dart';

import '../config/locator.dart';
import '../config/logger.dart';
import '../model/vo/BelongingBoxVO.dart';

///1、记录todoList页面当前所属收藏夹
class BelongingBoxProvider extends ChangeNotifier {
  List<BelongingBoxVO> all_belongingBoxes = [];
  BelongingBoxVO get cur_belongingBox => _currentBelongingBox;

  // 一个默认的收藏夹
  static BelongingBoxVO today_belongingBox = BelongingBoxVO(id: -1, name: "今天");
  static BelongingBoxVO default_belongingBox = BelongingBoxVO(
    id: 1,
    name: "收集箱1",
  );

  /// 注入 Repository，设置默认收藏夹为 “今天”
  BelongingBoxVO _currentBelongingBox;
  final BelongingBoxRepository _belongingBoxRepository;
  BelongingBoxProvider()
    : _belongingBoxRepository = locator<BelongingBoxRepository>(),
      _currentBelongingBox = today_belongingBox {
    loadAllBelongingBoxes();
  }

  /// 获取所有的收藏夹
  Future<void> loadAllBelongingBoxes() async {
    List<BelongingBox> belongingBoxes = await _belongingBoxRepository
        .getAllData();

    all_belongingBoxes = [
      for (var belongingBox in belongingBoxes) convertToVO(belongingBox),
    ];

    notifyListeners();
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
      taskIds: entity.taskIds,
    );
  }
  //endregion

  void updateCurBelongingBox(BelongingBoxVO belongingBox) {
    logger.i("updateCurBelongingBox 更新了 cur_belongingBox ！！");
    _currentBelongingBox = belongingBox;
    notifyListeners();
  }

  // Create a new belonging box
  Future<void> createBelongingBox(String name, Color color) async {
    final belongingBox = BelongingBox(name: name, colorValue: color.toARGB32());
    await _belongingBoxRepository.addData(belongingBox);
    await loadAllBelongingBoxes();
  }

  // Update an existing belonging box
  Future<void> updateBelongingBox(BelongingBoxVO belongingBox) async {
    final entity = convertToEntity(belongingBox);
    await _belongingBoxRepository.addData(entity); // put() updates if exists
    await loadAllBelongingBoxes();
  }

  // Delete a belonging box
  Future<void> deleteBelongingBox(BelongingBoxVO belongingBox) async {
    if (belongingBox.id == -1) return; // Don't delete special "today" box
    await _belongingBoxRepository.deleteById(belongingBox.id);
    await loadAllBelongingBoxes();

    // If we deleted the current box, switch to "today"
    if (_currentBelongingBox.id == belongingBox.id) {
      updateCurBelongingBox(today_belongingBox);
    }
  }
}
