import 'package:flutter/material.dart';
import 'package:my_dida/core/logger/logger.dart';
import 'package:my_dida/core/constants/app_constants.dart';
import 'package:my_dida/features/tasks/models/check_point.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/checklist/models/checklist_vo.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/checklist/widgets/checklist_selector.dart';
import 'package:my_dida/shared/widgets/datetime/custom_date_time_picker.dart';
import 'package:my_dida/shared/widgets/datetime/custom_repeat_picker.dart';
import 'package:my_dida/shared/widgets/datetime/repeat_picker_utils.dart';
import 'package:my_dida/core/utils/time_utils.dart';
import 'package:provider/provider.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({
    super.key,
    this.parentTask,
    this.presetTask,
    this.initialIsFullScreen = false,
  });

  final Task? parentTask;
  final Task? presetTask;
  final bool initialIsFullScreen;

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  late final Task? parentTask;

  late CustomDateTimePickerValue _dateTimePickerValue;
  bool _notificationEnabled = false;
  int? _reminderOffsetMinutes;
  TaskPriority _priority = TaskPriority.none;
  List<String> _tags = [];
  List<CheckPoint> _checkpoints = [];
  ChecklistVO? _selectedChecklist;

  bool _hasError = false;
  late bool _isFullScreen;
  bool _hasInitPreset = false;

  // 全屏模式下用于检查点聚焦管理的 FocusNode 列表
  final List<FocusNode> _checkpointFocusNodes = [];

  @override
  void initState() {
    super.initState();
    parentTask = widget.parentTask;
    _isFullScreen = widget.initialIsFullScreen;
    final now = DateTime.now();

    if (widget.presetTask != null) {
      _hasInitPreset = true;
      _textController.text = widget.presetTask!.name;
      _descController.text = widget.presetTask!.description;
      _priority = widget.presetTask!.priority;
      _tags = List.from(widget.presetTask!.tags);
      _checkpoints = widget.presetTask!.checkpoints
          .map((cp) => CheckPoint(name: cp.name, isDone: cp.isDone))
          .toList();

      final taskStart = widget.presetTask!.startTime;
      final taskEnd = widget.presetTask!.endTime;

      _dateTimePickerValue = CustomDateTimePickerValue(
        selectedDate: taskStart?.dateOnly ?? now.toBeijingTime().dateOnly,
        startTime: taskStart != null && !taskStart.justDate()
            ? TimeOfDay.fromDateTime(taskStart)
            : null,
        endTime: taskEnd != null && !taskEnd.justDate()
            ? TimeOfDay.fromDateTime(taskEnd)
            : null,
        startDate: taskStart?.dateOnly,
        endDate: taskEnd?.dateOnly,
        isAllDay: widget.presetTask!.isAllDay,
        rrule: widget.presetTask!.rrule,
      );
      _notificationEnabled = widget.presetTask!.notificationEnabled;
      _reminderOffsetMinutes = widget.presetTask!.reminderOffsetMinutes;

      if (widget.presetTask!.checklistId != null) {
        _selectedChecklist = ChecklistVO(
          id: widget.presetTask!.checklistId!,
          name: '',
          color: Colors.grey,
        );
      }
    } else {
      _dateTimePickerValue = CustomDateTimePickerValue(
        selectedDate: now.toBeijingTime().dateOnly,
        isAllDay: true,
      );
    }

    // 初始化已存 checkpoint 的 FocusNode
    for (int i = 0; i < _checkpoints.length; i++) {
      _checkpointFocusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _descController.dispose();
    for (final node in _checkpointFocusNodes) {
      node.dispose();
    }
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

    await context.read<TaskProvider>().execute(AddTask(newTask));

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _showDateTimePicker(BuildContext context) async {
    final result = await CustomDateTimePickerModal.show(
      context: context,
      initialValue: _dateTimePickerValue,
    );
    if (result != null) {
      setState(() {
        _dateTimePickerValue = result;
      });
    }
  }

  void _showReminderRepeatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String tempRepeat = rruleToSelection(_dateTimePickerValue.rrule);
        int? tempOffset = _reminderOffsetMinutes;
        bool tempNotify = _notificationEnabled;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('提醒与重复'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('重复'),
                  subtitle: Text(tempRepeat),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final selected = await CustomRepeatPicker.show(
                      context: context,
                      selectedRepeat: tempRepeat,
                      baseDate: _dateTimePickerValue.selectedDate,
                    );
                    if (selected != null) {
                      setDialogState(() {
                        tempRepeat = selected;
                      });
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('提醒时间'),
                  subtitle: Text(
                    tempNotify ? _getReminderDisplayText(tempOffset) : '无提醒',
                  ),
                  trailing: PopupMenuButton<int?>(
                    initialValue: tempNotify ? tempOffset : null,
                    onSelected: (val) {
                      setDialogState(() {
                        if (val == -1) {
                          tempNotify = false;
                          tempOffset = null;
                        } else {
                          tempNotify = true;
                          tempOffset = val;
                        }
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: -1, child: Text('无提醒')),
                      const PopupMenuItem(value: 0, child: Text('任务开始时')),
                      const PopupMenuItem(value: 5, child: Text('提前 5 分钟')),
                      const PopupMenuItem(value: 15, child: Text('提前 15 分钟')),
                      const PopupMenuItem(value: 30, child: Text('提前 30 分钟')),
                      const PopupMenuItem(value: 60, child: Text('提前 1 小时')),
                      const PopupMenuItem(value: 120, child: Text('提前 2 小时')),
                      const PopupMenuItem(value: 1440, child: Text('提前 1 天')),
                    ],
                    child: const Icon(Icons.arrow_drop_down),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消', style: TextStyle(color: Colors.orange)),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _dateTimePickerValue = _dateTimePickerValue.copyWith(
                      rrule: mapSelectionToRepeatPattern(
                        tempRepeat,
                        _dateTimePickerValue.selectedDate,
                      ),
                    );
                    _reminderOffsetMinutes = tempOffset;
                    _notificationEnabled = tempNotify;
                  });
                  Navigator.pop(context);
                },
                child: const Text('确定', style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getReminderDisplayText(int? offset) {
    if (offset == null) return '无提醒';
    if (offset == 0) return '任务开始时';
    if (offset == 5) return '提前 5 分钟';
    if (offset == 15) return '提前 15 分钟';
    if (offset == 30) return '提前 30 分钟';
    if (offset == 60) return '提前 1 小时';
    if (offset == 120) return '提前 2 小时';
    if (offset == 1440) return '提前 1 天';
    return '提前 $offset 分钟';
  }

  Future<void> _editTags() async {
    final textController = TextEditingController(text: _tags.join(', '));
    final updatedTags = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改标签'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: '输入标签，以逗号分隔'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final text = textController.text.trim();
              final tags = text.isEmpty
                  ? <String>[]
                  : text
                        .split(RegExp('[，,]'))
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
              Navigator.pop(context, tags);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (updatedTags != null) {
      setState(() {
        _tags = updatedTags;
      });
    }
  }

  String _getDateDisplayText() {
    final date = _dateTimePickerValue.selectedDate;
    if (date == null) return '设置日期';
    final now = DateTime.now().toBeijingTime();
    String dateStr = '';
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      dateStr = '今天';
    } else {
      final tomorrow = now.add(const Duration(days: 1));
      if (date.year == tomorrow.year &&
          date.month == tomorrow.month &&
          date.day == tomorrow.day) {
        dateStr = '明天';
      } else {
        dateStr = '${date.month}月${date.day}日';
      }
    }

    if (!_dateTimePickerValue.isAllDay &&
        _dateTimePickerValue.startTime != null) {
      final startStr =
          '${_dateTimePickerValue.startTime!.hour.toString().padLeft(2, '0')}:${_dateTimePickerValue.startTime!.minute.toString().padLeft(2, '0')}';
      if (_dateTimePickerValue.endTime != null) {
        final endStr =
            '${_dateTimePickerValue.endTime!.hour.toString().padLeft(2, '0')}:${_dateTimePickerValue.endTime!.minute.toString().padLeft(2, '0')}';
        return '$dateStr $startStr-$endStr';
      }
      return '$dateStr $startStr';
    }
    return dateStr;
  }

  String _getFullDateDisplayText() {
    final date = _dateTimePickerValue.selectedDate;
    if (date == null) return '设置日期与时间';
    final now = DateTime.now().toBeijingTime();
    String relativeStr = '';
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      relativeStr = '今天, ';
    } else {
      final tomorrow = now.add(const Duration(days: 1));
      if (date.year == tomorrow.year &&
          date.month == tomorrow.month &&
          date.day == tomorrow.day) {
        relativeStr = '明天, ';
      }
    }

    final String dateStr = '${date.month}月${date.day}日';
    String timeStr = '';

    if (!_dateTimePickerValue.isAllDay &&
        _dateTimePickerValue.startTime != null) {
      final startStr =
          '${_dateTimePickerValue.startTime!.hour.toString().padLeft(2, '0')}:${_dateTimePickerValue.startTime!.minute.toString().padLeft(2, '0')}';
      if (_dateTimePickerValue.endTime != null) {
        final endStr =
            '${_dateTimePickerValue.endTime!.hour.toString().padLeft(2, '0')}:${_dateTimePickerValue.endTime!.minute.toString().padLeft(2, '0')}';
        timeStr = ' $startStr-$endStr';
      } else {
        timeStr = ' $startStr';
      }
    }

    return '$relativeStr$dateStr$timeStr';
  }

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
    final preferredChecklist = provider.currentCheckList.isSmartList
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
    final Task newTask = Task(
      name: taskName,
      isAllDay: _dateTimePickerValue.isAllDay,
      priority: _priority,
      tags: _tags,
      checkpoints: _checkpoints,
      description: _descController.text.trim(),
    );

    DateTime? finalStart;
    DateTime? finalEnd;

    final date =
        _dateTimePickerValue.startDate ?? _dateTimePickerValue.selectedDate;
    if (date != null) {
      if (_dateTimePickerValue.isAllDay ||
          _dateTimePickerValue.startTime == null) {
        finalStart = DateTime(date.year, date.month, date.day);
      } else {
        finalStart = DateTime(
          date.year,
          date.month,
          date.day,
          _dateTimePickerValue.startTime!.hour,
          _dateTimePickerValue.startTime!.minute,
        );
      }
    }

    final endDate =
        _dateTimePickerValue.endDate ?? _dateTimePickerValue.selectedDate;
    if (endDate != null &&
        _dateTimePickerValue.endTime != null &&
        !_dateTimePickerValue.isAllDay) {
      finalEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        _dateTimePickerValue.endTime!.hour,
        _dateTimePickerValue.endTime!.minute,
      );
    }

    newTask
      ..startTime = finalStart
      ..endTime = finalEnd
      ..rrule = _dateTimePickerValue.rrule
      ..notificationEnabled = _notificationEnabled
      ..reminderOffsetMinutes = _reminderOffsetMinutes;

    if (parentTask != null) {
      newTask
        ..parentTaskId = parentTask!.id
        ..checklistId = parentTask!.checklistId;
      return newTask;
    }

    final selectedChecklist =
        _selectedChecklist ?? _resolveInitialChecklist(checklistProvider);
    newTask.checklistId = selectedChecklist.isSmartList
        ? AppConstants.defaultCheckList.id
        : selectedChecklist.id;
    return newTask;
  }

  void _addCheckpoint({int? index}) {
    setState(() {
      final newCp = CheckPoint();
      if (index != null) {
        _checkpoints.insert(index + 1, newCp);
        _checkpointFocusNodes.insert(index + 1, FocusNode());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && index + 1 < _checkpointFocusNodes.length) {
            FocusScope.of(
              context,
            ).requestFocus(_checkpointFocusNodes[index + 1]);
          }
        });
      } else {
        _checkpoints.add(newCp);
        _checkpointFocusNodes.add(FocusNode());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _checkpointFocusNodes.isNotEmpty) {
            FocusScope.of(context).requestFocus(_checkpointFocusNodes.last);
          }
        });
      }
    });
  }

  void _removeCheckpoint(int index) {
    setState(() {
      _checkpoints.removeAt(index);
      _checkpointFocusNodes.removeAt(index).dispose();
    });
  }

  Widget _buildCheckpointsList() => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _checkpoints.length,
    itemBuilder: (context, index) {
      final cp = _checkpoints[index];
      return Row(
        children: [
          Checkbox(
            value: cp.isDone,
            activeColor: Colors.orange,
            onChanged: (val) {
              setState(() {
                _checkpoints[index] = CheckPoint(
                  name: cp.name,
                  isDone: val ?? false,
                );
              });
            },
          ),
          Expanded(
            child: TextFormField(
              initialValue: cp.name,
              decoration: const InputDecoration(
                hintText: '步骤内容',
                border: InputBorder.none,
              ),
              onChanged: (val) {
                _checkpoints[index] = CheckPoint(name: val, isDone: cp.isDone);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              setState(() {
                _checkpoints.removeAt(index);
              });
            },
          ),
        ],
      );
    },
  );

  Widget _buildSelectedAttributesChips() {
    final hasRepeat = _dateTimePickerValue.rrule != null;
    if (_tags.isEmpty && !hasRepeat) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (hasRepeat)
            InputChip(
              avatar: const Icon(Icons.repeat, size: 14, color: Colors.orange),
              label: Text(
                rruleToSelection(_dateTimePickerValue.rrule),
                style: const TextStyle(color: Colors.orange, fontSize: 11),
              ),
              onDeleted: () {
                setState(() {
                  _dateTimePickerValue = _dateTimePickerValue.copyWith(
                    rrule: null,
                  );
                });
              },
              onPressed: () => _showDateTimePicker(context),
            ),
          ..._tags.map(
            (tag) => InputChip(
              label: Text(tag, style: const TextStyle(fontSize: 11)),
              onDeleted: () {
                setState(() {
                  _tags.remove(tag);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetLayout(BuildContext context) => Container(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '添加任务',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(
                  Icons.open_in_full,
                  size: 20,
                  color: Colors.grey,
                ),
                tooltip: '全屏编辑',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTaskDialog(
                        initialIsFullScreen: true,
                        presetTask: _buildTaskFromForm(
                          taskName: _textController.text.trim(),
                          checklistProvider: context.read<ChecklistProvider>(),
                        ),
                        parentTask: parentTask,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          TextField(
            controller: _textController,
            autofocus: !_hasInitPreset,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: '准备做点什么？',
              errorText: _hasError ? '请输入任务名称！' : null,
              errorStyle: const TextStyle(color: Colors.red),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
          TextField(
            controller: _descController,
            maxLines: null,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            decoration: const InputDecoration(
              hintText: '添加描述或备注...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
          ),
          const SizedBox(height: 8),
          _buildSelectedAttributesChips(),
          if (_checkpoints.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '检查点',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            _buildCheckpointsList(),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        icon: Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: _dateTimePickerValue.selectedDate != null
                              ? Colors.orange
                              : Colors.grey[600],
                        ),
                        label: Text(
                          _getDateDisplayText(),
                          style: TextStyle(
                            color: _dateTimePickerValue.selectedDate != null
                                ? Colors.orange
                                : Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () => _showDateTimePicker(context),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<TaskPriority>(
                        initialValue: _priority,
                        onSelected: (val) {
                          setState(() {
                            _priority = val;
                          });
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: TaskPriority.high,
                            child: Text('🔴 高优先级'),
                          ),
                          PopupMenuItem(
                            value: TaskPriority.medium,
                            child: Text('🟠 中优先级'),
                          ),
                          PopupMenuItem(
                            value: TaskPriority.low,
                            child: Text('🔵 低优先级'),
                          ),
                          PopupMenuItem(
                            value: TaskPriority.none,
                            child: Text('⚪ 无优先级'),
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.flag,
                            size: 20,
                            color: _priority == TaskPriority.high
                                ? Colors.red
                                : _priority == TaskPriority.medium
                                ? Colors.orange
                                : _priority == TaskPriority.low
                                ? Colors.blue
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.label_outline,
                          size: 20,
                          color: _tags.isNotEmpty
                              ? Colors.orange
                              : Colors.grey[600],
                        ),
                        onPressed: _editTags,
                      ),
                      if (parentTask == null)
                        Consumer<ChecklistProvider>(
                          builder: (context, provider, child) {
                            _ensureSelectedChecklist(provider);
                            return PopupMenuButton<ChecklistVO>(
                              initialValue: _selectedChecklist,
                              onSelected: (newValue) {
                                setState(() {
                                  _selectedChecklist = newValue;
                                });
                              },
                              itemBuilder: (context) => provider.allCheckLists
                                  .map(
                                    (checklist) => PopupMenuItem<ChecklistVO>(
                                      value: checklist,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.folder,
                                            color: checklist.color,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(checklist.name),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.folder_open,
                                      size: 20,
                                      color: _selectedChecklist != null
                                          ? Colors.orange
                                          : Colors.grey[600],
                                    ),
                                    if (_selectedChecklist != null) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        _selectedChecklist!.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.mic, color: Colors.grey[600], size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('语音录入功能暂未集成')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.orange,
                      size: 20,
                    ),
                    onPressed: () => _addTask(context),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildTimeDisplayRow(BuildContext context) => InkWell(
    onTap: () => _showDateTimePicker(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getFullDateDisplayText(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          if (_dateTimePickerValue.selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _dateTimePickerValue = _dateTimePickerValue.copyWith(
                    selectedDate: null,
                    startDate: null,
                    endDate: null,
                    startTime: null,
                    endTime: null,
                  );
                });
              },
            )
          else
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    ),
  );

  Widget _buildTextFields() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _textController,
          autofocus: !_hasInitPreset,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '准备做点什么？',
            errorText: _hasError ? '请输入任务名称！' : null,
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          onChanged: (val) {
            if (_hasError && val.isNotEmpty) {
              setState(() {
                _hasError = false;
              });
            }
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descController,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: const InputDecoration(
            hintText: '描述',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ],
    ),
  );

  Widget _buildFullScreenCheckpointsList() => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _checkpoints.length,
    itemBuilder: (context, index) {
      final cp = _checkpoints[index];
      while (_checkpointFocusNodes.length <= index) {
        _checkpointFocusNodes.add(FocusNode());
      }
      final focusNode = _checkpointFocusNodes[index];

      return Row(
        key: ObjectKey(cp),
        children: [
          Checkbox(
            value: cp.isDone,
            activeColor: Colors.orange,
            onChanged: (val) {
              setState(() {
                cp.isDone = val ?? false;
              });
            },
          ),
          Expanded(
            child: TextFormField(
              focusNode: focusNode,
              initialValue: cp.name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: '添加步骤',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) {
                cp.name = val;
              },
              onFieldSubmitted: (_) {
                _addCheckpoint(index: index);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            onPressed: () => _removeCheckpoint(index),
          ),
        ],
      );
    },
  );

  Widget _buildFullScreenCheckpointsSection() {
    if (_checkpoints.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 12.0, bottom: 4.0),
          child: Text(
            '检查点',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildFullScreenCheckpointsList(),
        ),
      ],
    );
  }

  Widget _buildFullScreenBottomBar(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          offset: const Offset(0, -1),
          blurRadius: 4,
        ),
      ],
    ),
    padding: EdgeInsets.only(
      left: 8.0,
      right: 8.0,
      bottom: MediaQuery.of(context).padding.bottom + 8.0,
      top: 8.0,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.label_outline,
                color: _tags.isNotEmpty ? Colors.orange : Colors.grey[600],
              ),
              onPressed: _editTags,
              tooltip: '修改标签',
            ),
            IconButton(
              icon: Icon(
                Icons.format_list_bulleted,
                color: _checkpoints.isNotEmpty
                    ? Colors.orange
                    : Colors.grey[600],
              ),
              onPressed: _addCheckpoint,
              tooltip: '添加检查点',
            ),
            IconButton(
              icon: Icon(Icons.attach_file, color: Colors.grey[600]),
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('附件功能暂未集成')));
              },
              tooltip: '添加附件',
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.fullscreen_exit, color: Colors.grey[600]),
          onPressed: () {
            Navigator.pop(context);
            showModalBottomSheet(
              context: context,
              useRootNavigator: true,
              isScrollControlled: true,
              builder: (context) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: AddTaskDialog(
                  presetTask: _buildTaskFromForm(
                    taskName: _textController.text.trim(),
                    checklistProvider: context.read<ChecklistProvider>(),
                  ),
                  parentTask: parentTask,
                ),
              ),
            );
          },
          tooltip: '取消任务展开',
        ),
      ],
    ),
  );

  Widget _buildFullScreenLayout(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context),
      ),
      title: Consumer<ChecklistProvider>(
        builder: (context, provider, child) {
          _ensureSelectedChecklist(provider);
          return ChecklistSelector(
            items: provider.allCheckLists,
            selectedValue: _selectedChecklist,
            hintText: _selectedChecklist?.name ?? '选择清单',
            isDense: true,
            onChanged: (newValue) {
              setState(() {
                _selectedChecklist = newValue;
              });
            },
          );
        },
      ),
      actions: [
        PopupMenuButton<TaskPriority>(
          initialValue: _priority,
          icon: Icon(
            Icons.flag,
            color: _priority == TaskPriority.high
                ? Colors.red
                : _priority == TaskPriority.medium
                ? Colors.orange
                : _priority == TaskPriority.low
                ? Colors.blue
                : Colors.grey[600],
          ),
          onSelected: (val) {
            setState(() {
              _priority = val;
            });
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: TaskPriority.high, child: Text('🔴 高优先级')),
            PopupMenuItem(value: TaskPriority.medium, child: Text('🟠 中优先级')),
            PopupMenuItem(value: TaskPriority.low, child: Text('🔵 低优先级')),
            PopupMenuItem(value: TaskPriority.none, child: Text('⚪ 无优先级')),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.orange),
          onPressed: () => _addTask(context),
          tooltip: '保存任务',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (val) {
            if (val == 'reminder') {
              _showReminderRepeatDialog(context);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'reminder', child: Text('提醒与重复')),
          ],
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeDisplayRow(context),
                const Divider(height: 1),
                const SizedBox(height: 8),
                _buildTextFields(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildSelectedAttributesChips(),
                ),
                const SizedBox(height: 8),
                _buildFullScreenCheckpointsSection(),
              ],
            ),
          ),
        ),
        _buildFullScreenBottomBar(context),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return _buildFullScreenLayout(context);
    } else {
      return _buildBottomSheetLayout(context);
    }
  }
}
