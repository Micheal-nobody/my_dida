import 'package:flutter/material.dart';
import 'package:my_dida/core/utils/time_formatter.dart';
import 'package:my_dida/features/checklist/models/checklist_vo.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/widgets/associate_main_task_dialog.dart';
import 'package:my_dida/features/tasks/widgets/task_date_time_picker.dart';
import 'package:provider/provider.dart';

class TaskDetailHeader extends StatelessWidget {
  const TaskDetailHeader({required this.task, this.onDelete, super.key});

  final Task task;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();

    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        // Get the updated task from the provider
        final updatedTask = provider.tasks.firstWhere(
          (t) => t.id == task.id,
          orElse: () => task,
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 第一行：返回键、checklist选择、优先级选择、更多功能
              Row(
                children: [
                  // 返回键
                  IconButton(
                    icon: Icon(
                      Navigator.of(context).canPop()
                          ? Icons.arrow_back
                          : Icons.close,
                      color: Colors.orange,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),

                  // Checklist 选择与显示
                  Consumer<ChecklistProvider>(
                    builder: (context, checklistProvider, child) {
                      final allChecklists = checklistProvider.allCheckLists;
                      final currentChecklist = allChecklists.firstWhere(
                        (box) => box.id == updatedTask.checklistId,
                        orElse: () => ChecklistVO(
                          id: updatedTask.checklistId ?? 1,
                          name: '收集箱',
                          color: Colors.grey,
                        ),
                      );

                      return PopupMenuButton<int?>(
                        initialValue: updatedTask.checklistId,
                        tooltip: '选择清单',
                        onSelected: (val) async {
                          await taskProvider.execute(
                            UpdateChecklist(updatedTask, val),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_open,
                                color: currentChecklist.color,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                currentChecklist.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          for (final box in allChecklists)
                            PopupMenuItem<int?>(
                              value: box.id,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.folder,
                                    color: box.color,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(box.name),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(width: 8),

                  // 优先级选择与显示
                  PopupMenuButton<TaskPriority>(
                    initialValue: updatedTask.priority,
                    tooltip: '选择优先级',
                    onSelected: (val) async {
                      await taskProvider.execute(
                        UpdatePriority(updatedTask, val),
                      );
                    },

                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag,
                            color: updatedTask.priority.color,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            updatedTask.priority.label,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ],
                      ),
                    ),

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
                  ),

                  const SizedBox(width: 4),

                  // 更多功能
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.orange),
                    tooltip: '更多功能',
                    onSelected: (value) async {
                      switch (value) {
                        case 'associate':
                          AssociateMainTaskDialog.show(context, updatedTask);
                          break;
                        case 'delete':
                          onDelete?.call();
                          await taskProvider.execute(DeleteTask(updatedTask));
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                          break;
                        case 'copy':
                          await taskProvider.copyTask(updatedTask);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'associate',
                        child: Row(
                          children: [
                            Icon(Icons.link, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('关联主任务'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('复制'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 第二行：任务完成框，任务时间
              Row(
                children: [
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      await taskProvider.execute(
                        UpdateTaskIsDone(updatedTask, !updatedTask.isDone),
                      );
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: updatedTask.isDone
                          ? const Icon(
                              Icons.check,
                              color: Colors.orange,
                              size: 16,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final DateTime? start = updatedTask.startTime;
                        final DateTime? end = updatedTask.endTime;

                        final String dateText =
                            TimeFormatter.formatTaskDateTimeRange(start, end);

                        return GestureDetector(
                          onTap: () async {
                            await TaskDateTimePicker.showForTask(
                              context: context,
                              task: updatedTask,
                            );
                          },
                          child: Text(
                            dateText.isEmpty ? '设置日期与时间' : dateText,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
