import 'package:flutter/material.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';

class SearchFilterChips extends StatelessWidget {
  final TaskVisibleRange statusFilter;
  final Function(TaskVisibleRange status) onStatusFilterChanged;
  final bool searchInText;
  final Function(bool selected) onSearchInTextChanged;
  final bool searchInSubtasks;
  final Function(bool selected) onSearchInSubtasksChanged;
  final bool searchInNotes;
  final Function(bool selected) onSearchInNotesChanged;

  const SearchFilterChips({
    super.key,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.searchInText,
    required this.onSearchInTextChanged,
    required this.searchInSubtasks,
    required this.onSearchInSubtasksChanged,
    required this.searchInNotes,
    required this.onSearchInNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 状态筛选
          ChoiceChip(
            label: const Text('全部'),
            selected: statusFilter == TaskVisibleRange.all,
            onSelected: (selected) {
              if (selected) {
                onStatusFilterChanged(TaskVisibleRange.all);
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('未完成'),
            selected: statusFilter == TaskVisibleRange.undone,
            onSelected: (selected) {
              if (selected) {
                onStatusFilterChanged(TaskVisibleRange.undone);
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('已完成'),
            selected: statusFilter == TaskVisibleRange.done,
            onSelected: (selected) {
              if (selected) {
                onStatusFilterChanged(TaskVisibleRange.done);
              }
            },
          ),
          const SizedBox(width: 16),
          // 分割垂直线
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 1,
            color: Colors.grey.shade300,
          ),
          const SizedBox(width: 16),
          // 类型检索筛选
          FilterChip(
            label: const Text('文本'),
            selected: searchInText,
            onSelected: onSearchInTextChanged,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('子任务'),
            selected: searchInSubtasks,
            onSelected: onSearchInSubtasksChanged,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('备注'),
            selected: searchInNotes,
            onSelected: onSearchInNotesChanged,
          ),
        ],
      ),
    );
  }
}
