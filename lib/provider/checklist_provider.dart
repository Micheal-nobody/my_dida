import 'package:flutter/cupertino.dart';
import 'package:my_dida/model/entity/checklist.dart';
import 'package:my_dida/repository/checklist_repository.dart';

import '../config/locator.dart';
import '../config/logger.dart';
import '../model/vo/checklist_vo.dart';

///1、记录todoList页面当前所属收藏夹
class ChecklistProvider extends ChangeNotifier {
  ChecklistProvider()
    : _belongingBoxRepository = locator<ChecklistRepository>(),
      _currentBelongingBox = todayBelongingBox {
    loadAllBelongingBoxes();
  }
  List<ChecklistVO> allBelongingBoxes = [];
  ChecklistVO get currentBelongingBox => _currentBelongingBox;

  // 一个默认的收藏夹
  static ChecklistVO todayBelongingBox = ChecklistVO(id: -1, name: '今天');
  static ChecklistVO defaultBelongingBox = ChecklistVO(
    id: 1,
    name: '收集箱',
  );

  /// 注入 Repository，设置默认收藏夹为 “今天”
  ChecklistVO _currentBelongingBox;
  final ChecklistRepository _belongingBoxRepository;

  /// 获取所有的收藏夹
  Future<void> loadAllBelongingBoxes() async {
    final belongingBoxes = await _belongingBoxRepository.getAllData();

    allBelongingBoxes = [
      for (final belongingBox in belongingBoxes) convertToVO(belongingBox),
    ];

    notifyListeners();
  }

  //region 看起来不是很有用的convert
  Checklist convertToEntity(ChecklistVO vo) => Checklist(name: vo.name)
    ..id = vo.id
    ..colorValue = vo.color.toARGB32()
    ..taskIds = vo.taskIds;

  ChecklistVO convertToVO(Checklist entity) => ChecklistVO(
    id: entity.id,
    name: entity.name,
    color: Color(entity.colorValue),
    taskIds: entity.taskIds,
  );
  //endregion

  void updateCurBelongingBox(ChecklistVO belongingBox) {
    logger.i('updateCurBelongingBox 更新了 cur_belongingBox ！！');
    _currentBelongingBox = belongingBox;
    notifyListeners();
  }

  // Create a new belonging box
  Future<void> createBelongingBox(String name, Color color) async {
    final belongingBox = Checklist(name: name, colorValue: color.toARGB32());
    await _belongingBoxRepository.addData(belongingBox);
    await loadAllBelongingBoxes();
  }

  // Update an existing belonging box
  Future<void> updateBelongingBox(ChecklistVO belongingBox) async {
    final entity = convertToEntity(belongingBox);
    await _belongingBoxRepository.addData(entity); // put() updates if exists
    await loadAllBelongingBoxes();
  }

  // Delete a belonging box
  Future<void> deleteBelongingBox(ChecklistVO belongingBox) async {
    if (belongingBox.id == -1) return; // Don't delete special "today" box
    await _belongingBoxRepository.deleteById(belongingBox.id);
    await loadAllBelongingBoxes();

    // If we deleted the current box, switch to "today"
    if (_currentBelongingBox.id == belongingBox.id) {
      updateCurBelongingBox(todayBelongingBox);
    }
  }
}
