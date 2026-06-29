import 'package:flutter/material.dart';
import 'package:my_dida/core/constants/ui_constants.dart';
import 'package:my_dida/features/checklist/models/checklist_vo.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:my_dida/features/habits/widgets/edit_habit_dialog.dart';
import 'package:my_dida/features/habits/widgets/habit_card.dart';
import 'package:my_dida/features/habits/widgets/habit_check_in_dialog.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/widgets/grouped_task_section.dart';
import 'package:provider/provider.dart';

class TaskListView extends StatelessWidget {
  const TaskListView({
    required this.groupedTasks,
    required this.allChecklists,
    required this.currentChecklist,
    required this.isTodayTasks,
    super.key,
  });

  final Map<String, List<Task>> groupedTasks;
  final List<ChecklistVO> allChecklists;
  final ChecklistVO currentChecklist;
  final bool isTodayTasks;

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final habitProvider = Provider.of<HabitProvider>(context);

    final List<Widget> groupWidgets = [];

    // 1. 添加任务分组组件
    groupedTasks.forEach((groupTitle, tasks) {
      if (tasks.isEmpty) return;

      groupWidgets.add(
        GroupedTaskSection(
          groupTitle: groupTitle,
          tasks: tasks,
          allChecklists: allChecklists,
          currentChecklist: currentChecklist,
        ),
      );
    });

    // 2. 添加习惯分组组件 (若为今天清单且有习惯)
    if (isTodayTasks && habitProvider.habits.isNotEmpty) {
      final habits = habitProvider.habits;
      final List<Widget> habitCards = [];

      for (final habit in habits) {
        final isCompleted = habitProvider.isTodayCompleted(habit);
        if (taskProvider.visibleRange == TaskVisibleRange.undone &&
            isCompleted) {
          continue;
        }
        if (taskProvider.visibleRange == TaskVisibleRange.done &&
            !isCompleted) {
          continue;
        }

        habitCards.add(
          HabitCard(
            habit: habit,
            progress: habitProvider.getTodayProgress(habit),
            isCompleted: isCompleted,
            onTap: () {
              HabitCheckInDialog.show(context: context, habit: habit);
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
                await habitProvider.skipToday(habit);
              }
            },
            onEdit: () {
              EditHabitDialog.show(context, habit);
            },
          ),
        );
      }

      if (habitCards.isNotEmpty) {
        groupWidgets.add(
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              title: Row(
                children: [
                  const Text(
                    UIStrings.habits,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${habitCards.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              children: habitCards,
            ),
          ),
        );
      }
    }

    // 3. 空白占位处理
    if (groupWidgets.isEmpty) {
      return const Center(
        child: Text(
          '暂无任务',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // 4. 返回滑动列表
    return ListView.builder(
      itemCount: groupWidgets.length,
      itemBuilder: (context, index) => groupWidgets[index],
    );
  }
}
