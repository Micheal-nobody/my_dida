import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_dida/features/dialogs/add_task_dialog.dart';
import 'package:my_dida/features/pickers/task_date_time_picker.dart';
import 'package:my_dida/features/task_detail/widgets/checkpoint_item_widget.dart';
import 'package:my_dida/features/task_detail/widgets/sub_task_section.dart';
import 'package:my_dida/features/task_detail/widgets/task_detail_header.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:my_dida/shared/widgets/inline_editable_multiline_text_field.dart';
import 'package:my_dida/shared/widgets/inline_editable_text_field.dart';
import 'package:provider/provider.dart';

// 任务详情 BottomSheet（由 TaskCard 的 onTap 触发）
class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage(this.taskId, {super.key, this.scrollController});

  final int taskId;
  final ScrollController? scrollController;

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

  @override
  void initState() {
    super.initState();
    _taskProvider = Provider.of<TaskProvider>(context, listen: false);
    _taskSub = _taskProvider.watchTaskById(widget.taskId).listen((t) {
      if (!mounted) return;
      setState(() {
        _task = t;
        _lastSavedDescription = t?.description ?? '';
      });
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

    await _taskProvider.updateDescription(task, normalizedValue);
    _lastSavedDescription = normalizedValue;
  }

  void _navigateToSubTask(int subTaskId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(subTaskId),
        fullscreenDialog: true,
      ),
    );
  }

  String _formatTaskTime(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      // 显示 startTime --> endTime 格式
      if (start.hour == 0 && start.minute == 0) {
        // 只有日期信息，不显示时间
        return '${start.month}月${start.day}日';
      } else {
        final startStr =
            "${start.month}月${start.day}日 ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
        final endStr =
            "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}";
        return '$startStr --> $endStr';
      }
    } else if (start != null) {
      // 只显示开始时间
      if (start.hour == 0 && start.minute == 0) {
        // 只有日期信息，不显示时间
        return '${start.month}月${start.day}日';
      } else {
        return "${start.month}月${start.day}日 ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
      }
    } else {
      return '未设置时间';
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final sortedCheckpointEntries =
        task?.checkpoints.asMap().entries.toList() ?? const [];
    sortedCheckpointEntries.sort((a, b) {
      if (a.value.isDone == b.value.isDone) {
        return a.key.compareTo(b.key);
      }
      return a.value.isDone ? 1 : -1;
    });

    return Material(
      child: SafeArea(
        child: task == null
            ? const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
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
                          TaskDetailHeader(task: task),
                          const SizedBox(height: 6),

                          // 时间显示和确认按钮区域
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    await _taskProvider.updateTaskIsDone(
                                      task,
                                      !task.isDone,
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
                                    final updatedTask = provider.tasks
                                        .firstWhere(
                                          (t) => t.id == task.id,
                                          orElse: () => task,
                                        );
                                    final DateTime? start =
                                        updatedTask.startTime;
                                    final DateTime? end = updatedTask.endTime;

                                    final String dateText = _formatTaskTime(
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
                              future: _taskProvider.getTaskById(
                                task.parentTaskId!,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Row(
                                    children: [
                                      TextButton.icon(
                                        label: Text('${snapshot.data!.name} >'),
                                        onPressed: () {
                                          _navigateToSubTask(
                                            task.parentTaskId!,
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),

                          // 标题
                          InlineEditableTextField(
                            key: ValueKey('title_${task.id}'),
                            value: task.name,
                            onSubmit: (updated) async {
                              await _taskProvider.updateTitle(task, updated);
                            },
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              decoration: TextDecoration.underline,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            onFieldSubmitted: (value) {
                              context
                                  .read<TaskProvider>()
                                  .loadCurrentBoxTasks();
                            },
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            hintText: '添加备注...',
                            decoration: const InputDecoration(
                              hintText: '添加备注...',
                              border: InputBorder.none,
                            ),
                            onFieldSubmitted: (value) {
                              context
                                  .read<TaskProvider>()
                                  .loadCurrentBoxTasks();
                            },
                          ),

                          // CheckpointItems
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (task.checkpoints.isEmpty)
                                const SizedBox.shrink(),

                              for (final entry in sortedCheckpointEntries)
                                CheckpointItemWidget(
                                  key: ValueKey(
                                    'cp_${widget.taskId}_${entry.key}_${entry.value.isDone}',
                                  ),
                                  task: task,
                                  index: entry.key,
                                  checkpoint: entry.value,
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 子任务
                          SubTaskSection(
                            task: task,
                            onOpenSubTask: _navigateToSubTask,
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
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            await _taskProvider.addCheckpoint(task);
                          },
                          icon: const Icon(
                            Icons.checklist,
                            color: Colors.orange,
                          ),
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
                                  bottom: MediaQuery.of(
                                    context,
                                  ).viewInsets.bottom,
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
              ),
      ),
    );
  }
}
