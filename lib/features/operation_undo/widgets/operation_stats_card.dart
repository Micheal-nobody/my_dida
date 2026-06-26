import 'package:flutter/material.dart';
import 'package:my_dida/features/operation_undo/providers/operation_stack_provider.dart';

class OperationStatsCard extends StatelessWidget {
  const OperationStatsCard({required this.operationStack, super.key});
  final OperationStackProvider operationStack;

  @override
  Widget build(BuildContext context) {
    final stats = operationStack.getOperationStats();
    final totalOperations = operationStack.operations.length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withValues(alpha: 0.05),
                Theme.of(context).primaryColor.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.analytics,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '操作统计',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        '总操作',
                        totalOperations.toString(),
                        Icons.history,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        '任务',
                        (stats['task_add'] ?? 0) +
                            (stats['task_update'] ?? 0) +
                            (stats['task_delete'] ?? 0),
                        Icons.task,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        '习惯',
                        (stats['habit_add'] ?? 0) +
                            (stats['habit_update'] ?? 0) +
                            (stats['habit_delete'] ?? 0),
                        Icons.psychology,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        '清单',
                        (stats['checklist_add'] ?? 0) +
                            (stats['checklist_update'] ?? 0) +
                            (stats['checklist_delete'] ?? 0),
                        Icons.list,
                        Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    dynamic value,
    IconData icon,
    Color color,
  ) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
