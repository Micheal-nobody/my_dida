import 'package:isar_community/isar.dart';
import 'package:my_dida/shared/models/base_entity.dart';

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

    this.showFourQuadrants = true,
    this.quadrantName1 = '重要且紧急',
    this.quadrantName2 = '重要不紧急',
    this.quadrantName3 = '紧急不重要',
    this.quadrantName4 = '不重要不紧急',
    this.quadrantColor1 = 0xFFE57373,
    this.quadrantColor2 = 0xFFFFB74D,
    this.quadrantColor3 = 0xFF64B5F6,
    this.quadrantColor4 = 0xFF81C784,
    this.quadrantHideCompleted = true,
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

  bool showFourQuadrants;
  String quadrantName1;
  String quadrantName2;
  String quadrantName3;
  String quadrantName4;
  int quadrantColor1;
  int quadrantColor2;
  int quadrantColor3;
  int quadrantColor4;
  bool quadrantHideCompleted;
}
