import 'package:flutter/material.dart';
import 'package:my_dida/features/habits/models/habit_check_in_record.dart';
import 'package:my_dida/features/habits/providers/habit_provider.dart';
import 'package:my_dida/features/habits/widgets/habit_day_summary_section.dart';
import 'package:my_dida/features/habits/widgets/habit_month_summary_section.dart';
import 'package:my_dida/features/habits/widgets/habit_week_summary_section.dart';
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
  Widget build(BuildContext context) => Scaffold(
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
              HabitDaySummarySection(
                allRecords: _allRecords,
                provider: context.watch<HabitProvider>(),
              ),
              HabitWeekSummarySection(
                allRecords: _allRecords,
                provider: context.watch<HabitProvider>(),
              ),
              HabitMonthSummarySection(
                allRecords: _allRecords,
                provider: context.watch<HabitProvider>(),
              ),
            ],
          ),
  );
}
