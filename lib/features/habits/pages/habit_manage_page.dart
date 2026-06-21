import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/features/habits/widgets/edit_habit_dialog.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:provider/provider.dart';

class HabitManagePage extends StatefulWidget {
  const HabitManagePage({super.key});

  @override
  State<HabitManagePage> createState() => _HabitManagePageState();
}

class _HabitManagePageState extends State<HabitManagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯管理'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.archive_outlined, color: Colors.white),
            label: const Text('已归档', style: TextStyle(color: Colors.white)),
            onPressed: () => context.push('/habits/manage/archived'),
          ),
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          final habits = habitProvider.activeHabits;

          if (habits.isEmpty) {
            return const Center(
              child: Text(
                '没有进行中的习惯',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ReorderableListView.builder(
            itemCount: habits.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final Habit item = habits.removeAt(oldIndex);
                habits.insert(newIndex, item);
                habitProvider.reorderHabits(habits);
              });
            },
            itemBuilder: (context, index) {
              final habit = habits[index];
              return ListTile(
                key: ValueKey('manage_${habit.id}'),
                leading: const Icon(Icons.drag_handle, color: Colors.grey),
                title: Text(
                  habit.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('目标：每日打卡 ${habit.checkInCount} 次'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => EditHabitDialog.show(context, habit),
                    ),
                    IconButton(
                      icon: const Icon(Icons.archive, color: Colors.orange),
                      onPressed: () async {
                        final confirmed = await _showConfirmDialog(
                          context,
                          '归档习惯',
                          '确定要归档习惯"${habit.name}"吗？归档后将不再显示在今日打卡中。',
                        );
                        if (confirmed == true) {
                          habitProvider.archiveHabit(habit.id);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await _showConfirmDialog(
                          context,
                          '彻底删除习惯',
                          '确定要彻底删除习惯"${habit.name}"吗？这将删除其所有历史打卡统计记录！',
                        );
                        if (confirmed == true) {
                          habitProvider.deleteHabit(habit.id);
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
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    return showDialog<bool>(
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
}
