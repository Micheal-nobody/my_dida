import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:my_dida/provider/sidebar_config_provider.dart';
import 'package:my_dida/constants/colors_constants.dart';
import 'package:my_dida/constants/dimension_constants.dart';

class SidebarSettingsPage extends StatelessWidget {
  const SidebarSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SidebarConfigProvider>(context);
    final config = provider.config;

    return Scaffold(
      appBar: AppBar(
        title: const Text('侧边栏设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: AppColors.background,
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
              side: const BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.account_box),
                  title: const Text('头像与用户信息'),
                  value: config.showProfile,
                  onChanged: (val) =>
                      provider.updateModuleVisibility(showProfile: val),
                ),
                const Divider(height: 1, indent: 50, color: AppColors.border),
                SwitchListTile(
                  secondary: const Icon(Icons.search),
                  title: const Text('搜索'),
                  value: config.showSearch,
                  onChanged: (val) =>
                      provider.updateModuleVisibility(showSearch: val),
                ),
                const Divider(height: 1, indent: 50, color: AppColors.border),
                SwitchListTile(
                  secondary: const Icon(Icons.view_agenda),
                  title: const Text('智能清单'),
                  value: config.showSmartLists,
                  onChanged: (val) =>
                      provider.updateModuleVisibility(showSmartLists: val),
                ),
                const Divider(height: 1, indent: 50, color: AppColors.border),
                SwitchListTile(
                  secondary: const Icon(Icons.folder),
                  title: const Text('清单'),
                  value: config.showCustomLists,
                  onChanged: (val) =>
                      provider.updateModuleVisibility(showCustomLists: val),
                ),
                const Divider(height: 1, indent: 50, color: AppColors.border),
                SwitchListTile(
                  secondary: const Icon(Icons.label),
                  title: const Text('标签'),
                  value: config.showTags,
                  onChanged: (val) =>
                      provider.updateModuleVisibility(showTags: val),
                ),
                const Divider(height: 1, indent: 50, color: AppColors.border),
                SwitchListTile(
                  secondary: const Icon(Icons.filter_alt),
                  title: const Text('过滤器'),
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
