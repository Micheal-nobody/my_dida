import 'package:flutter/material.dart';
import 'package:my_dida/core/themes/color_themes.dart';
import 'package:my_dida/core/themes/theme_provider.dart';

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
    final colorTheme = context.theme;

    if (history.isEmpty) {
      return Center(
        child: Text(
          '输入关键字搜索任务',
          style: TextStyle(color: colorTheme.textSecondary, fontSize: 14),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '历史搜索',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...history.map(
          (item) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.history, color: colorTheme.textDisabled),
            title: Text(
              item,
              style: TextStyle(color: colorTheme.textPrimary, fontSize: 15),
            ),
            trailing: IconButton(
              icon: Icon(Icons.close, color: colorTheme.textDisabled, size: 18),
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
