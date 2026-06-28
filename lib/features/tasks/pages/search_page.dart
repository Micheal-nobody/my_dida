import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/core/constants/colors_constants.dart';
import 'package:my_dida/core/constants/dimension_constants.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/core/utils/time_formatter.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:my_dida/features/tasks/models/check_point.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/services/search_history_manager.dart';
import 'package:my_dida/features/tasks/widgets/search_filter_chips.dart';
import 'package:my_dida/features/tasks/widgets/search_highlighted_text.dart';
import 'package:my_dida/features/tasks/widgets/search_history_section.dart';
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


  String _getDateString(DateTime? dateTime) {
    if (dateTime == null) return '';
    return TimeFormatter.formatRelativeDate(dateTime);
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
                  onSubmitted: _addSearchHistory,
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
          SearchFilterChips(
            statusFilter: _statusFilter,
            onStatusFilterChanged: (status) {
              setState(() => _statusFilter = status);
              _applyFilter();
            },
            searchInText: _searchInText,
            onSearchInTextChanged: (selected) {
              setState(() => _searchInText = selected);
              _applyFilter();
            },
            searchInSubtasks: _searchInSubtasks,
            onSearchInSubtasksChanged: (selected) {
              setState(() => _searchInSubtasks = selected);
              _applyFilter();
            },
            searchInNotes: _searchInNotes,
            onSearchInNotesChanged: (selected) {
              setState(() => _searchInNotes = selected);
              _applyFilter();
            },
          ),
          const Divider(height: 1, color: AppColors.border),

          // 主体展示区
          Expanded(
            child: showHistory
                ? SearchHistorySection(
                    history: _history,
                    onHistoryItemTapped: (item) {
                      _searchController.text = item;
                      _performSearch(item);
                      setState(() {});
                    },
                    onHistoryItemRemoved: _removeSearchHistory,
                    onClearHistoryTapped: _clearSearchHistory,
                  )
                : _buildSearchResultsSection(),
          ),
        ],
      ),
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
        final priorityColor = task.priority.color;
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
                await context.push('/tasks/${task.id}');
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
                              await taskProvider.execute(
                                UpdateTaskIsDone(task, value),
                              );
                              await _performSearch(query);
                            }
                          },
                          activeColor: Colors.blue,
                          side: BorderSide(color: priorityColor, width: 2),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingS),
                      // 任务标题与高亮
                      Expanded(
                        child: SearchHighlightedText(
                          text: task.name,
                          highlight: query,
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
                            child: SearchHighlightedText(
                              text: notesSnippet,
                              highlight: query,
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
                              child: SearchHighlightedText(
                                text: cp.name,
                                highlight: query,
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
                          task.getChecklistName(allChecklists),
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
