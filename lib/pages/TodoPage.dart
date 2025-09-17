import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/component/TaskCard.dart';
import 'package:provider/provider.dart';

import '../component/AddBelongingBoxDialog.dart';
import '../component/CustomFloatingActionButton.dart';
import '../component/HabitCard.dart';
import '../config/logger.dart';
import '../model/entity/Task.dart';
import '../model/vo/BelongingBoxVO.dart';
import '../provider/BelongingBoxProvider.dart';
import '../provider/TaskProvider.dart';
import '../provider/HabitProvider.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _TodoPageState();
  }
}

class _TodoPageState extends State<TodoPage> {
  bool _showCompletedTasks = false;

  @override
  Widget build(BuildContext context) {
    print('TodoPage build');

    /// 使用 Provider 来获取 TodosProvider 实例
    //Optimize: 可以选择优化，使用Selector
    final _belongingBoxProvider = Provider.of<BelongingBoxProvider>(context);

    var cur_belongingBox = _belongingBoxProvider.cur_belongingBox;

    return Scaffold(
      appBar: AppBar(
        title: Text(cur_belongingBox.name),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('确认Dialog'),
                  content: Text('是否要显示已完成的任务？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('不显示'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('显示'),
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

      // 可滑动的列表视图，同时依赖TaskProvider.cur_tasks和HabitProvider.habits
      //TODO: 使用Selector优化，避免无关重建
      //TODO: HabitCard 显示在TaskCard下方，且两者之间存在分界线
      body: Selector<TaskProvider, List<Task>>(
        selector: (_, taskProvider) => taskProvider.cur_tasks,
        builder: (context, currentTasks, __) {
          return Selector<HabitProvider, List<dynamic>>(
            selector: (_, habitProvider) => habitProvider.habits,
            builder: (context, habits, ___) {
              // 检查当前是否显示今天的任务（特殊belongingBox id为-1）
              final bool isTodayTasks = cur_belongingBox.id == -1;

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
                    direction: DismissDirection.horizontal,
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 20),
                      color: Colors.red,
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      color: Colors.green,
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        // Left swipe - delete
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Task'),
                            content: Text(
                              'Are you sure you want to delete this task?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text('Delete'),
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
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Task deleted')));
                      }
                    },
                    child: TaskCard(task),
                  ),
                );
              }

              // 添加分界线与习惯卡片（仅在“今天”盒子下显示）
              if (isTodayTasks && habits.isNotEmpty) {
                if (items.isNotEmpty) {
                  items.add(
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('习惯'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ),
                  );
                }
                for (var habit in habits) {
                  items.add(HabitCard(habit));
                }
              }

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => items[index],
              );
            },
          );
        },
      ),

      // 悬浮按钮
      floatingActionButton: CustomFloatingActionButton(),

      // 侧边栏
      drawer: Drawer(
        child: Column(
          children: [
            // user账户头部
            UserAccountsDrawerHeader(
              accountName: Text("my_dida"),
              accountEmail: Text("这里是简介"),
              decoration: BoxDecoration(color: Colors.blue),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),

            // 侧边栏菜单项
            Expanded(
              child: ListView(
                children: [
                  // Add new belonging box button
                  ListTile(
                    leading: Icon(Icons.add, color: Colors.green),
                    title: Text("Add New Box"),
                    onTap: () {
                      logger.i("点击了 Add New Box");
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
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.blue.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: cur_belongingBox.id == -1
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.today,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        "今天",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: cur_belongingBox.id == -1
                          ? Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            )
                          : null,
                      onTap: () {
                        _belongingBoxProvider.updateCurBelongingBox(
                          BelongingBoxProvider.today_belongingBox,
                        );
                        Navigator.of(context).pop(); // Close drawer
                      },
                    ),
                  ),

                  // User-created belonging boxes
                  for (var belongingBox
                      in _belongingBoxProvider.all_belongingBoxes)
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
                          if (cur_belongingBox.id == belongingBox.id)
                            Icon(Icons.check, color: Colors.green),
                          PopupMenuButton<String>(
                            onSelected: (value) =>
                                _handleBelongingBoxAction(value, belongingBox),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        _belongingBoxProvider.updateCurBelongingBox(
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
            title: const Text('Delete Belonging Box'),
            content: Text(
              'Are you sure you want to delete "${belongingBox.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
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
                        SnackBar(content: Text('Error deleting: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        break;
    }
  }
}
