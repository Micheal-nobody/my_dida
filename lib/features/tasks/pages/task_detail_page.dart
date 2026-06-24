import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/core/utils/time_formatter.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/widgets/add_task_dialog.dart';
import 'package:my_dida/features/tasks/widgets/task_date_time_picker.dart';
import 'package:my_dida/features/tasks/widgets/task_detail/widgets/checkpoint_item_widget.dart';
import 'package:my_dida/features/tasks/widgets/task_detail/widgets/sub_task_section.dart';
import 'package:my_dida/features/tasks/widgets/task_detail/widgets/task_detail_header.dart';
import 'package:my_dida/shared/widgets/inline_editable_multiline_text_field.dart';
import 'package:my_dida/shared/widgets/inline_editable_text_field.dart';
import 'package:provider/provider.dart';

// 任务详情 BottomSheet（由 TaskCard 的 onTap 触发）
class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage(
    this.taskId, {
    super.key,
    this.scrollController,
    this.useSafeArea = true,
  });

  final int taskId;
  final ScrollController? scrollController;
  final bool useSafeArea;

  @override
  State<StatefulWidget> createState() => _TaskDetailPageState();

  static void show(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        // 仅两种可见状态：默认 0.6 和 全屏 1.0
        initialChildSize: 0.6,
        minChildSize: 0.6,
        snap: true,
        // snap 开启后，snapSizes 设置可切换状态
        snapSizes: const [0.6, 1.0],
        builder: (context, scrollController) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Material(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: bottomInset),
                child: MediaQuery.removeViewInsets(
                  removeBottom: true,
                  context: context,
                  child: TaskDetailPage(
                    task.id,
                    scrollController: scrollController,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late TaskProvider _taskProvider;
  Task? _task;
  StreamSubscription<Task?>? _taskSub;
  Timer? _descriptionDebounce;
  String _lastSavedDescription = '';
  bool _hasResolvedTask = false;
  bool _didShowMissingTaskMessage = false;
  bool _isDeletingActively = false;

  @override
  void initState() {
    super.initState();
    _taskProvider = Provider.of<TaskProvider>(context, listen: false);
    _taskSub = _taskProvider.watchTaskById(widget.taskId).listen((t) {
      if (!mounted) return;
      setState(() {
        _task = t;
        _lastSavedDescription = t?.description ?? '';
        _hasResolvedTask = true;
        if (t != null) {
          _didShowMissingTaskMessage = false;
        }
      });

      if (t == null && !_didShowMissingTaskMessage && !_isDeletingActively) {
        _didShowMissingTaskMessage = true;
        getIt<AppMessageService>().showWarning('任务不存在或已删除');
      }
    });
  }

  @override
  void dispose() {
    _descriptionDebounce?.cancel();
    _taskSub?.cancel();
    super.dispose();
  }

  void _scheduleDescriptionUpdate(Task task, String value) {
    _descriptionDebounce?.cancel();
    _descriptionDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _persistDescription(task, value),
    );
  }

  Future<void> _persistDescription(Task task, String value) async {
    final normalizedValue = value.trim();
    if (normalizedValue == _lastSavedDescription) {
      return;
    }

    await _taskProvider.execute(UpdateDescription(task, normalizedValue));
    _lastSavedDescription = normalizedValue;
  }

  void _navigateToSubTask(int subTaskId) {
    context.push('/tasks/$subTaskId');
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final sortedCheckpointEntries =
        task?.checkpoints.asMap().entries.toList() ?? const []
          ..sort((a, b) {
            if (a.value.isDone == b.value.isDone) {
              return a.key.compareTo(b.key);
            }
            return a.value.isDone ? 1 : -1;
          });

    final body = task == null
        ? SizedBox(
            height: 300,
            child: Center(
              child: _hasResolvedTask
                  ? const Text('任务不存在或已删除')
                  : const CircularProgressIndicator(),
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // 任务详情头部
                      TaskDetailHeader(
                        task: task,
                        onDelete: () {
                          setState(() {
                            _isDeletingActively = true;
                          });
                          _taskSub?.cancel();
                        },
                      ),
                      const SizedBox(height: 6),

                      // 时间显示和确认按钮区域
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await _taskProvider.execute(
                                  UpdateTaskIsDone(task, !task.isDone),
                                );
                              },
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.orange),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: task.isDone
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.orange,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ),

                            // 增加一个空格
                            const SizedBox(width: 12),

                            Consumer<TaskProvider>(
                              builder: (context, provider, child) {
                                final updatedTask = provider.tasks.firstWhere(
                                  (t) => t.id == task.id,
                                  orElse: () => task,
                                );
                                final DateTime? start = updatedTask.startTime;
                                final DateTime? end = updatedTask.endTime;

                                final String dateText =
                                    TimeFormatter.formatTaskDateTimeRange(
                                      start,
                                      end,
                                    );

                                return GestureDetector(
                                  onTap: () async {
                                    // 使用新的 showForTask 方法，它会自动处理持久化
                                    await TaskDateTimePicker.showForTask(
                                      context: context,
                                      task: updatedTask,
                                    );
                                  },
                                  child: Text(
                                    dateText,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // 如果当前任务已关联主任务，则显示主任务标题（以及跳转按钮）
                      if (task.parentTaskId != null)
                        FutureBuilder<Task?>(
                          future: _taskProvider.getTaskById(task.parentTaskId!),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Row(
                                children: [
                                  TextButton.icon(
                                    label: Text('${snapshot.data!.name} >'),
                                    onPressed: () {
                                      _navigateToSubTask(task.parentTaskId!);
                                    },
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                      // 属性选择行（优先级、标签）
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            // 优先级选择
                            PopupMenuButton<TaskPriority>(
                              initialValue: task.priority,
                              onSelected: (val) async {
                                await _taskProvider.execute(
                                  UpdatePriority(task, val),
                                );
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.flag,
                                      color: task.priority == TaskPriority.high
                                          ? Colors.red
                                          : task.priority == TaskPriority.medium
                                          ? Colors.orange
                                          : task.priority == TaskPriority.low
                                          ? Colors.blue
                                          : Colors.grey,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      task.priority == TaskPriority.high
                                          ? '高优先级'
                                          : task.priority == TaskPriority.medium
                                          ? '中优先级'
                                          : task.priority == TaskPriority.low
                                          ? '低优先级'
                                          : '无优先级',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 标签编辑
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final textController = TextEditingController(
                                    text: task.tags.join(', '),
                                  );
                                  final updatedTags =
                                      await showDialog<List<String>>(
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
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('取消'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                final text = textController.text
                                                    .trim();
                                                final tags = text.isEmpty
                                                    ? <String>[]
                                                    : text
                                                          .split(RegExp('[，,]'))
                                                          .map((e) => e.trim())
                                                          .where(
                                                            (e) => e.isNotEmpty,
                                                          )
                                                          .toList();
                                                Navigator.pop(context, tags);
                                              },
                                              child: const Text('保存'),
                                            ),
                                          ],
                                        ),
                                      );
                                  if (updatedTags != null) {
                                    await _taskProvider.execute(
                                      UpdateTags(task, updatedTags),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.label_outline,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          task.tags.isEmpty
                                              ? '添加标签'
                                              : task.tags.join(', '),
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 标题
                      InlineEditableTextField(
                        key: ValueKey('title_${task.id}'),
                        value: task.name,
                        onSubmit: (updated) async {
                          await _taskProvider.execute(
                            UpdateTitle(task, updated),
                          );
                        },
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 描述
                      InlineEditableMultilineTextField(
                        key: ValueKey('desc_${task.id}'),
                        value: task.description,
                        onSubmit: (newDesc) async {
                          _descriptionDebounce?.cancel();
                          await _persistDescription(task, newDesc);
                        },
                        onChanged: (value) {
                          _scheduleDescriptionUpdate(task, value);
                        },
                        hintText: '添加备注...',
                        decoration: const InputDecoration(
                          hintText: '添加备注...',
                          border: InputBorder.none,
                        ),
                      ),

                      // CheckpointItems
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.checkpoints.isEmpty) const SizedBox.shrink(),

                          for (final entry in sortedCheckpointEntries)
                            CheckpointItemWidget(
                              key: ValueKey(
                                'cp_${widget.taskId}_${entry.key}_${entry.value.isDone}',
                              ),
                              task: task,
                              index: entry.key,
                              checkpoint: entry.value,
                              onToggle: (isDone) async {
                                await _taskProvider.execute(
                                  ToggleCheckpoint(task, entry.key, isDone),
                                );
                              },
                              onRename: (newName) async {
                                await _taskProvider.execute(
                                  RenameCheckpoint(task, entry.key, newName),
                                );
                              },
                              onDelete: () async {
                                await _taskProvider.execute(
                                  RemoveCheckpoint(task, entry.key),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 子任务
                      SubTaskSection(
                        task: task,
                        onOpenSubTask: _navigateToSubTask,
                        getSubTasks: (ids) => _taskProvider.getTasksByIds(ids),
                        onToggleSubTask: (subTask, isDone) async {
                          await _taskProvider.execute(
                            UpdateTaskIsDone(subTask, isDone),
                          );
                        },
                        onDeleteSubTask: (subTask) async {
                          await _taskProvider.execute(
                            DeleteSubTask(task, subTask.id),
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // 底部按钮栏
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await _taskProvider.execute(AddCheckpoint(task));
                      },
                      icon: const Icon(Icons.checklist, color: Colors.orange),
                      label: const Text(
                        '新检查点',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          isScrollControlled: true,
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: AddTaskDialog(parentTask: task),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.subdirectory_arrow_right,
                        color: Colors.orange,
                      ),
                      label: const Text(
                        '新子任务',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

    return Material(child: widget.useSafeArea ? SafeArea(child: body) : body);
  }
}
