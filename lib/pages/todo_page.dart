import 'package:flutter/material.dart';
import 'package:my_dida/constants/app_constants.dart';
import 'package:my_dida/constants/colors_constants.dart';
import 'package:my_dida/constants/dimension_constants.dart';
import 'package:my_dida/constants/ui_constants.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/features/cards/habit_card.dart';
import 'package:my_dida/features/cards/task_card.dart';
import 'package:my_dida/features/dialogs/edit_habit_dialog.dart';
import 'package:my_dida/features/dialogs/habit_check_in_dialog.dart';
import 'package:my_dida/features/task_detail/task_detail_page.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/provider/checklist_provider.dart';
import 'package:my_dida/provider/habit_provider.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/router/shell_scaffold_key.dart';
import 'package:my_dida/shared/common/custom_floating_action_button.dart';
import 'package:provider/provider.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<StatefulWidget> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final AppMessageService _messageService = getIt<AppMessageService>();
  bool _showCompletedTasks = false;

  @override
  void initState() {
    super.initState();
    // 加载习惯数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HabitProvider>(context, listen: false).loadAllHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    /// 使用 Provider 来获取 TodosProvider 实例
    //Optimize: 可以选择优化，使用Selector
    final checklistProvider = Provider.of<ChecklistProvider>(context);

    final currentChecklist = checklistProvider.currentCheckList;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => shellScaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(currentChecklist.name),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(UIStrings.confirmDialog),
                  content: const Text(UIStrings.showCompletedTasksQuestion),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(UIStrings.hideButton),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(UIStrings.showButton),
                    ),
                  ],
                ),
              );
              if (result != null) {
                setState(() {
                  _showCompletedTasks = result;
                });
              }
            },
            icon: Icon(
              _showCompletedTasks ? Icons.visibility : Icons.visibility_off,
            ),
          ),
        ],
      ),

      // 可滑动的列表视图，同时依赖TaskProvider.currentTasks和HabitProvider.habits
      body:
          Selector2<
            TaskProvider,
            HabitProvider,
            ({List<Task> tasks, List<dynamic> habits, bool isTodayTasks})
          >(
            selector: (_, taskProvider, habitProvider) => (
              tasks: taskProvider.currentTasks,
              habits: habitProvider.habits,
              isTodayTasks:
                  currentChecklist.id == AppConstants.todayCheckList.id,
            ),
            builder: (context, data, _) {
              final currentTasks = data.tasks;
              final habits = data.habits;
              final isTodayTasks = data.isTodayTasks;

              // 构建列表项
              final List<Widget> items = [];

              // 先添加任务卡片
              for (int i = 0; i < currentTasks.length; i++) {
                final task = currentTasks[i];
                // 如果任务已完成且不显示已完成任务，则跳过
                if (task.isDone && !_showCompletedTasks) {
                  continue;
                }

                items.add(
                  Dismissible(
                    key: Key(task.id.toString()),
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: Dimensions.paddingL),
                      color: AppColors.success,
                      child: const Icon(
                        Icons.check,
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
                        // Left swipe - complete task
                        await Provider.of<TaskProvider>(
                          context,
                          listen: false,
                        ).updateTaskIsDone(task, true);
                        return false; // Don't dismiss, just complete
                      } else if (direction == DismissDirection.endToStart) {
                        // Right swipe - delete task
                        return showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text(UIStrings.deleteTaskTitle),
                            content: const Text(UIStrings.deleteTaskMessage),
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
                        // Left swipe - delete task
                        try {
                          await Provider.of<TaskProvider>(
                            context,
                            listen: false,
                          ).deleteTask(task);
                          _messageService.showSuccess(UIStrings.taskDeleted);
                        } catch (e) {
                          _messageService.showError(
                            '${UIStrings.errorDeleting}: $e',
                          );
                        }
                      }
                    },
                    child: TaskCard(
                      task: task,
                      checklistName: currentChecklist.name,
                      onToggleDone: (value) {
                        Provider.of<TaskProvider>(
                          context,
                          listen: false,
                        ).updateTaskIsDone(task, value!);
                      },
                      onTap: () {
                        TaskDetailPage.show(
                          context,
                          task,
                        );
                      },
                    ),
                  ),
                );
              }

              // 添加分界线与习惯卡片（仅在"今天"盒子下显示）
              if (isTodayTasks && habits.isNotEmpty) {
                // 先检查有多少习惯需要显示
                final List<Widget> habitCards = [];
                final habitProvider = Provider.of<HabitProvider>(
                  context,
                  listen: false,
                );

                for (final habit in habits) {
                  // 如果习惯已完成且不显示已完成项目，则跳过
                  if (habitProvider.isTodayCompleted(habit) &&
                      !_showCompletedTasks) {
                    continue;
                  }
                  habitCards.add(HabitCard(
                    habit: habit,
                    progress: habitProvider.getTodayProgress(habit),
                    isCompleted: habitProvider.isTodayCompleted(habit),
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
                        habitProvider.skipToday(habit);
                      }
                    },
                    onEdit: () {
                      EditHabitDialog.show(context, habit);
                    },
                  ));
                }

                // 只有当有习惯要显示时才添加分隔线
                if (habitCards.isNotEmpty) {
                  if (items.isNotEmpty) {
                    items.add(
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: Dimensions.paddingS,
                          horizontal: Dimensions.paddingM,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingS,
                              ),
                              child: Text(UIStrings.habits),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),
                    );
                  }

                  // 添加所有习惯卡片
                  items.addAll(habitCards);
                }
              }

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => items[index],
              );
            },
          ),

      // 悬浮按钮
      floatingActionButton: const CustomFloatingActionButton(),
    );
  }
}
