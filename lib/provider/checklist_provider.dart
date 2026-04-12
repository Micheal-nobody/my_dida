import 'package:flutter/cupertino.dart';
import 'package:my_dida/model/entity/checklist.dart';
import 'package:my_dida/repository/checklist_repository.dart';

import '../config/locator.dart';
import '../config/logger.dart';
import '../constants/app_constants.dart';
import '../model/vo/checklist_vo.dart';

///1、记录todoList页面当前所属收藏夹
class ChecklistProvider extends ChangeNotifier {
  ChecklistProvider()
    : _checkListRepository = getIt<ChecklistRepository>(),
      _currentCheckList = AppConstants.todayCheckList {
    loadAllBelongingBoxes();
  }

  List<ChecklistVO> allCheckLists = [];

  ChecklistVO get currentCheckList => _currentCheckList;

  /// 注入 Repository，设置默认收藏夹为 “今天”
  ChecklistVO _currentCheckList;
  final ChecklistRepository _checkListRepository;

  /// 获取所有的收藏夹
  Future<void> loadAllBelongingBoxes() async {
    final belongingBoxes = await _checkListRepository.getAllData();

    allCheckLists = [
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
    _currentCheckList = belongingBox;
    notifyListeners();
  }

  // Create a new belonging box
  Future<void> createBelongingBox(String name, Color color) async {
    final belongingBox = Checklist(name: name, colorValue: color.toARGB32());
    await _checkListRepository.addData(belongingBox);
    await loadAllBelongingBoxes();
  }

  // Update an existing belonging box
  Future<void> updateBelongingBox(ChecklistVO belongingBox) async {
    final entity = convertToEntity(belongingBox);
    await _checkListRepository.addData(entity); // put() updates if exists
    await loadAllBelongingBoxes();
  }

  // Delete a belonging box
  Future<void> deleteBelongingBox(ChecklistVO checkListVO) async {
    if (checkListVO.id == AppConstants.todayCheckList.id ||
        checkListVO.id == AppConstants.defaultCheckList.id) {
      return; // Don't delete special "today" box
    }

    await _checkListRepository.deleteById(checkListVO.id);
    await loadAllBelongingBoxes();

    // If we deleted the current box, switch to "today"
    if (_currentCheckList.id == checkListVO.id) {
      updateCurBelongingBox(AppConstants.todayCheckList);
    }
  }
}
