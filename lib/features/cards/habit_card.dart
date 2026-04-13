import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/habit.dart';
import 'package:my_dida/provider/habit_provider.dart';
import 'package:provider/provider.dart';

import '../dialogs/edit_habit_dialog.dart';
import '../dialogs/habit_check_in_dialog.dart';

class HabitCard extends StatefulWidget {
  const HabitCard(this.habit, {super.key});

  final Habit habit;

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  late final Habit habit;
  bool _isSkipped = false;

  // 根据图标名称返回对应的IconData
  static const iconMap = {
    'brush': Icons.brush,
    'fitness': Icons.fitness_center,
    'book': Icons.book,
    'water': Icons.water_drop,
    'sleep': Icons.bedtime,
    'food': Icons.restaurant,
    'meditation': Icons.self_improvement,
    'walk': Icons.directions_walk,
    'music': Icons.music_note,
  };

  @override
  void initState() {
    super.initState();
    habit = widget.habit;
  }

  @override
  Widget build(BuildContext context) => Consumer<HabitProvider>(
    builder: (context, habitProvider, child) {
      final isCompleted = habitProvider.isTodayCompleted(habit);
      final progress = habitProvider.getTodayProgress(habit);

      return Dismissible(
        key: Key('habit_${habit.id}'),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.skip_next, color: Colors.white, size: 30),
        ),
        secondaryBackground: Container(
          color: Colors.blue,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.edit, color: Colors.white, size: 30),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // 向左滑 - 跳过今天
            final confirmed = await _showSkipConfirmation();
            if (confirmed) {
              habitProvider.skipToday(habit);
              setState(() {
                _isSkipped = true;
              });
            }
            return false; // 不删除卡片，只更新状态
          } else if (direction == DismissDirection.endToStart) {
            // 向右滑 - 编辑习惯
            _showEditDialog();
            return false; // 不删除卡片
          }
          return false;
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: _isSkipped ? Colors.grey.withValues(alpha: 0.5) : null,
          child: ListTile(
            // 左侧图标和完成状态
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 习惯图标
                Icon(
                  iconMap[habit.icon] ?? Icons.star,
                  size: 24,
                  color: isCompleted ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                // 完成状态对号
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),

            // 习惯名称
            title: Text(
              habit.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isSkipped ? Colors.grey : null,
              ),
            ),

            // 进度条
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${habit.currentCheckInCount}/${habit.checkInCount}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),

            // 提醒时间
            trailing: Text(
              _formatTime(habit.remindTime),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),

            onTap: () {
              if (!_isSkipped) {
                HabitCheckInDialog.show(context: context, habit: habit);
              }
            },
          ),
        ),
      );
    },
  );

  Future<bool> _showSkipConfirmation() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('跳过今天'),
          content: const Text('确定要跳过今天的习惯吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定'),
            ),
          ],
        ),
      ) ??
      false;

  void _showEditDialog() {
    EditHabitDialog.show(context, habit);
  }

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
