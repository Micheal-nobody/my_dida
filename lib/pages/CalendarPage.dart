import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/TodosProvider.dart';
import 'CalendarScreen.dart';

//TODO:这个类是最难的，我需要设计日历视图！但是我觉得Flutter应该提供了日历的封装
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    /// 使用 Provider 来获取 TodosProvider 实例
    final todosProvider = context.watch<TodosProvider>();

    return Column(children: [
      Expanded(child: CalendarScreen()),
      Expanded(
        child: ListView.builder(
          itemCount: todosProvider.cur_todos.length, // 项目总数
          itemBuilder: (context, index) {
            return TodosProvider.generateCard(todosProvider.cur_todos[index]);
          },
        ),
      ),
    ]);
  }
}
