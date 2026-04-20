import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/ui/app_message_service.dart';
import 'config/locator.dart';
import 'provider/checklist_provider.dart';
import 'provider/habit_provider.dart';
import 'provider/operation_stack_provider.dart';
import 'provider/task_provider.dart';
import 'router/go_router.dart';

void main() async {
  // ensureInitialized() 方法的作用是确保 Flutter 运行时环境已经初始化完毕。
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Isar 数据库
  await setupLocator();

  // 初始化操作栈
  final operationStack = getIt<OperationStackProvider>();
  await operationStack.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ChecklistProvider()),
        ChangeNotifierProvider(create: (context) => HabitProvider()),
        ChangeNotifierProvider.value(value: operationStack),

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
