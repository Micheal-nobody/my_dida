import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/pages/CalendarPage.dart';
import 'package:my_dida/pages/PomodoroPage.dart';
import 'package:my_dida/pages/TodoPage.dart';

import '../pages/CalendarScreen.dart';

//TODO: 也许可以把 TodoDetails 模块放在这里，父 Navigator 就是Material App 的 Navigator
final GoRouter goRouter = GoRouter(
  // 初始路由
  initialLocation: '/tomato',
  routes: [
    StatefulShellRoute.indexedStack(
      /// 整个页面的内容，其中 Branch 中的内容会填充到 body 中
      builder: (context, state, navigationShell) => Scaffold(
        appBar: AppBar(title: const Text('My Dida')),

        //? StatefulNavigationShell 是一个特殊的路由组件，它允许在底部导航栏中切换不同的分支（branch），每个分支都有自己的导航栈。
        body: navigationShell,

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,

          /// index 参数表示当前选中的底部导航项索引，当前项目中
          onTap: (index) => _onTap(context, index, navigationShell),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.masks), label: '待办清单'),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_view_day),
              label: '日历视图',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.circle), label: '番茄钟'),
          ],
        ),
      ),

      /// 这部分是路由分支，每个分支对应一个底部导航项
      branches: [
        // 为每一个底部导航项创建一个分支（branch）
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/todoList',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TodoPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CalendarPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tomato',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: PomodoroPage()),
            ),
          ],
        ),
      ],
    ),
  ],

  /// errorBuilder 作用是 构建错误页面，默认情况下，当路由匹配失败时，会显示一个错误页面。
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(child: Text('Error: ${state.error}')),
  ),
);

// 底部导航栏点击处理
void _onTap(
  BuildContext context,
  int index,
  StatefulNavigationShell navigationShell,
) {
  navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );
}
