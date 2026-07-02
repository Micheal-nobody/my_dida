import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/tomato/models/custom_tomato.dart';
import 'package:my_dida/features/tomato/pages/tomato_summary_page.dart';
import 'package:my_dida/features/tomato/providers/tomato_provider.dart';
import 'package:provider/provider.dart';

class TomatoPage extends StatelessWidget {
  const TomatoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TomatoProvider>();
    final colorTheme = context.theme;

    // 格式化今日累计时间显示 (例如 0m, 4h37m, 25m)
    String formatTodayMinutes(int minutes) {
      if (minutes <= 0) return '0m';
      if (minutes < 60) return '${minutes}m';
      final hrs = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hrs}h${mins}m';
    }

    // 格式化时间为 分:秒
    String formatTime(int totalSeconds) {
      final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
      final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }

    return Scaffold(
      backgroundColor: colorTheme.primary.withValues(alpha: 0.08), // 暖色调单色背景
      appBar: AppBar(
        title: Text(
          '番茄专注',
          style: TextStyle(
            color: colorTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorTheme.textPrimary),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: colorTheme.textPrimary,
              size: 26,
            ),
            tooltip: '新建番茄钟',
            onPressed: () => _showAddTomatoDialog(context, provider),
          ),
          IconButton(
            icon: Icon(
              Icons.bar_chart_rounded,
              color: colorTheme.textPrimary,
              size: 28,
            ),
            tooltip: '专注统计',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TomatoSummaryPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: colorTheme.textPrimary,
              size: 24,
            ),
            tooltip: '番茄设置',
            onPressed: () => _showSettingsDialog(context, provider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部自定义番茄钟预设列表
            Expanded(
              child: provider.customTomatoes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hourglass_empty_rounded,
                            size: 64,
                            color: colorTheme.textDisabled,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无自定义番茄钟',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorTheme.primary,
                              foregroundColor: colorTheme.textOnPrimary,
                            ),
                            onPressed: () =>
                                _showAddTomatoDialog(context, provider),
                            icon: const Icon(Icons.add),
                            label: const Text('立即创建'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      itemCount: provider.customTomatoes.length,
                      itemBuilder: (context, index) {
                        final tomato = provider.customTomatoes[index];
                        final isCurrentActive =
                            provider.activeCustomTomato?.id == tomato.id;
                        final isRunningThis =
                            isCurrentActive &&
                            provider.isRunning &&
                            !provider.isPaused;

                        return GestureDetector(
                          onLongPress: () =>
                              _confirmDelete(context, provider, tomato),
                          child: Card(
                            color: colorTheme.cardBackground,
                            elevation: 0.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                children: [
                                  // 笑脸图标
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: colorTheme.success.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.sentiment_satisfied_alt_rounded,
                                      color: colorTheme.success,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // 名字与今日专注时间
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tomato.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: colorTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        FutureBuilder<int>(
                                          future: provider
                                              .getCustomTomatoTodayMinutes(
                                                tomato.id,
                                              ),
                                          builder: (context, snapshot) {
                                            final todayMins =
                                                snapshot.data ?? 0;
                                            return Text(
                                              formatTodayMinutes(todayMins),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: colorTheme.textSecondary,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 右侧播放/旋转状态
                                  GestureDetector(
                                    onTap: () {
                                      if (isCurrentActive) {
                                        if (provider.isRunning &&
                                            !provider.isPaused) {
                                          provider.pause();
                                        } else if (provider.isPaused) {
                                          provider.resume();
                                        } else {
                                          provider.start();
                                        }
                                      } else {
                                        // 激活这个自定义番茄钟并直接启动
                                        provider
                                          ..setActiveCustomTomato(tomato)
                                          ..start();
                                      }
                                    },
                                    child: isRunningThis
                                        ? SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: CircularProgressIndicator(
                                              value: provider.totalDuration > 0
                                                  ? provider.duration /
                                                        provider.totalDuration
                                                  : 1.0,
                                              strokeWidth: 3,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    colorTheme.primary,
                                                  ),
                                              backgroundColor: colorTheme
                                                  .primary
                                                  .withValues(alpha: 0.2),
                                            ),
                                          )
                                        : Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: colorTheme.primary
                                                  .withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.play_arrow_rounded,
                                              color: colorTheme.primary,
                                              size: 22,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // 底部常驻迷你倒计时控制栏
            if (provider.status != TomatoStatus.idle || provider.isRunning)
              GestureDetector(
                onTap: () {
                  context.push('/pomodoro/timer');
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colorTheme.cardBackground,
                    boxShadow: [
                      BoxShadow(
                        color: colorTheme.textPrimary.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                  child: Row(
                    children: [
                      // 左侧绿色微笑图标
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorTheme.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sentiment_satisfied_alt_rounded,
                          color: colorTheme.success,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // 番茄钟名称与倒计时
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.activeCustomTomato != null
                                  ? provider.activeCustomTomato!.name
                                  : (provider.associatedTask != null
                                        ? provider.associatedTask!.name
                                        : '普通番茄钟'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colorTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              provider.statusText,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 倒计时文字显示
                      Text(
                        formatTime(provider.duration),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colorTheme.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 播放/暂停控制按钮
                      GestureDetector(
                        onTap: () {
                          if (provider.isRunning && !provider.isPaused) {
                            provider.pause();
                          } else {
                            if (provider.isPaused) {
                              provider.resume();
                            } else {
                              provider.start();
                            }
                          }
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: colorTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            provider.isRunning && !provider.isPaused
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: colorTheme.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 新建番茄钟预设对话框
  void _showAddTomatoDialog(BuildContext context, TomatoProvider provider) {
    final nameController = TextEditingController();
    int focusVal = 25;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('新建自定义番茄钟'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '番茄钟名称',
                    hintText: '例如：帕梅拉 / 冥想 / 写作',
                  ),
                  maxLength: 20,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                _buildSlider(
                  context,
                  '专注时间',
                  focusVal,
                  5,
                  120,
                  (val) => setState(() => focusVal = val.round()),
                  '分钟',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请输入番茄钟名称')));
                  return;
                }
                await provider.addCustomTomato(name, focusVal);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  // 长按删除确认对话框
  Future<void> _confirmDelete(
    BuildContext context,
    TomatoProvider provider,
    CustomTomato tomato,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除番茄预设'),
        content: Text('确定要删除自定义番茄钟“${tomato.name}”吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.deleteButton,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteCustomTomato(tomato.id);
    }
  }

  void _showSettingsDialog(BuildContext context, TomatoProvider provider) {
    int focusVal = provider.focusMinutes;
    int shortVal = provider.shortBreakMinutes;
    int longVal = provider.longBreakMinutes;
    int intervalVal = provider.longBreakInterval;
    bool autoBreakVal = provider.autoStartBreak;
    bool autoFocusVal = provider.autoStartFocus;
    bool autoCompVal = provider.autoCompletedTask;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('番茄偏好设置'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSlider(
                  context,
                  '专注时长',
                  focusVal,
                  5,
                  60,
                  (val) => setDialogState(() => focusVal = val.round()),
                  '分钟',
                ),
                _buildSlider(
                  context,
                  '短休时长',
                  shortVal,
                  1,
                  20,
                  (val) => setDialogState(() => shortVal = val.round()),
                  '分钟',
                ),
                _buildSlider(
                  context,
                  '长休时长',
                  longVal,
                  5,
                  45,
                  (val) => setDialogState(() => longVal = val.round()),
                  '分钟',
                ),
                _buildSlider(
                  context,
                  '长休间隔',
                  intervalVal,
                  2,
                  8,
                  (val) => setDialogState(() => intervalVal = val.round()),
                  '个番茄',
                ),
                SwitchListTile(
                  title: const Text('自动开始休息', style: TextStyle(fontSize: 14)),
                  value: autoBreakVal,
                  dense: true,
                  onChanged: (val) => setDialogState(() => autoBreakVal = val),
                ),
                SwitchListTile(
                  title: const Text('自动开始下轮专注', style: TextStyle(fontSize: 14)),
                  value: autoFocusVal,
                  dense: true,
                  onChanged: (val) => setDialogState(() => autoFocusVal = val),
                ),
                SwitchListTile(
                  title: const Text('自动完成关联任务', style: TextStyle(fontSize: 14)),
                  value: autoCompVal,
                  dense: true,
                  onChanged: (val) => setDialogState(() => autoCompVal = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.updateSettings(
                  focusMin: focusVal,
                  shortMin: shortVal,
                  longMin: longVal,
                  interval: intervalVal,
                  autoBreak: autoBreakVal,
                  autoFocus: autoFocusVal,
                  autoComp: autoCompVal,
                );
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context,
    String label,
    int currentValue,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String unit,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '$currentValue $unit',
              style: TextStyle(
                fontSize: 14,
                color: context.theme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      Slider(
        activeColor: context.theme.primary,
        inactiveColor: context.theme.primary.withValues(alpha: 0.2),
        value: currentValue.toDouble(),
        min: min,
        max: max,
        divisions: (max - min).toInt(),
        onChanged: onChanged,
      ),
    ],
  );
}
