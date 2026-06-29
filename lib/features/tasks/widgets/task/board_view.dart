import 'package:flutter/material.dart';
import 'package:my_dida/core/constants/dimension_constants.dart';
import 'package:my_dida/core/constants/ui_constants.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/features/checklist/models/checklist_vo.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:my_dida/features/habits/widgets/edit_habit_dialog.dart';
import 'package:my_dida/features/habits/widgets/habit_card.dart';
import 'package:my_dida/features/habits/widgets/habit_check_in_dialog.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/pages/task_detail_page.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/widgets/task/task_card.dart';
import 'package:provider/provider.dart';

class BoardView extends StatelessWidget {
  const BoardView({
    required this.groupedTasks,
    required this.allChecklists,
    required this.currentChecklist,
    required this.isTodayTasks,
    super.key,
  });

  final Map<String, List<Task>> groupedTasks;
  final List<ChecklistVO> allChecklists;
  final ChecklistVO currentChecklist;
  final bool isTodayTasks;

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final habitProvider = Provider.of<HabitProvider>(context);
    final colorTheme = context.theme;
    final messageService = getIt<AppMessageService>();
    final isTrashList = currentChecklist.isTrash;

    // 1. 确定所有的 Tab
    final taskGroups = groupedTasks.keys.toList();
    final List<String> tabTitles = [...taskGroups];

    // 计算过滤后的习惯卡片
    final List<Widget> habitCards = [];
    if (isTodayTasks && habitProvider.habits.isNotEmpty) {
      final habits = habitProvider.habits;
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
    }

    final hasHabits = isTodayTasks && habitCards.isNotEmpty;
    if (hasHabits) {
      tabTitles.add('习惯');
    }

    if (tabTitles.isEmpty) {
      return const Center(
        child: Text(
          '暂无任务',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // 2. 渲染带有顶部 TabBar 和中下部 TabBarView 的布局
    return DefaultTabController(
      length: tabTitles.length,
      child: Column(
        children: [
          Container(
            color: colorTheme.cardBackground,
            alignment: Alignment.centerLeft,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: colorTheme.primary,
              unselectedLabelColor: colorTheme.textSecondary,
              indicatorColor: colorTheme.primary,
              dividerColor: Colors.grey[200],
              tabs: tabTitles.map((title) {
                // 计算该 Tab 的数量
                int count = 0;
                if (title == '习惯') {
                  count = habitCards.length;
                } else {
                  count = groupedTasks[title]?.length ?? 0;
                }

                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: tabTitles.map((title) {
                if (title == '习惯') {
                  return ListView.builder(
                    itemCount: habitCards.length,
                    itemBuilder: (context, index) => habitCards[index],
                  );
                }

                final tasks = groupedTasks[title] ?? [];

                if (tasks.isEmpty) {
                  return const Center(
                    child: Text(
                      '暂无任务',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemBuilder: (context, taskIndex) {
                    final task = tasks[taskIndex];

                    return Dismissible(
                      key: Key('board_${task.id}'),
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(
                          left: Dimensions.paddingL,
                        ),
                        color: isTrashList ? Colors.blue : colorTheme.success,
                        child: Icon(
                          isTrashList
                              ? Icons.settings_backup_restore
                              : Icons.check,
                          color: colorTheme.textOnPrimary,
                          size: 28,
                        ),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        color: colorTheme.error,
                        padding: const EdgeInsets.only(
                          right: Dimensions.paddingL,
                        ),
                        child: Icon(
                          Icons.delete,
                          color: colorTheme.textOnPrimary,
                          size: 28,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          if (isTrashList) {
                            await taskProvider.execute(RestoreTask(task));
                            messageService.showSuccess('任务已还原');
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
                                    backgroundColor: colorTheme.error,
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
                            messageService.showSuccess(
                              isTrashList
                                  ? '任务已永久删除'
                                  : UIStrings.taskDeleted,
                            );
                          } catch (e) {
                            messageService.showError(
                              '${UIStrings.errorDeleting}: $e',
                            );
                          }
                        }
                      },
                      child: TaskCard(
                        task: task,
                        checklistName: task.getChecklistName(allChecklists),
                        checklistColor: task.getChecklist(allChecklists).color,
                        onToggleDone: (value) {
                          if (isTrashList) {
                            taskProvider.execute(RestoreTask(task));
                            messageService.showSuccess('任务已还原');
                          } else {
                            taskProvider.execute(
                              UpdateTaskIsDone(task, value!),
                            );
                          }
                        },
                        onTap: () {
                          if (isTrashList) {
                            messageService.showInfo('垃圾桶中的任务无法直接查看详情');
                          } else {
                            TaskDetailPage.show(context, task);
                          }
                        },
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
