import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/features/tomato/widgets/associate_task_dialog.dart';
import 'package:my_dida/provider/tomato_provider.dart';
import 'package:provider/provider.dart';
import 'tomato_summary_page.dart';

class TomatoPage extends StatelessWidget {
  const TomatoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TomatoProvider>();

    // 状态冷暖背景色定义
    Color backgroundColor;
    Color buttonColor;
    switch (provider.status) {
      case TomatoStatus.focus:
        backgroundColor = Colors.redAccent.shade700;
        buttonColor = Colors.white.withValues(alpha: 0.2);
        break;
      case TomatoStatus.shortBreak:
      case TomatoStatus.longBreak:
        backgroundColor = Colors.teal.shade700;
        buttonColor = Colors.white.withValues(alpha: 0.2);
        break;
      case TomatoStatus.idle:
      default:
        backgroundColor = Colors.blueGrey.shade800;
        buttonColor = Colors.white.withValues(alpha: 0.15);
        break;
    }

    // 格式化时间为 分:秒
    String formatTime(int totalSeconds) {
      final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
      final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('番茄专注', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 28),
            tooltip: '专注统计',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TomatoSummaryPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
            tooltip: '番茄设置',
            onPressed: () => _showSettingsDialog(context, provider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. 顶部关联任务区域
              GestureDetector(
                onTap: provider.isRunning ? null : () => _selectTask(context, provider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.playlist_add_check_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          provider.associatedTask != null
                              ? '当前任务: ${provider.associatedTask!.name}'
                              : '关联待办任务开始高效专注...',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (provider.associatedTask != null && !provider.isRunning) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => provider.setAssociatedTask(null),
                          child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                        ),
                      ]
                    ],
                  ),
                ),
              ),

              // 2. 中间大圆形计时器
              Stack(
                alignment: Alignment.center,
                children: [
                  // 圆环背景
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: provider.totalDuration > 0 ? provider.duration / provider.totalDuration : 1.0,
                      strokeWidth: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  // 时间文字与状态
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatTime(provider.duration),
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.statusText,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 3. 快捷时间设定区 + 周期小圆圈
              Column(
                children: [
                  if (!provider.isRunning)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildQuickSetButton(context, '专注', buttonColor, () => provider.selectFocus()),
                        const SizedBox(width: 12),
                        _buildQuickSetButton(context, '短休', buttonColor, () => provider.selectShortBreak()),
                        const SizedBox(width: 12),
                        _buildQuickSetButton(context, '长休', buttonColor, () => provider.selectLongBreak()),
                      ],
                    ),
                  const SizedBox(height: 20),
                  // 番茄数点点 (例如 4 个周期小点)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(provider.longBreakInterval, (index) {
                      final isCompleted = index < provider.completedTomatoCount;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.25),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      );
                    }),
                  ),
                ],
              ),

              // 4. 底部主控制区
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!provider.isRunning) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: backgroundColor,
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 4,
                      ),
                      onPressed: () => provider.start(),
                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                      label: const Text('开始专注', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    if (provider.isPaused) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: backgroundColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () => provider.resume(),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('继续'),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () => provider.pause(),
                        icon: const Icon(Icons.pause_rounded),
                        label: const Text('暂停'),
                      ),
                    ],
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () => _confirmAbandon(context, provider),
                      icon: const Icon(Icons.stop_rounded),
                      label: Text(provider.status == TomatoStatus.focus ? '放弃' : '跳过'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSetButton(
    BuildContext context,
    String label,
    Color buttonColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _selectTask(BuildContext context, TomatoProvider provider) async {
    final selectedTask = await AssociateTaskDialog.show(context);
    // 如果返回 null，表示点击了取消关联
    provider.setAssociatedTask(selectedTask);
  }

  Future<void> _confirmAbandon(BuildContext context, TomatoProvider provider) async {
    if (provider.status != TomatoStatus.focus) {
      provider.skipBreak();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃当前专注'),
        content: const Text('确定要放弃本次专注吗？放弃将记录为未完成专注。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.abandon();
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
                _buildSettingSlider(
                  '专注时长',
                  focusVal,
                  5,
                  60,
                  (val) => setDialogState(() => focusVal = val.round()),
                  '分钟',
                ),
                _buildSettingSlider(
                  '短休时长',
                  shortVal,
                  1,
                  20,
                  (val) => setDialogState(() => shortVal = val.round()),
                  '分钟',
                ),
                _buildSettingSlider(
                  '长休时长',
                  longVal,
                  5,
                  45,
                  (val) => setDialogState(() => longVal = val.round()),
                  '分钟',
                ),
                _buildSettingSlider(
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

  Widget _buildSettingSlider(
    String label,
    int currentValue,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String unit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text('$currentValue $unit', style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Slider(
          value: currentValue.toDouble(),
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
