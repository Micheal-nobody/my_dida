import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:provider/provider.dart';

class SubTaskSection extends StatelessWidget {
  const SubTaskSection({
    required this.task,
    required this.onOpenSubTask,
    super.key,
  });

  final Task task;
  final void Function(int subTaskId) onOpenSubTask;

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();

    return Padding(
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
                future: taskProvider.getTasksByIds(task.subTaskIds),
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
                            onChanged: (v) async {
                              if (v == null) return;
                              await taskProvider.updateTaskIsDone(st, v);
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
                            onPressed: () async {
                              await taskProvider.deleteSubTask(task, st.id);
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
}
