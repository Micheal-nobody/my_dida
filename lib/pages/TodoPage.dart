import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/provider/TodosProvider.dart';
import 'package:provider/provider.dart';

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
    /// 使用 Provider 来获取 TodosProvider 实例
    final todosProvider = context.watch<TodosProvider>();

    final _taskProvider = Provider.of<TaskProvider>(context);
    final _belongingBoxProvider = Provider.of<BelongingBoxProvider>(context);
    var current_tasks = _taskProvider.currentTasks;

    return Scaffold(
      appBar: AppBar(title: Text("代办")),

      /// 可滑动的列表视图
      body: ListView.builder(
        itemCount: current_tasks.length, // 项目总数
        itemBuilder: (context, index) {
          return Text(current_tasks[index].name);
        },
      ),

      /// 添加一个悬浮按钮
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          print("Add new todo item");
          _taskProvider.showAddDialog(context);
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
                  /// 默认收藏夹
                  ListTile(
                    leading: Icon(Icons.home),
                    title: Text("今天"),
                    onTap: () {
                      print("点击了 今天");
                      _taskProvider.loadTodayTasks();
                    },
                  ),
                  for (var belongingBox
                      in _belongingBoxProvider.all_belongingBoxes)
                    ListTile(
                      leading: Icon(Icons.home),
                      title: Text(belongingBox.name),
                      onTap: () {
                        print("点击了 ${belongingBox.name}");
                        //TODO: 修改 BelongingBoxProvider中的 cur
                        // Navigator.of(context).push(MaterialPageRoute(builder: (context) => TaskListPage()));
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
