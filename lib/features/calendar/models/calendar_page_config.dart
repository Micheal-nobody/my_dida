import 'package:isar_community/isar.dart';
import 'package:my_dida/shared/models/base_entity.dart';

part 'calendar_page_config.g.dart';

enum CalendarVisibleMode{all , custom}

enum CalendarViewMode { month, week, agenda, threeDay }

@Collection()
class CalendarPageConfig extends BaseEntity {
  CalendarPageConfig({
    this.showCompletedTasks = true,
    this.visibleMode = CalendarVisibleMode.all,
    this.visibleChecklistIds = const [],
    this.viewMode = CalendarViewMode.month,
    this.isTimeFolded = false,
  });

  bool showCompletedTasks;
  @Enumerated(EnumType.name)
  CalendarVisibleMode visibleMode;
  List<int> visibleChecklistIds;
  @Enumerated(EnumType.name)
  CalendarViewMode viewMode;
  bool isTimeFolded;
}
