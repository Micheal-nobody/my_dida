import 'package:flutter/material.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/widgets/add_task_bottom_sheet.dart';
import 'package:my_dida/features/tomato/providers/tomato_provider.dart';
import 'package:provider/provider.dart';

class AssociateTaskDialog extends StatefulWidget {
  const AssociateTaskDialog({super.key});

  static Future<Task?> show(BuildContext context) => showDialog<Task?>(
    context: context,
    builder: (context) => const AssociateTaskDialog(),
  );

  @override
  State<AssociateTaskDialog> createState() => _AssociateTaskDialogState();
}

class _AssociateTaskDialogState extends State<AssociateTaskDialog> {
  Task? _selectedTask;

  @override
  void initState() {
    super.initState();
    final tomatoProvider = context.read<TomatoProvider>();
    _selectedTask = tomatoProvider.associatedTask;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tomatoProvider = context.read<TomatoProvider>();

    // 过滤出未完成的任务
    final undoneTasks = taskProvider.tasks.where((t) => !t.isDone).toList();

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('关联专注任务'),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            tooltip: '新建任务',
            onPressed: () => {
              AddTaskBottomSheet.show(context: context)
                  .then((_) {
                // 任务创建后刷新任务列表，在UI上触发重新渲染
                setState(() {});
              })
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: undoneTasks.isEmpty
            ? const Center(
                child: Text(
                  '暂无未完成任务，点击右上角 + 创建一个吧！',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: undoneTasks.length,
                itemBuilder: (context, index) {
                  final task = undoneTasks[index];
                  final isSelected = _selectedTask?.id == task.id;
                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                    title: Text(
                      task.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: task.description.isNotEmpty
                        ? Text(
                            task.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedTask = task;
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        if (tomatoProvider.associatedTask != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 返回 null 表示清除绑定
            },
            child: const Text('取消关联', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedTask), // 取消，不更改选择
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedTask);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
