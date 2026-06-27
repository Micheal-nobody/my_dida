import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/events/event_bus.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/features/checklist/repositories/checklist_repository.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';
import 'package:my_dida/features/settings/models/sidebar_config.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/repositories/task_repository.dart';
import 'package:my_dida/features/tasks/services/notification_service.dart';
import 'package:my_dida/features/tasks/services/task_notification_navigation_service.dart';
import 'package:my_dida/features/tomato/models/custom_tomato.dart';
import 'package:my_dida/features/tomato/models/tomato_record.dart';
import 'package:my_dida/features/tomato/providers/tomato_provider.dart';
import 'package:my_dida/features/tomato/repositories/custom_tomato_repository.dart';
import 'package:my_dida/features/tomato/repositories/tomato_record_repository.dart';

void main() {
  late Isar isar;
  late Directory tempDir;
  late TomatoRecordRepository tomatoRepository;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await getIt.reset();

    tempDir = await Directory.systemTemp.createTemp('my_dida_tomato_test_');
    isar = await Isar.open(
      [
        TaskSchema,
        HabitSchema,
        OperationSchema,
        ChecklistSchema,
        SidebarConfigSchema,
        TomatoRecordSchema,
        CustomTomatoSchema,
      ],
      directory: tempDir.path,
      name: 'tomato_test_${DateTime.now().microsecondsSinceEpoch}',
    );

    getIt
      ..registerSingleton<Isar>(isar)
      ..registerSingleton<AppMessageService>(AppMessageService())
      ..registerSingleton<EventBus>(EventBus())
      ..registerSingleton<TaskNotificationNavigationService>(
        TaskNotificationNavigationService(),
      )
      ..registerSingleton<TaskRepository>(TaskRepository())
      ..registerSingleton<ChecklistRepository>(ChecklistRepository())
      ..registerSingleton<TomatoRecordRepository>(TomatoRecordRepository())
      ..registerSingleton<CustomTomatoRepository>(CustomTomatoRepository())
      // 注册一个最小化的 NotificationService 依赖
      ..registerSingleton<NotificationService>(NotificationService());

    tomatoRepository = getIt<TomatoRecordRepository>();
  });

  tearDown(() async {
    await getIt.reset();
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('TomatoProvider 计时状态测试', () {
    test('初始状态应该为空闲，计时为25分钟', () {
      final provider = TomatoProvider(
        tomatoRecordRepository: tomatoRepository,
      );

      expect(provider.status, TomatoStatus.idle);
      expect(provider.duration, 25 * 60);
      expect(provider.isRunning, false);
      expect(provider.isPaused, false);
    });

    test('选择不同快捷时间应该改变计时时长', () {
      final provider = TomatoProvider(
        tomatoRecordRepository: tomatoRepository,
      );

      provider.selectShortBreak();
      expect(provider.status, TomatoStatus.shortBreak);
      expect(provider.duration, 5 * 60);

      provider.selectLongBreak();
      expect(provider.status, TomatoStatus.longBreak);
      expect(provider.duration, 15 * 60);

      provider.selectFocus();
      expect(provider.status, TomatoStatus.idle);
      expect(provider.duration, 25 * 60);
    });

    test('关联任务应该更新 associatedTask 属性', () {
      final provider = TomatoProvider(
        tomatoRecordRepository: tomatoRepository,
      );

      final task = Task(name: '测试专注任务', isAllDay: true);
      provider.setAssociatedTask(task);

      expect(provider.associatedTask?.name, '测试专注任务');

      provider.setAssociatedTask(null);
      expect(provider.associatedTask, null);
    });

    test('开始计时应该切换状态为专注中并启动运行', () {
      final provider = TomatoProvider(
        tomatoRecordRepository: tomatoRepository,
      );

      provider.start();
      expect(provider.status, TomatoStatus.focus);
      expect(provider.isRunning, true);
      expect(provider.isPaused, false);

      provider.pause();
      expect(provider.isRunning, true);
      expect(provider.isPaused, true);

      provider.resume();
      expect(provider.isRunning, true);
      expect(provider.isPaused, false);

      provider.dispose();
    });

    test('在未开始专注前放弃番茄钟不应该记录在数据库', () async {
      final provider = TomatoProvider(
        tomatoRecordRepository: tomatoRepository,
      );

      await provider.abandon();
      final records = await tomatoRepository.selectAll();
      expect(records.isEmpty, true);
    });

    test('自定义番茄钟的增删、激活和统计测试', () async {
      final customRepo = getIt<CustomTomatoRepository>();
      final provider = TomatoProvider(
        tomatoRecordRepository: tomatoRepository,
        customTomatoRepository: customRepo,
      );

      await provider.loadCustomTomatoes();
      expect(provider.customTomatoes.isEmpty, true);

      // 添加自定义番茄钟
      await provider.addCustomTomato('帕梅拉', 40);
      expect(provider.customTomatoes.length, 1);
      expect(provider.customTomatoes[0].name, '帕梅拉');
      expect(provider.customTomatoes[0].focusMinutes, 40);

      // 激活自定义番茄钟
      provider.setActiveCustomTomato(provider.customTomatoes[0]);
      expect(provider.activeCustomTomato?.name, '帕梅拉');
      expect(provider.duration, 40 * 60);

      // 统计测试 (今天累计)
      int todayMins = await provider.getCustomTomatoTodayMinutes(
        provider.customTomatoes[0].id,
      );
      expect(todayMins, 0);

      // 模拟专注完成记录
      final record = TomatoRecord(
        customTomatoId: provider.customTomatoes[0].id,
        taskName: '帕梅拉',
        categoryName: '自定义番茄钟',
        startTime: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          12,
        ),
        endTime: DateTime.now(),
        durationMinutes: 40,
      );
      await tomatoRepository.insert(record);

      todayMins = await provider.getCustomTomatoTodayMinutes(
        provider.customTomatoes[0].id,
      );
      expect(todayMins, 40);

      final totalStats = await provider.getCustomTomatoTotalStats(
        provider.customTomatoes[0].id,
      );
      expect(totalStats['completedCount'], 1);
      expect(totalStats['totalMinutes'], 40);

      // 删除自定义番茄钟
      final tomatoId = provider.customTomatoes[0].id;
      await provider.deleteCustomTomato(tomatoId);
      expect(provider.customTomatoes.isEmpty, true);
      expect(provider.activeCustomTomato, null);
    });
  });
}
