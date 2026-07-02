import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/core/constants/app_constants.dart';
import 'package:my_dida/core/constants/dimension_constants.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/services/data_transfer_service.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:my_dida/features/settings/models/sidebar_config.dart';
import 'package:my_dida/features/settings/providers/sidebar_config_provider.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tomato/providers/tomato_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<SidebarConfigProvider>(context);
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final config = configProvider.config;

    final colorTheme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: colorTheme.background,
      body: ListView(
        children: [
          // 个人中心 Section
          const SectionHeader('个人中心'),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingM,
              vertical: Dimensions.paddingXS,
            ),
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              side: BorderSide(color: colorTheme.border),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Icon(Icons.person, color: colorTheme.textSecondary),
              ),
              title: const Text(
                'Michel-nobody',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('2201389816@qq.com'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Placeholder
              },
            ),
          ),

          // 偏好设置 Section
          const SectionHeader('偏好设置'),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingM,
              vertical: Dimensions.paddingXS,
            ),
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              side: BorderSide(color: colorTheme.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('主题'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        config.theme == AppTheme.light
                            ? '浅色'
                            : config.theme == AppTheme.dark
                            ? '深色'
                            : '自动',
                        style: TextStyle(color: colorTheme.selectedColor),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showThemeDialog(context, configProvider),
                ),
                Divider(height: 1, indent: 50, color: colorTheme.border),
                ListTile(
                  leading: const Icon(Icons.menu_open),
                  title: const Text('侧边栏'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/sidebar'),
                ),
                Divider(height: 1, indent: 50, color: colorTheme.border),
                ListTile(
                  leading: const Icon(Icons.volume_up_outlined),
                  title: const Text('声音与振动'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('声音与振动设置开发中')));
                  },
                ),
                Divider(height: 1, indent: 50, color: colorTheme.border),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('语言'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        config.language == AppLanguage.zh ? '简体中文' : 'English',
                        style: TextStyle(color: colorTheme.selectedColor),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showLanguageDialog(context, configProvider),
                ),
              ],
            ),
          ),

          // 任务管理 Section
          const SectionHeader('任务管理'),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingM,
              vertical: Dimensions.paddingXS,
            ),
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              side: BorderSide(color: colorTheme.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('智能清单'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/smart-lists'),
                ),
                Divider(height: 1, indent: 50, color: colorTheme.border),
                ListTile(
                  leading: const Icon(Icons.inbox_outlined),
                  title: const Text('默认清单'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        checklistProvider.allCheckLists
                            .firstWhere(
                              (c) => c.id == config.defaultChecklistId,
                              orElse: () =>
                                  checklistProvider.allCheckLists.first,
                            )
                            .name,
                        style: TextStyle(color: colorTheme.selectedColor),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showDefaultChecklistDialog(
                    context,
                    configProvider,
                    checklistProvider,
                  ),
                ),
                Divider(height: 1, indent: 50, color: colorTheme.border),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('日期与时间'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('日期与时间设置开发中')));
                  },
                ),
              ],
            ),
          ),

          // 备份与同步 Section
          const SectionHeader('备份与同步'),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingM,
              vertical: Dimensions.paddingXS,
            ),
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              side: BorderSide(color: colorTheme.border),
            ),

            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('导入数据'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showImportDialog(context, checklistProvider),
                ),
                Divider(height: 1, indent: 50, color: colorTheme.border),
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('导出数据'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showExportDialog(context),
                ),
                Divider(height: 1, indent: 50, color: colorTheme.border),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    '删除数据',
                    style: TextStyle(color: Colors.red),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
                  onTap: () => _showDeleteDialog(context, checklistProvider),
                ),
              ],
            ),
          ),

          // 关于 Section
          const SectionHeader('关于'),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingM,
              vertical: Dimensions.paddingXS,
            ),
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              side: BorderSide(color: colorTheme.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('版本信息'),
                  subtitle: const Text('v1.1.0'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    launchUrl(
                      Uri.parse(
                        'https://github.com/Micheal-nobody/my_dida/releases',
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingL),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SidebarConfigProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        final colorTheme = context.theme;
        return AlertDialog(
          title: const Text('主题设置'),
          content: RadioGroup<AppTheme>(
            groupValue: provider.config.theme,
            onChanged: (val) {
              if (val != null) provider.updateTheme(val);
              context.pop();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<AppTheme>(
                  activeColor: colorTheme.selectedColor,
                  title: const Text('自动'),
                  value: AppTheme.system,
                ),
                RadioListTile<AppTheme>(
                  activeColor: colorTheme.selectedColor,
                  title: const Text('浅色'),
                  value: AppTheme.light,
                ),
                RadioListTile<AppTheme>(
                  activeColor: colorTheme.selectedColor,
                  title: const Text('深色'),
                  value: AppTheme.dark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    SidebarConfigProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final colorTheme = context.theme;
        return AlertDialog(
          title: const Text('语言设置'),
          content: RadioGroup<AppLanguage>(
            groupValue: provider.config.language,
            onChanged: (val) {
              if (val != null) provider.updateLanguage(val);
              context.pop();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<AppLanguage>(
                  activeColor: colorTheme.selectedColor,
                  title: const Text('简体中文'),
                  value: AppLanguage.zh,
                ),
                RadioListTile<AppLanguage>(
                  activeColor: colorTheme.selectedColor,
                  title: const Text('English'),
                  value: AppLanguage.en,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDefaultChecklistDialog(
    BuildContext context,
    SidebarConfigProvider configProvider,
    ChecklistProvider checklistProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final colorTheme = context.theme;
        return AlertDialog(
          title: const Text('选择默认清单'),
          content: SizedBox(
            width: double.maxFinite,
            child: RadioGroup<int>(
              groupValue: configProvider.config.defaultChecklistId,
              onChanged: (val) {
                if (val != null) {
                  configProvider.updateDefaultChecklistId(val);
                }
                context.pop();
              },
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: checklistProvider.allCheckLists.length,
                itemBuilder: (context, index) {
                  final list = checklistProvider.allCheckLists[index];
                  return RadioListTile<int>(
                    activeColor: colorTheme.selectedColor,
                    title: Text(list.name),
                    value: list.id,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showExportDialog(BuildContext context) async {
    final transferService = getIt<DataTransferService>();
    final defaultPath = await transferService.getDefaultExportPath();
    final controller = TextEditingController(text: defaultPath);

    if (!context.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导出数据'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('即将导出所有核心数据（任务、清单、习惯、打卡记录、番茄记录等）为本地备份文件。'),
            const SizedBox(height: Dimensions.paddingM),
            const Text(
              '导出路径：',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: Dimensions.paddingXS),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '请输入导出文件绝对路径',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingS,
                        vertical: Dimensions.paddingXS,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingS),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () async {
                    try {
                      final String? result = await FilePicker.platform.saveFile(
                        dialogTitle: '选择备份文件保存位置',
                        fileName: 'dida_backup.json',
                        type: FileType.custom,
                        allowedExtensions: ['json'],
                      );
                      if (result != null) {
                        controller.text = result;
                      }
                    } on Object catch (_) {
                      final String? directoryPath = await FilePicker.platform
                          .getDirectoryPath();
                      if (directoryPath != null) {
                        controller.text =
                            '$directoryPath${Platform.pathSeparator}dida_backup.json';
                      }
                    }
                  },
                  tooltip: '选择保存位置',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final path = controller.text.trim();
              if (path.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('路径不能为空')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              try {
                await transferService.exportData(path);
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('数据已成功导出至：$path')),
                );
              } on Object catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('数据导出失败：$e')),
                );
              }
            },
            child: const Text('确认导出'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(
    BuildContext context,
    ChecklistProvider checklistProvider,
  ) async {
    final transferService = getIt<DataTransferService>();
    final defaultPath = await transferService.getDefaultExportPath();
    final controller = TextEditingController(text: defaultPath);

    if (!context.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入数据'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '警告：导入备份数据将会清空当前应用中所有的核心业务数据！此操作无法撤销。',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: Dimensions.paddingM),
            const Text(
              '备份文件路径：',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: Dimensions.paddingXS),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '请输入备份文件绝对路径',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingS,
                        vertical: Dimensions.paddingXS,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingS),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                    );
                    if (result != null && result.files.single.path != null) {
                      controller.text = result.files.single.path!;
                    }
                  },
                  tooltip: '选择备份文件',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final path = controller.text.trim();
              if (path.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('路径不能为空')),
                );
                return;
              }

              final taskProvider = Provider.of<TaskProvider>(
                context,
                listen: false,
              );
              final tomatoProvider = Provider.of<TomatoProvider>(
                context,
                listen: false,
              );

              Navigator.pop(dialogContext);
              try {
                await transferService.importData(path);
                await checklistProvider.loadAllChecklistes();
                checklistProvider.updateCurChecklist(
                  AppConstants.todayCheckList,
                );
                await taskProvider.updateCurrentTasks(
                  AppConstants.todayCheckList,
                );
                await tomatoProvider.loadCustomTomatoes();

                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('数据导入成功，界面已更新')),
                );
              } on Object catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('数据导入失败：$e')),
                );
              }
            },
            child: const Text('确认导入并覆写'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ChecklistProvider checklistProvider,
  ) async {
    final transferService = getIt<DataTransferService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除所有数据'),
        content: const Text(
          '警告：该操作将永久删除您的所有任务、清单、习惯、打卡记录、番茄记录！此操作是不可逆的，确认要继续吗？',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final taskProvider = Provider.of<TaskProvider>(
                context,
                listen: false,
              );
              final tomatoProvider = Provider.of<TomatoProvider>(
                context,
                listen: false,
              );

              Navigator.pop(dialogContext);
              try {
                await transferService.clearData();
                await checklistProvider.loadAllChecklistes();
                checklistProvider.updateCurChecklist(
                  AppConstants.todayCheckList,
                );
                await taskProvider.updateCurrentTasks(
                  AppConstants.todayCheckList,
                );
                await tomatoProvider.loadCustomTomatoes();

                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('所有业务实体数据已成功清除')),
                );
              } on Object catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('删除数据失败：$e')),
                );
              }
            },
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.theme;
    return Padding(
      padding: const EdgeInsets.only(
        left: Dimensions.paddingL,
        top: Dimensions.paddingM,
        bottom: Dimensions.paddingS,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: colorTheme.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
