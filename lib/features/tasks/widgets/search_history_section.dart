import 'package:flutter/material.dart';
import 'package:my_dida/core/constants/colors_constants.dart';

class SearchHistorySection extends StatelessWidget {
  const SearchHistorySection({
    required this.history,
    required this.onHistoryItemTapped,
    required this.onHistoryItemRemoved,
    required this.onClearHistoryTapped,
    super.key,
  });
  final List<String> history;
  final Function(String item) onHistoryItemTapped;
  final Function(String item) onHistoryItemRemoved;
  final VoidCallback onClearHistoryTapped;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Text(
          '输入关键字搜索任务',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '历史搜索',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...history.map(
          (item) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history, color: AppColors.textDisabled),
            title: Text(
              item,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.close,
                color: AppColors.textDisabled,
                size: 18,
              ),
              onPressed: () => onHistoryItemRemoved(item),
            ),
            onTap: () => onHistoryItemTapped(item),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: onClearHistoryTapped,
            child: const Text(
              '清除历史搜索记录',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
