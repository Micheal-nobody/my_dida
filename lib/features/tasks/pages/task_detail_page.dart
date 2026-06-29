import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/features/tasks/models/check_point.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/widgets/task_detail/tag_picker_dialog.dart';
import 'package:my_dida/features/tasks/widgets/task_description_editor.dart';
import 'package:my_dida/features/tasks/widgets/task_detail/widgets/checkpoint_item_widget.dart';
import 'package:my_dida/features/tasks/widgets/task_detail/widgets/sub_task_section.dart';
import 'package:my_dida/features/tasks/widgets/task_detail/widgets/task_detail_bottom_bar.dart';
import 'package:my_dida/features/tasks/widgets/task_detail/widgets/task_detail_header.dart';
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
                color: context.theme.cardBackground,
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
    final colorTheme = context.theme;
    final task = _task;
    final sortedCheckpointEntries =
        (task?.checkpoints.asMap().entries.toList() ??
              <MapEntry<int, CheckPoint>>[])
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
            children: [
              // 上区域 (Top region) - 不支持滑动
              TaskDetailHeader(
                task: task,
                onDelete: () {
                  setState(() {
                    _isDeletingActively = true;
                  });
                  unawaited(_taskSub?.cancel());
                },
              ),

              // 中区域 (Middle region) - 支持上下滑动
              Expanded(
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // 如果当前任务已关联主任务，则显示主任务标题（以及跳转按钮）
                      if (task.parentTaskId != null)
                        FutureBuilder<Task?>(
                          future: _taskProvider.getTaskById(task.parentTaskId!),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    TextButton.icon(
                                      label: Text('${snapshot.data!.name} >'),
                                      onPressed: () {
                                        _navigateToSubTask(task.parentTaskId!);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                      // 标题 (任务名)
                      InlineEditableTextField(
                        key: ValueKey('title_${task.id}'),
                        value: task.name,
                        onSubmit: (updated) async {
                          await _taskProvider.execute(
                            UpdateTitle(task, updated),
                          );
                        },
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 描述（富文本）
                      TaskDescriptionEditor(
                        key: ValueKey('desc_${task.id}'),
                        taskId: task.id,
                        value: task.description,
                        onSubmit: (newDesc) async {
                          _descriptionDebounce?.cancel();
                          await _persistDescription(task, newDesc);
                        },
                        onChanged: (value) {
                          _scheduleDescriptionUpdate(task, value);
                        },
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

                      // tags 显示区域（可包含多个 tag）
                      if (task.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: task.tags
                                .map(
                                  (tag) => ActionChip(
                                    label: Text(
                                      tag,
                                      style: TextStyle(
                                        color: colorTheme.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    backgroundColor: colorTheme.primary
                                        .withValues(alpha: 0.1),
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    onPressed: () async {
                                      final allTags = await _taskProvider
                                          .getGlobalTags();
                                      if (context.mounted) {
                                        final newTags =
                                            await TagPickerDialog.show(
                                              context,
                                              initialTags: task.tags,
                                              allTags: allTags,
                                            );
                                        if (newTags != null) {
                                          await _taskProvider.execute(
                                            UpdateTags(task, newTags),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),

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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // 底部区域 (Bottom region) - 不支持滑动
              TaskDetailBottomBar(task: task),
            ],
          );

    return Material(child: widget.useSafeArea ? SafeArea(child: body) : body);
  }
}
