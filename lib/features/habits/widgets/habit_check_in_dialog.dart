import 'package:flutter/material.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:provider/provider.dart';

/// 习惯打卡对话框
///
/// 封装了习惯打卡的完整逻辑，包含滑动动画、进度显示和撤销操作。
/// 通过 [accentColor] 参数控制主题色。
class HabitCheckInDialog extends StatefulWidget {
  const HabitCheckInDialog({
    required this.habit,
    this.accentColor = Colors.orange,
    super.key,
  });

  final Habit habit;
  final Color accentColor;

  /// 显示习惯打卡对话框
  static Future<void> show({
    required BuildContext context,
    required Habit habit,
    Color accentColor = Colors.orange,
    VoidCallback? onUpdated,
  }) async {
    await showDialog(
      context: context,
      builder: (context) =>
          HabitCheckInDialog(habit: habit, accentColor: accentColor),
    );

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
  final TextEditingController _inputController = TextEditingController();

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

    // 设定默认打卡增量
    if (widget.habit.habitType == 'duration') {
      _inputController.text = '15';
    } else if (widget.habit.habitType == 'count') {
      if (widget.habit.unit == '毫升') {
        _inputController.text = '250';
      } else if (widget.habit.unit == '页') {
        _inputController.text = '5';
      } else {
        _inputController.text = '1';
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<HabitProvider>(
    builder: (context, habitProvider, child) {
      final habit = widget.habit;
      final isCompleted = habitProvider.isTodayCompleted(habit);
      final progress = habitProvider.getTodayProgress(habit);

      return AlertDialog(
        title: Row(
          children: [
            Icon(
              _getIconData(habit.icon),
              color: isCompleted ? Colors.green : widget.accentColor,
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
                      isCompleted ? Colors.green : widget.accentColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    habit.habitType == 'yesNo'
                        ? '${habit.currentCheckInCount}/${habit.checkInCount}'
                        : '${habit.currentValue.toStringAsFixed(0)}/${habit.targetValue?.toStringAsFixed(0) ?? 0} ${habit.unit ?? ""}',
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
              if (habit.habitType == 'count' ||
                  habit.habitType == 'duration') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        double val =
                            double.tryParse(_inputController.text) ?? 0.0;
                        double step = habit.habitType == 'duration'
                            ? 15.0
                            : (habit.unit == '毫升'
                                  ? 250.0
                                  : (habit.unit == '页' ? 5.0 : 1.0));
                        val = (val - step).clamp(0.0, 999999.0);
                        _inputController.text = val.toStringAsFixed(0);
                      },
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _inputController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          suffixText: habit.unit ?? '',
                          hintText: '输入数值',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        double val =
                            double.tryParse(_inputController.text) ?? 0.0;
                        double step = habit.habitType == 'duration'
                            ? 15.0
                            : (habit.unit == '毫升'
                                  ? 250.0
                                  : (habit.unit == '页' ? 5.0 : 1.0));
                        val = val + step;
                        _inputController.text = val.toStringAsFixed(0);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
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

  Widget _buildSlideButton(HabitProvider habitProvider) => Container(
    height: 60,
    width: 250,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(30),
    ),
    child: Stack(
      children: [
        // 背景轨道
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),

        // 已滑过的进度
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
                  color: widget.accentColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            );
          },
        ),

        // 滑动按钮
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) => Positioned(
            left: _slideAnimation.value * 200,
            top: 5,
            child: GestureDetector(
              onPanUpdate: (details) {
                final progress = details.localPosition.dx / 200;
                _slideController.value = progress.clamp(0.0, 1.0);
              },
              onPanEnd: (details) {
                if (_slideController.value > 0.8) {
                  _slideController.forward().then((_) async {
                    await habitProvider.checkIn(
                      widget.habit,
                      value: double.tryParse(_inputController.text),
                    );
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
                  _slideController.reverse();
                }
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ),
          ),
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
