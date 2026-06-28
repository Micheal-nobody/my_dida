import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/core/themes/color_constants.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/settings/providers/sidebar_config_provider.dart';
import 'package:provider/provider.dart';

class SmartListsSettingsPage extends StatelessWidget {
  const SmartListsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SidebarConfigProvider>(context);
    final config = provider.config;
    final colorTheme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能清单'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: colorTheme.background,
      body: ListView(
        children: [
          _buildListTile(
            context: context,
            title: '今天',
            currentValue: config.todayShowOption,
            onChanged: (val) =>
                provider.updateSmartListShowOption(todayShowOption: val),
          ),
          _buildListTile(
            context: context,
            title: '明天',
            currentValue: config.tomorrowShowOption,
            onChanged: (val) =>
                provider.updateSmartListShowOption(tomorrowShowOption: val),
          ),
          _buildListTile(
            context: context,
            title: '最近七天',
            currentValue: config.nextSevenDaysShowOption,
            onChanged: (val) => provider.updateSmartListShowOption(
              nextSevenDaysShowOption: val,
            ),
          ),
          _buildListTile(
            context: context,
            title: '收集箱',
            currentValue: config.inboxShowOption,
            onChanged: (val) =>
                provider.updateSmartListShowOption(inboxShowOption: val),
          ),
          _buildListTile(
            context: context,
            title: '所有',
            currentValue: config.allShowOption,
            onChanged: (val) =>
                provider.updateSmartListShowOption(allShowOption: val),
          ),
          _buildListTile(
            context: context,
            title: '已完成',
            currentValue: config.completedShowOption,
            onChanged: (val) =>
                provider.updateSmartListShowOption(completedShowOption: val),
          ),
          _buildListTile(
            context: context,
            title: '垃圾桶',
            currentValue: config.trashShowOption,
            onChanged: (val) =>
                provider.updateSmartListShowOption(trashShowOption: val),
          ),
          ListTile(
            title: const Text(
              '四象限',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Switch(
              value: config.showFourQuadrants,
              activeThumbColor: Colors.orange,
              onChanged: provider.updateFourQuadrantsVisibility,
            ),
          ),
          Divider(height: 1, indent: 16, color: colorTheme.border),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required String title,
    required int currentValue,
    required ValueChanged<int> onChanged,
  }) {
    String stateText = '显示';
    if (currentValue == 0) stateText = '隐藏';
    if (currentValue == 2) stateText = '自动';

    final colorTheme = context.theme;

    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stateText,
                style: TextStyle(
                  color: colorTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              Icon(Icons.chevron_right, color: colorTheme.textDisabled),
            ],
          ),
          onTap: () =>
              _showOptionPicker(context, title, currentValue, onChanged),
        ),
        Divider(height: 1, indent: 16, color: colorTheme.border),
      ],
    );
  }

  void _showOptionPicker(
    BuildContext context,
    String title,
    int currentValue,
    ValueChanged<int> onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title 的显示设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('显示'),
              value: 1,
              groupValue: currentValue,
              onChanged: (val) {
                if (val != null) onChanged(val);
                context.pop();
              },
            ),
            RadioListTile<int>(
              title: const Text('隐藏'),
              value: 0,
              groupValue: currentValue,
              onChanged: (val) {
                if (val != null) onChanged(val);
                context.pop();
              },
            ),
            RadioListTile<int>(
              title: const Text('自动 (有任务时显示)'),
              value: 2,
              groupValue: currentValue,
              onChanged: (val) {
                if (val != null) onChanged(val);
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
