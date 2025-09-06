import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/locator/locator.dart';
import 'package:my_dida/model/IsarTest.dart';
import 'package:my_dida/repository/IsarTestRepository.dart';
import 'package:provider/provider.dart';

import '../provider/TodosProvider.dart';
import 'CalendarScreen.dart';

//TODO:这个类是最难的，我需要设计日历视图！但是我觉得Flutter应该提供了日历的封装
class PomodoroPage extends StatelessWidget {
  /// 这段代码的作用是获取 能够通过 const 关键字创建的实例的 TodosProvider 实例
  const PomodoroPage({super.key});

  //! 暂时作为测试 isar 的页面！
  @override
  Widget build(BuildContext context) {
    final _isarTestRepository = locator<IsarTestRepository>();

    //TODO: 这玩意可以直接 as吗？
    // List<IsarTest> _tasks = _isarTestRepository.collection as List<IsarTest>;

    return Column(
      children: [
        Expanded(child: Text("这是一个测试 Isar 的页面")),

        /// 创建4个按钮，对应CRUD
        Expanded(
          child: Row(
            children: [
              TextButton(
                onPressed: () async {
                  _isarTestRepository.addData(IsarTest(name: "测试数据", age: 18));
                  print('添加数据成功');
                },
                child: Text("增加数据"),
              ),
              TextButton(onPressed: () async {}, child: Text("删除数据")),
              TextButton(onPressed: () async {}, child: Text("更改数据")),
              TextButton(onPressed: () async {}, child: Text("减少数据")),
            ],
          ),
        ),

        Expanded(
          child: FutureBuilder<List<IsarTest>>(
            future: _isarTestRepository.getAll(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Text("没有数据");
              }

              //TODO： 实现响应式变化，或者不实现？
              //TODO：路由跳转之后List.builder中itemBuilder函数不会重新执行！发生了复用！
              /// 1、实现响应式变化（应该去看看Repository中get的原理，它何时出发？如何访问？）
              /// 2、组件在路由跳转时卸载
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  print('列表数据更新了');
                  return Text(snapshot.data![index].name ?? "");
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
