import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/entity/Task.dart';
import '../provider/TaskProvider.dart';

class AddTaskDialog{

  //TODO: 添加自动聚焦！
  //TODO: 美化 Container
  //TODO: 添加 BelongingBox 选择器！
  /// 1、对ai这样说：我希望showModalBottomSheet可以自动展示键盘并聚焦于TextField
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      //TODO: 键盘出现时还是会遮挡输入框！
      isScrollControlled: true,
      builder: (BuildContext context) {
        final TextEditingController _textController = TextEditingController();
        DateTime? _selectedDate = DateTime.now();

        bool _hasError = false;

        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: '准备做点什么？',
                  errorText: _hasError ? '请输入任务名称！' : null,
                  errorStyle: TextStyle(color: Colors.red),
                ),
                // onChanged: (value) { // 当用户开始输入时清除错误状态
                //   if (_hasError && value.isNotEmpty) {
                //     setState(() {
                //       _hasError = false;
                //     });
                //   }
                // },
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );

                      if (picked != null) {
                        _selectedDate = picked;
                      }
                    },
                  ),
                  Spacer(),
                  ElevatedButton(
                    child: Text("确认"),
                    onPressed: () async {
                      String taskName = _textController.text;
                      print('添加任务 ==> $taskName');

                      //TODO: 修改TextField，当 输入为空时，显示红色的错误信息
                      /// 或者说，taskName为空的话，就不显示确认按钮
                      if (taskName.isEmpty) {
                        print('任务名称不能为空！');

                        _hasError = true;
                        return;
                      }

                      Task newTask = Task(name: taskName);
                      newTask.startTime = _selectedDate;

                      await Provider.of<TaskProvider>(context, listen: false).addTask(newTask);

                      Navigator.pop(context);
                      _textController.dispose();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
