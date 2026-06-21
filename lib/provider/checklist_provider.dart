import 'package:flutter/cupertino.dart';
import 'package:my_dida/model/entity/checklist.dart';
import 'package:my_dida/repository/checklist_repository.dart';
import 'package:my_dida/services/checklist_lifecycle_manager.dart';

import '../config/locator.dart';
import '../config/logger.dart';
import '../constants/app_constants.dart';
import '../constants/ui_constants.dart';
import '../model/vo/checklist_vo.dart';

///1、记录todoList页面当前所属收藏夹
class ChecklistProvider extends ChangeNotifier {
  ChecklistProvider({
    ChecklistRepository? checklistRepository,
    ChecklistLifecycleManager? checklistLifecycleManager,
  }) : _checkListRepository =
           checklistRepository ?? getIt<ChecklistRepository>(),
       _checklistLifecycleManager =
           checklistLifecycleManager ?? getIt<ChecklistLifecycleManager>(),
       _currentCheckList = AppConstants.todayCheckList {
    loadAllChecklistes();
  }

  List<ChecklistVO> allCheckLists = [];

  ChecklistVO get currentCheckList => _currentCheckList;

  /// 注入 Repository，设置默认收藏夹为 “今天”
  ChecklistVO _currentCheckList;
  final ChecklistRepository _checkListRepository;
  final ChecklistLifecycleManager _checklistLifecycleManager;

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
    ..colorValue = vo.color.toARGB32();

  ChecklistVO convertToVO(Checklist entity) => ChecklistVO(
    id: entity.id,
    name: entity.name,
    color: Color(entity.colorValue),
  );

  //endregion

  void updateCurChecklist(ChecklistVO checklist) {
    logger.i('updateCurChecklist 更新了 cur_checklist ！！');
    _currentCheckList = checklist;
    notifyListeners();
  }

  // Create a new belonging box
  Future<void> createChecklist(String name, Color color) async {
    await _checklistLifecycleManager.createChecklist(name, color.toARGB32());
    await loadAllChecklistes();
  }

  // Update an existing belonging box
  Future<void> updateChecklist(ChecklistVO checklist) async {
    final entity = convertToEntity(checklist);
    await _checklistLifecycleManager.updateChecklist(entity);
    await loadAllChecklistes();
  }

  // Delete a belonging box
  Future<void> deleteChecklist(ChecklistVO checkListVO) async {
    if (checkListVO.isToday || checkListVO.isInbox) {
      return; // Don't delete special "today" box
    }

    try {
      await _checklistLifecycleManager.deleteChecklist(
        checkListVO.id,
        name: checkListVO.name,
      );
      await loadAllChecklistes();

      // If we deleted the current box, switch to "today"
      if (_currentCheckList == checkListVO) {
        updateCurChecklist(AppConstants.todayCheckList);
      }
    } catch (e) {
      // Managed inside lifecycle manager
    }
  }
}
