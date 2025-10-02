import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/entity/Habit.dart';
import '../provider/HabitProvider.dart';

/// 专门用于处理 Habit 打卡的对话框
///
/// 这个组件封装了习惯打卡的完整逻辑，
/// 直接处理习惯的持久化更新
class HabitCheckInDialog extends StatefulWidget {
  final Habit habit;

  const HabitCheckInDialog({super.key, required this.habit});

  /// 显示习惯打卡对话框
  ///
  /// [context] - 上下文
  /// [habit] - 要打卡的习惯对象
  /// [onUpdated] - 更新完成回调（可选，用于UI刷新）
  static Future<void> show({
    required BuildContext context,
    required Habit habit,
    VoidCallback? onUpdated,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => HabitCheckInDialog(habit: habit),
    );

    // 调用更新完成回调
    onUpdated?.call();
  }

  @override
  State<HabitCheckInDialog> createState() => _HabitCheckInDialogState();
}

class _HabitCheckInDialogState extends State<HabitCheckInDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  bool _isCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final habit = widget.habit;
        final isCompleted = habitProvider.isTodayCompleted(habit);
        final progress = habitProvider.getTodayProgress(habit);

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getIconData(habit.icon),
                color: isCompleted ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(habit.name, style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 进度显示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '今日进度',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${habit.currentCheckInCount}/${habit.checkInCount}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 滑动按钮
              if (!isCompleted) ...[
                Text(
                  '向右滑动完成打卡',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                _buildSlideButton(habitProvider),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '今日已完成！',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          actions: [
            // 撤销一次打卡按钮
            if (isCompleted && habit.currentCheckInCount > 0)
              TextButton(
                onPressed: () async {
                  await habitProvider.undoLastCheckIn(habit);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('撤销一次'),
              ),
            // 撤销所有打卡按钮
            if (isCompleted && habit.currentCheckInCount > 0)
              TextButton(
                onPressed: () async {
                  await habitProvider.undoAllCheckIns(habit);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('撤销全部'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSlideButton(HabitProvider habitProvider) {
    return Container(
      height: 60,
      width: 250,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          // 背景轨道（灰色）
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),

          // 已滑过的进度（橙色）
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              final double progressWidth = (_slideAnimation.value * 200 + 50)
                  .clamp(0.0, 250.0);
              return Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: progressWidth,
                  decoration: BoxDecoration(
                    color: Colors.orange[300],
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              );
            },
          ),

          // 滑动按钮
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Positioned(
                left: _slideAnimation.value * 200,
                top: 5,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final progress = details.localPosition.dx / 200;
                    _slideController.value = progress.clamp(0.0, 1.0);
                  },
                  onPanEnd: (details) {
                    if (_slideController.value > 0.8) {
                      // 完成打卡
                      _slideController.forward().then((_) async {
                        await habitProvider.checkIn(widget.habit);
                        setState(() {
                          _isCheckedIn = true;
                        });
                        Future.delayed(const Duration(seconds: 1), () {
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        });
                      });
                    } else {
                      // 回弹
                      _slideController.reverse();
                    }
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ),
              );
            },
          ),

          // 文字提示
          Center(
            child: Text(
              _isCheckedIn ? '完成！' : '滑动打卡',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'brush':
        return Icons.brush;
      case 'fitness':
        return Icons.fitness_center;
      case 'book':
        return Icons.book;
      case 'water':
        return Icons.water_drop;
      case 'sleep':
        return Icons.bedtime;
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.star;
    }
  }
}
