import 'package:flutter/material.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/widgets/add_task_bottom_sheet.dart';
import 'package:my_dida/features/tasks/widgets/tag_picker_dialog.dart';
import 'package:provider/provider.dart';

class TaskDetailBottomBar extends StatelessWidget {
  const TaskDetailBottomBar({required this.task, super.key});

  final Task task;

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
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Row(
            children: [
              // tag 创建与选择
              IconButton(
                onPressed: () async {
                  final allTags = await taskProvider.getGlobalTags();
                  if (context.mounted) {
                    final newTags = await TagPickerDialog.show(
                      context,
                      initialTags: updatedTask.tags,
                      allTags: allTags,
                    );
                    if (newTags != null) {
                      await taskProvider.execute(
                        UpdateTags(updatedTask, newTags),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.label_outline, color: Colors.orange),
                tooltip: '添加/管理标签',
              ),
              const SizedBox(width: 8),

              // 新建检查点
              IconButton(
                onPressed: () async {
                  await taskProvider.execute(AddCheckpoint(updatedTask));
                },
                icon: const Icon(Icons.checklist, color: Colors.orange),
                tooltip: '新建检查点',
              ),
              const SizedBox(width: 8),

              // 新建子任务
              IconButton(
                onPressed: () {
                  AddTaskBottomSheet.show(
                    context: context,
                    parentTask: updatedTask,
                  );
                },
                icon: const Icon(
                  Icons.subdirectory_arrow_right,
                  color: Colors.orange,
                ),
                tooltip: '新建子任务',
              ),
            ],
          ),
        );
      },
    );
  }
}
