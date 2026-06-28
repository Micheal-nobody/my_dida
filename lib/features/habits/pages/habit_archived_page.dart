import 'package:flutter/material.dart';
import 'package:my_dida/core/utils/time_utils.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:provider/provider.dart';

class HabitArchivedPage extends StatelessWidget {
  const HabitArchivedPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('已归档的习惯'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    body: Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final habits = habitProvider.archivedHabits;

        if (habits.isEmpty) {
          return const Center(
            child: Text(
              '没有已归档的习惯',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];
            return ListTile(
              title: Text(
                habit.name,
                style: const TextStyle(
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              subtitle: Text(
                '开始日期：${DateTimeUtils.formatDate(habit.startDate)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.unarchive, color: Colors.green),
                    onPressed: () async {
                      final confirmed = await _showConfirmDialog(
                        context,
                        '恢复习惯',
                        '确定要恢复习惯"${habit.name}"吗？恢复后将重新进入主打卡列表中。',
                      );
                      if (confirmed == true) {
                        await habitProvider.unarchiveHabit(habit.id);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () async {
                      final confirmed = await _showConfirmDialog(
                        context,
                        '彻底删除归档习惯',
                        '确定要彻底删除已归档的习惯"${habit.name}"吗？所有历史数据都会消失！',
                      );
                      if (confirmed == true) {
                        await habitProvider.deleteHabit(habit.id);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String content,
  ) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
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
  );
}
