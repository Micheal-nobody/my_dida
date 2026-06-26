import 'dart:math';

import 'package:flutter/material.dart';
import 'package:my_dida/features/habits/models/habit_check_in_record.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:my_dida/features/habits/widgets/habit_summary_painters.dart';

class HabitMonthSummarySection extends StatelessWidget {
  const HabitMonthSummarySection({
    required this.allRecords,
    required this.provider,
    super.key,
  });
  final List<HabitCheckInRecord> allRecords;
  final HabitProvider provider;

  @override
  Widget build(BuildContext context) {
    final activeHabits = provider.activeHabits;

    // 统计最近 35 天的每天打卡次数，画热力图网格 (7行 x 5列)
    final now = DateTime.now();
    final startOfGrid = now.subtract(const Duration(days: 34)); // 总共 35 天
    final List<int> gridCounts = List.filled(35, 0);

    for (int i = 0; i < 35; i++) {
      final date = startOfGrid.add(Duration(days: i));
      final dayRecords = allRecords
          .where(
            (r) =>
                !r.isSkip &&
                r.checkInTime.year == date.year &&
                r.checkInTime.month == date.month &&
                r.checkInTime.day == date.day,
          )
          .toList();
      gridCounts[i] = dayRecords.length;
    }

    // 历史累计总打卡次数
    int totalCheckIn = 0;
    int longestStreak = 0;
    for (final h in activeHabits) {
      totalCheckIn += h.totalCheckInCount;
      longestStreak = max(longestStreak, h.longestContinuousCheckInDays);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        '历史总打卡',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$totalCheckIn 次',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        '最长连续习惯流',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$longestStreak 天',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
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
            '月度打卡热力图 (最近35天)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 260,
              height: 180,
              child: CustomPaint(
                size: const Size(260, 180),
                painter: HeatmapGridPainter(counts: gridCounts),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '少  ',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              _buildColorBox(Colors.grey.shade100),
              const SizedBox(width: 4),
              _buildColorBox(Colors.orange.shade100),
              const SizedBox(width: 4),
              _buildColorBox(Colors.orange.shade300),
              const SizedBox(width: 4),
              _buildColorBox(Colors.orange.shade500),
              const SizedBox(width: 4),
              _buildColorBox(Colors.orange.shade800),
              const Text(
                '  多',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorBox(Color color) => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
