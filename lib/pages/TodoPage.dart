import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/model/TodoItem.dart';
import 'package:my_dida/provider/TodosProvider.dart';
import 'package:provider/provider.dart';

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

    //TODO: 按说子 widget 中是不应该使用 Scaffold 的，但我确实没想到显示 悬浮按钮和侧边栏 好的处理方式
    return Scaffold(
      /// 可滑动的列表视图
      body: ListView.builder(
        itemCount: todosProvider.cur_todos.length, // 项目总数
        itemBuilder: (context, index) {
          return TodosProvider.generateCard(todosProvider.cur_todos[index]);
        },
      ),

      /// 添加一个悬浮按钮
      //TODO: 这里的悬浮按钮是一个添加新任务的按钮，点击后会弹出一个对话框（对话框和键盘同时弹出），
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Add new todo item");
          todosProvider.init_todos();
        },
      ),

      /// 添加侧边栏
      //TODO: 侧边栏中根据我写下的类进行渲染
      drawer: Drawer(
        child: Column(
          children: [
            /// user账户头部
            UserAccountsDrawerHeader(
              accountName: Text("我喜欢你"),
              accountEmail: Text("这里其实是邮件地址，但是我找不到简介的地方"),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
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
                    title: Text("主页"),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text("设置"),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.info),
                    title: Text("关于"),
                    onTap: () {},
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
