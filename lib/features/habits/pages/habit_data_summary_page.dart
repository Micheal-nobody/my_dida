import 'dart:math';
import 'package:flutter/material.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/habits/models/habit_check_in_record.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:provider/provider.dart';

class HabitDataSummaryPage extends StatefulWidget {
  const HabitDataSummaryPage({super.key});

  @override
  State<HabitDataSummaryPage> createState() => _HabitDataSummaryPageState();
}

class _HabitDataSummaryPageState extends State<HabitDataSummaryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<HabitCheckInRecord> _allRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final provider = context.read<HabitProvider>();
    final records = await provider.getAllRecords();
    setState(() {
      _allRecords = records;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('打卡数据统计'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '日汇总'),
            Tab(text: '周汇总'),
            Tab(text: '月汇总'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDaySummary(),
                _buildWeekSummary(),
                _buildMonthSummary(),
              ],
            ),
    );
  }

  // ==========================================
  // 1. 日汇总 (data_day_summary.jpg)
  // ==========================================
  Widget _buildDaySummary() {
    final provider = context.watch<HabitProvider>();
    final activeHabits = provider.activeHabits;
    final today = DateTime.now();

    // 筛选今日打卡流水
    final todayRecords = _allRecords.where((r) {
      return r.checkInTime.year == today.year &&
          r.checkInTime.month == today.month &&
          r.checkInTime.day == today.day;
    }).toList();

    // 计算今日打卡完成度
    final completedCount = activeHabits
        .where((h) => provider.isTodayCompleted(h))
        .length;
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
          todayRecords.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      '今天还没有打卡记录',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
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

                    final timeStr =
                        '${record.checkInTime.hour.toString().padLeft(2, '0')}:${record.checkInTime.minute.toString().padLeft(2, '0')}';
                    return ListTile(
                      leading: Icon(
                        record.isSkip ? Icons.skip_next : Icons.check,
                        color: record.isSkip ? Colors.amber : Colors.blue,
                      ),
                      title: Text(
                        record.isSkip
                            ? '跳过了习惯 "$habitName"'
                            : '打卡习惯 "$habitName"',
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

  // ==========================================
  // 2. 周汇总 (data_week_summary.jpg)
  // ==========================================
  Widget _buildWeekSummary() {
    final provider = context.watch<HabitProvider>();
    final activeHabits = provider.activeHabits;

    // 统计本周每一天的完成次数
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final List<double> weeklyCompletionRate = List.filled(7, 0.0);

    // 过去7天每日完成状态
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dayRecords = _allRecords.where((r) {
        return !r.isSkip &&
            r.checkInTime.year == date.year &&
            r.checkInTime.month == date.month &&
            r.checkInTime.day == date.day;
      }).toList();

      // 如果有习惯需要在这天打卡，计算打卡总次数或打卡率
      if (activeHabits.isNotEmpty) {
        int checkInCount = dayRecords.length;
        int targetTotal = activeHabits
            .map((e) => e.checkInCount)
            .reduce((a, b) => a + b);
        weeklyCompletionRate[i] = targetTotal == 0
            ? 0.0
            : (checkInCount / targetTotal).clamp(0.0, 1.0);
      }
    }

    // 本周总打卡次数
    final thisWeekRecords = _allRecords.where((r) {
      return !r.isSkip && r.checkInTime.isAfter(startOfWeek);
    }).length;

    // 习惯本周排行榜
    final Map<int, int> habitCounts = {};
    for (var r in _allRecords) {
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
              painter: _WeekBarChartPainter(rates: weeklyCompletionRate),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '本周打卡排行榜',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          sortedRank.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      '本周暂无排行榜数据',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
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

  // ==========================================
  // 3. 月汇总 (data_mouth_summary.jpg)
  // ==========================================
  Widget _buildMonthSummary() {
    final provider = context.watch<HabitProvider>();
    final activeHabits = provider.activeHabits;

    // 统计最近 35 天的每天打卡次数，画热力图网格 (7行 x 5列)
    final now = DateTime.now();
    final startOfGrid = now.subtract(const Duration(days: 34)); // 总共 35 天
    final List<int> gridCounts = List.filled(35, 0);

    for (int i = 0; i < 35; i++) {
      final date = startOfGrid.add(Duration(days: i));
      final dayRecords = _allRecords.where((r) {
        return !r.isSkip &&
            r.checkInTime.year == date.year &&
            r.checkInTime.month == date.month &&
            r.checkInTime.day == date.day;
      }).toList();
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
                painter: _HeatmapGridPainter(counts: gridCounts),
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

  Widget _buildColorBox(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ==========================================
// A. 周趋势柱状图 Painter
// ==========================================
class _WeekBarChartPainter extends CustomPainter {
  _WeekBarChartPainter({required this.rates});
  final List<double> rates;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final stepX = width / 7;

    final bgPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..color = Colors.green.shade300
      ..style = PaintingStyle.fill;

    final activeFillPaint = Paint()
      ..color = Colors.green.shade500
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    for (int i = 0; i < 7; i++) {
      final double x = i * stepX + (stepX - 22) / 2;
      final double maxBarHeight = height - 30;

      // 绘制背景圆角矩形
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 10, 22, maxBarHeight),
          const Radius.circular(4),
        ),
        bgPaint,
      );

      // 绘制达成率填充高度
      final rate = rates[i];
      if (rate > 0) {
        final barHeight = maxBarHeight * rate;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 10 + (maxBarHeight - barHeight), 22, barHeight),
            const Radius.circular(4),
          ),
          rate >= 0.8 ? activeFillPaint : fillPaint,
        );
      }

      // 绘制星期文字
      textPainter.text = TextSpan(
        text: weekdays[i],
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(i * stepX + (stepX - textPainter.width) / 2, height - 16),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// B. 月度打卡热力图 (GitHub Contribution Grid 样式) Painter
// ==========================================
class _HeatmapGridPainter extends CustomPainter {
  _HeatmapGridPainter({required this.counts});
  final List<int> counts;

  @override
  void paint(Canvas canvas, Size size) {
    const double sizeBox = 26;
    const double spacing = 6;

    // 绘制 5 列 x 7 行 (代表 35 天)
    // 每一列是一个星期的 7 天
    for (int col = 0; col < 5; col++) {
      for (int row = 0; row < 7; row++) {
        final index = col * 7 + row;
        if (index >= counts.length) continue;

        final count = counts[index];
        Color color = Colors.grey.shade100;
        if (count > 0) {
          if (count == 1) {
            color = Colors.orange.shade100;
          } else if (count == 2) {
            color = Colors.orange.shade300;
          } else if (count <= 4) {
            color = Colors.orange.shade500;
          } else {
            color = Colors.orange.shade800;
          }
        }

        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        final double x = col * (sizeBox + spacing) + 20;
        final double y = row * (sizeBox + spacing) + 10;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, sizeBox, sizeBox),
            const Radius.circular(4),
          ),
          paint,
        );
      }
    }

    // 绘制横向行首的星期缩写，比如周一、周三、周五
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final weekdayLabels = ['一', '', '三', '', '五', '', '日'];
    for (int r = 0; r < 7; r++) {
      if (weekdayLabels[r].isNotEmpty) {
        textPainter.text = TextSpan(
          text: weekdayLabels[r],
          style: const TextStyle(color: Colors.grey, fontSize: 9),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            2,
            r * (sizeBox + spacing) + 10 + (sizeBox - textPainter.height) / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
