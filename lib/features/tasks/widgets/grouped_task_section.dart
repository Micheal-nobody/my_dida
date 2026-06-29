import 'package:flutter/material.dart';
import 'package:my_dida/core/constants/dimension_constants.dart';
import 'package:my_dida/core/constants/ui_constants.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/features/checklist/models/checklist_vo.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/pages/task_detail_page.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/widgets/task/task_card.dart';
import 'package:provider/provider.dart';

class GroupedTaskSection extends StatelessWidget {
  final String groupTitle;
  final List<Task> tasks;
  final List<ChecklistVO> allChecklists;
  final ChecklistVO currentChecklist;

  const GroupedTaskSection({
    required this.groupTitle,
    required this.tasks,
    required this.allChecklists,
    required this.currentChecklist,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final colorTheme = context.theme;
    final messageService = getIt<AppMessageService>();
    final isTrashList = currentChecklist.isTrash;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            Text(
              groupTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${tasks.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
        children: tasks.map((task) => Dismissible(
            key: Key('list_${task.id}'),
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(
                left: Dimensions.paddingL,
              ),
              color: isTrashList ? colorTheme.iconColor : colorTheme.success,
              child: Icon(
                isTrashList ? Icons.settings_backup_restore : Icons.check,
                color: colorTheme.iconOnPrimary,
                size: 28,
              ),
            ),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              color: colorTheme.error,
              padding: const EdgeInsets.only(
                right: Dimensions.paddingL,
              ),
              child: Icon(
                Icons.delete,
                color: colorTheme.iconOnPrimary,
                size: 28,
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                if (isTrashList) {
                  await taskProvider.execute(RestoreTask(task));
                  messageService.showSuccess('任务已还原');
                  return false;
                }
                await taskProvider.execute(
                  UpdateTaskIsDone(task, true),
                );
                return false;
              } else if (direction == DismissDirection.endToStart) {
                return showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      isTrashList ? '永久删除任务' : UIStrings.deleteTaskTitle,
                    ),
                    content: Text(
                      isTrashList
                          ? '确认要永久删除此任务吗？该操作无法恢复。'
                          : UIStrings.deleteTaskMessage,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(UIStrings.cancel),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorTheme.error,
                        ),
                        child: const Text(UIStrings.delete),
                      ),
                    ],
                  ),
                );
              }
              return false;
            },
            onDismissed: (direction) async {
              if (direction == DismissDirection.endToStart) {
                try {
                  await taskProvider.execute(DeleteTask(task));
                  messageService.showSuccess(
                    isTrashList ? '任务已永久删除' : UIStrings.taskDeleted,
                  );
                } catch (e) {
                  messageService.showError(
                    '${UIStrings.errorDeleting}: $e',
                  );
                }
              }
            },
            child: TaskCard(
              task: task,
              checklistName: task.getChecklistName(allChecklists),
              checklistColor: task.getChecklist(allChecklists).color,
              onToggleDone: (value) {
                if (isTrashList) {
                  taskProvider.execute(RestoreTask(task));
                  messageService.showSuccess('任务已还原');
                } else {
                  taskProvider.execute(
                    UpdateTaskIsDone(task, value!),
                  );
                }
              },
              onTap: () {
                if (isTrashList) {
                  messageService.showInfo('垃圾桶中的任务无法直接查看详情');
                } else {
                  TaskDetailPage.show(context, task);
                }
              },
            ),
          )).toList(),
      ),
    );
  }
}
