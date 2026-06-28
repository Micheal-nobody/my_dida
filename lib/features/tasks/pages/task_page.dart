import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/core/constants/app_constants.dart';
import 'package:my_dida/core/constants/colors_constants.dart';
import 'package:my_dida/core/constants/dimension_constants.dart';
import 'package:my_dida/core/constants/ui_constants.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/router/shell_scaffold_key.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:my_dida/features/checklist/widgets/add_checklist_dialog.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:my_dida/features/habits/widgets/edit_habit_dialog.dart';
import 'package:my_dida/features/habits/widgets/habit_card.dart';
import 'package:my_dida/features/habits/widgets/habit_check_in_dialog.dart';
import 'package:my_dida/features/settings/widgets/sort_and_group_dialog.dart';
import 'package:my_dida/features/settings/widgets/view_changer_dialog.dart';
import 'package:my_dida/features/settings/widgets/visible_range_dialog.dart';
import 'package:my_dida/features/tasks/pages/task_detail_page.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/widgets/board_view.dart';
import 'package:my_dida/features/tasks/widgets/task_card.dart';
import 'package:my_dida/shared/widgets/custom_floating_action_button.dart';
import 'package:provider/provider.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<StatefulWidget> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final AppMessageService _messageService = getIt<AppMessageService>();



  @override
  Widget build(BuildContext context) {
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final currentChecklist = checklistProvider.currentCheckList;
    final allChecklists = checklistProvider.allCheckLists;

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
            icon: const Icon(Icons.view_quilt),
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
                          child: const Text(
                            '删除',
                            style: TextStyle(color: Colors.red),
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
                const PopupMenuItem(
                  value: 'sort_group',
                  child: Row(
                    children: [
                      Icon(Icons.sort, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('排序与分组'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'visible_range',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('可见范围'),
                    ],
                  ),
                ),
                if (!isSystemList) ...[
                  const PopupMenuItem(
                    value: 'list_settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('清单设置'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete_list',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red),
                        SizedBox(width: 8),
                        Text('放入垃圾桶', style: TextStyle(color: Colors.red)),
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
            );
          }

          final List<Widget> groupWidgets = [];

          groupedTasks.forEach((groupTitle, tasks) {
            if (tasks.isEmpty) return;

            groupWidgets.add(
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Row(
                    children: [
                      Text(
                        groupTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${tasks.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  children: tasks.map((task) {
                    final isTrashList = currentChecklist.isTrash;
                    return Dismissible(
                      key: Key('list_${task.id}'),
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(
                          left: Dimensions.paddingL,
                        ),
                        color: isTrashList ? Colors.blue : AppColors.success,
                        child: Icon(
                          isTrashList
                              ? Icons.settings_backup_restore
                              : Icons.check,
                          color: AppColors.textOnPrimary,
                          size: 28,
                        ),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        color: AppColors.error,
                        padding: const EdgeInsets.only(
                          right: Dimensions.paddingL,
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: AppColors.textOnPrimary,
                          size: 28,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          if (isTrashList) {
                            await taskProvider.execute(RestoreTask(task));
                            _messageService.showSuccess('任务已还原');
                            return false;
                          }
                          await taskProvider.execute(
                            UpdateTaskIsDone(task, true),
                          );
                          return false;
                        } else if (direction == DismissDirection.endToStart) {
                          return showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                isTrashList
                                    ? '永久删除任务'
                                    : UIStrings.deleteTaskTitle,
                              ),
                              content: Text(
                                isTrashList
                                    ? '确认要永久删除此任务吗？该操作无法恢复。'
                                    : UIStrings.deleteTaskMessage,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text(UIStrings.cancel),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                  child: const Text(UIStrings.delete),
                                ),
                              ],
                            ),
                          );
                        }
                        return false;
                      },
                      onDismissed: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          try {
                            await taskProvider.execute(DeleteTask(task));
                            _messageService.showSuccess(
                              isTrashList ? '任务已永久删除' : UIStrings.taskDeleted,
                            );
                          } catch (e) {
                            _messageService.showError(
                              '${UIStrings.errorDeleting}: $e',
                            );
                          }
                        }
                      },
                      child: TaskCard(
                        task: task,
                        checklistName: task.getChecklistName(allChecklists),
                        onToggleDone: (value) {
                          if (isTrashList) {
                            taskProvider.execute(RestoreTask(task));
                            _messageService.showSuccess('任务已还原');
                          } else {
                            taskProvider.execute(
                              UpdateTaskIsDone(task, value!),
                            );
                          }
                        },
                        onTap: () {
                          if (isTrashList) {
                            _messageService.showInfo('垃圾桶中的任务无法直接查看详情');
                          } else {
                            TaskDetailPage.show(context, task);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          });

          // 习惯卡片
          if (isTodayTasks && habitProvider.habits.isNotEmpty) {
            final habits = habitProvider.habits;
            final List<Widget> habitCards = [];

            for (final habit in habits) {
              final isCompleted = habitProvider.isTodayCompleted(habit);
              if (taskProvider.visibleRange == TaskVisibleRange.undone &&
                  isCompleted) {
                continue;
              }
              if (taskProvider.visibleRange == TaskVisibleRange.done &&
                  !isCompleted) {
                continue;
              }

              habitCards.add(
                HabitCard(
                  habit: habit,
                  progress: habitProvider.getTodayProgress(habit),
                  isCompleted: isCompleted,
                  onTap: () {
                    HabitCheckInDialog.show(context: context, habit: habit);
                  },
                  onSkip: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('跳过今天'),
                        content: const Text('确定要跳过今天的习惯吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await habitProvider.skipToday(habit);
                    }
                  },
                  onEdit: () {
                    EditHabitDialog.show(context, habit);
                  },
                ),
              );
            }

            if (habitCards.isNotEmpty) {
              groupWidgets.add(
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Row(
                      children: [
                        const Text(
                          UIStrings.habits,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${habitCards.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: habitCards,
                  ),
                ),
              );
            }
          }

          if (groupWidgets.isEmpty) {
            return const Center(
              child: Text(
                '暂无任务',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: groupWidgets.length,
            itemBuilder: (context, index) => groupWidgets[index],
          );
        },
      ),

      floatingActionButton: const CustomFloatingActionButton(),
    );
  }
}
