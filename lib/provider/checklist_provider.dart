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
    loadAllChecklistes();
  }

  List<ChecklistVO> allCheckLists = [];

  ChecklistVO get currentCheckList => _currentCheckList;

  /// 注入 Repository，设置默认收藏夹为 “今天”
  ChecklistVO _currentCheckList;
  final ChecklistRepository _checkListRepository;

  /// 获取所有的收藏夹
  Future<void> loadAllChecklistes() async {
    final checklistes = await _checkListRepository.getAllData();

    allCheckLists = [
      for (final checklist in checklistes) convertToVO(checklist),
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

  void updateCurChecklist(ChecklistVO checklist) {
    logger.i('updateCurChecklist 更新了 cur_checklist ！！');
    _currentCheckList = checklist;
    notifyListeners();
  }

  // Create a new belonging box
  Future<void> createChecklist(String name, Color color) async {
    final checklist = Checklist(name: name, colorValue: color.toARGB32());
    await _checkListRepository.addData(checklist);
    await loadAllChecklistes();
  }

  // Update an existing belonging box
  Future<void> updateChecklist(ChecklistVO checklist) async {
    final entity = convertToEntity(checklist);
    await _checkListRepository.addData(entity); // put() updates if exists
    await loadAllChecklistes();
  }

  // Delete a belonging box
  Future<void> deleteChecklist(ChecklistVO checkListVO) async {
    if (checkListVO.id == AppConstants.todayCheckList.id ||
        checkListVO.id == AppConstants.defaultCheckList.id) {
      return; // Don't delete special "today" box
    }

    await _checkListRepository.deleteById(checkListVO.id);
    await loadAllChecklistes();

    // If we deleted the current box, switch to "today"
    if (_currentCheckList.id == checkListVO.id) {
      updateCurChecklist(AppConstants.todayCheckList);
    }
  }
}
