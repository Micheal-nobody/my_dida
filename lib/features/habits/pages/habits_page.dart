import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:my_dida/features/habits/widgets/add_habit_dialog.dart';
import 'package:my_dida/features/habits/widgets/edit_habit_dialog.dart';
import 'package:my_dida/features/habits/widgets/habit_card.dart';
import 'package:my_dida/features/habits/widgets/habit_check_in_dialog.dart';
import 'package:my_dida/features/habits/widgets/habit_visible_range_dialog.dart';
import 'package:provider/provider.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  @override
  Widget build(BuildContext context) {
    final colorTheme = context.theme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯'),
        backgroundColor: colorTheme.primary,
        foregroundColor: colorTheme.textOnPrimary,
        actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart),
          onPressed: () => context.push('/habits/summary'),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => context.push('/habits/manage'),
        ),
        IconButton(
          icon: const Icon(Icons.filter_alt),
          onPressed: () => HabitVisibleRangeDialog.show(context),
        ),
      ],
    ),

    body: Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final habits = habitProvider.habits;

        if (habits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_outline, size: 80, color: colorTheme.textSecondary),
                const SizedBox(height: 16),
                Text(
                  '还没有创建任何习惯',
                  style: TextStyle(fontSize: 18, color: colorTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击右下角的 + 按钮创建第一个习惯吧！',
                  style: TextStyle(fontSize: 14, color: colorTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: habits.length,
          itemBuilder: (context, index) => HabitCard(
            habit: habits[index],
            progress: habitProvider.getTodayProgress(habits[index]),
            isCompleted: habitProvider.isTodayCompleted(habits[index]),
            isSkipped: habits[index].isTodaySkipped,
            onTap: () {
              HabitCheckInDialog.show(context: context, habit: habits[index]);
            },
            onSkip: () async {
              final confirmed = await showDialog<bool>(
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
              );
              if (confirmed == true) {
                habitProvider.skipToday(habits[index]);
              }
            },
            onEdit: () {
              EditHabitDialog.show(context, habits[index]);
            },
          ),
        );
      },
    ),

    floatingActionButton: FloatingActionButton(
      onPressed: () {
        AddHabitDialog.show(context);
      },
      backgroundColor: colorTheme.primary,
      child: Icon(Icons.add, color: colorTheme.textOnPrimary),
    ),
  );
}
}
