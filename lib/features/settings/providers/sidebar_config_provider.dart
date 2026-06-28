import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/features/settings/models/sidebar_config.dart';

class SidebarConfigProvider with ChangeNotifier {
  SidebarConfigProvider() : _isar = getIt<Isar>() {
    loadConfig();
  }

  final Isar _isar;
  SidebarConfig _config = SidebarConfig();

  SidebarConfig get config => _config;

  Future<void> loadConfig() async {
    final existing = await _isar.sidebarConfigs.where().findFirst();
    if (existing != null) {
      _config = existing;
    } else {
      // Create a default one
      await _isar.writeTxn(() async {
        await _isar.sidebarConfigs.put(_config);
      });
    }
    notifyListeners();
  }

  Future<void> updateConfig(SidebarConfig newConfig) async {
    await _isar.writeTxn(() async {
      await _isar.sidebarConfigs.put(newConfig);
    });
    _config = newConfig;
    notifyListeners();
  }

  Future<void> updateTheme(AppTheme theme) async {
    _config.theme = theme;
    await updateConfig(_config);
  }

  Future<void> updateLanguage(AppLanguage language) async {
    _config.language = language;
    await updateConfig(_config);
  }

  Future<void> updateModuleVisibility({
    bool? showProfile,
    bool? showSearch,
    bool? showSmartLists,
    bool? showCustomLists,
    bool? showTags,
    bool? showFilters,
  }) async {
    if (showProfile != null) _config.showProfile = showProfile;
    if (showSearch != null) _config.showSearch = showSearch;
    if (showSmartLists != null) _config.showSmartLists = showSmartLists;
    if (showCustomLists != null) _config.showCustomLists = showCustomLists;
    if (showTags != null) _config.showTags = showTags;
    if (showFilters != null) _config.showFilters = showFilters;
    await updateConfig(_config);
  }

  Future<void> updateSmartListShowOption({
    SmartListShowOption? todayShowOption,
    SmartListShowOption? tomorrowShowOption,
    SmartListShowOption? nextSevenDaysShowOption,
    SmartListShowOption? inboxShowOption,
    SmartListShowOption? allShowOption,
    SmartListShowOption? completedShowOption,
    SmartListShowOption? trashShowOption,
  }) async {
    if (todayShowOption != null) _config.todayShowOption = todayShowOption;
    if (tomorrowShowOption != null) {
      _config.tomorrowShowOption = tomorrowShowOption;
    }
    if (nextSevenDaysShowOption != null) {
      _config.nextSevenDaysShowOption = nextSevenDaysShowOption;
    }
    if (inboxShowOption != null) _config.inboxShowOption = inboxShowOption;
    if (allShowOption != null) _config.allShowOption = allShowOption;
    if (completedShowOption != null) {
      _config.completedShowOption = completedShowOption;
    }
    if (trashShowOption != null) _config.trashShowOption = trashShowOption;
    await updateConfig(_config);
  }

  Future<void> updateDefaultChecklistId(int id) async {
    _config.defaultChecklistId = id;
    await updateConfig(_config);
  }

  Future<void> updateQuadrantHideCompleted(bool hide) async {
    _config.quadrantHideCompleted = hide;
    await updateConfig(_config);
  }

  Future<void> updateFourQuadrantsVisibility(bool visible) async {
    _config.showFourQuadrants = visible;
    await updateConfig(_config);
  }
}
