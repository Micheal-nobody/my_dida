import 'package:flutter/material.dart';

import 'AddTaskDialog.dart';

//TODO: 写一个自定义日期选择器，可以输入日期，选择日期，选择时间，选择任务
class CustomFloatingActionButton extends StatelessWidget {
  const CustomFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {

      return FloatingActionButton(
        backgroundColor: Colors.orange,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            builder: (BuildContext context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: const AddTaskDialog(),
            ),
          );
        },
      );
  }
}
