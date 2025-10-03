import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/cards/HabitCard.dart';
import '../components/cards/TaskCard.dart';
import '../components/common/CustomFloatingActionButton.dart';
import '../components/dialogs/AddBelongingBoxDialog.dart';
import '../config/logger.dart';
import '../constants/app_constants.dart';
import '../constants/colors.dart';
import '../constants/dimensions.dart';
import '../constants/ui_strings.dart';
import '../model/entity/Task.dart';
import '../model/vo/BelongingBoxVO.dart';
import '../provider/BelongingBoxProvider.dart';
import '../provider/HabitProvider.dart';
import '../provider/TaskProvider.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<StatefulWidget> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
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
    print('TodoPage build');

    /// 使用 Provider 来获取 TodosProvider 实例
    //Optimize: 可以选择优化，使用Selector
    final belongingBoxProvider = Provider.of<BelongingBoxProvider>(context);

    final currentBelongingBox = belongingBoxProvider.currentBelongingBox;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentBelongingBox.name),
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
                  currentBelongingBox.id == AppConstants.todayBelongingBoxId,
            ),
            builder: (context, data, __) {
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
                      color: AppColors.error,
                      child: const Icon(
                        Icons.delete,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(
                        right: Dimensions.paddingL,
                      ),
                      color: AppColors.success,
                      child: const Icon(
                        Icons.check,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        // Left swipe - delete
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
                      } else if (direction == DismissDirection.endToStart) {
                        // Right swipe - complete
                        Provider.of<TaskProvider>(
                          context,
                          listen: false,
                        ).updateTaskIsDone(task, true);
                        return false; // Don't dismiss, just complete
                      }
                      return false;
                    },
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        // Delete task
                        Provider.of<TaskProvider>(
                          context,
                          listen: false,
                        ).deleteTask(task);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(UIStrings.taskDeleted)),
                        );
                      }
                    },
                    child: TaskCard(task),
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
                  habitCards.add(HabitCard(habit));
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

      // 侧边栏
      drawer: Drawer(
        child: Column(
          children: [
            // user账户头部
            const UserAccountsDrawerHeader(
              accountName: Text(AppConstants.appName),
              accountEmail: Text(AppConstants.appDescription),
              decoration: BoxDecoration(color: AppColors.primary),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.background,
                child: Icon(
                  Icons.person,
                  size: Dimensions.iconXL,
                  color: AppColors.primary,
                ),
              ),
            ),

            // 侧边栏菜单项
            Expanded(
              child: ListView(
                children: [
                  // Add new belonging box button
                  ListTile(
                    leading: const Icon(Icons.add, color: AppColors.success),
                    title: const Text(UIStrings.addNewBox),
                    onTap: () {
                      logger.i('点击了 Add New Box');
                      showDialog(
                        context: context,
                        builder: (context) => const AddBelongingBoxDialog(),
                      );
                    },
                  ),
                  const Divider(),

                  // Today special box
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                      border:
                          currentBelongingBox.id ==
                              AppConstants.todayBelongingBoxId
                          ? Border.all(
                              color: AppColors.primary,
                              width: Dimensions.borderMedium,
                            )
                          : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusM,
                          ),
                        ),
                        child: const Icon(
                          Icons.today,
                          color: AppColors.textOnPrimary,
                          size: Dimensions.iconS,
                        ),
                      ),
                      title: const Text(
                        UIStrings.today,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing:
                          currentBelongingBox.id ==
                              AppConstants.todayBelongingBoxId
                          ? Container(
                              padding: const EdgeInsets.all(
                                Dimensions.paddingXS,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: AppColors.textOnPrimary,
                                size: Dimensions.iconXS,
                              ),
                            )
                          : null,
                      onTap: () {
                        belongingBoxProvider.updateCurBelongingBox(
                          BelongingBoxProvider.todayBelongingBox,
                        );
                        Navigator.of(context).pop(); // Close drawer
                      },
                    ),
                  ),

                  // User-created belonging boxes
                  for (final belongingBox
                      in belongingBoxProvider.allBelongingBoxes)
                    ListTile(
                      leading: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: belongingBox.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(belongingBox.name),
                      // trailing is a popup menu button
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (currentBelongingBox.id == belongingBox.id)
                            const Icon(Icons.check, color: AppColors.success),
                          PopupMenuButton<String>(
                            onSelected: (value) =>
                                _handleBelongingBoxAction(value, belongingBox),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: Dimensions.iconS),
                                    SizedBox(width: Dimensions.paddingS),
                                    Text(UIStrings.edit),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: Dimensions.iconS,
                                      color: AppColors.error,
                                    ),
                                    SizedBox(width: Dimensions.paddingS),
                                    Text(
                                      UIStrings.delete,
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        belongingBoxProvider.updateCurBelongingBox(
                          belongingBox,
                        );
                        Navigator.of(context).pop(); // Close drawer
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBelongingBoxAction(String action, BelongingBoxVO belongingBox) {
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (context) =>
              AddBelongingBoxDialog(belongingBox: belongingBox),
        );
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(UIStrings.deleteBelongingBoxTitle),
            content: Text(
              'Are you sure you want to delete "${belongingBox.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(UIStrings.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    final provider = Provider.of<BelongingBoxProvider>(
                      context,
                      listen: false,
                    );
                    await provider.deleteBelongingBox(belongingBox);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deleted "${belongingBox.name}"'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${UIStrings.errorDeleting}: $e'),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text(UIStrings.delete),
              ),
            ],
          ),
        );
        break;
    }
  }
}
