import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_dida/provider/OperationStackProvider.dart';
import 'package:my_dida/model/entity/Operation.dart';
import 'package:my_dida/provider/TaskProvider.dart';
import 'package:my_dida/provider/HabitProvider.dart';

class OperationPage extends StatefulWidget {
  const OperationPage({super.key});

  @override
  State<OperationPage> createState() => _OperationPageState();
}

class _OperationPageState extends State<OperationPage> {
  OperationType? _selectedType;
  OperationTarget? _selectedTarget;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '暂无操作记录',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 统计信息
              _buildStatsCard(operationStack),

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
  }

  Widget _buildStatsCard(OperationStackProvider operationStack) {
    final stats = operationStack.getOperationStats();
    final totalOperations = operationStack.operations.length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('操作统计', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '总操作',
                  totalOperations.toString(),
                  Icons.history,
                ),
                _buildStatItem(
                  '任务操作',
                  (stats['task_add'] ?? 0) +
                      (stats['task_update'] ?? 0) +
                      (stats['task_delete'] ?? 0),
                  Icons.task,
                ),
                _buildStatItem(
                  '习惯操作',
                  (stats['habit_add'] ?? 0) +
                      (stats['habit_update'] ?? 0) +
                      (stats['habit_delete'] ?? 0),
                  Icons.psychology,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildOperationCard(Operation operation, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getOperationColor(operation.type),
          child: Icon(_getOperationIcon(operation.type), color: Colors.white),
        ),
        title: Text(
          operation.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatTimestamp(operation.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildOperationChip(operation.type),
                const SizedBox(width: 8),
                _buildTargetChip(operation.target),
              ],
            ),
          ],
        ),
        trailing: index == 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '最新',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () => _showOperationDetails(operation),
      ),
    );
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors[type]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        labels[type]!,
        style: TextStyle(
          color: colors[type],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTargetChip(OperationTarget target) {
    final colors = {
      OperationTarget.task: Colors.orange,
      OperationTarget.habit: Colors.purple,
    };

    final labels = {OperationTarget.task: '任务', OperationTarget.habit: '习惯'};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors[target]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        labels[target]!,
        style: TextStyle(
          color: colors[target],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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

  List<Operation> _getFilteredOperations(List<Operation> operations) {
    return operations.where((operation) {
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
  }

  void _showUndoDialog(BuildContext context) {
    final operationStack = context.read<OperationStackProvider>();

    if (!operationStack.canUndo) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有可撤回的操作')));
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
                // 刷新相关Provider
                if (mounted) {
                  context.read<TaskProvider>().loadCurrentBoxTasks();
                  context.read<HabitProvider>().loadAllHabits();
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('操作已撤回')));
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('撤回失败')));
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('操作历史已清空')));
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('筛选操作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 操作类型筛选
              DropdownButtonFormField<OperationType?>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: '操作类型',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('全部')),
                  ...OperationType.values.map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_getOperationTypeLabel(type)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 目标类型筛选
              DropdownButtonFormField<OperationTarget?>(
                value: _selectedTarget,
                decoration: const InputDecoration(
                  labelText: '目标类型',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('全部')),
                  ...OperationTarget.values.map(
                    (target) => DropdownMenuItem(
                      value: target,
                      child: Text(_getOperationTargetLabel(target)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTarget = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedType = null;
                  _selectedTarget = null;
                  _startDate = null;
                  _endDate = null;
                });
              },
              child: const Text('重置'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOperationDetails(Operation operation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(operation.description),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('操作类型: ${_getOperationTypeLabel(operation.type)}'),
            Text('目标类型: ${_getOperationTargetLabel(operation.target)}'),
            Text('操作时间: ${_formatTimestamp(operation.timestamp)}'),
            Text('目标ID: ${operation.targetId}'),
            if (operation.previousData != null) ...[
              const SizedBox(height: 8),
              const Text(
                '操作前数据:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                operation.previousData!,
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (operation.newData != null) ...[
              const SizedBox(height: 8),
              const Text(
                '操作后数据:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(operation.newData!, style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  static String _getOperationTypeLabel(OperationType type) {
    switch (type) {
      case OperationType.add:
        return '添加';
      case OperationType.update:
        return '更新';
      case OperationType.delete:
        return '删除';
    }
  }

  static String _getOperationTargetLabel(OperationTarget target) {
    switch (target) {
      case OperationTarget.task:
        return '任务';
      case OperationTarget.habit:
        return '习惯';
    }
  }
}
