import 'package:flutter/material.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/habits/models/habit_check_in_record.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:my_dida/features/habits/widgets/habit_summary_painters.dart';

class HabitWeekSummarySection extends StatelessWidget {
  final List<HabitCheckInRecord> allRecords;
  final HabitProvider provider;

  const HabitWeekSummarySection({
    super.key,
    required this.allRecords,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final activeHabits = provider.activeHabits;

    // 统计本周每一天的完成次数
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final List<double> weeklyCompletionRate = List.filled(7, 0.0);

    // 过去7天每日完成状态
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dayRecords = allRecords
          .where(
            (r) =>
                !r.isSkip &&
                r.checkInTime.year == date.year &&
                r.checkInTime.month == date.month &&
                r.checkInTime.day == date.day,
          )
          .toList();

      // 如果有习惯需要在这天打卡，计算打卡总次数或打卡率
      if (activeHabits.isNotEmpty) {
        final int checkInCount = dayRecords.length;
        final int targetTotal = activeHabits
            .map((e) => e.checkInCount)
            .reduce((a, b) => a + b);
        weeklyCompletionRate[i] = targetTotal == 0
            ? 0.0
            : (checkInCount / targetTotal).clamp(0.0, 1.0);
      }
    }

    // 本周总打卡次数
    final thisWeekRecords = allRecords
        .where((r) => !r.isSkip && r.checkInTime.isAfter(startOfWeek))
        .length;

    // 习惯本周排行榜
    final Map<int, int> habitCounts = {};
    for (final r in allRecords) {
      if (!r.isSkip && r.checkInTime.isAfter(startOfWeek)) {
        habitCounts[r.habitId] = (habitCounts[r.habitId] ?? 0) + 1;
      }
    }
    final sortedRank = habitCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        '本周累计打卡',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$thisWeekRecords 次',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        '进行中习惯',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${activeHabits.length} 个',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
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
            '本周打卡走势图 (打卡达成率)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: WeekBarChartPainter(rates: weeklyCompletionRate),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '本周打卡排行榜',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (sortedRank.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('本周暂无排行榜数据', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedRank.length,
              itemBuilder: (context, index) {
                final entry = sortedRank[index];
                final habitName = activeHabits
                    .firstWhere(
                      (h) => h.id == entry.key,
                      orElse: () => Habit(
                        name: '已删除习惯',
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
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                  title: Text(
                    habitName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    '本周打卡 ${entry.value} 次',
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
