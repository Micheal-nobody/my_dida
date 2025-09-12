import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/component/EditableTitleWidget.dart';
import 'package:my_dida/component/EditableDescriptionWidget.dart';
import 'package:my_dida/component/CheckpointItemWidget.dart';
import 'package:my_dida/component/TaskDetailHeader.dart';
import 'package:my_dida/component/SubTaskSection.dart';
import 'package:provider/provider.dart';
import 'package:my_dida/provider/TaskProvider.dart';
import 'dart:async';

// 任务详情 BottomSheet（由 TaskCard 的 onTap 触发）
class TaskDetailPage extends StatefulWidget {
  final int taskId;
  final ScrollController? scrollController;

  const TaskDetailPage(this.taskId, {super.key, this.scrollController});

  @override
  State<StatefulWidget> createState() {
    return _TaskDetailPageState();
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

  // 其余返回 Widget 的函数已拆分为独立组件

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
    return SafeArea(
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
                        TaskDetailHeader(task: task),
                        const SizedBox(height: 6),

                        // 标题
                        EditableTitleWidget(
                          key: ValueKey('title_${task.id}'),
                          task: task,
                          onSubmit: (updated) async {
                            await _taskProvider.updateTitle(task, updated);
                          },
                          onFieldSubmitted: (value) {
                            context.read<TaskProvider>().loadCurrentBoxTasks();
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
                            context.read<TaskProvider>().loadCurrentBoxTasks();
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
                        icon: const Icon(Icons.checklist, color: Colors.orange),
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
    );
  }
}
