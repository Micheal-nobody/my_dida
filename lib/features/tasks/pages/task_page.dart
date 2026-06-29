import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/core/constants/app_constants.dart';
import 'package:my_dida/core/router/shell_scaffold_key.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:my_dida/features/checklist/widgets/add_checklist_dialog.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:my_dida/features/settings/widgets/sort_and_group_dialog.dart';
import 'package:my_dida/features/settings/widgets/view_changer_dialog.dart';
import 'package:my_dida/features/settings/widgets/visible_range_dialog.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/widgets/add_task_bottom_sheet.dart';
import 'package:my_dida/features/tasks/widgets/task/board_view.dart';
import 'package:my_dida/features/tasks/widgets/task/task_list_view.dart';
import 'package:provider/provider.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<StatefulWidget> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  @override
  Widget build(BuildContext context) {
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final currentChecklist = checklistProvider.currentCheckList;
    final allChecklists = checklistProvider.allCheckLists;
    final colorTheme = context.theme;

    return Scaffold(
      drawerEnableOpenDragGesture: false,
      endDrawerEnableOpenDragGesture: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => shellScaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(currentChecklist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: Icon(
              taskProvider.viewMode == TaskViewMode.list
                  ? Icons.list
                  : Icons.dashboard,
              color: colorTheme.iconColor,
            ),
            onPressed: () => ViewChangerDialog.show(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'sort_group') {
                SortAndGroupDialog.show(context);
              } else if (value == 'visible_range') {
                VisibleRangeDialog.show(context);
              } else if (value == 'list_settings') {
                if (!currentChecklist.isToday && !currentChecklist.isInbox) {
                  await showDialog(
                    context: context,
                    builder: (context) =>
                        AddChecklistDialog(checklist: currentChecklist),
                  );
                }
              } else if (value == 'delete_list') {
                if (!currentChecklist.isToday && !currentChecklist.isInbox) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('删除清单'),
                      content: Text('确认要删除清单 "${currentChecklist.name}" 吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            '删除',
                            style: TextStyle(color: colorTheme.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await checklistProvider.deleteChecklist(currentChecklist);
                  }
                }
              }
            },
            itemBuilder: (context) {
              final isSystemList =
                  currentChecklist.isToday || currentChecklist.isInbox;

              return [
                PopupMenuItem(
                  value: 'sort_group',
                  child: Row(
                    children: [
                      Icon(Icons.sort, color: colorTheme.textSecondary),
                      const SizedBox(width: 8),
                      const Text('排序与分组'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'visible_range',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, color: colorTheme.textSecondary),
                      const SizedBox(width: 8),
                      const Text('可见范围'),
                    ],
                  ),
                ),
                if (!isSystemList) ...[
                  PopupMenuItem(
                    value: 'list_settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: colorTheme.textSecondary),
                        const SizedBox(width: 8),
                        const Text('清单设置'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_list',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: colorTheme.error),
                        const SizedBox(width: 8),
                        Text(
                          '放入垃圾桶',
                          style: TextStyle(color: colorTheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ];
            },
          ),
        ],
      ),

      body: Consumer3<TaskProvider, HabitProvider, ChecklistProvider>(
        builder: (context, taskProvider, habitProvider, _, _) {
          final isTodayTasks =
              currentChecklist.id == AppConstants.todayCheckList.id;
          final groupedTasks = taskProvider.getGroupedCurrentTasks(
            allChecklists,
          );

          if (taskProvider.viewMode == TaskViewMode.board) {
            return BoardView(
              groupedTasks: groupedTasks,
              allChecklists: allChecklists,
              currentChecklist: currentChecklist,
              isTodayTasks: isTodayTasks,
            );
          }

          return TaskListView(
            groupedTasks: groupedTasks,
            allChecklists: allChecklists,
            currentChecklist: currentChecklist,
            isTodayTasks: isTodayTasks,
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: colorTheme.primaryBackground,
        child: Icon(Icons.add, color: colorTheme.iconOnPrimary),
        onPressed: () {
          AddTaskBottomSheet.show(context: context);
        },
      ),
    );
  }
}
