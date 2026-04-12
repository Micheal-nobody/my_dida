import 'package:flutter/material.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/model/vo/checklist_vo.dart';
import 'package:my_dida/provider/checklist_provider.dart';
import 'package:my_dida/utils/TimeUtils.dart';
import 'package:provider/provider.dart';

import '../../model/entity/Task.dart';
import '../../provider/task_provider.dart';
import '../pickers/CustomDatePicker/TaskDateTimePicker.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key, this.parentTask});
  final Task? parentTask;

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

//TODO：一个任务如果是全天任务，仍然应该具有startTime（选择的日期，时间为00:00）,用于显示在calendar_page,todo_page等页面中。
class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _textController = TextEditingController();
  late final Task? parentTask;
  TaskTimeInfo _timeInfo = TaskTimeInfo();
  bool _hasError = false;
  late ChecklistVO _selectedBelongingBox;

  @override
  void initState() {
    super.initState();
    parentTask = widget.parentTask;
    final now = DateTime.now();
    // 初始化时间信息
    _timeInfo = TaskTimeInfo(
      selectedDate: now.toBeijingTime().dateOnly,
      isAllDay: true, // 默认全天任务
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addTask(BuildContext context) async {
    final String taskName = _textController.text;

    if (taskName.isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    final DateTime? finalStart = _timeInfo.getFinalStartTime();
    final DateTime? finalEnd = _timeInfo.getFinalEndTime();
    final bool isAllDay = _timeInfo.isAllDay; // 以选择器状态为准

    final Task newTask = Task(name: taskName, isAllDay: isAllDay);

    if (!isAllDay) {
      newTask..startTime = finalStart
              ..endTime = finalEnd;
    } else {
      // 全天任务：确保有 startTime（所选日期 00:00）用于各页面展示
      final DateTime date =
          (_timeInfo.selectedDate ?? DateTime.now().toBeijingTime()).dateOnly;
      newTask.startTime = DateTime(date.year, date.month, date.day);
      newTask.endTime = null;
    }
    newTask.rrule = _timeInfo.rrule;

    // 如果是子任务，设置父任务ID和归属盒子
    if (parentTask != null) {
      newTask.parentTaskId = parentTask!.id;
      newTask.belongingBoxId = parentTask!.belongingBoxId;
    } else {
      newTask.belongingBoxId = _selectedBelongingBox.id;
    }

    logger.i('newTask == $newTask');

    await Provider.of<TaskProvider>(context, listen: false).addTask(newTask);

    Navigator.pop(context);
  }

  void _showCustomDatePicker(BuildContext context) async {
    await TaskDateTimePicker.showForNewTask(
      context: context,
      initialTimeInfo: _timeInfo, // 传递当前的时间信息
      onTimeInfoUpdated: (timeInfo) {
        logger.i('Task time updated: $timeInfo');
        setState(() {
          _timeInfo = timeInfo;
        });
      },
    );
  }

  String _getSelectDateString() => _timeInfo.getTodayDisplayText();

  @override
  Widget build(BuildContext context) => Container(
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
            if (parentTask == null)
              Consumer<ChecklistProvider>(
                builder: (context, provider, child) {
                  // 更新为当前归属盒子，如果当前归属盒子为defaultBelongingBox则返回allBelongingBox
                  _selectedBelongingBox =
                      provider.currentBelongingBox ==
                          ChecklistProvider.todayBelongingBox
                      ? ChecklistProvider.defaultBelongingBox
                      : provider.currentBelongingBox;

                  return DropdownButton<ChecklistVO>(
                    hint: Text(_selectedBelongingBox.name),
                    items: provider.allBelongingBoxes
                        .map<DropdownMenuItem<ChecklistVO>>(
                          (value) => DropdownMenuItem<ChecklistVO>(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) {
                      logger.i(
                        'newValue: $newValue ,newValue.id: ${newValue?.id}',
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
              child: const Text('确认'),
              onPressed: () => _addTask(context),
            ),
          ],
        ),
      ],
    ),
  );
}
