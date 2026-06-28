import 'package:flutter/material.dart';
import 'package:my_dida/core/utils/time_formatter.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/habits/models/habit_check_in_record.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';

class HabitDaySummarySection extends StatelessWidget {
  const HabitDaySummarySection({
    required this.allRecords,
    required this.provider,
    super.key,
  });
  final List<HabitCheckInRecord> allRecords;
  final HabitProvider provider;

  @override
  Widget build(BuildContext context) {
    final activeHabits = provider.activeHabits;
    final today = DateTime.now();

    // 筛选今日打卡流水
    final todayRecords = allRecords
        .where(
          (r) =>
              r.checkInTime.year == today.year &&
              r.checkInTime.month == today.month &&
              r.checkInTime.day == today.day,
        )
        .toList();

    // 计算今日打卡完成度
    final completedCount = activeHabits.where(provider.isTodayCompleted).length;
    final totalCount = activeHabits.length;
    final completionRate = totalCount == 0
        ? 0.0
        : (completedCount / totalCount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 概览卡片
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        '今日完成比例',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completedCount/$totalCount',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        '今日打卡率',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(completionRate * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '今日习惯清单',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...activeHabits.map((habit) {
            final isDone = provider.isTodayCompleted(habit);
            return ListTile(
              leading: Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isDone ? Colors.green : Colors.grey,
              ),
              title: Text(
                habit.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: habit.isTodaySkipped
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Text(
                habit.isTodaySkipped
                    ? '已跳过今天'
                    : '打卡进度: ${habit.currentCheckInCount}/${habit.checkInCount}',
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text(
            '今日打卡时间线',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (todayRecords.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('今天还没有打卡记录', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayRecords.length,
              itemBuilder: (context, index) {
                final record = todayRecords[index];
                final habitName = activeHabits
                    .firstWhere(
                      (h) => h.id == record.habitId,
                      orElse: () => Habit(
                        name: '未知习惯',
                        icon: '',
                        remindTime: DateTime.now(),
                        checkInCount: 1,
                        currentCheckInCount: 0,
                        startDate: DateTime.now(),
                        totalCheckInCount: 0,
                        longestContinuousCheckInDays: 0,
                      ),
                    )
                    .name;

                final timeStr = TimeFormatter.formatTimeOnly(
                  record.checkInTime,
                );
                return ListTile(
                  leading: Icon(
                    record.isSkip ? Icons.skip_next : Icons.check,
                    color: record.isSkip ? Colors.amber : Colors.blue,
                  ),
                  title: Text(
                    record.isSkip ? '跳过了习惯 "$habitName"' : '打卡习惯 "$habitName"',
                  ),
                  trailing: Text(
                    timeStr,
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
