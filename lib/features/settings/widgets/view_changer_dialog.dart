import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';

class ViewChangerDialog extends StatelessWidget {
  const ViewChangerDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const ViewChangerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final currentMode = taskProvider.viewMode;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '切换视图',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.list, color: Colors.orange),
            title: const Text('列表视图'),
            trailing: currentMode == TaskViewMode.list
                ? const Icon(Icons.check, color: Colors.orange)
                : null,
            onTap: () {
              taskProvider.setViewMode(TaskViewMode.list);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.orange),
            title: const Text('看板视图'),
            trailing: currentMode == TaskViewMode.board
                ? const Icon(Icons.check, color: Colors.orange)
                : null,
            onTap: () {
              taskProvider.setViewMode(TaskViewMode.board);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
