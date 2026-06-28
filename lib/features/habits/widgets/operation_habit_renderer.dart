import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_dida/core/constants/icon_constants.dart';
import 'package:my_dida/core/utils/time_formatter.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/operation_undo/services/operation_data_renderer.dart';

/// 习惯数据渲染器实现
class HabitOperationDataRenderer implements OperationDataRenderer {
  @override
  Widget render(
    BuildContext context,
    String jsonData, {
    required bool isPreviousData,
  }) {
    try {
      final decoded = jsonDecode(jsonData);
      // 处理删除习惯操作中的嵌套 habit 数据，或者普通的 habit 数据
      final habitMap =
          decoded is Map<String, dynamic> && decoded.containsKey('habit')
          ? decoded['habit'] as Map<String, dynamic>
          : decoded as Map<String, dynamic>;

      final habit = Habit.fromJson(habitMap);
      return OperationHabitRenderer(
        habit: habit,
        isPreviousData: isPreviousData,
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          jsonData,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        ),
      );
    }
  }
}

/// 用于在操作详情中渲染Habit的组件
class OperationHabitRenderer extends StatelessWidget {
  const OperationHabitRenderer({
    required this.habit,
    super.key,
    this.isPreviousData = false,
  });

  final Habit habit;
  final bool isPreviousData;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isPreviousData
          ? Colors.grey[100]
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isPreviousData
            ? Colors.grey[300]!
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          children: [
            // 习惯图标
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: IconConstants.getIconColorByName(habit.icon).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  IconConstants.getIconByName(habit.icon) ?? Icons.star,
                  color: IconConstants.getIconColorByName(habit.icon),
                  size: 20,
                ),
              ),
            const SizedBox(width: 12),
            // 习惯名称
            Expanded(
              child: Text(
                habit.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // 状态标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 进度信息
        Row(
          children: [
            Icon(Icons.trending_up, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              '进度: ${habit.currentCheckInCount}/${habit.checkInCount}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 进度条
        LinearProgressIndicator(
          value: habit.checkInCount > 0
              ? habit.currentCheckInCount / habit.checkInCount
              : 0,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            IconConstants.getIconColorByName(habit.icon),
          ),
        ),

        const SizedBox(height: 12),

        // 统计信息
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                '总打卡',
                habit.totalCheckInCount.toString(),
                Icons.check_circle_outline,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                '最长连续',
                '${habit.longestContinuousCheckInDays}天',
                Icons.local_fire_department,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 提醒时间
        Row(
          children: [
            Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              '提醒时间: ${TimeFormatter.formatTimeOnly(habit.remindTime)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),

        // 开始日期
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              '开始日期: ${TimeFormatter.formatFullDate(habit.startDate)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),

        // 重复规则
        if (!habit.rrule.isNone) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '重复习惯',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _buildStatItem(String label, String value, IconData icon) => Column(
    children: [
      Icon(icon, size: 20, color: Colors.grey[600]),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ],
  );

  Color _getStatusColor() {
    final progress = habit.checkInCount > 0
        ? habit.currentCheckInCount / habit.checkInCount
        : 0;
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return Colors.blue;
  }

  String _getStatusText() {
    final progress = habit.checkInCount > 0
        ? habit.currentCheckInCount / habit.checkInCount
        : 0;
    if (progress >= 1.0) return '已完成';
    if (progress >= 0.5) return '进行中';
    return '未开始';
  }
}
