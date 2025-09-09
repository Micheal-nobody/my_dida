import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/component/AddTaskDialog.dart';
import 'package:my_dida/component/TaskCard.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/provider/TodosProvider.dart';
import 'package:provider/provider.dart';

import '../model/entity/Task.dart';
import '../provider/BelongingBoxProvider.dart';
import '../provider/DateBoxProvider.dart';
import '../provider/TaskProvider.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _TodoPageState();
  }
}

class _TodoPageState extends State<TodoPage> {
  @override
  Widget build(BuildContext context) {
    print('TodoPage build');

    /// 使用 Provider 来获取 TodosProvider 实例
    final todosProvider = context.watch<TodosProvider>();

    final _taskProvider = Provider.of<TaskProvider>(context, listen: false);
    //TODO: 可以选择优化，使用Selector
    final _belongingBoxProvider = Provider.of<BelongingBoxProvider>(context);

    var cur_belongingBox = _belongingBoxProvider.cur_belongingBox;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          cur_belongingBox?.name != null ? cur_belongingBox!.name : "代办",
        ),
      ),

      /// 可滑动的列表视图，当且仅当TaskProvider.cur_tasks更新时，才出发更新
      body: Selector<TaskProvider, List<Task>>(
        selector: (context, provider) => provider.cur_tasks,
        builder: (context, current_tasks, child) {
          logger.e("TaskProvider.cur_tasks 更新了，所以刷新列表: ${current_tasks.length}");
          return ListView.builder(
            itemCount: current_tasks.length, // 项目总数
            itemBuilder: (context, index) {
              // 如果任务已完成，则不显示
              if (current_tasks[index].isDone) {
                return Container();
              }
              // TODO:美化样式
              return TaskCard(current_tasks[index]);
            },
          );
        },
      ),

      /// 添加一个悬浮按钮
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          print("Add new todo item");
          AddTaskDialog.show(context);
        },
      ),

      /// 添加侧边栏
      drawer: Drawer(
        child: Column(
          children: [
            /// user账户头部
            UserAccountsDrawerHeader(
              accountName: Text("我喜欢你"),
              accountEmail: Text("这里其实是邮件地址，但是我找不到简介的地方"),
              decoration: BoxDecoration(color: Colors.blue),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),

            /// 侧边栏菜单项
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(Icons.home),
                    title: Text("今天"),
                    onTap: () {
                      _belongingBoxProvider.updateCurBelongingBox(
                        BelongingBoxProvider.default_belongingBox,
                      );
                    },
                  ),
                  for (var belongingBox
                      in _belongingBoxProvider.all_belongingBoxes)
                    ListTile(
                      leading: Icon(Icons.home),
                      title: Text(belongingBox.name),
                      onTap: () {
                        _belongingBoxProvider.updateCurBelongingBox(
                          belongingBox,
                        );
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
}
