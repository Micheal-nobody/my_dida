import 'package:flutter/material.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/core/utils/time_formatter.dart';

/// 用于在操作详情中渲染Habit的组件
class OperationHabitRenderer extends StatelessWidget {
  final Habit habit;
  final bool isPreviousData;

  const OperationHabitRenderer({
    super.key,
    required this.habit,
    this.isPreviousData = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: _getIconColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getIconData(), color: _getIconColor(), size: 20),
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
                  color: _getStatusColor().withOpacity(0.1),
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
            valueColor: AlwaysStoppedAnimation<Color>(_getIconColor()),
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
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
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
  }

  IconData _getIconData() {
    const iconMap = {
      'brush': Icons.brush,
      'fitness': Icons.fitness_center,
      'book': Icons.book,
      'water': Icons.water_drop,
      'sleep': Icons.bedtime,
      'food': Icons.restaurant,
      'meditation': Icons.self_improvement,
      'walk': Icons.directions_walk,
      'music': Icons.music_note,
    };
    return iconMap[habit.icon] ?? Icons.star;
  }

  Color _getIconColor() {
    const colorMap = {
      'brush': Colors.blue,
      'fitness': Colors.orange,
      'book': Colors.green,
      'water': Colors.cyan,
      'sleep': Colors.purple,
      'food': Colors.red,
      'meditation': Colors.indigo,
      'walk': Colors.teal,
      'music': Colors.pink,
    };
    return colorMap[habit.icon] ?? Colors.amber;
  }

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
