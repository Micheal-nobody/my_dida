import 'package:flutter/material.dart';
import 'package:my_dida/constants/app_constants.dart';
import 'package:my_dida/constants/colors_constants.dart';
import 'package:my_dida/constants/dimension_constants.dart';
import 'package:my_dida/constants/ui_constants.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/checklist_vo.dart';
import 'package:my_dida/provider/checklist_provider.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:my_dida/config/locator.dart';
import 'package:provider/provider.dart';

import '../dialogs/add_checklist_dialog.dart';

class TodoDrawer extends StatefulWidget {
  const TodoDrawer({super.key});

  @override
  State<TodoDrawer> createState() => _TodoDrawerState();
}

class _TodoDrawerState extends State<TodoDrawer> {
  final AppMessageService _messageService = getIt<AppMessageService>();

  @override
  Widget build(BuildContext context) {
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final currentChecklist = checklistProvider.currentCheckList;
    final defaultChecklist = _findDefaultChecklistt(checklistProvider);
    final userDefinedChecklists = checklistProvider.allCheckLists
        .where((checkList) => checkList.id != AppConstants.defaultCheckList.id)
        .toList();
    final checklistIds = [
      if (defaultChecklist != null) defaultChecklist.id,
      ...userDefinedChecklists.map((checklist) => checklist.id),
    ];

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: FutureBuilder<Map<int, int>>(
                future: taskProvider.getTaskCountsByChecklistIds(checklistIds),
                builder: (context, snapshot) {
                  final checklistCounts = snapshot.data ?? const <int, int>{};

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingM,
                    ),
                    children: [
                      _buildTodayChecklistTile(currentChecklist),
                      _buildStaticChecklistTile(
                        icon: Icons.inbox_rounded,
                        iconColor: Colors.deepOrange,
                        title: '收集箱',
                        count:
                            checklistCounts[AppConstants.defaultCheckList.id] ??
                            0,
                        selected:
                            currentChecklist.id ==
                            AppConstants.defaultCheckList.id,
                        onTap: () => _switchChecklist(
                          defaultChecklist ?? AppConstants.defaultCheckList,
                        ),
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
                      if (userDefinedChecklists.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: Dimensions.paddingXL,
                          ),
                          child: Text(
                            '暂无自定义清单',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      for (final checklist in userDefinedChecklists)
                        _buildCustomChecklistTile(
                          checklist: checklist,
                          count: checklistCounts[checklist.id] ?? 0,
                          selected: currentChecklist.id == checklist.id,
                          onTap: () => _switchChecklist(checklist),
                        ),
                    ],
                  );
                },
              ),
            ),
            _buildDrawerFooter(),
          ],
        ),
      ),
    );
  }

  ChecklistVO? _findDefaultChecklistt(ChecklistProvider checklistProvider) {
    for (final box in checklistProvider.allCheckLists) {
      if (box.id == AppConstants.defaultCheckList.id) {
        return box;
      }
    }
    return null;
  }

  Widget _buildDrawerHeader() => Container(
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
          child: Text(
            AppConstants.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _buildHeaderAction(icon: Icons.search_rounded, label: '搜索功能暂未开放'),
        _buildHeaderAction(
          icon: Icons.notifications_none_rounded,
          label: '通知功能暂未开放',
        ),
        _buildHeaderAction(icon: Icons.settings_outlined, label: '设置功能暂未开放'),
      ],
    ),
  );

  Widget _buildHeaderAction({required IconData icon, required String label}) =>
      IconButton(
        splashRadius: Dimensions.iconL,
        onPressed: () => _showPlaceholderSnackBar(label),
        icon: Icon(icon, color: AppColors.textPrimary),
      );

  Widget _buildStaticChecklistTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.only(top: Dimensions.paddingM),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingM,
            vertical: Dimensions.paddingM,
          ),
          decoration: BoxDecoration(
            color: selected ? Colors.orange.withValues(alpha: 0.12) : null,
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
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
  }) => Material(
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
          color: selected ? Colors.orange.withValues(alpha: 0.1) : null,
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
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

  Widget _buildDrawerFooter() => Container(
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
                Icon(Icons.add_box_outlined, color: AppColors.textPrimary),
                SizedBox(width: Dimensions.paddingM),
                Expanded(
                  child: Text(
                    '添加',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.tune_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildTodayChecklistTile(ChecklistVO currentChecklist) =>
      FutureBuilder<List<Task>>(
        future: Provider.of<TaskProvider>(context, listen: false)
            .loadTasksForDateRange(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ),
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                23,
                59,
                59,
                999,
              ),
            ),
        builder: (context, snapshot) {
          final count = snapshot.data?.length ?? 0;
          return _buildStaticChecklistTile(
            icon: Icons.calendar_today_rounded,
            iconColor: Colors.deepOrange,
            title: UIStrings.today,
            count: count,
            selected: currentChecklist.id == AppConstants.todayCheckList.id,
            onTap: () => _switchChecklist(AppConstants.todayCheckList),
          );
        },
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
