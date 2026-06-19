import 'package:flutter/material.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/constants/app_constants.dart';
import 'package:my_dida/model/entity/check_point.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/checklist_vo.dart';
import 'package:my_dida/provider/checklist_provider.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:my_dida/shared/widgets/checklist_selector.dart';
import 'package:my_dida/shared/widgets/datetime/custom_date_picker_dialog.dart';
import 'package:my_dida/shared/widgets/datetime/custom_repeat_picker.dart';
import 'package:my_dida/shared/widgets/datetime/repeat_picker_utils.dart';
import 'package:my_dida/utils/TimeUtils.dart';
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

  DateTime? _startTime;
  bool _isAllDay = true;
  String? _rrule;
  bool _notificationEnabled = false;
  int? _reminderOffsetMinutes;
  TaskPriority _priority = TaskPriority.none;
  List<String> _tags = [];
  List<CheckPoint> _checkpoints = [];
  ChecklistVO? _selectedChecklist;

  bool _hasError = false;
  bool _isExpanded = false;
  late bool _isFullScreen;
  bool _hasInitPreset = false;

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

      if (widget.presetTask!.startTime != null) {
        _startTime = widget.presetTask!.startTime;
        _isAllDay = widget.presetTask!.isAllDay;
        _rrule = widget.presetTask!.rrule;
        _notificationEnabled = widget.presetTask!.notificationEnabled;
        _reminderOffsetMinutes = widget.presetTask!.reminderOffsetMinutes;
      } else {
        _startTime = now.toBeijingTime().dateOnly;
        _isAllDay = true;
      }

      if (widget.presetTask!.checklistId != null) {
        _selectedChecklist = ChecklistVO(
          id: widget.presetTask!.checklistId!,
          name: '',
          color: Colors.grey,
        );
      }
    } else {
      _startTime = now.toBeijingTime().dateOnly;
      _isAllDay = true;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _descController.dispose();
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

  void _showDatePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CustomDatePickerDialog(
        selectedDate: _startTime,
        onDateSelected: (date) {
          setState(() {
            _startTime = date;
            _isAllDay = true;
          });
        },
      ),
    );
  }

  void _showReminderRepeatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String tempRepeat = rruleToSelection(_rrule);
        int? tempOffset = _reminderOffsetMinutes;
        bool tempNotify = _notificationEnabled;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
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
                        baseDate: _startTime,
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
                      tempNotify
                          ? _getReminderDisplayText(tempOffset)
                          : '无提醒',
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
                      _rrule = mapSelectionToRRule(tempRepeat, _startTime);
                      _reminderOffsetMinutes = tempOffset;
                      _notificationEnabled = tempNotify;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('确定', style: TextStyle(color: Colors.orange)),
                ),
              ],
            );
          },
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
          decoration: const InputDecoration(
            hintText: '输入标签，以逗号分隔',
          ),
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
                      .split(RegExp(r'[，,]'))
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
    if (_startTime == null) return '设置日期';
    final now = DateTime.now().toBeijingTime();
    if (_startTime!.year == now.year &&
        _startTime!.month == now.month &&
        _startTime!.day == now.day) {
      return '今天';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (_startTime!.year == tomorrow.year &&
        _startTime!.month == tomorrow.month &&
        _startTime!.day == tomorrow.day) {
      return '明天';
    }
    return '${_startTime!.month}月${_startTime!.day}日';
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
    final Task newTask = Task(
      name: taskName,
      isAllDay: _isAllDay,
      priority: _priority,
      tags: _tags,
      checkpoints: _checkpoints,
    );

    if (_startTime != null) {
      final DateTime date = _startTime!.dateOnly;
      newTask
        ..startTime = DateTime(date.year, date.month, date.day)
        ..endTime = null;
    } else {
      newTask
        ..startTime = null
        ..endTime = null;
    }

    newTask.rrule = _rrule;
    newTask.notificationEnabled = _notificationEnabled;
    newTask.reminderOffsetMinutes = _reminderOffsetMinutes;

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

  Widget _buildCheckpointsList() {
    return ListView.builder(
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
                  _checkpoints[index] = CheckPoint(name: cp.name, isDone: val ?? false);
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
  }

  Widget _buildSelectedAttributesChips() {
    if (_startTime == null && _tags.isEmpty && _rrule == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (_startTime != null)
            InputChip(
              avatar: const Icon(Icons.calendar_today, size: 14, color: Colors.orange),
              label: Text(
                _getDateDisplayText(),
                style: const TextStyle(color: Colors.orange, fontSize: 11),
              ),
              onDeleted: () {
                setState(() {
                  _startTime = null;
                });
              },
              onPressed: () => _showDatePicker(context),
            ),
          if (_rrule != null)
            InputChip(
              avatar: const Icon(Icons.repeat, size: 14, color: Colors.orange),
              label: Text(
                rruleToSelection(_rrule),
                style: const TextStyle(color: Colors.orange, fontSize: 11),
              ),
              onDeleted: () {
                setState(() {
                  _rrule = null;
                });
              },
              onPressed: () => _showReminderRepeatDialog(context),
            ),
          ..._tags.map((tag) => InputChip(
                label: Text(tag, style: const TextStyle(fontSize: 11)),
                onDeleted: () {
                  setState(() {
                    _tags.remove(tag);
                  });
                },
              )),
        ],
      ),
    );
  }

  Widget _buildBottomSheetLayout(BuildContext context) {
    return Container(
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
                  icon: const Icon(Icons.open_in_full, size: 20, color: Colors.grey),
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
            const SizedBox(height: 8),
            _buildSelectedAttributesChips(),
            if (_isExpanded) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '添加备注或描述...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(8),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '检查点',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              _buildCheckpointsList(),
              TextButton.icon(
                icon: const Icon(Icons.add, color: Colors.orange, size: 18),
                label: const Text('添加检查点', style: TextStyle(color: Colors.orange, fontSize: 13)),
                onPressed: () {
                  setState(() {
                    _checkpoints.add(CheckPoint(name: ''));
                  });
                },
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.calendar_month,
                    color: _startTime != null ? Colors.orange : Colors.grey[600],
                  ),
                  onPressed: () => _showDatePicker(context),
                ),
                IconButton(
                  icon: Icon(
                    Icons.notifications_none,
                    color: _rrule != null || _notificationEnabled ? Colors.orange : Colors.grey[600],
                  ),
                  onPressed: () => _showReminderRepeatDialog(context),
                ),
                PopupMenuButton<TaskPriority>(
                  initialValue: _priority,
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.flag,
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
                    color: _tags.isNotEmpty ? Colors.orange : Colors.grey[600],
                  ),
                  onPressed: _editTags,
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _isExpanded ? Colors.orange : Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.mic, color: Colors.grey[600]),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('语音录入功能暂未集成')),
                    );
                  },
                ),
                const Spacer(),
                if (parentTask == null)
                  Consumer<ChecklistProvider>(
                    builder: (context, provider, child) {
                      _ensureSelectedChecklist(provider);
                      return SizedBox(
                        width: 100,
                        child: ChecklistSelector(
                          items: provider.allCheckLists,
                          selectedValue: _selectedChecklist,
                          hintText: _selectedChecklist?.name ?? '选择清单',
                          onChanged: (newValue) {
                            setState(() {
                              _selectedChecklist = newValue;
                            });
                          },
                        ),
                      );
                    },
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _addTask(context),
                  child: const Text('确认'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建任务'),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(
            onPressed: () => _addTask(context),
            child: const Text('保存', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '想要做点什么？',
                errorText: _hasError ? '请输入任务名称！' : null,
                border: InputBorder.none,
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
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '添加描述或备注...',
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.orange),
              title: const Text('日期'),
              subtitle: Text(_startTime != null ? _getDateDisplayText() : '设置日期'),
              trailing: _startTime != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _startTime = null;
                        });
                      },
                    )
                  : const Icon(Icons.chevron_right),
              onTap: () => _showDatePicker(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_none, color: Colors.orange),
              title: const Text('提醒与重复'),
              subtitle: Text(
                _rrule != null || _notificationEnabled
                    ? '${rruleToSelection(_rrule)} / ${_notificationEnabled ? _getReminderDisplayText(_reminderOffsetMinutes) : '无提醒'}'
                    : '设置提醒与重复',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showReminderRepeatDialog(context),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.flag,
                color: _priority == TaskPriority.high
                    ? Colors.red
                    : _priority == TaskPriority.medium
                        ? Colors.orange
                        : _priority == TaskPriority.low
                            ? Colors.blue
                            : Colors.grey,
              ),
              title: const Text('优先级'),
              subtitle: Text(
                _priority == TaskPriority.high
                    ? '高优先级'
                    : _priority == TaskPriority.medium
                        ? '中优先级'
                        : _priority == TaskPriority.low
                            ? '低优先级'
                            : '无优先级',
              ),
              trailing: PopupMenuButton<TaskPriority>(
                initialValue: _priority,
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
                child: const Icon(Icons.arrow_drop_down),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.folder_open, color: Colors.orange),
              title: const Text('所属清单'),
              trailing: Consumer<ChecklistProvider>(
                builder: (context, provider, child) {
                  _ensureSelectedChecklist(provider);
                  return ChecklistSelector(
                    items: provider.allCheckLists,
                    selectedValue: _selectedChecklist,
                    hintText: _selectedChecklist?.name ?? '选择清单',
                    onChanged: (newValue) {
                      setState(() {
                        _selectedChecklist = newValue;
                      });
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.label_outline, color: Colors.orange),
              title: const Text('标签'),
              subtitle: _tags.isEmpty
                  ? const Text('添加标签')
                  : Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _tags.map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        onDeleted: () {
                          setState(() {
                            _tags.remove(tag);
                          });
                        },
                      )).toList(),
                    ),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _editTags,
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '检查点',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            _buildCheckpointsList(),
            TextButton.icon(
              icon: const Icon(Icons.add, color: Colors.orange),
              label: const Text('添加检查点', style: TextStyle(color: Colors.orange)),
              onPressed: () {
                setState(() {
                  _checkpoints.add(CheckPoint(name: ''));
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return _buildFullScreenLayout(context);
    } else {
      return _buildBottomSheetLayout(context);
    }
  }
}
