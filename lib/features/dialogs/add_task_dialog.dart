import 'package:flutter/material.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/constants/app_constants.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/checklist_vo.dart';
import 'package:my_dida/provider/checklist_provider.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:my_dida/shared/widgets/checklist_selector.dart';
import 'package:my_dida/shared/widgets/task_schedule_trigger.dart';
import 'package:my_dida/utils/TimeUtils.dart';
import 'package:provider/provider.dart';

import '../pickers/task_date_time_picker.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key, this.parentTask, this.presetTask});

  final Task? parentTask;
  final Task? presetTask;

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

//TODO：一个任务如果是全天任务，仍然应该具有startTime（选择的日期，时间为00:00）,用于显示在calendar_page,todo_page等页面中。
class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _textController = TextEditingController();
  late final Task? parentTask;
  TaskTimeInfo _timeInfo = TaskTimeInfo();
  bool _hasError = false;
  ChecklistVO? _selectedChecklist;

  @override
  void initState() {
    super.initState();
    parentTask = widget.parentTask;
    final now = DateTime.now();

    // 初始化时间信息
    if (widget.presetTask != null && widget.presetTask!.startTime != null) {
      _timeInfo = TaskTimeInfo(
        selectedDate: widget.presetTask!.startTime!.toBeijingTime().dateOnly,
        isAllDay: widget.presetTask!.isAllDay,
      );
    } else {
      _timeInfo = TaskTimeInfo(
        selectedDate: now.toBeijingTime().dateOnly,
        isAllDay: true, // 默认全天任务
      );
    }

    if (widget.presetTask != null && widget.presetTask!.checklistId != null) {
      _selectedChecklist = ChecklistVO(
        id: widget.presetTask!.checklistId!,
        name: '',
        color: Colors.grey,
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _addTask(BuildContext context) async {
    final String taskName = _textController.text.trim();

    if (taskName.isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    final Task newTask = _buildTaskFromForm(
      taskName: taskName,
      checklistProvider: context.read<ChecklistProvider>(),
    );

    logger.i('newTask == $newTask');

    await context.read<TaskProvider>().addTask(newTask);

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  void _showCustomDatePicker(BuildContext context) async {
    final updatedTimeInfo = await TaskDateTimePicker.showForNewTask(
      context: context,
      initialTimeInfo: _timeInfo, // 传递当前的时间信息
    );
    if (updatedTimeInfo == null) {
      return;
    }
    logger.i('Task time updated: $updatedTimeInfo');
    setState(() {
      _timeInfo = updatedTimeInfo;
    });
  }

  String _getSelectDateString() => _timeInfo.getTodayDisplayText();

  void _ensureSelectedChecklist(ChecklistProvider provider) {
    if (_selectedChecklist != null) {
      final matchedChecklist = provider.allCheckLists
          .where((item) => item.id == _selectedChecklist!.id)
          .firstOrNull;
      if (matchedChecklist != null) {
        _selectedChecklist = matchedChecklist;
        return;
      }
    }

    _selectedChecklist = _resolveInitialChecklist(provider);
  }

  ChecklistVO _resolveInitialChecklist(ChecklistProvider provider) {
    final preferredChecklist =
        provider.currentCheckList == AppConstants.todayCheckList
        ? AppConstants.defaultCheckList
        : provider.currentCheckList;

    return provider.allCheckLists
            .where((item) => item.id == preferredChecklist.id)
            .firstOrNull ??
        preferredChecklist;
  }

  Task _buildTaskFromForm({
    required String taskName,
    required ChecklistProvider checklistProvider,
  }) {
    final DateTime? finalStart = _timeInfo.getFinalStartTime();
    final DateTime? finalEnd = _timeInfo.getFinalEndTime();
    final bool isAllDay = _timeInfo.isAllDay;
    final Task newTask = Task(
      name: taskName,
      isAllDay: isAllDay,
      priority: widget.presetTask?.priority ?? TaskPriority.none,
      tags: widget.presetTask?.tags ?? const [],
    );

    if (isAllDay) {
      final DateTime date =
          (_timeInfo.selectedDate ?? DateTime.now().toBeijingTime()).dateOnly;
      newTask
        ..startTime = DateTime(date.year, date.month, date.day)
        ..endTime = null;
    } else {
      newTask
        ..startTime = finalStart
        ..endTime = finalEnd;
    }

    newTask.rrule = _timeInfo.rrule;

    if (parentTask != null) {
      newTask
        ..parentTaskId = parentTask!.id
        ..checklistId = parentTask!.checklistId;
      return newTask;
    }

    final selectedChecklist =
        _selectedChecklist ?? _resolveInitialChecklist(checklistProvider);
    newTask.checklistId = selectedChecklist.id;
    return newTask;
  }

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
            TaskScheduleTrigger(
              text: _getSelectDateString(),
              hasSelection: _timeInfo.getFinalStartTime() != null,
              onTap: () => _showCustomDatePicker(context),
            ),
            if (parentTask == null)
              Consumer<ChecklistProvider>(
                builder: (context, provider, child) {
                  _ensureSelectedChecklist(provider);

                  return ChecklistSelector(
                    items: provider.allCheckLists,
                    selectedValue: _selectedChecklist,
                    hintText: _selectedChecklist?.name ?? '选择清单',
                    onChanged: (newValue) {
                      logger.i(
                        'newValue: $newValue ,newValue.id: ${newValue?.id}',
                      );
                      setState(() {
                        _selectedChecklist = newValue;
                      });
                    },
                  );
                },
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _addTask(context),
              child: const Text('确认'),
            ),
          ],
        ),
      ],
    ),
  );
}
