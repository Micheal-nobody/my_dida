import 'package:flutter/material.dart';
import 'package:my_dida/provider/BelongingBoxVOProvider.dart';
import 'package:my_dida/provider/TaskProvider.dart';
import 'package:my_dida/provider/TodosProvider.dart';
import 'package:my_dida/provider/UIStatusProvider.dart';
import 'package:my_dida/router/goRouter.dart';
import 'package:provider/provider.dart';

import 'locator/locator.dart';

void main() async{

  /// ensureInitialized() 方法的作用是确保 Flutter 运行时环境已经初始化完毕。
  WidgetsFlutterBinding.ensureInitialized();

  /// 初始化 Isar 数据库
  await setupLocator();

  //TODO: 或者使用ChangeNotifierProvider 中 create 返回一个 Future 对象
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TodosProvider()),
        ChangeNotifierProvider(create: (context) => UIStatusProvider()),

        /// 添加两个 Service
        ChangeNotifierProvider(create: (context) => TaskProvider()),
        ChangeNotifierProvider(create: (context) => BelongingBoxProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "My dida",

      /// 路由配置
      routerConfig: goRouter,

      /// builder 作用是 在 MaterialApp.router 构建任意子组件时，插入额外的 widget
      /// 只不过这里没有插入而是直接返回了child，原因：Material.router会创建新的context，导致子widget无法通过context获取Provider，所以通过builder传入 MultiProvider 的context，
      builder: (context,child) =>child!, // !是空安全断言，child 不是 null

      // 主题
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
    );
  }
}
