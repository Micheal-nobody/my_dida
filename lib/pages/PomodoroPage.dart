import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/locator/locator.dart';
import 'package:my_dida/model/IsarTest.dart';
import 'package:my_dida/provider/TaskProvider.dart';
import 'package:my_dida/repository/IsarTestRepository.dart';
import 'package:provider/provider.dart';

import '../provider/TodosProvider.dart';
import 'CalendarScreen.dart';

class PomodoroPage extends StatelessWidget {
  /// 这段代码的作用是获取 能够通过 const 关键字创建的实例
  const PomodoroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _taskProvider = Provider.of<TaskProvider>(context);

    var tasks =_taskProvider.tasks;

    return Column(
      children: [
        Expanded(child: Text("这是一个番茄钟页面")),
      ],
    );
  }
}
