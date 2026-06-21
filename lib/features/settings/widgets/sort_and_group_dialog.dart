import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';

class SortAndGroupDialog extends StatelessWidget {
  const SortAndGroupDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const SortAndGroupDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                '排序与分组',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '分组方式',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildGroupChip(context, taskProvider, TaskGroupBy.date, '按日期'),
                _buildGroupChip(
                  context,
                  taskProvider,
                  TaskGroupBy.checklist,
                  '按清单',
                ),
                _buildGroupChip(
                  context,
                  taskProvider,
                  TaskGroupBy.priority,
                  '按优先级',
                ),
                _buildGroupChip(context, taskProvider, TaskGroupBy.tag, '按标签'),
                _buildGroupChip(context, taskProvider, TaskGroupBy.none, '无分组'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '排序方式',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildSortChip(
                  context,
                  taskProvider,
                  TaskSortBy.dueDate,
                  '按日期',
                ),
                _buildSortChip(
                  context,
                  taskProvider,
                  TaskSortBy.priority,
                  '按优先级',
                ),
                _buildSortChip(context, taskProvider, TaskSortBy.title, '按标题'),
                _buildSortChip(
                  context,
                  taskProvider,
                  TaskSortBy.createTime,
                  '按创建时间',
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupChip(
    BuildContext context,
    TaskProvider provider,
    TaskGroupBy val,
    String label,
  ) {
    final isSelected = provider.groupBy == val;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.orange.withValues(alpha: 0.2),
      checkmarkColor: Colors.orange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          provider.setGroupBy(val);
        }
      },
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    TaskProvider provider,
    TaskSortBy val,
    String label,
  ) {
    final isSelected = provider.sortBy == val;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.orange.withValues(alpha: 0.2),
      checkmarkColor: Colors.orange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          provider.setSortBy(val);
        }
      },
    );
  }
}
