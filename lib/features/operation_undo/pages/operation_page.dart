import 'package:flutter/material.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';
import 'package:my_dida/features/operation_undo/providers/operation_stack_provider.dart';
import 'package:my_dida/features/operation_undo/widgets/operation_detail_dialog.dart';
import 'package:my_dida/features/operation_undo/widgets/operation_filter_dialog.dart';
import 'package:my_dida/features/operation_undo/widgets/operation_stats_card.dart';
import 'package:provider/provider.dart';

class OperationPage extends StatefulWidget {
  const OperationPage({super.key});

  @override
  State<OperationPage> createState() => _OperationPageState();
}

class _OperationPageState extends State<OperationPage> {
  final AppMessageService _messageService = getIt<AppMessageService>();
  OperationType? _selectedType;
  OperationTarget? _selectedTarget;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('操作历史'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed: () => _showUndoDialog(context),
          tooltip: '撤回操作',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'clear':
                _showClearDialog(context);
                break;
              case 'filter':
                _showFilterDialog(context);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'filter',
              child: Row(
                children: [
                  Icon(Icons.filter_list),
                  SizedBox(width: 8),
                  Text('筛选'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.clear_all),
                  SizedBox(width: 8),
                  Text('清空历史'),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
    body: Consumer<OperationStackProvider>(
      builder: (context, operationStack, child) {
        final operations = _getFilteredOperations(operationStack.operations);
        if (operations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(Icons.history, size: 64, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),
                Text(
                  '暂无操作记录',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '开始使用应用后，操作记录将显示在这里',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 统计信息
            OperationStatsCard(operationStack: operationStack),

            // 操作列表
            Expanded(
              child: ListView.builder(
                itemCount: operations.length,
                itemBuilder: (context, index) {
                  final operation = operations[index];
                  return _buildOperationCard(operation, index);
                },
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _buildOperationCard(Operation operation, int index) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showOperationDetails(operation),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: index == 0
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.05),
                      Theme.of(context).primaryColor.withValues(alpha: 0.02),
                    ],
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部行：图标、标题、最新标签
              Row(
                children: [
                  // 操作图标
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getOperationColor(operation.type),
                          _getOperationColor(
                            operation.type,
                          ).withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _getOperationColor(
                            operation.type,
                          ).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getOperationIcon(operation.type),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 标题和描述
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          operation.description,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(operation.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 最新标签
                  if (index == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '最新',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // 操作类型和目标类型标签
              Row(
                children: [
                  _buildOperationChip(operation.type),
                  const SizedBox(width: 8),
                  _buildTargetChip(operation.target),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildOperationChip(OperationType type) {
    final colors = {
      OperationType.add: Colors.green,
      OperationType.update: Colors.blue,
      OperationType.delete: Colors.red,
    };

    final labels = {
      OperationType.add: '添加',
      OperationType.update: '更新',
      OperationType.delete: '删除',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[type]!.withValues(alpha: 0.1),
            colors[type]!.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[type]!.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getOperationIcon(type), size: 14, color: colors[type]),
          const SizedBox(width: 4),
          Text(
            labels[type]!,
            style: TextStyle(
              color: colors[type],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetChip(OperationTarget target) {
    final colors = {
      OperationTarget.task: Colors.orange,
      OperationTarget.habit: Colors.purple,
      OperationTarget.checklist: Colors.teal,
    };

    final labels = {
      OperationTarget.task: '任务',
      OperationTarget.habit: '习惯',
      OperationTarget.checklist: '清单',
    };
    final icons = {
      OperationTarget.task: Icons.task,
      OperationTarget.habit: Icons.psychology,
      OperationTarget.checklist: Icons.list,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[target]!.withValues(alpha: 0.1),
            colors[target]!.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[target]!.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icons[target]!, size: 14, color: colors[target]),
          const SizedBox(width: 4),
          Text(
            labels[target]!,
            style: TextStyle(
              color: colors[target],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getOperationColor(OperationType type) {
    switch (type) {
      case OperationType.add:
        return Colors.green;
      case OperationType.update:
        return Colors.blue;
      case OperationType.delete:
        return Colors.red;
    }
  }

  IconData _getOperationIcon(OperationType type) {
    switch (type) {
      case OperationType.add:
        return Icons.add;
      case OperationType.update:
        return Icons.edit;
      case OperationType.delete:
        return Icons.delete;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  List<Operation> _getFilteredOperations(List<Operation> operations) =>
      operations.where((operation) {
        if (_selectedType != null && operation.type != _selectedType) {
          return false;
        }
        if (_selectedTarget != null && operation.target != _selectedTarget) {
          return false;
        }
        if (_startDate != null && operation.timestamp.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && operation.timestamp.isAfter(_endDate!)) {
          return false;
        }
        return true;
      }).toList();

  void _showUndoDialog(BuildContext context) {
    final operationStack = context.read<OperationStackProvider>();

    if (!operationStack.canUndo) {
      _messageService.showInfo('没有可撤回的操作');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('撤回操作'),
        content: const Text('确定要撤回最近的一次操作吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await operationStack.undo();
              if (success) {
                if (mounted) {
                  _messageService.showSuccess('操作已撤回');
                }
              } else {
                _messageService.showError('撤回失败');
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史'),
        content: const Text('确定要清空所有操作历史吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await context.read<OperationStackProvider>().clearOperations();
              if (mounted) {
                _messageService.showSuccess('操作历史已清空');
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => OperationFilterDialog(
        initialType: _selectedType,
        initialTarget: _selectedTarget,
        onFilterSelected: (type, target) {
          setState(() {
            _selectedType = type;
            _selectedTarget = target;
          });
        },
      ),
    );
  }

  void _showOperationDetails(Operation operation) {
    showDialog(
      context: context,
      builder: (context) => OperationDetailDialog(
        operation: operation,
        showSuccess: (msg) {
          if (mounted) _messageService.showSuccess(msg);
        },
        showError: (msg) {
          if (mounted) _messageService.showError(msg);
        },
      ),
    );
  }
}
