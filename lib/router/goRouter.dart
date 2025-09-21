import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/pages/CalendarPage.dart';
import 'package:my_dida/pages/HabitsPage.dart';
import 'package:my_dida/pages/OperationPage.dart';
import 'package:my_dida/pages/TodoPage.dart';

final GoRouter goRouter = GoRouter(
  // 初始路由
  initialLocation: '/todoList',
  // initialLocation: '/calendarView',
  routes: [
    StatefulShellRoute.indexedStack(
      /// 整个页面的内容，其中 Branch 中的内容会填充到 body 中
      builder: (context, state, navigationShell) => Scaffold(
        //? 路由跳转时，这个函数会被调用！这意味着页面重新渲染！
        // appBar: _getAppBar(context, navigationShell.currentIndex),

        //? StatefulNavigationShell 是一个特殊的路由组件，它允许在底部导航栏中切换不同的分支（branch），每个分支都有自己的导航栈。
        body: navigationShell,

        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: navigationShell.currentIndex,

          /// index 参数表示当前选中的底部导航项索引，当前项目中
          onTap: (index) => _onTap(context, index, navigationShell),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.masks), label: '待办清单'),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: '日历视图',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.lock_clock), label: '习惯'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: '操作记录'),
          ],
        ),
      ),

      /// 这部分是路由分支，每个分支对应一个底部导航项
      branches: [
        // 为每一个底部导航项创建一个分支（branch）
        StatefulShellBranch(
          /// StatefulShellBranch.routes 表示分支中的路由
          routes: [
            GoRoute(
              path: '/todoList',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TodoPage()),
            ),
            GoRoute(
              path: '/todoDetails',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: Text("这是还没有做的 todo 详情页面！")),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendarView',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CalendarPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pomodoro',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HabitsPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/operations',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: OperationPage()),
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

/// 底部导航栏点击处理
void _onTap(
  BuildContext context,
  int index,
  StatefulNavigationShell navigationShell,
) {
  navigationShell.goBranch(
    index,
    //? initialLocation 表示是否初始化该分支的导航栈，如果为 true，则该分支的导航栈将初始化为该分支的根路由。
    //? 在这里 index == navigationShell.currentIndex 表示是否跳转到当前分支，如果是，则不需要初始化导航栈
    initialLocation: index == navigationShell.currentIndex,
  );
}
