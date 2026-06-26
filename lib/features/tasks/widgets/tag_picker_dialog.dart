import 'package:flutter/material.dart';

class TagPickerDialog extends StatefulWidget {
  const TagPickerDialog({
    required this.initialTags,
    required this.allTags,
    super.key,
  });

  final List<String> initialTags;
  final List<String> allTags;

  @override
  State<TagPickerDialog> createState() => _TagPickerDialogState();

  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> initialTags,
    required List<String> allTags,
  }) {
    return showDialog<List<String>>(
      context: context,
      builder: (context) =>
          TagPickerDialog(initialTags: initialTags, allTags: allTags),
    );
  }
}

class _TagPickerDialogState extends State<TagPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedTags = [];
  List<String> _allTags = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialTags);
    _allTags = List.from(widget.allTags);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _createAndSelectTag(String newTag) {
    final trimmed = newTag.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      if (!_allTags.contains(trimmed)) {
        _allTags.add(trimmed);
      }
      if (!_selectedTags.contains(trimmed)) {
        _selectedTags.add(trimmed);
      }
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter tags based on search query
    final filteredTags = _allTags.where((tag) {
      return tag.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Check if the exact search query exists in the list
    final exactMatchExists = _allTags.any(
      (tag) => tag.toLowerCase() == _searchQuery.trim().toLowerCase(),
    );
    final showCreateOption =
        _searchQuery.trim().isNotEmpty && !exactMatchExists;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '选择标签',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.orange),
                    onPressed: () => Navigator.pop(context, _selectedTags),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search Box
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索或创建标签',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty && !exactMatchExists) {
                    _createAndSelectTag(val);
                  }
                },
              ),
            ),

            // Tags list
            Expanded(
              child: ListView(
                children: [
                  if (showCreateOption)
                    ListTile(
                      leading: const Icon(Icons.add, color: Colors.orange),
                      title: Text(
                        '创建新标签 "${_searchQuery.trim()}"',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () => _createAndSelectTag(_searchQuery),
                    ),
                  ...filteredTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return ListTile(
                      leading: const Icon(
                        Icons.label_outline,
                        color: Colors.grey,
                      ),
                      title: Text(tag),
                      trailing: Checkbox(
                        value: isSelected,
                        activeColor: Colors.orange,
                        onChanged: (val) {
                          _toggleTag(tag);
                        },
                      ),
                      onTap: () => _toggleTag(tag),
                    );
                  }),
                  if (filteredTags.isEmpty && !showCreateOption)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          '暂无标签',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
