import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/features/calendar/models/calendar_page_config.dart';
import 'package:my_dida/features/calendar/providers/calendar_page_provider.dart';
import 'package:my_dida/features/calendar/widgets/calendar_visible_range_dialog.dart';
import 'package:my_dida/features/checklist/models/checklist_vo.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:provider/provider.dart';

class FakeCalendarPageProvider extends ChangeNotifier
    implements CalendarPageProvider {
  FakeCalendarPageProvider(this.config);
  @override
  CalendarPageConfig config;

  @override
  Future<void> updateConfig({
    bool? showCompletedTasks,
    String? visibleMode,
    List<int>? visibleChecklistIds,
    String? viewMode,
    bool? isTimeFolded,
  }) async {
    if (showCompletedTasks != null) {
      config.showCompletedTasks = showCompletedTasks;
    }
    if (visibleMode != null) config.visibleMode = visibleMode;
    if (visibleChecklistIds != null) {
      config.visibleChecklistIds = visibleChecklistIds;
    }
    if (viewMode != null) config.viewMode = viewMode;
    if (isTimeFolded != null) config.isTimeFolded = isTimeFolded;
    notifyListeners();
  }
}

class FakeChecklistProvider extends ChangeNotifier
    implements ChecklistProvider {
  FakeChecklistProvider(this.allCheckLists, this.currentCheckList);
  @override
  List<ChecklistVO> allCheckLists;

  @override
  ChecklistVO currentCheckList;

  @override
  void updateCurChecklist(ChecklistVO checklist) {
    currentCheckList = checklist;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'CalendarVisibleRangeDialog cascade logic test with Fake Providers',
    (tester) async {
      final checklists = [
        const ChecklistVO(id: 1, name: '收集箱', color: Colors.orange),
        const ChecklistVO(id: 2, name: '工作', color: Colors.blue),
        const ChecklistVO(id: 3, name: '生活', color: Colors.green),
      ];

      final fakeChecklistProvider = FakeChecklistProvider(
        checklists,
        checklists.first,
      );
      final fakeCalendarProvider = FakeCalendarPageProvider(
        CalendarPageConfig(visibleChecklistIds: [1, 2, 3]),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ChecklistProvider>.value(
              value: fakeChecklistProvider,
            ),
            ChangeNotifierProvider<CalendarPageProvider>.value(
              value: fakeCalendarProvider,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CalendarVisibleRangeDialog()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initially "全部" is checked (since visibleMode is 'all' by default)
      final allTile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, '全部'),
      );
      expect(allTile.value, true);

      // Verify sub-checklists are also visually rendered
      expect(find.text('收集箱'), findsOneWidget);
      expect(find.text('工作'), findsOneWidget);
      expect(find.text('生活'), findsOneWidget);

      // Uncheck "工作" checklist
      await tester.tap(find.text('工作'));
      await tester.pumpAndSettle();

      // "全部" should now be unchecked
      final allTileAfterUncheck = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, '全部'),
      );
      expect(allTileAfterUncheck.value, false);

      // "工作" tile should be unchecked
      final workTile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, '工作'),
      );
      expect(workTile.value, false);

      // "收集箱" tile should still be checked
      final inboxTile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, '收集箱'),
      );
      expect(inboxTile.value, true);

      // Tap "全部" to check it again
      await tester.tap(find.text('全部'));
      await tester.pumpAndSettle();

      // All should be checked now
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, '全部'),
            )
            .value,
        true,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, '工作'),
            )
            .value,
        true,
      );

      // Click cancel/confirm
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      // Verify calendarProvider config is updated
      expect(fakeCalendarProvider.config.visibleMode, 'all');
    },
  );
}
