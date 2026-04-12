import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../constants/colors_constants.dart';
import '../constants/dimension_constants.dart';
import '../constants/ui_constants.dart';
import '../model/entity/Task.dart';
import '../model/vo/checklist_vo.dart';
import '../provider/checklist_provider.dart';
import '../provider/task_provider.dart';
import 'dialogs/add_checklist_dialog.dart';

class TodoDrawer extends StatefulWidget {
  const TodoDrawer({super.key});

  @override
  State<TodoDrawer> createState() => _TodoDrawerState();
}

class _TodoDrawerState extends State<TodoDrawer> {
  @override
  Widget build(BuildContext context) {
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final currentBelongingBox = checklistProvider.currentCheckList;
    final defaultBelongingBox = _findDefaultBelongingBox(checklistProvider);
    final userDefinedBoxes = checklistProvider.allCheckLists
        .where((checkList) => checkList.id != AppConstants.defaultCheckList.id)
        .toList();

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingM,
                ),
                children: [
                  _buildTodayChecklistTile(currentBelongingBox),
                  _buildStaticChecklistTile(
                    icon: Icons.inbox_rounded,
                    iconColor: Colors.deepOrange,
                    title: '收集箱',
                    count: defaultBelongingBox?.taskIds.length ?? 0,
                    selected:
                        currentBelongingBox.id ==
                        AppConstants.defaultCheckList.id,
                    onTap: () => _switchChecklist(
                      defaultBelongingBox ?? AppConstants.defaultCheckList,
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
                  if (userDefinedBoxes.isEmpty)
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
                  for (final belongingBox in userDefinedBoxes)
                    _buildCustomChecklistTile(
                      belongingBox: belongingBox,
                      selected: currentBelongingBox.id == belongingBox.id,
                      onTap: () => _switchChecklist(belongingBox),
                    ),
                ],
              ),
            ),
            _buildDrawerFooter(),
          ],
        ),
      ),
    );
  }

  ChecklistVO? _findDefaultBelongingBox(ChecklistProvider checklistProvider) {
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
        _buildHeaderAction(icon: Icons.notifications_none_rounded, label: '通知功能暂未开放',),
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
    required ChecklistVO belongingBox,
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
              child: Icon(Icons.folder_rounded, color: belongingBox.color),
            ),
            const SizedBox(width: Dimensions.paddingS),
            Expanded(
              child: Text(
                belongingBox.name,
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
              '${belongingBox.taskIds.length}',
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
              onSelected: (value) =>
                  _handleBelongingBoxAction(value, belongingBox),
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
          onTap: _openAddBelongingBoxDialog,
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

  Widget _buildTodayChecklistTile(ChecklistVO currentBelongingBox) =>
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
            selected: currentBelongingBox.id == AppConstants.todayCheckList.id,
            onTap: () => _switchChecklist(AppConstants.todayCheckList),
          );
        },
      );

  void _switchChecklist(ChecklistVO belongingBox) {
    Provider.of<ChecklistProvider>(
      context,
      listen: false,
    ).updateCurBelongingBox(belongingBox);
    Navigator.of(context).pop();
  }

  void _openAddBelongingBoxDialog() {
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleBelongingBoxAction(String action, ChecklistVO belongingBox) {
    switch (action) {
      case 'edit':
        _showEditBelongingBoxDialog(belongingBox);
        break;
      case 'delete':
        _showDeleteBelongingBoxDialog(belongingBox);
        break;
    }
  }

  void _showEditBelongingBoxDialog(ChecklistVO belongingBox) {
    showDialog(
      context: context,
      builder: (context) => AddChecklistDialog(belongingBox: belongingBox),
    );
  }

  void _showDeleteBelongingBoxDialog(ChecklistVO belongingBox) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(UIStrings.deleteBelongingBoxTitle),
        content: Text(
          'Are you sure you want to delete "${belongingBox.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(UIStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final provider = Provider.of<ChecklistProvider>(
                  context,
                  listen: false,
                );
                await provider.deleteBelongingBox(belongingBox);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${belongingBox.name}"')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${UIStrings.errorDeleting}: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(UIStrings.delete),
          ),
        ],
      ),
    );
  }
}
