import 'package:isar_community/isar.dart';
import 'package:my_dida/shared/models/base_entity.dart';

part 'sidebar_config.g.dart';

enum SmartListShowOption {
  hide, // 0
  show, // 1
  auto, // 2
}

enum AppTheme { system, light, dark }

enum AppLanguage { zh, en }

@Collection()
class SidebarConfig extends BaseEntity {
  SidebarConfig({
    this.theme = AppTheme.system,
    this.language = AppLanguage.zh,
    // 侧边栏整体模块可见性开关
    this.showProfile = true,
    this.showSearch = true,
    this.showSmartLists = true,
    this.showCustomLists = true,
    this.showTags = true,
    this.showFilters = false,

    // 智能清单可见性配置 (0: 隐藏, 1: 显示, 2: 自动)
    this.todayShowOption = SmartListShowOption.show,
    this.tomorrowShowOption = SmartListShowOption.auto,
    this.nextSevenDaysShowOption = SmartListShowOption.show,
    this.inboxShowOption = SmartListShowOption.show,
    this.allShowOption = SmartListShowOption.hide,
    this.completedShowOption = SmartListShowOption.hide,
    this.trashShowOption = SmartListShowOption.hide,

    // 默认清单ID
    this.defaultChecklistId = 1,

    this.showFourQuadrants = true,
    this.quadrantHideCompleted = true,
  });

  @Enumerated(EnumType.name)
  AppTheme theme;
  @Enumerated(EnumType.name)
  AppLanguage language;

  bool showProfile;
  bool showSearch;
  bool showSmartLists;
  bool showCustomLists;
  bool showTags;
  bool showFilters;

  @enumerated
  SmartListShowOption todayShowOption;
  @enumerated
  SmartListShowOption tomorrowShowOption;
  @enumerated
  SmartListShowOption nextSevenDaysShowOption;
  @enumerated
  SmartListShowOption inboxShowOption;
  @enumerated
  SmartListShowOption allShowOption;
  @enumerated
  SmartListShowOption completedShowOption;
  @enumerated
  SmartListShowOption trashShowOption;

  int defaultChecklistId;

  bool showFourQuadrants;
  bool quadrantHideCompleted;
}
