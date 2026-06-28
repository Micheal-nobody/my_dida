import 'package:flutter/material.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/core/utils/time_formatter.dart';
import 'package:my_dida/features/tasks/models/task.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.checklistName,
    this.checklistColor,
    this.onToggleDone,
    this.onTap,
    super.key,
  });

  final Task task;
  final String checklistName;
  final Color? checklistColor;
  final void Function(bool?)? onToggleDone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final colorTheme = context.theme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (checklistColor != null)
              Container(
                width: 4,
                color: checklistColor,
              ),
            Expanded(
              child: ListTile(
                // 任务完成状态，复选框边框颜色与优先级一致
                leading: SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: task.isDone,
                    onChanged: onToggleDone,
                    activeColor: colorTheme.selectedColor,
                    side: BorderSide(color: task.priority.color, width: 2),
                  ),
                ),

                // 任务名称
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    if (task.tags.isNotEmpty)
                      ...task.tags.map(
                        (tag) => Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorTheme.cardTagBackground,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(fontSize: 10, color: colorTheme.cardTagLabel),
                          ),
                        ),
                      ),
                  ],
                ),

                // 任务时间、所属收藏夹
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        TimeFormatter.formatTaskDate(task.startTime, now: now),
                        style:  TextStyle(color: colorTheme.primary, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        checklistName,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
