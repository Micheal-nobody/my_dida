import 'package:flutter/material.dart';
import 'package:my_dida/features/tomato/providers/tomato_provider.dart';
import 'package:my_dida/features/tomato/widgets/associate_task_dialog.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class TomatoTimerFullScreenPage extends StatefulWidget {
  const TomatoTimerFullScreenPage({super.key});

  @override
  State<TomatoTimerFullScreenPage> createState() =>
      _TomatoTimerFullScreenPageState();
}

enum TimerThemeMode { white, black, immersive }

class _TomatoTimerFullScreenPageState extends State<TomatoTimerFullScreenPage> {
  bool _isWakelockEnabled = false;
  TimerThemeMode _currentMode = TimerThemeMode.white;
  late PageController _immersivePageController;
  int _immersivePageIndex = 0;

  @override
  void initState() {
    super.initState();
    _immersivePageController = PageController(initialPage: _immersivePageIndex);
  }

  @override
  void dispose() {
    _immersivePageController.dispose();
    if (_isWakelockEnabled) {
      WakelockPlus.disable();
    }
    super.dispose();
  }

  // 格式化时间为 分:秒
  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TomatoProvider>();

    final isWhiteMode = _currentMode == TimerThemeMode.white;
    final isImmersiveMode = _currentMode == TimerThemeMode.immersive;

    final backgroundColor = isWhiteMode ? Colors.white : Colors.black;
    final foregroundColor = isWhiteMode ? Colors.black87 : Colors.white;
    final subForegroundColor = isWhiteMode
        ? Colors.black54
        : Colors.grey.shade600;
    final buttonBgColor = isWhiteMode
        ? Colors.grey.shade200
        : Colors.grey.shade900;
    final buttonTextColor = isWhiteMode ? Colors.black87 : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: isImmersiveMode
          ? null
          : AppBar(
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: foregroundColor,
                ),
                onPressed: () {
                  if (isWhiteMode) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() {
                      _currentMode = TimerThemeMode.white;
                    });
                  }
                },
              ),
              title: Text(
                provider.activeCustomTomato != null
                    ? '番茄钟: ${provider.activeCustomTomato!.name}'
                    : '番茄专注',
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isWakelockEnabled
                        ? Icons.lightbulb
                        : Icons.lightbulb_outline,
                    color: _isWakelockEnabled ? Colors.yellow : foregroundColor,
                  ),
                  onPressed: () async {
                    setState(() {
                      _isWakelockEnabled = !_isWakelockEnabled;
                    });
                    if (_isWakelockEnabled) {
                      await WakelockPlus.enable();
                    } else {
                      await WakelockPlus.disable();
                    }
                  },
                  tooltip: '屏幕常亮',
                ),
              ],
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          setState(() {
            if (_currentMode == TimerThemeMode.white) {
              _currentMode = TimerThemeMode.black;
            } else if (_currentMode == TimerThemeMode.black) {
              _currentMode = TimerThemeMode.immersive;
              _immersivePageController = PageController(
                initialPage: _immersivePageIndex,
              );
            } else {
              _currentMode = TimerThemeMode.black;
            }
          });
        },
        child: SafeArea(
          child: isImmersiveMode
              ? PageView(
                  controller: _immersivePageController,
                  onPageChanged: (index) {
                    setState(() {
                      _immersivePageIndex = index;
                    });
                  },
                  children: [
                    Center(
                      child: _buildTimerArea(
                        context,
                        provider,
                        styleIndex: 0,
                        isImmersive: true,
                        foregroundColor: foregroundColor,
                        subForegroundColor: subForegroundColor,
                      ),
                    ),
                    Center(
                      child: _buildTimerArea(
                        context,
                        provider,
                        styleIndex: 1,
                        isImmersive: true,
                        foregroundColor: foregroundColor,
                        subForegroundColor: subForegroundColor,
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 1. 顶部关联区域
                      _buildTopAssociatedArea(
                        provider,
                        foregroundColor,
                        subForegroundColor,
                      ),

                      // 2. 中间大圆形计时器 (计时区域)
                      _buildTimerArea(
                        context,
                        provider,
                        styleIndex: 0,
                        isImmersive: false,
                        foregroundColor: foregroundColor,
                        subForegroundColor: subForegroundColor,
                      ),

                      // 3. 快捷时间设定区 + 周期小圆圈
                      _buildQuickSettingsAndDots(
                        provider,
                        foregroundColor,
                        buttonBgColor,
                        buttonTextColor,
                      ),

                      // 4. 底部主控制区
                      _buildBottomControls(
                        provider,
                        backgroundColor,
                        foregroundColor,
                        buttonBgColor,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTopAssociatedArea(
    TomatoProvider provider,
    Color foregroundColor,
    Color subForegroundColor,
  ) {
    if (provider.activeCustomTomato != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: foregroundColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_bottom_rounded,
              color: foregroundColor,
              size: 22,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '当前预设: ${provider.activeCustomTomato!.name} (${provider.activeCustomTomato!.focusMinutes}分钟)',
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else {
      return GestureDetector(
        onTap: provider.isRunning ? null : () => _selectTask(context, provider),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: foregroundColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.playlist_add_check_rounded,
                color: foregroundColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  provider.associatedTask != null
                      ? '当前任务: ${provider.associatedTask!.name}'
                      : '关联待办任务开始高效专注...',
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (provider.associatedTask != null && !provider.isRunning) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => provider.setAssociatedTask(null),
                  child: Icon(
                    Icons.close_rounded,
                    color: subForegroundColor,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
  }

  Widget _buildTimerArea(
    BuildContext context,
    TomatoProvider provider, {
    required int styleIndex,
    required bool isImmersive,
    required Color foregroundColor,
    required Color subForegroundColor,
  }) {
    if (styleIndex == 0) {
      // Style 0: 圆环进度条模式
      return Stack(
        alignment: Alignment.center,
        children: [
          // 圆环背景
          SizedBox(
            width: isImmersive ? 280 : 250,
            height: isImmersive ? 280 : 250,
            child: CircularProgressIndicator(
              value: provider.totalDuration > 0
                  ? provider.duration / provider.totalDuration
                  : 1.0,
              strokeWidth: isImmersive ? 12 : 10,
              backgroundColor: foregroundColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          // 时间文字与状态
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: provider.toggleCountUpMode,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  _formatTime(
                    provider.countUpMode
                        ? (provider.totalDuration - provider.duration)
                        : provider.duration,
                  ),
                  style: TextStyle(
                    fontSize: isImmersive ? 60 : 54,
                    fontWeight: FontWeight.bold,
                    color: foregroundColor,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.statusText,
                style: TextStyle(
                  fontSize: isImmersive ? 18 : 16,
                  color: subForegroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Style 1: 纯数字模式
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: provider.toggleCountUpMode,
            behavior: HitTestBehavior.opaque,
            child: Text(
              _formatTime(
                provider.countUpMode
                    ? (provider.totalDuration - provider.duration)
                    : provider.duration,
              ),
              style: TextStyle(
                fontSize: isImmersive ? 80 : 64,
                fontWeight: FontWeight.bold,
                color: foregroundColor,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            provider.statusText,
            style: TextStyle(
              fontSize: isImmersive ? 22 : 18,
              color: subForegroundColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildQuickSettingsAndDots(
    TomatoProvider provider,
    Color foregroundColor,
    Color buttonBgColor,
    Color buttonTextColor,
  ) => Column(
    children: [
      if (!provider.isRunning)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildQuickSetButton(
              context,
              '专注',
              buttonBgColor,
              buttonTextColor,
              () {
                provider
                  ..setActiveCustomTomato(null)
                  ..selectFocus();
              },
            ),
            const SizedBox(width: 12),
            _buildQuickSetButton(
              context,
              '短休',
              buttonBgColor,
              buttonTextColor,
              provider.selectShortBreak,
            ),
            const SizedBox(width: 12),
            _buildQuickSetButton(
              context,
              '长休',
              buttonBgColor,
              buttonTextColor,
              provider.selectLongBreak,
            ),
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
                  ? foregroundColor
                  : foregroundColor.withValues(alpha: 0.25),
              border: Border.all(color: foregroundColor, width: 1.5),
            ),
          );
        }),
      ),
    ],
  );

  Widget _buildBottomControls(
    TomatoProvider provider,
    Color backgroundColor,
    Color foregroundColor,
    Color buttonBgColor,
  ) {
    final isWhiteMode = _currentMode == TimerThemeMode.white;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!provider.isRunning) ...[
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isWhiteMode
                  ? Colors.grey.shade200
                  : buttonBgColor,
              foregroundColor: foregroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: isWhiteMode ? 0 : 4,
            ),
            onPressed: provider.start,
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text(
              '开始专注',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ] else ...[
          if (provider.isPaused) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isWhiteMode
                    ? Colors.grey.shade200
                    : buttonBgColor,
                foregroundColor: foregroundColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: isWhiteMode ? 0 : 4,
              ),
              onPressed: provider.resume,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('继续'),
            ),
          ] else ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: foregroundColor.withValues(alpha: 0.1),
                foregroundColor: foregroundColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              onPressed: provider.pause,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            onPressed: () => _confirmAbandon(context, provider),
            icon: const Icon(Icons.stop_rounded),
            label: Text(provider.status == TomatoStatus.focus ? '放弃' : '跳过'),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickSetButton(
    BuildContext context,
    String label,
    Color buttonBgColor,
    Color buttonTextColor,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: buttonBgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: buttonTextColor,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  Future<void> _selectTask(
    BuildContext context,
    TomatoProvider provider,
  ) async {
    final selectedTask = await AssociateTaskDialog.show(context);
    provider.setAssociatedTask(selectedTask);
  }

  Future<void> _confirmAbandon(
    BuildContext context,
    TomatoProvider provider,
  ) async {
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
}
