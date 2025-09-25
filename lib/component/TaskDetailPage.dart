import 'package:flutter/material.dart';
import 'package:my_dida/component/taskDetailWidgets/EditableTitleWidget.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/component/taskDetailWidgets/EditableDescriptionWidget.dart';
import 'package:my_dida/component/taskDetailWidgets/CheckpointItemWidget.dart';
import 'package:my_dida/component/taskDetailWidgets/TaskDetailHeader.dart';
import 'package:my_dida/component/taskDetailWidgets/SubTaskSection.dart';
import 'package:provider/provider.dart';
import 'package:my_dida/provider/TaskProvider.dart';
import 'dart:async';
import 'package:my_dida/component/CustomDatePicker/CustomDatePicker.dart';

// 任务详情 BottomSheet（由 TaskCard 的 onTap 触发）
class TaskDetailPage extends StatefulWidget {
  final int taskId;
  final ScrollController? scrollController;

  const TaskDetailPage(this.taskId, {super.key, this.scrollController});

  @override
  State<StatefulWidget> createState() {
    return _TaskDetailPageState();
  }

  static void show(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          // 仅两种可见状态：默认 0.6 和 全屏 1.0
          initialChildSize: 0.6,
          minChildSize: 0.6,
          maxChildSize: 1.0,
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
        );
      },
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
                            // padding 表示内边距，表示内容与边缘的距离
                            // 改为左边距 16
                            padding: const EdgeInsets.only(left: 16),
                            // padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    final String dateText = start != null
                                        ? "${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}"
                                        : "未设置时间";

                                    return GestureDetector(
                                      onTap: () async {
                                        DateTime? tempSelectedDate =
                                            start ?? DateTime.now();
                                        TimeOfDay? tempStartTime = start != null
                                            ? TimeOfDay(
                                                hour: start.hour,
                                                minute: start.minute,
                                              )
                                            : null;

                                        await showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (ctx) {
                                            return CustomDatePicker(
                                              selectedDate: tempSelectedDate,
                                              startTime: tempStartTime,
                                              endTime: null,
                                              isAllDay: false,
                                              initialRRule: task.rrule,
                                              onDateChanged: (d) {
                                                tempSelectedDate = d;
                                              },
                                              onTimeChanged: (s, e) {
                                                tempStartTime = s;
                                              },
                                              onAllDayChanged: (_) {},
                                              onClear: () async {
                                                await context
                                                    .read<TaskProvider>()
                                                    .updateStartTime(
                                                      task,
                                                      null,
                                                    );
                                              },
                                              onRepeatChanged: (rrule) async {
                                                await context
                                                    .read<TaskProvider>()
                                                    .updateRRule(task, rrule);
                                              },
                                            );
                                          },
                                        );

                                        if (tempSelectedDate != null &&
                                            tempStartTime != null) {
                                          final selected = DateTime(
                                            tempSelectedDate!.year,
                                            tempSelectedDate!.month,
                                            tempSelectedDate!.day,
                                            tempStartTime!.hour,
                                            tempStartTime!.minute,
                                          );
                                          await context
                                              .read<TaskProvider>()
                                              .updateStartTime(task, selected);
                                        }
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
                              for (final entry in ([
                                ...task.checkpoints.where((e) => !e.isDone),
                                ...task.checkpoints.where((e) => e.isDone),
                              ]).asMap().entries)
                                CheckpointItemWidget(
                                  key: ValueKey(
                                    'cp_${widget.taskId}_${entry.key}_${entry.value.isDone}',
                                  ),
                                  task: task,
                                  index: entry.key,
                                  checkpoint: entry.value,
                                  onToggle: (bool v) async {
                                    await _taskProvider.toggleCheckpoint(
                                      task,
                                      entry.key,
                                      v,
                                    );
                                  },
                                  onRename: (String name) async {
                                    await _taskProvider.renameCheckpoint(
                                      task,
                                      entry.key,
                                      name,
                                    );
                                  },
                                  onRemove: () async {
                                    await _taskProvider.removeCheckpoint(
                                      task,
                                      entry.key,
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
                          onPressed: () async {
                            await _taskProvider.createSubTask(task);
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
