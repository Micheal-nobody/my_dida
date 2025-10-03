import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_dida/components/dialogs/AddTaskDialog.dart';
import 'package:my_dida/components/pickers/CustomDatePicker/TaskDateTimePicker.dart';
import 'package:my_dida/components/task_detail/widgets/CheckpointItemWidget.dart';
import 'package:my_dida/components/task_detail/widgets/EditableDescriptionWidget.dart';
import 'package:my_dida/components/task_detail/widgets/EditableTitleWidget.dart';
import 'package:my_dida/components/task_detail/widgets/SubTaskSection.dart';
import 'package:my_dida/components/task_detail/widgets/TaskDetailHeader.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/provider/TaskProvider.dart';
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

  @override
  void initState() {
    super.initState();
    _taskProvider = Provider.of<TaskProvider>(context, listen: false);
    _taskSub = _taskProvider.watchTaskById(widget.taskId).listen((t) {
      if (!mounted) return;
      setState(() {
        _task = t;
      });
    });
  }

  @override
  void dispose() {
    _taskSub?.cancel();
    super.dispose();
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
                          EditableTitleWidget(
                            key: ValueKey('title_${task.id}'),
                            task: task,
                            onSubmit: (updated) async {
                              await _taskProvider.updateTitle(task, updated);
                            },
                            onFieldSubmitted: (value) {
                              context
                                  .read<TaskProvider>()
                                  .loadCurrentBoxTasks();
                            },
                          ),
                          const SizedBox(height: 8),

                          // 描述
                          EditableDescriptionWidget(
                            key: ValueKey('desc_${task.id}'),
                            task: task,
                            onSubmit: (newDesc) async {
                              await _taskProvider.updateDescription(
                                task,
                                newDesc,
                              );
                            },
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
                              for (final entry in [
                                ...task.checkpoints.where((e) => !e.isDone),
                                ...task.checkpoints.where((e) => e.isDone),
                              ].asMap().entries)
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
