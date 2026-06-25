import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/features/settings/models/sidebar_config.dart';
import 'package:my_dida/features/settings/providers/sidebar_config_provider.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/pages/four_quadrants_page.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:provider/provider.dart';

class FakeTaskProvider extends ChangeNotifier implements TaskProvider {
  final List<Task> _mockTasks;
  final List<dynamic> executedOperations = [];

  FakeTaskProvider(this._mockTasks);

  @override
  Stream<List<Task>> watchAllTasks() {
    return Stream.value(_mockTasks);
  }

  @override
  Future<void> execute(dynamic operation) async {
    executedOperations.add(operation);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSidebarConfigProvider extends ChangeNotifier implements SidebarConfigProvider {
  @override
  SidebarConfig config;

  FakeSidebarConfigProvider(this.config);

  @override
  Future<void> updateQuadrantHideCompleted(bool hide) async {
    config.quadrantHideCompleted = hide;
    notifyListeners();
  }

  @override
  Future<void> updateQuadrantColors({int? color1, int? color2, int? color3, int? color4}) async {
    if (color1 != null) config.quadrantColor1 = color1;
    if (color2 != null) config.quadrantColor2 = color2;
    if (color3 != null) config.quadrantColor3 = color3;
    if (color4 != null) config.quadrantColor4 = color4;
    notifyListeners();
  }

  @override
  Future<void> updateQuadrantNames({String? name1, String? name2, String? name3, String? name4}) async {
    if (name1 != null) config.quadrantName1 = name1;
    if (name2 != null) config.quadrantName2 = name2;
    if (name3 != null) config.quadrantName3 = name3;
    if (name4 != null) config.quadrantName4 = name4;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'FourQuadrantsPage builds tasks and toggles task completion',
    (WidgetTester tester) async {
      final tasks = [
        Task(
          name: '高优先级任务',
          priority: TaskPriority.high,
          isAllDay: true,
        ),
        Task(
          name: '中优先级任务',
          priority: TaskPriority.medium,
          isAllDay: true,
        ),
      ];

      final fakeTaskProvider = FakeTaskProvider(tasks);
      final fakeSidebarProvider = FakeSidebarConfigProvider(
        SidebarConfig(quadrantHideCompleted: false),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TaskProvider>.value(value: fakeTaskProvider),
            ChangeNotifierProvider<SidebarConfigProvider>.value(value: fakeSidebarProvider),
          ],
          child: const MaterialApp(
            home: FourQuadrantsPage(),
          ),
        ),
      );

      // 等待异步 Stream 数据
      await tester.pumpAndSettle();

      // 验证页面标题
      expect(find.text('时间管理四象限'), findsOneWidget);

      // 验证任务是否正确被渲染
      expect(find.text('高优先级任务'), findsOneWidget);
      expect(find.text('中优先级任务'), findsOneWidget);

      // 通过 Key 找到高优先级任务的方框并点击
      final checkboxFinder = find.byKey(const ValueKey('task_checkbox_高优先级任务'));
      expect(checkboxFinder, findsOneWidget);

      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // 校验 TaskProvider 的 execute 是否被调用，以切换状态
      expect(fakeTaskProvider.executedOperations.length, 1);
      final op = fakeTaskProvider.executedOperations.first;
      expect(op, isA<UpdateTaskIsDone>());
      expect((op as UpdateTaskIsDone).task.name, '高优先级任务');
      expect(op.value, true); // 原始状态是未完成，点击后变为已完成
    },
  );
}
