import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/repeat_pattern.dart';
import 'package:my_dida/provider/checklist_provider.dart';
import 'package:my_dida/utils/time_formatter.dart';
import 'package:provider/provider.dart';

/// 用于在操作详情中渲染Task的组件
class OperationTaskRenderer extends StatelessWidget {
  const OperationTaskRenderer({
    required this.task,
    super.key,
    this.isPreviousData = false,
  });

  final Task task;
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
        width: 1,
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
            // 完成状态图标
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: task.isDone ? Colors.green : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: task.isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            // 任务名称
            Expanded(
              child: Text(
                task.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: task.isDone ? Colors.grey[600] : null,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            // 状态标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: task.isDone ? Colors.green[100] : Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.isDone ? '已完成' : '进行中',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: task.isDone ? Colors.green[700] : Colors.blue[700],
                ),
              ),
            ),
          ],
        ),

        // 描述
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            task.description,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],

        // 时间信息
        if (task.startTime != null || task.endTime != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                _formatTimeInfo(),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],

        // 检查点
        if (task.checkpoints.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '检查点 (${task.checkpoints.where((cp) => cp.isDone).length}/${task.checkpoints.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ...task.checkpoints.map(
            (checkpoint) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    checkpoint.isDone
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: checkpoint.isDone ? Colors.green : Colors.grey[400],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      checkpoint.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: checkpoint.isDone ? Colors.grey[600] : null,
                        decoration: checkpoint.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // 重复规则
        if (!task.rrule.isNone) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '重复任务',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],

        // 所属收集箱
        if (task.checklistId != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.folder, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Consumer<ChecklistProvider>(
                builder: (context, provider, child) {
                  final box = provider.allCheckLists
                      .where((b) => b.id == task.checklistId)
                      .firstOrNull;
                  return Text(
                    '收集箱: ${box?.name ?? '未知'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  );
                },
              ),
            ],
          ),
        ],
      ],
    ),
  );

  String _formatTimeInfo() {
    if (task.startTime != null && task.endTime != null) {
      return '${TimeFormatter.formatTaskDate(task.startTime!)} - ${TimeFormatter.formatTaskDate(task.endTime!)}';
    } else if (task.startTime != null) {
      return '开始: ${TimeFormatter.formatTaskDate(task.startTime!)}';
    } else if (task.endTime != null) {
      return '结束: ${TimeFormatter.formatTaskDate(task.endTime!)}';
    }
    return '';
  }
}
