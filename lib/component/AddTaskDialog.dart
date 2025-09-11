import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/model/vo/BelongingBoxVO.dart';
import 'package:my_dida/provider/BelongingBoxProvider.dart';
import 'package:provider/provider.dart';

import '../model/entity/Task.dart';
import '../provider/TaskProvider.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  DateTime? _selectedDate;
  bool _hasError = false;
  late BelongingBoxVO _selectedBelongingBox; // 其实是不可能为null的

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    //TODO: 自动聚焦到输入框，但是没有发挥作用！
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   FocusScope.of(context).requestFocus(_focusNode);
    // });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addTask(BuildContext context) async {
    String taskName = _textController.text;

    if (taskName.isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    Task newTask = Task(name: taskName);
    newTask.startTime = _selectedDate;
    newTask.belongingBoxId = _selectedBelongingBox!.id;

    await Provider.of<TaskProvider>(context, listen: false).addTask(newTask);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //TODO: 添加自动聚焦！
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: '准备做点什么？',
              errorText: _hasError ? '请输入任务名称！' : null,
              errorStyle: const TextStyle(color: Colors.red),
            ),
            onSubmitted: (value) => _addTask(context),
            onChanged: (value) {
              if (_hasError && value.isNotEmpty) {
                setState(() {
                  _hasError = false;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 选择日期按钮
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              //TODO: 根据 provider.all_belongingBoxes 添加 BelongingBox 选择器！
              Consumer<BelongingBoxProvider>(
                builder: (context, provider, child) {
                  // 更新为当前归属盒子
                  _selectedBelongingBox = provider.cur_belongingBox;

                  print("组件构建");

                  //! 可否写一个普通的Button ，onPressed触发类似于showModalBottomSheet的函数？
                  return DropdownButton<BelongingBoxVO>(
                    hint: Text(_selectedBelongingBox!.name),
                    items: provider.all_belongingBoxes
                        .map<DropdownMenuItem<BelongingBoxVO>>((
                          BelongingBoxVO value,
                        ) {
                          return DropdownMenuItem<BelongingBoxVO>(
                            value: value,
                            child: Text(value.name),
                          );
                        })
                        .toList(),
                    onChanged: (BelongingBoxVO? newValue) {
                      logger.i(
                        "newValue: $newValue ,newValue.id: ${newValue?.id}",
                      );
                      // 更新State
                      setState(() {
                        _selectedBelongingBox = newValue!;
                      });
                    },
                  );
                },
              ),
              const Spacer(),
              ElevatedButton(
                child: const Text("确认"),
                onPressed: () => _addTask(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
