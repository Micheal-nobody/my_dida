import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:my_dida/provider/sidebar_config_provider.dart';
import 'package:my_dida/provider/checklist_provider.dart';
import 'package:my_dida/constants/colors_constants.dart';
import 'package:my_dida/constants/dimension_constants.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<SidebarConfigProvider>(context);
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final config = configProvider.config;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: AppColors.background,
      body: ListView(
        children: [
          // 个人中心 Section
          _buildSectionHeader('个人中心'),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingM,
              vertical: Dimensions.paddingXS,
            ),
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              side: const BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.person, color: AppColors.textSecondary),
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
          _buildSectionHeader('偏好设置'),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingM,
              vertical: Dimensions.paddingXS,
            ),
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              side: const BorderSide(color: AppColors.border),
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
                        config.theme == 'light'
                            ? '浅色'
                            : config.theme == 'dark'
                            ? '深色'
                            : '自动',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showThemeDialog(context, configProvider),
                ),
                const Divider(height: 1, indent: 50, color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.menu_open),
                  title: const Text('侧边栏'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/sidebar'),
                ),
                const Divider(height: 1, indent: 50, color: AppColors.border),
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
                const Divider(height: 1, indent: 50, color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('语言'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        config.language == 'zh' ? '简体中文' : 'English',
                        style: const TextStyle(color: AppColors.textSecondary),
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
          _buildSectionHeader('任务管理'),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingM,
              vertical: Dimensions.paddingXS,
            ),
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('智能清单'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/smart-lists'),
                ),
                const Divider(height: 1, indent: 50, color: AppColors.border),
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
                        style: const TextStyle(color: AppColors.textSecondary),
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
                const Divider(height: 1, indent: 50, color: AppColors.border),
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
          _buildSectionHeader('备份与同步'),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingM,
              vertical: Dimensions.paddingXS,
            ),
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.sync),
                  title: const Text('自动同步'),
                  value: true,
                  onChanged: (value) {},
                ),
                const Divider(height: 1, indent: 50, color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('立即同步'),
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('正在同步数据...')));
                  },
                ),
              ],
            ),
          ),

          // 关于 Section
          _buildSectionHeader('关于'),
          Card(
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingM,
              vertical: Dimensions.paddingXS,
            ),
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              side: const BorderSide(color: AppColors.border),
            ),
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('版本信息'),
                  subtitle: Text('v1.0.0'),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingL),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: Dimensions.paddingL,
        top: Dimensions.paddingM,
        bottom: Dimensions.paddingS,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SidebarConfigProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('主题设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('自动'),
              value: 'system',
              groupValue: provider.config.theme,
              onChanged: (val) {
                if (val != null) provider.updateTheme(val);
                context.pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('浅色'),
              value: 'light',
              groupValue: provider.config.theme,
              onChanged: (val) {
                if (val != null) provider.updateTheme(val);
                context.pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('深色'),
              value: 'dark',
              groupValue: provider.config.theme,
              onChanged: (val) {
                if (val != null) provider.updateTheme(val);
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    SidebarConfigProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('语言设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('简体中文'),
              value: 'zh',
              groupValue: provider.config.language,
              onChanged: (val) {
                if (val != null) provider.updateLanguage(val);
                context.pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: provider.config.language,
              onChanged: (val) {
                if (val != null) provider.updateLanguage(val);
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDefaultChecklistDialog(
    BuildContext context,
    SidebarConfigProvider configProvider,
    ChecklistProvider checklistProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择默认清单'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: checklistProvider.allCheckLists.length,
            itemBuilder: (context, index) {
              final list = checklistProvider.allCheckLists[index];
              return RadioListTile<int>(
                title: Text(list.name),
                value: list.id,
                groupValue: configProvider.config.defaultChecklistId,
                onChanged: (val) {
                  if (val != null) {
                    configProvider.updateDefaultChecklistId(val);
                  }
                  context.pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
