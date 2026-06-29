import 'package:flutter/material.dart';
import 'package:my_dida/core/themes/theme_provider.dart';

class TagSelectorBottomSheet extends StatefulWidget {
  const TagSelectorBottomSheet({
    required this.initialTags,
    required this.allHistoryTags,
    super.key,
  });

  final List<String> initialTags;
  final List<String> allHistoryTags;

  @override
  State<TagSelectorBottomSheet> createState() => _TagSelectorBottomSheetState();
}

class _TagSelectorBottomSheetState extends State<TagSelectorBottomSheet> {
  late List<String> _selectedTags;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !_selectedTags.contains(trimmed)) {
      setState(() {
        _selectedTags.add(trimmed);
      });
    }
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final recommendedTags = widget.allHistoryTags
        .where((tag) => !_selectedTags.contains(tag))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomInset + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('取消', style: TextStyle(color: context.theme.unselectedLabelColor)),
              ),
              Text(
                '管理标签',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.theme.textPrimary),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _selectedTags),
                child: Text('保存', style: TextStyle(color: context.theme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedTags.isNotEmpty) ...[
            Text(
              '当前已选标签',
              style: TextStyle(
                fontSize: 12,
                color: context.theme.unselectedLabelColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _selectedTags
                  .map(
                    (tag) => InputChip(
                      label: Text(tag),
                      onDeleted: () {
                        setState(() {
                          _selectedTags.remove(tag);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              hintText: '输入新标签并回车确认',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: _addTag,
          ),
          const SizedBox(height: 16),
          if (recommendedTags.isNotEmpty) ...[
            Text(
              '推荐常用标签',
              style: TextStyle(
                fontSize: 12,
                color: context.theme.unselectedLabelColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: recommendedTags
                      .map(
                        (tag) => ActionChip(
                          label: Text(tag),
                          onPressed: () => _addTag(tag),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
