import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/core/config/app_config.dart';
import 'package:my_dida/core/config/prod_config.dart';
import 'package:my_dida/core/themes/color_constants.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/logger/logger.dart';
import 'package:my_dida/core/router/go_router.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/features/calendar/providers/calendar_page_provider.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:my_dida/features/operation_undo/providers/operation_stack_provider.dart';
import 'package:my_dida/features/settings/providers/sidebar_config_provider.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/services/active_reminder_manager.dart';
import 'package:my_dida/features/tasks/services/attachment_service.dart';
import 'package:my_dida/features/tasks/services/notification_service.dart';
import 'package:my_dida/features/tasks/services/task_notification_navigation_service.dart';
import 'package:my_dida/features/tomato/providers/tomato_provider.dart';
import 'package:provider/provider.dart';

void main() => mainCommon(ProdConfig());

void mainCommon(AppConfig config) async {
  // ensureInitialized() 方法的作用是确保 Flutter 运行时环境已经初始化完毕。
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Isar 数据库
  await setupLocator(config);

  // 初始化本地通知
  await getIt<NotificationService>().initialize();

  // 初始化操作栈
  final operationStack = getIt<OperationStackProvider>();
  await operationStack.initialize();

  // 异步清理孤儿附件目录，不阻塞启动
  unawaited(_runAttachmentCleanup());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(DefaultColorTheme()),
        ),
        ProxyProvider<ThemeProvider, ColorTheme>(
          update: (context, themeProvider, previousTheme) =>
              themeProvider.theme,
        ),
        ChangeNotifierProvider(create: (context) => ChecklistProvider()),
        ChangeNotifierProvider(create: (context) => CalendarPageProvider()),
        ChangeNotifierProvider(create: (context) => HabitProvider()),
        ChangeNotifierProvider(create: (context) => TomatoProvider()),
        ChangeNotifierProvider.value(value: operationStack),
        ChangeNotifierProvider.value(value: getIt<SidebarConfigProvider>()),

        // 使用 ChangeNotifierProxyProvider
        ChangeNotifierProxyProvider<ChecklistProvider, TaskProvider>(
          // 首次创建时调用，就传入 checklistProvider.currentChecklist
          create: (context) => TaskProvider(
            Provider.of<ChecklistProvider>(
              context,
              listen: false,
            ).currentCheckList,
          ),
          // update 的返回值应该是 TaskProvider
          update: (context, checklistProvider, previousTaskProvider) {
            /// 只有 checklistProvider.currentChecklist 发生变化时才进行更新
            if (previousTaskProvider != null &&
                checklistProvider.currentCheckList !=
                    previousTaskProvider.currentChecklist) {
              // 更新 TaskProvider 中的依赖，级联操作符会返回 updateCurrentTasks 之后的自身！
              return previousTaskProvider
                ..updateCurrentTasks(checklistProvider.currentCheckList);
            }

            return TaskProvider(
              Provider.of<ChecklistProvider>(
                context,
                listen: false,
              ).currentCheckList,
            );
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final TaskNotificationNavigationService _navigationService;
  late final StreamSubscription<int> _taskSelectionSubscription;

  @override
  void initState() {
    super.initState();
    _navigationService = getIt<TaskNotificationNavigationService>();
    _taskSelectionSubscription = _navigationService.taskSelections.listen(
      _openTaskDetailRoute,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingTaskId = _navigationService.consumePendingTaskId();
      if (pendingTaskId != null) {
        _openTaskDetailRoute(pendingTaskId);
      }
    });

    getIt<ActiveReminderManager>().startForegroundCheck();
  }

  @override
  void dispose() {
    _taskSelectionSubscription.cancel();
    getIt<ActiveReminderManager>().stopForegroundCheck();
    super.dispose();
  }

  void _openTaskDetailRoute(int taskId) {
    if (!mounted) {
      return;
    }

    goRouter.push('/tasks/$taskId');
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'My dida',
    scaffoldMessengerKey: getIt<AppMessageService>().scaffoldMessengerKey,

    /// 路由配置
    routerConfig: goRouter,

    /// builder 作用是 在 MaterialApp.router 构建任意子组件时，插入额外的 widget
    /// 只不过这里没有插入而是直接返回了child，原因：Material.router会创建新的context，导致子widget无法通过context获取Provider，所以通过builder传入 MultiProvider 的context，
    builder: (context, child) => child!,

    // 主题
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
    ),

    // 本地化：强制中文并提供所需 delegate（含 Cupertino）
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );
}

Future<void> _runAttachmentCleanup() async {
  try {
    final isar = getIt<Isar>();
    final taskIds = await isar.tasks.where().idProperty().findAll();
    await getIt<AttachmentService>().cleanupOrphans(taskIds);
  } catch (e) {
    logger.e('启动扫描清理孤儿附件目录异常: $e');
  }
}
