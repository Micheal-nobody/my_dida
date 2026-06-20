import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/model/entity/calendar_page_config.dart';

void main() {
  test('CalendarPageConfig 默认配置测试', () {
    final config = CalendarPageConfig();
    expect(config.showCompletedTasks, true);
    expect(config.visibleMode, 'all');
    expect(config.visibleChecklistIds, isEmpty);
    expect(config.viewMode, 'month');
    expect(config.isTimeFolded, false);
  });
}
