import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/model/vo/BelongingBoxVO.dart';
import 'package:my_dida/provider/BelongingBoxProvider.dart';
import 'package:provider/provider.dart';

import '../model/entity/Task.dart';
import '../provider/TaskProvider.dart';
import 'CustomDatePicker/CustomDatePicker.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _textController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isAllDay = false;
  bool _hasError = false;
  late BelongingBoxVO _selectedBelongingBox;

  @override
  void initState() {
    super.initState();
    // 获取中国北京时区的时间 (UTC+8)
    _selectedDate = DateTime.now().toUtc().add(const Duration(hours: 8));

    logger.i("AddTaskDialog initState,_selectedDate == $_selectedDate");
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
    newTask.belongingBoxId = _selectedBelongingBox.id;

    logger.i("newTask == $newTask");

    await Provider.of<TaskProvider>(context, listen: false).addTask(newTask);

    Navigator.pop(context);
  }

  void _showCustomDatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomDatePicker(
        selectedDate: _selectedDate,
        startTime: _startTime,
        endTime: _endTime,
        isAllDay: _isAllDay,
        onDateChanged: (date) {
          logger.i("onDateChanged date == $date");
          setState(() {
            _selectedDate = date;
          });
        },
        onTimeChanged: (start, end) {
          // onTimeChanged start == TimeOfDay(09:00), end == TimeOfDay(10:00)
          logger.i("onTimeChanged start == $start, end == $end");
          setState(() {
            _startTime = start;
            _endTime = end;
          });
        },
        onAllDayChanged: (isAllDay) {
          logger.i("onAllDayChanged isAllDay == $isAllDay");
          setState(() {
            _isAllDay = isAllDay;
          });
        },
        onClear: () {
          setState(() {
            _selectedDate = DateTime.now();
            _startTime = null;
            _endTime = null;
            _isAllDay = false;
          });
        },
      ),
    );
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
                        _selectedDate != null
                            ? '${_selectedDate!.month}月${_selectedDate!.day}日'
                            : '选择日期',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDate != null
                              ? Colors.orange
                              : Colors.grey,
                          fontWeight: _selectedDate != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),

              // BelongingBox 下拉框
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
