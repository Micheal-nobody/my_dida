import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/model/entity/checklist.dart';
import 'package:my_dida/model/entity/habit.dart';
import 'package:my_dida/model/entity/operation.dart';
import 'package:my_dida/model/entity/sidebar_config.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/entity/tomato_record.dart';
import 'package:my_dida/provider/tomato_provider.dart';
import 'package:my_dida/repository/task_repository.dart';
import 'package:my_dida/repository/tomato_record_repository.dart';
import 'package:my_dida/services/notification_service.dart';
import 'package:my_dida/services/task_notification_navigation_service.dart';
import 'package:my_dida/core/ui/app_message_service.dart';

void main() {
  late Isar isar;
  late Directory tempDir;
  late TomatoRecordRepository tomatoRepository;
  late TaskRepository taskRepository;

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
      ],
      directory: tempDir.path,
      name: 'tomato_test_${DateTime.now().microsecondsSinceEpoch}',
    );

    getIt
      ..registerSingleton<Isar>(isar)
      ..registerSingleton<AppMessageService>(AppMessageService())
      ..registerSingleton<TaskNotificationNavigationService>(
        TaskNotificationNavigationService(),
      )
      ..registerSingleton<TaskRepository>(TaskRepository())
      ..registerSingleton<TomatoRecordRepository>(TomatoRecordRepository())
      // 注册一个最小化的 NotificationService 依赖
      ..registerSingleton<NotificationService>(NotificationService());

    tomatoRepository = getIt<TomatoRecordRepository>();
    taskRepository = getIt<TaskRepository>();
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
        taskRepository: taskRepository,
      );

      expect(provider.status, TomatoStatus.idle);
      expect(provider.duration, 25 * 60);
      expect(provider.isRunning, false);
      expect(provider.isPaused, false);
    });

    test('选择不同快捷时间应该改变计时时长', () {
      final provider = TomatoProvider(
        tomatoRecordRepository: tomatoRepository,
        taskRepository: taskRepository,
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
        taskRepository: taskRepository,
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
        taskRepository: taskRepository,
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
        taskRepository: taskRepository,
      );

      await provider.abandon();
      final records = await tomatoRepository.selectAll();
      expect(records.isEmpty, true);
    });
  });
}
