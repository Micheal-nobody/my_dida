import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/core/constants/dimension_constants.dart';
import 'package:my_dida/core/themes/color_constants.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/settings/providers/sidebar_config_provider.dart';
import 'package:provider/provider.dart';

class SidebarSettingsPage extends StatelessWidget {
  const SidebarSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SidebarConfigProvider>(context);
    final config = provider.config;
    final colorTheme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('侧边栏设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: colorTheme.background,
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingM),
            child: Text(
              '配置在侧边栏中显示哪些模块：',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingM),
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              side: BorderSide(color: colorTheme.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.account_box,
                    color: config.showProfile ? colorTheme.selectedColor : colorTheme.textSecondary,
                  ),
                  title: Text(
                    '头像与用户信息',
                    style: TextStyle(
                      color: config.showProfile ? colorTheme.selectedColor : colorTheme.textPrimary,
                    ),
                  ),
                  activeColor: colorTheme.selectedColor,
                  value: config.showProfile,
                  onChanged: (val) =>
                      provider.updateModuleVisibility(showProfile: val),
                ),
                Divider(height: 1, indent: 50, color: colorTheme.border),
                SwitchListTile(
                  secondary: Icon(
                    Icons.search,
                    color: config.showSearch ? colorTheme.selectedColor : colorTheme.textSecondary,
                  ),
                  title: Text(
                    '搜索',
                    style: TextStyle(
                      color: config.showSearch ? colorTheme.selectedColor : colorTheme.textPrimary,
                    ),
                  ),
                  activeColor: colorTheme.selectedColor,
                  value: config.showSearch,
                  onChanged: (val) =>
                      provider.updateModuleVisibility(showSearch: val),
                ),
                Divider(height: 1, indent: 50, color: colorTheme.border),
                SwitchListTile(
                  secondary: Icon(
                    Icons.view_agenda,
                    color: config.showSmartLists ? colorTheme.selectedColor : colorTheme.textSecondary,
                  ),
                  title: Text(
                    '智能清单',
                    style: TextStyle(
                      color: config.showSmartLists ? colorTheme.selectedColor : colorTheme.textPrimary,
                    ),
                  ),
                  activeColor: colorTheme.selectedColor,
                  value: config.showSmartLists,
                  onChanged: (val) =>
                      provider.updateModuleVisibility(showSmartLists: val),
                ),
                Divider(height: 1, indent: 50, color: colorTheme.border),
                SwitchListTile(
                  secondary: Icon(
                    Icons.folder,
                    color: config.showCustomLists ? colorTheme.selectedColor : colorTheme.textSecondary,
                  ),
                  title: Text(
                    '清单',
                    style: TextStyle(
                      color: config.showCustomLists ? colorTheme.selectedColor : colorTheme.textPrimary,
                    ),
                  ),
                  activeColor: colorTheme.selectedColor,
                  value: config.showCustomLists,
                  onChanged: (val) =>
                      provider.updateModuleVisibility(showCustomLists: val),
                ),
                Divider(height: 1, indent: 50, color: colorTheme.border),
                SwitchListTile(
                  secondary: Icon(
                    Icons.label,
                    color: config.showTags ? colorTheme.selectedColor : colorTheme.textSecondary,
                  ),
                  title: Text(
                    '标签',
                    style: TextStyle(
                      color: config.showTags ? colorTheme.selectedColor : colorTheme.textPrimary,
                    ),
                  ),
                  activeColor: colorTheme.selectedColor,
                  value: config.showTags,
                  onChanged: (val) =>
                      provider.updateModuleVisibility(showTags: val),
                ),
                Divider(height: 1, indent: 50, color: colorTheme.border),
                SwitchListTile(
                  secondary: Icon(
                    Icons.filter_alt,
                    color: config.showFilters ? colorTheme.selectedColor : colorTheme.textSecondary,
                  ),
                  title: Text(
                    '过滤器',
                    style: TextStyle(
                      color: config.showFilters ? colorTheme.selectedColor : colorTheme.textPrimary,
                    ),
                  ),
                  activeThumbColor: colorTheme.selectedColor,
                  value: config.showFilters,
                  onChanged: (val) =>
                      provider.updateModuleVisibility(showFilters: val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
