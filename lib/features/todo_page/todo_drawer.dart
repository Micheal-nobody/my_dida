import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/constants/app_constants.dart';
import 'package:my_dida/constants/colors_constants.dart';
import 'package:my_dida/constants/dimension_constants.dart';
import 'package:my_dida/constants/ui_constants.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/model/vo/checklist_vo.dart';
import 'package:my_dida/provider/checklist_provider.dart';
import 'package:my_dida/provider/sidebar_config_provider.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:provider/provider.dart';

import '../dialogs/add_checklist_dialog.dart';

class TodoDrawer extends StatefulWidget {
  const TodoDrawer({super.key});

  @override
  State<TodoDrawer> createState() => _TodoDrawerState();
}

class _TodoDrawerState extends State<TodoDrawer> {
  final AppMessageService _messageService = getIt<AppMessageService>();
  bool _isListsExpanded = true;
  bool _isTagsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<SidebarConfigProvider>(context);
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final config = configProvider.config;
    final currentChecklist = checklistProvider.currentCheckList;

    final userDefinedChecklists = checklistProvider.allCheckLists
        .where((checkList) => checkList.id != AppConstants.defaultCheckList.id)
        .toList();

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // 1. 用户信息区 (Profile Section)
            if (config.showProfile) _buildDrawerHeader(context),

            // 2. 搜索区 (Search Section)
            if (config.showSearch) _buildSearchSection(),

            // 3. 侧边栏主体内容
            Expanded(
              child: FutureBuilder<Map<int, int>>(
                future: taskProvider.getSmartListCounts(),
                builder: (context, snapshot) {
                  final counts = snapshot.data ?? const <int, int>{};

                  final customListIds = userDefinedChecklists.map((c) => c.id).toList();
                  return FutureBuilder<Map<int, int>>(
                    future: taskProvider.getTaskCountsByChecklistIds(customListIds),
                    builder: (context, customSnapshot) {
                      final customCounts = customSnapshot.data ?? const <int, int>{};

                      return ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingM,
                        ),
                        children: [
                          // 智能清单模块
                          if (config.showSmartLists) ...[
                            _buildSmartListsGroup(context, config, currentChecklist, counts),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: Dimensions.paddingM,
                              ),
                              child: Divider(
                                height: 1,
                                thickness: Dimensions.borderThin,
                                color: AppColors.border,
                              ),
                            ),
                          ],

                          // 自定义清单模块
                          if (config.showCustomLists) ...[
                            _buildCustomListsGroup(
                              context,
                              userDefinedChecklists,
                              customCounts,
                              currentChecklist,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: Dimensions.paddingM,
                              ),
                              child: Divider(
                                height: 1,
                                thickness: Dimensions.borderThin,
                                color: AppColors.border,
                              ),
                            ),
                          ],

                          // 标签模块
                          if (config.showTags) ...[
                            _buildTagsGroup(),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: Dimensions.paddingM,
                              ),
                              child: Divider(
                                height: 1,
                                thickness: Dimensions.borderThin,
                                color: AppColors.border,
                              ),
                            ),
                          ],

                          // 过滤器模块
                          if (config.showFilters) ...[
                            _buildFiltersGroup(),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: Dimensions.paddingM,
                              ),
                              child: Divider(
                                height: 1,
                                thickness: Dimensions.borderThin,
                                color: AppColors.border,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // 4. 底部固定工具栏 (Bottom Toolbar Section)
            _buildDrawerFooter(context),
          ],
        ),
      ),
    );
  }

  // Header redesign: Profile Only (No notifications or sync buttons)
  Widget _buildDrawerHeader(BuildContext context) => InkWell(
        onTap: () {
          Navigator.of(context).pop();
          context.push('/settings');
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingM,
            Dimensions.paddingL,
            Dimensions.paddingM,
            Dimensions.paddingM,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border,
                width: Dimensions.borderThin,
              ),
            ),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: Dimensions.avatarM,
                    height: Dimensions.avatarM,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                    ),
                    child: const Icon(
                      Icons.account_circle_rounded,
                      size: Dimensions.iconXL,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.star,
                        size: 12,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: Dimensions.paddingM),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Michel-nobody',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '2201389816@qq.com',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      );

  // Search Section below header
  Widget _buildSearchSection() => Padding(
        padding: const EdgeInsets.all(Dimensions.paddingM),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingS),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              context.push('/search');
            },
            child: const Row(
              children: [
                Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                SizedBox(width: Dimensions.paddingS),
                Text(
                  '搜索',
                  style: TextStyle(color: AppColors.textDisabled, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      );

  bool _shouldShowSmartList(int id, int option, int count) {
    if (option == 0) return false; // Hide
    if (option == 1) return true;  // Show
    if (option == 2) return count > 0; // Auto
    return false;
  }

  // Built-in Smart Lists visibility groups
  Widget _buildSmartListsGroup(
    BuildContext context,
    dynamic config,
    ChecklistVO currentChecklist,
    Map<int, int> counts,
  ) {
    final List<Widget> listTiles = [];

    // 今天 (id = -1)
    final todayCount = counts[-1] ?? 0;
    if (_shouldShowSmartList(-1, config.todayShowOption, todayCount)) {
      listTiles.add(_buildStaticChecklistTile(
        icon: Icons.calendar_today_rounded,
        iconColor: Colors.blue,
        title: '今天',
        count: todayCount,
        selected: currentChecklist.id == AppConstants.todayCheckList.id,
        onTap: () => _switchChecklist(AppConstants.todayCheckList),
      ));
    }

    // 明天 (id = -2)
    final tomorrowCount = counts[-2] ?? 0;
    if (_shouldShowSmartList(-2, config.tomorrowShowOption, tomorrowCount)) {
      listTiles.add(_buildStaticChecklistTile(
        icon: Icons.wb_sunny_outlined,
        iconColor: Colors.orange,
        title: '明天',
        count: tomorrowCount,
        selected: currentChecklist.id == AppConstants.tomorrowCheckList.id,
        onTap: () => _switchChecklist(AppConstants.tomorrowCheckList),
      ));
    }

    // 最近七天 (id = -3)
    final nextSevenDaysCount = counts[-3] ?? 0;
    if (_shouldShowSmartList(-3, config.nextSevenDaysShowOption, nextSevenDaysCount)) {
      listTiles.add(_buildStaticChecklistTile(
        icon: Icons.calendar_month_outlined,
        iconColor: Colors.purple,
        title: '最近七天',
        count: nextSevenDaysCount,
        selected: currentChecklist.id == AppConstants.nextSevenDaysCheckList.id,
        onTap: () => _switchChecklist(AppConstants.nextSevenDaysCheckList),
      ));
    }

    // 收集箱 (id = 1)
    final inboxCount = counts[1] ?? 0;
    if (_shouldShowSmartList(1, config.inboxShowOption, inboxCount)) {
      listTiles.add(_buildStaticChecklistTile(
        icon: Icons.inbox_rounded,
        iconColor: Colors.deepOrange,
        title: '收集箱',
        count: inboxCount,
        selected: currentChecklist.id == AppConstants.defaultCheckList.id,
        onTap: () => _switchChecklist(AppConstants.defaultCheckList),
      ));
    }

    // 所有 (id = -4)
    final allCount = counts[-4] ?? 0;
    if (_shouldShowSmartList(-4, config.allShowOption, allCount)) {
      listTiles.add(_buildStaticChecklistTile(
        icon: Icons.all_inbox_rounded,
        iconColor: Colors.teal,
        title: '所有',
        count: allCount,
        selected: currentChecklist.id == AppConstants.allCheckList.id,
        onTap: () => _switchChecklist(AppConstants.allCheckList),
      ));
    }

    // 已完成 (id = -5)
    final completedCount = counts[-5] ?? 0;
    if (_shouldShowSmartList(-5, config.completedShowOption, completedCount)) {
      listTiles.add(_buildStaticChecklistTile(
        icon: Icons.check_circle_outline_rounded,
        iconColor: Colors.green,
        title: '已完成',
        count: completedCount,
        selected: currentChecklist.id == AppConstants.completedCheckList.id,
        onTap: () => _switchChecklist(AppConstants.completedCheckList),
      ));
    }

    // 垃圾桶 (id = -6)
    final trashCount = counts[-6] ?? 0;
    if (_shouldShowSmartList(-6, config.trashShowOption, trashCount)) {
      listTiles.add(_buildStaticChecklistTile(
        icon: Icons.delete_outline_rounded,
        iconColor: Colors.red,
        title: '垃圾桶',
        count: trashCount,
        selected: currentChecklist.id == AppConstants.trashCheckList.id,
        onTap: () => _switchChecklist(AppConstants.trashCheckList),
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: listTiles,
    );
  }

  // Custom User Lists
  Widget _buildCustomListsGroup(
    BuildContext context,
    List<ChecklistVO> checklists,
    Map<int, int> counts,
    ChecklistVO currentChecklist,
  ) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isListsExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isListsExpanded = !_isListsExpanded;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  '清单',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.textSecondary, size: 20),
                onPressed: _openAddChecklistDialog,
              ),
            ],
          ),
          if (_isListsExpanded) ...[
            if (checklists.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: Dimensions.paddingM,
                ),
                child: Text(
                  '暂无自定义清单',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
            for (final checklist in checklists)
              _buildCustomChecklistTile(
                checklist: checklist,
                count: counts[checklist.id] ?? 0,
                selected: currentChecklist.id == checklist.id,
                onTap: () => _switchChecklist(checklist),
              ),
          ],
        ],
      );

  // Tags placeholder
  Widget _buildTagsGroup() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isTagsExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isTagsExpanded = !_isTagsExpanded;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  '标签',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.textSecondary, size: 20),
                onPressed: () => _showPlaceholderSnackBar('新建标签功能开发中'),
              ),
            ],
          ),
          if (_isTagsExpanded)
            const Padding(
              padding: EdgeInsets.only(left: 45.0, top: 4.0, bottom: 8.0),
              child: Text(
                '暂无标签',
                style: TextStyle(color: AppColors.textDisabled, fontSize: 14),
              ),
            ),
        ],
      );

  // Filters placeholder
  Widget _buildFiltersGroup() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {},
              ),
              const Expanded(
                child: Text(
                  '过滤器',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.textSecondary, size: 20),
                onPressed: () => _showPlaceholderSnackBar('过滤器开发中'),
              ),
            ],
          ),
        ],
      );

  // Footer redesign: Left button "新增自定义清单", Right button settings entrance
  Widget _buildDrawerFooter(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingM,
          vertical: Dimensions.paddingS,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Left button: Add custom list
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                    onTap: _openAddChecklistDialog,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingS,
                        vertical: Dimensions.paddingS,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: AppColors.textPrimary),
                          SizedBox(width: Dimensions.paddingM),
                          Text(
                            '添加清单',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Right button: Settings
              Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
                  splashRadius: Dimensions.iconL,
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/settings');
                  },
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildStaticChecklistTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      Padding(
        key: ValueKey('smart_list_$title'),
        padding: const EdgeInsets.only(top: Dimensions.paddingS),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingM,
                vertical: Dimensions.paddingS,
              ),
              decoration: BoxDecoration(
                color: selected ? iconColor.withValues(alpha: 0.12) : null,
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: Dimensions.iconS, color: iconColor),
                  ),
                  const SizedBox(width: Dimensions.paddingM),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        color: selected ? iconColor : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 14,
                      color: selected ? iconColor : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildCustomChecklistTile({
    required ChecklistVO checklist,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingS,
              vertical: Dimensions.paddingXS,
            ),
            decoration: BoxDecoration(
              color: selected ? checklist.color.withValues(alpha: 0.1) : null,
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Icon(Icons.folder_rounded, color: checklist.color),
                ),
                const SizedBox(width: Dimensions.paddingS),
                Expanded(
                  child: Text(
                    checklist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: selected ? checklist.color : AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? checklist.color : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingXS),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  splashRadius: Dimensions.iconM,
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.textDisabled,
                  ),
                  onSelected: (value) => _handleChecklistAction(value, checklist),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: Dimensions.iconS),
                          SizedBox(width: Dimensions.paddingS),
                          Text(UIStrings.edit),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: Dimensions.iconS,
                            color: AppColors.error,
                          ),
                          SizedBox(width: Dimensions.paddingS),
                          Text(
                            UIStrings.delete,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  void _switchChecklist(ChecklistVO checklist) {
    Provider.of<ChecklistProvider>(
      context,
      listen: false,
    ).updateCurChecklist(checklist);
    Navigator.of(context).pop();
  }

  void _openAddChecklistDialog() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => const AddChecklistDialog(),
      );
    });
  }

  void _showPlaceholderSnackBar(String message) {
    _messageService.showInfo(message);
  }

  void _handleChecklistAction(String action, ChecklistVO checklist) {
    switch (action) {
      case 'edit':
        _showEditChecklistDialog(checklist);
        break;
      case 'delete':
        _showDeleteChecklistDialog(checklist);
        break;
    }
  }

  void _showEditChecklistDialog(ChecklistVO checklist) {
    showDialog(
      context: context,
      builder: (context) => AddChecklistDialog(checklist: checklist),
    );
  }

  void _showDeleteChecklistDialog(ChecklistVO checklist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(UIStrings.deleteChecklistTitle),
        content: Text('Are you sure you want to delete "${checklist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(UIStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<ChecklistProvider>(
                context,
                listen: false,
              );
              await provider.deleteChecklist(checklist);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(UIStrings.delete),
          ),
        ],
      ),
    );
  }
}
