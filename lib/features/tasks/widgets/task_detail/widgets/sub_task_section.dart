import 'package:flutter/material.dart';
import 'package:my_dida/features/tasks/models/task.dart';

class SubTaskSection extends StatelessWidget {
  const SubTaskSection({
    required this.task,
    required this.onOpenSubTask,
    this.getSubTasks,
    this.onToggleSubTask,
    this.onDeleteSubTask,
    super.key,
  });

  final Task task;
  final void Function(int subTaskId) onOpenSubTask;
  final Future<List<Task>> Function(List<int> ids)? getSubTasks;
  final void Function(Task subTask, bool isDone)? onToggleSubTask;
  final void Function(Task subTask)? onDeleteSubTask;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            FutureBuilder<List<Task>>(
              future: getSubTasks?.call(task.subTaskIds) ?? Future.value([]),
              builder: (context, snapshot) {
                final List<Task> subs = snapshot.data ?? [];
                if (subs.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    for (final st in subs)
                      ListTile(
                        leading: Checkbox(
                          value: st.isDone,
                          onChanged: (v) {
                            if (v == null) return;
                            onToggleSubTask?.call(st, v);
                          },
                        ),
                        title: GestureDetector(
                          onTap: () {
                            onOpenSubTask(st.id);
                          },
                          child: Text(st.name),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            onDeleteSubTask?.call(st);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
