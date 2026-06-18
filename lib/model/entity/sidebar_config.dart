import 'package:isar_community/isar.dart';
import 'package:my_dida/model/entity/base_entity.dart';

part 'sidebar_config.g.dart';

@Collection()
class SidebarConfig extends BaseEntity {
  SidebarConfig({
    this.theme = 'system',
    this.language = 'zh',
    // 侧边栏整体模块可见性开关
    this.showProfile = true,
    this.showSearch = true,
    this.showSmartLists = true,
    this.showCustomLists = true,
    this.showTags = true,
    this.showFilters = false,

    // 智能清单可见性配置 (0: 隐藏, 1: 显示, 2: 自动)
    this.todayShowOption = 1,
    this.tomorrowShowOption = 2,
    this.nextSevenDaysShowOption = 1,
    this.inboxShowOption = 1,
    this.allShowOption = 0,
    this.completedShowOption = 0,
    this.trashShowOption = 0,

    // 默认清单ID
    this.defaultChecklistId = 1,
  });

  String theme;
  String language;

  bool showProfile;
  bool showSearch;
  bool showSmartLists;
  bool showCustomLists;
  bool showTags;
  bool showFilters;

  int todayShowOption;
  int tomorrowShowOption;
  int nextSevenDaysShowOption;
  int inboxShowOption;
  int allShowOption;
  int completedShowOption;
  int trashShowOption;

  int defaultChecklistId;
}
