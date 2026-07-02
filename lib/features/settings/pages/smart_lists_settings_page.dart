import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/settings/models/sidebar_config.dart';
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
            title: Text(
              '四象限',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: config.showFourQuadrants ? colorTheme.primary : colorTheme.textPrimary,
              ),
            ),
            trailing: Switch(
              value: config.showFourQuadrants,
              activeColor: colorTheme.primary,
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
    required SmartListShowOption currentValue,
    required ValueChanged<SmartListShowOption> onChanged,
  }) {
    String stateText = '显示';
    if (currentValue == SmartListShowOption.hide) stateText = '隐藏';
    if (currentValue == SmartListShowOption.auto) stateText = '自动';

    final colorTheme = context.theme;
    final isEnabled = currentValue != SmartListShowOption.hide;

    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isEnabled ? colorTheme.primary : colorTheme.textPrimary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stateText,
                style: TextStyle(
                  color: isEnabled ? colorTheme.primary : colorTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isEnabled ? colorTheme.primary : colorTheme.textDisabled,
              ),
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
    SmartListShowOption currentValue,
    ValueChanged<SmartListShowOption> onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final colorTheme = context.theme;
        return AlertDialog(
          title: Text('$title 的显示设置'),
          content: RadioGroup<SmartListShowOption>(
            groupValue: currentValue,
            onChanged: (val) {
              if (val != null) onChanged(val);
              context.pop();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<SmartListShowOption>(
                  activeColor: colorTheme.primary,
                  title: const Text('显示'),
                  value: SmartListShowOption.show,
                ),
                RadioListTile<SmartListShowOption>(
                  activeColor: colorTheme.primary,
                  title: const Text('隐藏'),
                  value: SmartListShowOption.hide,
                ),
                RadioListTile<SmartListShowOption>(
                  activeColor: colorTheme.primary,
                  title: const Text('自动 (有任务时显示)'),
                  value: SmartListShowOption.auto,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
