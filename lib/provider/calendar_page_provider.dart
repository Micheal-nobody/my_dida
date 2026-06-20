import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/model/entity/calendar_page_config.dart';

class CalendarPageProvider extends ChangeNotifier {
  final Isar _isar = getIt<Isar>();
  CalendarPageConfig _config = CalendarPageConfig();

  CalendarPageConfig get config => _config;

  CalendarPageProvider() {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final existing = await _isar.calendarPageConfigs.where().findFirst();
    if (existing != null) {
      _config = existing;
    } else {
      await _isar.writeTxn(() async {
        await _isar.calendarPageConfigs.put(_config);
      });
    }
    notifyListeners();
  }

  Future<void> updateConfig({
    bool? showCompletedTasks,
    String? visibleMode,
    List<int>? visibleChecklistIds,
    String? viewMode,
    bool? isTimeFolded,
  }) async {
    if (showCompletedTasks != null)
      _config.showCompletedTasks = showCompletedTasks;
    if (visibleMode != null) _config.visibleMode = visibleMode;
    if (visibleChecklistIds != null)
      _config.visibleChecklistIds = visibleChecklistIds;
    if (viewMode != null) _config.viewMode = viewMode;
    if (isTimeFolded != null) _config.isTimeFolded = isTimeFolded;

    await _isar.writeTxn(() async {
      await _isar.calendarPageConfigs.put(_config);
    });
    notifyListeners();
  }
}
