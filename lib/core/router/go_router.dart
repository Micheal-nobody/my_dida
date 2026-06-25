import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/core/router/shell_scaffold_key.dart';
import 'package:my_dida/features/calendar/pages/calendar_page.dart';
import 'package:my_dida/features/habits/pages/habit_archived_page.dart';
import 'package:my_dida/features/habits/pages/habit_data_summary_page.dart';
import 'package:my_dida/features/habits/pages/habit_manage_page.dart';
import 'package:my_dida/features/habits/pages/habits_page.dart';
import 'package:my_dida/features/operation_undo/pages/operation_page.dart';
import 'package:my_dida/features/settings/pages/settings_page.dart';
import 'package:my_dida/features/settings/pages/sidebar_settings_page.dart';
import 'package:my_dida/features/settings/pages/smart_lists_settings_page.dart';
import 'package:my_dida/features/tasks/pages/four_quadrants_page.dart';
import 'package:my_dida/features/tasks/pages/search_page.dart';
import 'package:my_dida/features/tasks/pages/task_detail_route_page.dart';
import 'package:my_dida/features/tasks/pages/task_page.dart';
import 'package:my_dida/features/tasks/widgets/task_drawer.dart';
import 'package:my_dida/features/tomato/pages/tomato_page.dart';
import 'package:my_dida/features/tomato/pages/tomato_timer_full_screen_page.dart';
import 'package:my_dida/features/tomato/providers/tomato_provider.dart';
import 'package:my_dida/shared/widgets/dynamic_calendar_icon.dart';
import 'package:provider/provider.dart';

final GoRouter goRouter = GoRouter(
  // 初始路由
  initialLocation: '/todoList',
  routes: [
    GoRoute(
      path: '/pomodoro/timer',
      pageBuilder: (context, state) =>
          const MaterialPage(child: TomatoTimerFullScreenPage()),
    ),
    GoRoute(
      path: '/tasks/:taskId',
      pageBuilder: (context, state) {
        final taskId = int.tryParse(state.pathParameters['taskId'] ?? '');
        if (taskId == null) {
          return const NoTransitionPage(
            child: Scaffold(body: Center(child: Text('无效的任务 ID'))),
          );
        }

        return MaterialPage(child: TaskDetailRoutePage(taskId: taskId));
      },
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => const MaterialPage(child: SearchPage()),
    ),
    GoRoute(
      path: '/four_quadrants',
      pageBuilder: (context, state) =>
          const MaterialPage(child: FourQuadrantsPage()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) =>
          const MaterialPage(child: SettingsPage()),
    ),
    GoRoute(
      path: '/settings/smart-lists',
      pageBuilder: (context, state) =>
          const MaterialPage(child: SmartListsSettingsPage()),
    ),
    GoRoute(
      path: '/settings/sidebar',
      pageBuilder: (context, state) =>
          const MaterialPage(child: SidebarSettingsPage()),
    ),
    GoRoute(
      path: '/habits/summary',
      pageBuilder: (context, state) =>
          const MaterialPage(child: HabitDataSummaryPage()),
    ),
    GoRoute(
      path: '/habits/manage',
      pageBuilder: (context, state) =>
          const MaterialPage(child: HabitManagePage()),
    ),
    GoRoute(
      path: '/habits/manage/archived',
      pageBuilder: (context, state) =>
          const MaterialPage(child: HabitArchivedPage()),
    ),
    StatefulShellRoute.indexedStack(
      /// 整个页面的内容，其中 Branch 中的内容会填充到 body 中
      builder: (context, state, navigationShell) => Scaffold(
        key: shellScaffoldKey,
        drawer: navigationShell.currentIndex == 0 ? const TodoDrawer() : null,
        drawerEnableOpenDragGesture: navigationShell.currentIndex == 0,
        //? StatefulNavigationShell 是一个特殊的路由组件，它允许在底部导航栏中切换不同的分支（branch），每个分支都有自己的导航栈。
        body: navigationShell,

        bottomNavigationBar: Consumer<TomatoProvider>(
          builder: (context, tomatoProvider, child) {
            final isRunning =
                tomatoProvider.isRunning &&
                !tomatoProvider.isPaused &&
                tomatoProvider.status != TomatoStatus.idle;

            return BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.masks),
                  label: '待办清单',
                ),
                const BottomNavigationBarItem(
                  icon: DynamicCalendarIcon(),
                  label: '日历视图',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.lock_clock),
                  label: '习惯',
                ),
                BottomNavigationBarItem(
                  icon: isRunning
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.timer),
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                value: tomatoProvider.totalDuration > 0
                                    ? tomatoProvider.duration /
                                          tomatoProvider.totalDuration
                                    : 1.0,
                                strokeWidth: 2,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Icon(Icons.timer_outlined),
                  label: '番茄钟',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: '操作记录',
                ),
              ],
            );
          },
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
              path: '/habits',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HabitsPage()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pomodoro',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TomatoPage()),
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
