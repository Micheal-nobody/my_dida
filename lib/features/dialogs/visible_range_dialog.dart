import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_dida/provider/task_provider.dart';

class VisibleRangeDialog extends StatelessWidget {
  const VisibleRangeDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const VisibleRangeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final currentRange = taskProvider.visibleRange;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '可见范围',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.select_all, color: Colors.orange),
            title: const Text('全部显示'),
            trailing: currentRange == TaskVisibleRange.all
                ? const Icon(Icons.check, color: Colors.orange)
                : null,
            onTap: () {
              taskProvider.setVisibleRange(TaskVisibleRange.all);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.check_box_outline_blank,
              color: Colors.orange,
            ),
            title: const Text('未完成'),
            trailing: currentRange == TaskVisibleRange.undone
                ? const Icon(Icons.check, color: Colors.orange)
                : null,
            onTap: () {
              taskProvider.setVisibleRange(TaskVisibleRange.undone);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_box, color: Colors.orange),
            title: const Text('已完成'),
            trailing: currentRange == TaskVisibleRange.done
                ? const Icon(Icons.check, color: Colors.orange)
                : null,
            onTap: () {
              taskProvider.setVisibleRange(TaskVisibleRange.done);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
