import 'package:flutter/material.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/shared/widgets/base_bottom_sheet_layout.dart';
import 'package:provider/provider.dart';

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

    return BaseBottomSheetLayout(
      title: '可见范围',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
