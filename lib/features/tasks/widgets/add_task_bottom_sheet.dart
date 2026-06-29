import 'package:flutter/material.dart';
import 'package:my_dida/core/constants/app_constants.dart';
import 'package:my_dida/core/logger/logger.dart';
import 'package:my_dida/core/utils/time_formatter.dart';
import 'package:my_dida/core/utils/time_utils.dart';
import 'package:my_dida/features/checklist/models/checklist_vo.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:my_dida/features/tasks/models/check_point.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/pages/task_detail_page.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/widgets/add_task/add_task_full_screen_content.dart';
import 'package:my_dida/features/tasks/widgets/add_task/add_task_standard_content.dart';
import 'package:my_dida/features/tasks/widgets/add_task/tag_selector_bottom_sheet.dart';
import 'package:my_dida/shared/widgets/datetime/custom_date_time_picker.dart';
import 'package:provider/provider.dart';

class AddTaskStateScope extends InheritedWidget {
  const AddTaskStateScope({
    super.key,
    required this.state,
    required super.child,
  });

  final AddTaskBottomSheetState state;

  static AddTaskBottomSheetState of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final scope = context.dependOnInheritedWidgetOfExactType<AddTaskStateScope>();
      assert(scope != null, 'No AddTaskStateScope found in context');
      return scope!.state;
    } else {
      final element = context.getElementForInheritedWidgetOfExactType<AddTaskStateScope>();
      assert(element != null, 'No AddTaskStateScope found in context');
      return (element!.widget as AddTaskStateScope).state;
    }
  }

  @override
  bool updateShouldNotify(AddTaskStateScope oldWidget) => true;
}

class AddTaskBottomSheet extends StatefulWidget {
  const AddTaskBottomSheet({
    super.key,
    this.parentTask,
    this.initTask,
    this.initialIsFullScreen = false,
  });

  final Task? parentTask;
  final Task? initTask;
  final bool initialIsFullScreen;

  @override
  State<AddTaskBottomSheet> createState() => AddTaskBottomSheetState();

  static Future<T?> show<T>({
    required BuildContext context,
    Task? parentTask,
    Task? initTask,
    bool initialIsFullScreen = false,
  }) => showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AddTaskBottomSheet(
        parentTask: parentTask,
        initTask: initTask,
        initialIsFullScreen: initialIsFullScreen,
      ),
    ),
  );
}

class AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final TextEditingController textController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  late final Task? parentTask;

  late CustomDateTimePickerValue dateTimePickerValue;
  bool notificationEnabled = false;
  List<int> reminderOffsets = [];
  TaskPriority priority = TaskPriority.none;
  List<String> tags = [];
  List<CheckPoint> checkpoints = [];
  ChecklistVO? selectedChecklist;

  bool hasError = false;
  late bool isFullScreen;
  bool hasInitPreset = false;

  // 全屏模式下用于检查点聚焦管理的 FocusNode 列表
  final List<FocusNode> checkpointFocusNodes = [];

  @override
  void initState() {
    super.initState();
    parentTask = widget.parentTask;
    isFullScreen = widget.initialIsFullScreen;
    final now = DateTime.now();

    if (widget.initTask != null) {
      hasInitPreset = true;
      textController.text = widget.initTask!.name;
      descController.text = widget.initTask!.description;
      priority = widget.initTask!.priority;
      tags = List.from(widget.initTask!.tags);
      checkpoints = widget.initTask!.checkpoints
          .map((cp) => CheckPoint(name: cp.name, isDone: cp.isDone))
          .toList();

      final taskStart = widget.initTask!.startTime;
      final taskEnd = widget.initTask!.endTime;

      notificationEnabled = widget.initTask!.notificationEnabled;
      reminderOffsets = List.from(widget.initTask!.reminderOffsets);
      if (reminderOffsets.isEmpty &&
          widget.initTask!.reminderOffsetMinutes != null) {
        reminderOffsets.add(widget.initTask!.reminderOffsetMinutes!);
      }

      dateTimePickerValue = CustomDateTimePickerValue(
        selectedDate: taskStart?.dateOnly ?? now.toBeijingTime().dateOnly,
        startTime: taskStart != null && !taskStart.justDate()
            ? TimeOfDay.fromDateTime(taskStart)
            : null,
        endTime: taskEnd != null && !taskEnd.justDate()
            ? TimeOfDay.fromDateTime(taskEnd)
            : null,
        startDate: taskStart?.dateOnly,
        endDate: taskEnd?.dateOnly,
        isAllDay: widget.initTask!.isAllDay,
        rrule: widget.initTask!.rrule,
        reminderOffsets: reminderOffsets,
        notificationEnabled: notificationEnabled,
      );

      if (widget.initTask!.checklistId != null) {
        selectedChecklist = ChecklistVO(
          id: widget.initTask!.checklistId!,
          name: '',
          color: Colors.grey,
        );
      }
    } else {
      dateTimePickerValue = CustomDateTimePickerValue(
        selectedDate: now.toBeijingTime().dateOnly,
        isAllDay: true,
      );
    }

    // 初始化已存 checkpoint 的 FocusNode
    for (int i = 0; i < checkpoints.length; i++) {
      checkpointFocusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    textController.dispose();
    descController.dispose();
    for (final node in checkpointFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // 状态修改方法

  void setPriority(TaskPriority val) {
    setState(() {
      priority = val;
    });
  }

  void setSelectedChecklist(ChecklistVO? val) {
    setState(() {
      selectedChecklist = val;
    });
  }

  void setCheckpoint(int index, CheckPoint cp) {
    setState(() {
      checkpoints[index] = cp;
    });
  }

  void deleteTag(String tag) {
    setState(() {
      tags.remove(tag);
    });
  }

  void setHasError(bool val) {
    setState(() {
      hasError = val;
    });
  }

  void clearDateTimePicker() {
    setState(() {
      dateTimePickerValue = dateTimePickerValue.copyWith(
        selectedDate: null,
        startDate: null,
        endDate: null,
        startTime: null,
        endTime: null,
      );
    });
  }

  String getDateDisplayText() {
    final date = dateTimePickerValue.selectedDate;
    if (date == null) return '设置日期';
    return TimeFormatter.formatDateTimeRange(
      date,
      isAllDay: dateTimePickerValue.isAllDay,
      startTime: dateTimePickerValue.startTime,
      endTime: dateTimePickerValue.endTime,
      now: DateTime.now().toBeijingTime(),
    );
  }

  String getFullDateDisplayText() {
    final date = dateTimePickerValue.selectedDate;
    if (date == null) return '设置日期与时间';
    return TimeFormatter.formatFullDateTimeRange(
      date,
      isAllDay: dateTimePickerValue.isAllDay,
      startTime: dateTimePickerValue.startTime,
      endTime: dateTimePickerValue.endTime,
      now: DateTime.now().toBeijingTime(),
    );
  }

  Future<void> addTask(BuildContext context) async {
    final String taskName = textController.text.trim();

    if (taskName.isEmpty) {
      setState(() {
        hasError = true;
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

  Future<void> showDateTimePicker(BuildContext context) async {
    final result = await CustomDateTimePickerModal.show(
      context: context,
      initialValue: dateTimePickerValue,
    );
    if (result != null) {
      setState(() {
        dateTimePickerValue = result;
        if (result.startTime != null && !result.isAllDay) {
          notificationEnabled = result.notificationEnabled;
          reminderOffsets = result.reminderOffsets;
        } else if (result.startTime == null || result.isAllDay) {
          notificationEnabled = false;
          reminderOffsets = [];
        }
      });
    }
  }

  Future<void> editTags() async {
    final allTasks = context.read<TaskProvider>().tasks;
    final allTags = allTasks.expand((t) => t.tags).toSet().toList();

    final updatedTags = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          TagSelectorBottomSheet(initialTags: tags, allHistoryTags: allTags),
    );
    if (updatedTags != null) {
      setState(() {
        tags = updatedTags;
      });
    }
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
      isAllDay: dateTimePickerValue.isAllDay,
      priority: priority,
      tags: tags,
      checkpoints: checkpoints,
      description: descController.text.trim(),
    );

    DateTime? finalStart;
    DateTime? finalEnd;

    final date =
        dateTimePickerValue.startDate ?? dateTimePickerValue.selectedDate;
    if (date != null) {
      if (dateTimePickerValue.isAllDay ||
          dateTimePickerValue.startTime == null) {
        finalStart = DateTime(date.year, date.month, date.day);
      } else {
        finalStart = DateTime(
          date.year,
          date.month,
          date.day,
          dateTimePickerValue.startTime!.hour,
          dateTimePickerValue.startTime!.minute,
        );
      }
    }

    final endDate =
        dateTimePickerValue.endDate ?? dateTimePickerValue.selectedDate;
    if (endDate != null &&
        dateTimePickerValue.endTime != null &&
        !dateTimePickerValue.isAllDay) {
      finalEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        dateTimePickerValue.endTime!.hour,
        dateTimePickerValue.endTime!.minute,
      );
    }

    newTask
      ..startTime = finalStart
      ..endTime = finalEnd
      ..rrule = dateTimePickerValue.rrule
      ..notificationEnabled = notificationEnabled
      ..reminderOffsets = reminderOffsets
      ..reminderOffsetMinutes = reminderOffsets.isNotEmpty
          ? reminderOffsets.first
          : null;

    if (parentTask != null) {
      newTask
        ..parentTaskId = parentTask!.id
        ..checklistId = parentTask!.checklistId;
      return newTask;
    }

    final selectedChecklist =
        this.selectedChecklist ?? _resolveInitialChecklist(checklistProvider);
    newTask.checklistId = selectedChecklist.isSmartList
        ? AppConstants.defaultCheckList.id
        : selectedChecklist.id;
    return newTask;
  }

  void addCheckpoint({int? index}) {
    setState(() {
      final newCp = CheckPoint();
      if (index != null) {
        checkpoints.insert(index + 1, newCp);
        checkpointFocusNodes.insert(index + 1, FocusNode());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && index + 1 < checkpointFocusNodes.length) {
            FocusScope.of(
              context,
            ).requestFocus(checkpointFocusNodes[index + 1]);
          }
        });
      } else {
        checkpoints.add(newCp);
        checkpointFocusNodes.add(FocusNode());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && checkpointFocusNodes.isNotEmpty) {
            FocusScope.of(context).requestFocus(checkpointFocusNodes.last);
          }
        });
      }
    });
  }

  void removeCheckpoint(int index) {
    if (index == -999) {
      setState(() {});
      return;
    }
    setState(() {
      checkpoints.removeAt(index);
      checkpointFocusNodes.removeAt(index).dispose();
    });
  }

  Future<void> triggerExtendedDetail() async {
    final String taskName = textController.text.trim();
    if (taskName.isEmpty) {
      setState(() {
        hasError = true;
      });
      return;
    }
    final newTask = _buildTaskFromForm(
      taskName: taskName,
      checklistProvider: context.read<ChecklistProvider>(),
    );
    final savedTask = await context.read<TaskProvider>().addTask(newTask);
    if (!mounted) return;
    Navigator.pop(context);
    TaskDetailPage.show(context, savedTask);
  }

  void cancelFullScreen() {
    Navigator.pop(context);
    AddTaskBottomSheet.show(
      context: context,
      initTask: _buildTaskFromForm(
        taskName: textController.text.trim(),
        checklistProvider: context.read<ChecklistProvider>(),
      ),
      parentTask: parentTask,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AddTaskStateScope(
      state: this,
      child: isFullScreen
          ? const AddTaskFullScreenContent()
          : const AddTaskStandardContent(),
    );
  }
}
