import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_dida/core/themes/color_constants.dart';
import 'package:my_dida/features/settings/models/sidebar_config.dart';
import 'package:my_dida/features/settings/providers/sidebar_config_provider.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/pages/four_quadrants_page.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:provider/provider.dart';

class FakeTaskProvider extends ChangeNotifier implements TaskProvider {
  FakeTaskProvider(this._mockTasks);
  final List<Task> _mockTasks;
  final List<dynamic> executedOperations = [];

  @override
  Stream<List<Task>> watchAllTasks() => Stream.value(_mockTasks);

  @override
  Future<void> execute(dynamic operation) async {
    executedOperations.add(operation);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSidebarConfigProvider extends ChangeNotifier
    implements SidebarConfigProvider {
  FakeSidebarConfigProvider(this.config);
  @override
  SidebarConfig config;

  @override
  Future<void> updateQuadrantHideCompleted(bool hide) async {
    config.quadrantHideCompleted = hide;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('FourQuadrantsPage builds tasks and toggles task completion', (
    tester,
  ) async {
    final tasks = [
      Task(name: '高优先级任务', priority: TaskPriority.high, isAllDay: true),
      Task(name: '中优先级任务', priority: TaskPriority.medium, isAllDay: true),
    ];

    final fakeTaskProvider = FakeTaskProvider(tasks);
    final fakeSidebarProvider = FakeSidebarConfigProvider(
      SidebarConfig(quadrantHideCompleted: false),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ColorTheme>.value(value: DefaultColorTheme()),
          ChangeNotifierProvider<TaskProvider>.value(value: fakeTaskProvider),
          ChangeNotifierProvider<SidebarConfigProvider>.value(
            value: fakeSidebarProvider,
          ),
        ],
        child: const MaterialApp(home: FourQuadrantsPage()),
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
  });
}
