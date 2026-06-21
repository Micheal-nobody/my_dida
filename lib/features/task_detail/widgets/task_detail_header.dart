import 'package:flutter/material.dart';
import 'package:my_dida/features/dialogs/associate_main_task_dialog.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/checklist_vo.dart';
import 'package:my_dida/provider/checklist_provider.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:provider/provider.dart';

class TaskDetailHeader extends StatelessWidget {
  const TaskDetailHeader({required this.task, super.key});

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

        final bool canPop = Navigator.of(context).canPop();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  canPop ? Icons.arrow_back : Icons.close,
                  color: Colors.orange,
                ),
                onPressed: () {
                  if (canPop) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              ),

              const SizedBox(width: 6),
              const Spacer(),

              //通过Selector构建ChecklistDropdown - 居中显示
              Selector<ChecklistProvider, List<ChecklistVO>>(
                selector: (context, provider) => provider.allCheckLists,
                builder: (context, allBoxes, child) => DropdownButton<int?>(
                  value: updatedTask.checklistId,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final box in allBoxes)
                      DropdownMenuItem<int?>(
                        value: box.id,
                        child: Text(box.name),
                      ),
                  ],
                  onChanged: (v) async {
                    await taskProvider.execute(UpdateChecklist(updatedTask, v));
                  },
                ),
              ),

              const Spacer(),

              // 更多操作按钮
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.orange),
                onSelected: (value) async {
                  switch (value) {
                    case 'associate':
                      AssociateMainTaskDialog.show(context, updatedTask);
                      break;
                    case 'delete':
                      await taskProvider.execute(DeleteTask(updatedTask));
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                      break;
                    case 'copy':
                      // 递归复制任务及其所有子任务
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
        );
      },
    );
  }
}
