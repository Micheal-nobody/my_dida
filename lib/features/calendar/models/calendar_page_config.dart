import 'package:isar_community/isar.dart';
import 'package:my_dida/shared/models/base_entity.dart';

part 'calendar_page_config.g.dart';

@Collection()
class CalendarPageConfig extends BaseEntity {
  CalendarPageConfig({
    this.showCompletedTasks = true,
    this.visibleMode = 'all', // 'all' 或 'custom'
    this.visibleChecklistIds = const [],
    this.viewMode = 'month', // 'month', 'week', 'agenda' 等
    this.isTimeFolded = false,
  });

  bool showCompletedTasks;
  String visibleMode;
  List<int> visibleChecklistIds;
  String viewMode;
  bool isTimeFolded;
}
