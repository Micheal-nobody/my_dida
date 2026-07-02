import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/tomato/models/tomato_record.dart';
import 'package:my_dida/features/tomato/providers/tomato_provider.dart';
import 'package:my_dida/features/tomato/widgets/tomato_charts.dart';
import 'package:provider/provider.dart';

class TomatoSummaryPage extends StatefulWidget {
  const TomatoSummaryPage({super.key});

  @override
  State<TomatoSummaryPage> createState() => _TomatoSummaryPageState();
}

class _TomatoSummaryPageState extends State<TomatoSummaryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TomatoProvider>();
    final colorTheme = context.theme;

    return Scaffold(
      backgroundColor: colorTheme.surface,
      appBar: AppBar(
        title: const Text(
          '专注数据统计',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorTheme.background,
        foregroundColor: colorTheme.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorTheme.primary,
          unselectedLabelColor: colorTheme.textSecondary,
          indicatorColor: colorTheme.primary,
          tabs: const [
            Tab(text: '本日'),
            Tab(text: '本周'),
            Tab(text: '本月'),
            Tab(text: '总览'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. 本日
          _buildDayView(provider),
          // 2. 本周
          _buildWeekView(provider),
          // 3. 本月
          _buildMonthView(provider),
          // 4. 总览
          _buildAllView(provider),
        ],
      ),
    );
  }

  // 本日视图
  Widget _buildDayView(TomatoProvider provider) =>
      FutureBuilder<Map<String, dynamic>>(
        future: provider.getSummaryData(_today),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final List<TomatoRecord> records = List<TomatoRecord>.from(
            data['records'] ?? [],
          );
          final completedCount = data['completedCount'] as int;
          final totalMinutes = data['totalMinutes'] as int;

          return _buildScrollContent(
            records: records,
            completedCount: completedCount,
            totalMinutes: totalMinutes,
            children: [
              TomatoHourlyDistributionChart(records: records),
              const SizedBox(height: 16),
              TomatoCategoryRatioChart(records: records),
            ],
          );
        },
      );

  // 本周视图
  Widget _buildWeekView(TomatoProvider provider) =>
      FutureBuilder<List<TomatoRecord>>(
        future: provider.getWeeklyRecords(_today),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data!;
          final completed = records.where((r) => r.isCompleted).toList();
          final completedCount = completed.length;
          final totalMinutes = completed.fold(
            0,
            (sum, r) => sum + r.durationMinutes,
          );

          return _buildScrollContent(
            records: records,
            completedCount: completedCount,
            totalMinutes: totalMinutes,
            children: [
              TomatoTrendChart(records: records, daysCount: 7),
              const SizedBox(height: 16),
              TomatoCategoryRatioChart(records: records),
            ],
          );
        },
      );

  // 本月视图
  Widget _buildMonthView(TomatoProvider provider) =>
      FutureBuilder<List<TomatoRecord>>(
        future: provider.getMonthlyRecords(_today),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data!;
          final completed = records.where((r) => r.isCompleted).toList();
          final completedCount = completed.length;
          final totalMinutes = completed.fold(
            0,
            (sum, r) => sum + r.durationMinutes,
          );

          return _buildScrollContent(
            records: records,
            completedCount: completedCount,
            totalMinutes: totalMinutes,
            children: [
              TomatoTrendChart(records: records, daysCount: 30),
              const SizedBox(height: 16),
              TomatoCategoryRatioChart(records: records),
            ],
          );
        },
      );

  // 总览视图
  Widget _buildAllView(TomatoProvider provider) =>
      FutureBuilder<List<TomatoRecord>>(
        future: provider.getAllRecords(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data!;
          final completed = records.where((r) => r.isCompleted).toList();
          final completedCount = completed.length;
          final totalMinutes = completed.fold(
            0,
            (sum, r) => sum + r.durationMinutes,
          );

          return _buildScrollContent(
            records: records,
            completedCount: completedCount,
            totalMinutes: totalMinutes,
            children: [TomatoCategoryRatioChart(records: records)],
          );
        },
      );

  // 通用的可滚动组件列表构建
  Widget _buildScrollContent({
    required List<TomatoRecord> records,
    required int completedCount,
    required int totalMinutes,
    required List<Widget> children,
  }) {
    final provider = context.read<TomatoProvider>();
    final colorTheme = context.theme;
    final totalCount = records.length;
    final double completionRate = totalCount == 0
        ? 0.0
        : (completedCount / totalCount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 核心指标数据面板
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                '完成番茄',
                '$completedCount',
                '个',
                colorTheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                '专注时长',
                '$totalMinutes',
                '分钟',
                colorTheme.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                '番茄完成率',
                (completionRate * 100).toStringAsFixed(0),
                '%',
                colorTheme.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 外部传入的不同维度的图表
        ...children,
        const SizedBox(height: 20),

        // 各番茄钟专注明细
        if (provider.customTomatoes.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: colorTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorTheme.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '各预设番茄钟统计',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.customTomatoes.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tomato = provider.customTomatoes[index];
                    return FutureBuilder<Map<String, dynamic>>(
                      future: provider.getCustomTomatoTotalStats(tomato.id),
                      builder: (context, snapshot) {
                        final stats = snapshot.data;
                        final count = stats?['completedCount'] ?? 0;
                        final minutes = stats?['totalMinutes'] ?? 0;

                        return ListTile(
                          leading: Icon(
                            Icons.hourglass_full_rounded,
                            color: colorTheme.primary,
                            size: 20,
                          ),
                          title: Text(
                            tomato.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '单次时长: ${tomato.focusMinutes}分钟',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorTheme.textSecondary,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '完成 $count 次',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '累计 $minutes分钟',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 历史明细记录
        Container(
          decoration: BoxDecoration(
            color: colorTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorTheme.textPrimary.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '专注历史明细',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              if (records.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      '暂无历史专注记录',
                      style: TextStyle(color: colorTheme.textSecondary),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    // 按倒序排列，展示最新记录
                    final record = records[records.length - 1 - index];
                    return _buildRecordTile(context, record);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // 单个指标卡片
  Widget _buildMetricCard(String title, String val, String unit, Color color) {
    final colorTheme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: colorTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorTheme.textPrimary.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, color: colorTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                val,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(fontSize: 9, color: colorTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 历史明细瓦片
  Widget _buildRecordTile(BuildContext context, TomatoRecord record) {
    final colorTheme = context.theme;
    final dateStr = DateFormat('MM-dd HH:mm').format(record.startTime);
    final taskName = record.taskName ?? '无关联任务';
    final checklistName = record.categoryName ?? '默认收集箱';

    return ListTile(
      leading: Icon(
        record.isCompleted ? Icons.check_circle : Icons.cancel,
        color: record.isCompleted
            ? colorTheme.success
            : colorTheme.textSecondary,
        size: 20,
      ),
      title: Text(
        taskName,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: record.isCompleted
              ? colorTheme.textPrimary
              : colorTheme.textSecondary,
          decoration: record.isCompleted ? null : TextDecoration.lineThrough,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          children: [
            Text(
              checklistName,
              style: TextStyle(fontSize: 11, color: colorTheme.primary),
            ),
            const SizedBox(width: 8),
            Text(
              dateStr,
              style: TextStyle(fontSize: 11, color: colorTheme.textSecondary),
            ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${record.durationMinutes}分钟',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: record.isCompleted
                  ? colorTheme.textPrimary
                  : colorTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: colorTheme.textSecondary,
            ),
            onPressed: () => _confirmDelete(context, record),
          ),
        ],
      ),
    );
  }

  // 确认删除历史记录
  Future<void> _confirmDelete(BuildContext context, TomatoRecord record) async {
    final colorTheme = context.theme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除专注记录'),
        content: const Text('确定要永久删除这条专注历史记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorTheme.deleteButton,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final provider = context.read<TomatoProvider>();
      await provider.deleteRecord(record.id);
      setState(() {}); // 刷新页面
    }
  }
}
