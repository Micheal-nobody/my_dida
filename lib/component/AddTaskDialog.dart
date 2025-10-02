import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/model/vo/BelongingBoxVO.dart';
import 'package:my_dida/provider/BelongingBoxProvider.dart';
import 'package:my_dida/utils/TimeUtils.dart';
import 'package:provider/provider.dart';

import '../model/entity/Task.dart';
import '../provider/TaskProvider.dart';
import 'CustomDatePicker/TaskDateTimePicker.dart';

class AddTaskDialog extends StatefulWidget {
  final Task? parentTask;

  const AddTaskDialog({super.key, this.parentTask});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _textController = TextEditingController();
  TaskTimeInfo _timeInfo = TaskTimeInfo();
  bool _hasError = false;
  late BelongingBoxVO _selectedBelongingBox;

  @override
  void initState() {
    super.initState();
    // 初始化时间信息
    _timeInfo = TaskTimeInfo(
      selectedDate: DateTime.now().toBeijingTime().dateOnly,
    );
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
    // 使用 TaskTimeInfo 获取最终时间
    newTask.startTime = _timeInfo.getFinalStartTime();
    newTask.endTime = _timeInfo.getFinalEndTime();
    newTask.rrule = _timeInfo.rrule;

    // 如果是子任务，设置父任务ID和归属盒子
    if (widget.parentTask != null) {
      newTask.parentTaskId = widget.parentTask!.id;
      newTask.belongingBoxId = widget.parentTask!.belongingBoxId;
    } else {
      newTask.belongingBoxId = _selectedBelongingBox.id;
    }

    logger.i("newTask == $newTask");

    await Provider.of<TaskProvider>(context, listen: false).addTask(newTask);

    Navigator.pop(context);
  }

  void _showCustomDatePicker(BuildContext context) async {
    await TaskDateTimePicker.showForNewTask(
      context: context,
      onTimeInfoUpdated: (timeInfo) {
        logger.i("Task time updated: $timeInfo");
        setState(() {
          _timeInfo = timeInfo;
        });
      },
    );
  }

  String _getSelectDateString() {
    return _timeInfo.getTodayDisplayText();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              GestureDetector(
                onTap: () => _showCustomDatePicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _getSelectDateString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: _timeInfo.getFinalStartTime() != null
                              ? Colors.orange
                              : Colors.grey,
                          fontWeight: _timeInfo.getFinalStartTime() != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),

              // BelongingBox 下拉框（仅当不是子任务时显示）
              if (widget.parentTask == null)
                Consumer<BelongingBoxProvider>(
                  builder: (context, provider, child) {
                    // 更新为当前归属盒子，如果当前归属盒子为default_belongingBox则返回all_belongBox
                    _selectedBelongingBox =
                        provider.cur_belongingBox ==
                            BelongingBoxProvider.today_belongingBox
                        ? BelongingBoxProvider.default_belongingBox
                        : provider.cur_belongingBox;

                    return DropdownButton<BelongingBoxVO>(
                      hint: Text(_selectedBelongingBox.name),
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
