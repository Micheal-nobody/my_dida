import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/constants/colors_constants.dart';
import 'package:my_dida/constants/dimension_constants.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/model/entity/check_point.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/checklist_vo.dart';
import 'package:my_dida/provider/checklist_provider.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:my_dida/utils/search_history_manager.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AppMessageService _messageService = getIt<AppMessageService>();

  Timer? _debounce;
  List<String> _history = [];
  List<Task> _searchResults = [];
  bool _isSearching = false;

  // 过滤选项
  TaskVisibleRange _statusFilter = TaskVisibleRange.all;
  bool _searchInText = false;
  bool _searchInSubtasks = false;
  bool _searchInNotes = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // 自动获取焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final list = await SearchHistoryManager.loadHistory();
    if (mounted) {
      setState(() {
        _history = list;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final results = await taskProvider.searchTasks(
      query: query,
      statusFilter: _statusFilter,
      searchInText: _searchInText,
      searchInSubtasks: _searchInSubtasks,
      searchInNotes: _searchInNotes,
    );

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _addSearchHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final updated = await SearchHistoryManager.addHistory(trimmed);
    setState(() {
      _history = updated;
    });
  }

  Future<void> _removeSearchHistory(String item) async {
    final updated = await SearchHistoryManager.removeHistory(item);
    setState(() {
      _history = updated;
    });
  }

  Future<void> _clearSearchHistory() async {
    await SearchHistoryManager.clearHistory();
    setState(() {
      _history = [];
    });
    _messageService.showSuccess('历史记录已清除');
  }

  void _applyFilter() {
    _performSearch(_searchController.text);
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.blue;
      case TaskPriority.none:
        return Colors.grey;
    }
  }

  String _getDateString(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (date.isAtSameMomentAs(today)) {
      return '今天';
    } else if (date.isAtSameMomentAs(tomorrow)) {
      return '明天';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }

  String _getChecklistName(int? id, List<ChecklistVO> allChecklists) {
    if (id == null) return '';
    final cl = allChecklists.firstWhere(
      (c) => c.id == id,
      orElse: () => allChecklists.first,
    );
    return cl.name;
  }

  Widget _buildHighlightedText(
    String text,
    String highlight, {
    TextStyle? style,
    TextStyle? highlightStyle,
  }) {
    if (highlight.isEmpty ||
        !text.toLowerCase().contains(highlight.toLowerCase())) {
      return Text(text, style: style);
    }

    final List<TextSpan> spans = [];
    final lowercaseText = text.toLowerCase();
    final lowercaseHighlight = highlight.toLowerCase();

    int start = 0;
    int indexOfHighlight;

    while ((indexOfHighlight = lowercaseText.indexOf(
          lowercaseHighlight,
          start,
        )) !=
        -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfHighlight)));
      }
      spans.add(
        TextSpan(
          text: text.substring(
            indexOfHighlight,
            indexOfHighlight + highlight.length,
          ),
          style:
              highlightStyle ??
              const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
      start = indexOfHighlight + highlight.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style:
            style ??
            const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        children: spans,
      ),
    );
  }

  String _getNotesSnippet(String notes, String query) {
    if (notes.isEmpty || query.isEmpty) return '';
    final lowerNotes = notes.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerNotes.indexOf(lowerQuery);
    if (index == -1) return '';

    int start = index - 10;
    if (start < 0) start = 0;

    int end = index + query.length + 20;
    if (end > notes.length) end = notes.length;

    String snippet = notes.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < notes.length) snippet = '$snippet...';

    return snippet.replaceAll('\n', ' ');
  }

  List<CheckPoint> _getMatchedCheckpoints(
    List<CheckPoint> checkpoints,
    String query,
  ) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return checkpoints
        .where((cp) => cp.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text;
    final showHistory = query.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingS),
          child: Row(
            children: [
              const Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: Dimensions.paddingS),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: _onSearchChanged,
                  onSubmitted: (value) => _addSearchHistory(value),
                  decoration: const InputDecoration(
                    hintText: '搜索任务、步骤、备注',
                    hintStyle: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  textInputAction: TextInputAction.search,
                ),
              ),
              if (query.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _onSearchChanged('');
                    setState(() {});
                  },
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // 过滤标签栏 (Chips)
          _buildFilterChips(),
          const Divider(height: 1, color: AppColors.border),

          // 主体展示区
          Expanded(
            child: showHistory
                ? _buildHistorySection()
                : _buildSearchResultsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingM),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 状态筛选
          ChoiceChip(
            label: const Text('全部'),
            selected: _statusFilter == TaskVisibleRange.all,
            onSelected: (selected) {
              if (selected) {
                setState(() => _statusFilter = TaskVisibleRange.all);
                _applyFilter();
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('未完成'),
            selected: _statusFilter == TaskVisibleRange.undone,
            onSelected: (selected) {
              if (selected) {
                setState(() => _statusFilter = TaskVisibleRange.undone);
                _applyFilter();
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('已完成'),
            selected: _statusFilter == TaskVisibleRange.done,
            onSelected: (selected) {
              if (selected) {
                setState(() => _statusFilter = TaskVisibleRange.done);
                _applyFilter();
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
            selected: _searchInText,
            onSelected: (selected) {
              setState(() => _searchInText = selected);
              _applyFilter();
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('子任务'),
            selected: _searchInSubtasks,
            onSelected: (selected) {
              setState(() => _searchInSubtasks = selected);
              _applyFilter();
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('备注'),
            selected: _searchInNotes,
            onSelected: (selected) {
              setState(() => _searchInNotes = selected);
              _applyFilter();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) {
      return const Center(
        child: Text(
          '输入关键字搜索任务',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(Dimensions.paddingM),
      children: [
        const Text(
          '历史搜索',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: Dimensions.paddingS),
        ..._history.map(
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
              onPressed: () => _removeSearchHistory(item),
            ),
            onTap: () {
              _searchController.text = item;
              _performSearch(item);
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: Dimensions.paddingM),
        Center(
          child: TextButton(
            onPressed: _clearSearchHistory,
            child: const Text(
              '清除历史搜索记录',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsSection() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textDisabled),
            SizedBox(height: Dimensions.paddingM),
            Text(
              '未找到相关任务',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final allChecklists = checklistProvider.allCheckLists;
    final query = _searchController.text;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingS),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final task = _searchResults[index];
        final priorityColor = _getPriorityColor(task.priority);
        final checklistName = _getChecklistName(
          task.checklistId,
          allChecklists,
        );
        final dateStr = _getDateString(task.startTime);

        // 匹配特化：备注和子任务
        final notesSnippet = _getNotesSnippet(task.description, query);
        final matchedCheckpoints = _getMatchedCheckpoints(
          task.checkpoints,
          query,
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: InkWell(
            onTap: () async {
              await _addSearchHistory(query);
              if (context.mounted) {
                context.push('/tasks/${task.id}');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 复选框
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: task.isDone,
                          onChanged: (value) async {
                            if (value != null) {
                              final taskProvider = Provider.of<TaskProvider>(
                                context,
                                listen: false,
                              );
                              await taskProvider.updateTaskIsDone(task, value);
                              _performSearch(query);
                            }
                          },
                          activeColor: Colors.blue,
                          side: BorderSide(color: priorityColor, width: 2),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingS),
                      // 任务标题与高亮
                      Expanded(
                        child: _buildHighlightedText(
                          task.name,
                          query,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: task.isDone
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 备注片段展示
                  if (notesSnippet.isNotEmpty) ...[
                    const SizedBox(height: Dimensions.paddingXS),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notes,
                            size: 14,
                            color: AppColors.textDisabled,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildHighlightedText(
                              notesSnippet,
                              query,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 子任务匹配项展示
                  if (matchedCheckpoints.isNotEmpty) ...[
                    const SizedBox(height: Dimensions.paddingXS),
                    ...matchedCheckpoints.map(
                      (cp) => Padding(
                        padding: const EdgeInsets.only(left: 32, top: 4),
                        child: Row(
                          children: [
                            Icon(
                              cp.isDone
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 14,
                              color: AppColors.textDisabled,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildHighlightedText(
                                cp.name,
                                query,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  decoration: cp.isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // 元数据（清单和截止日期）
                  const SizedBox(height: Dimensions.paddingS),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (dateStr.isNotEmpty)
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          )
                        else
                          const SizedBox(),
                        Text(
                          checklistName,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
