import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/model/entity/habit.dart';
import 'package:my_dida/model/entity/operation.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/provider/habit_provider.dart';
import 'package:my_dida/provider/operation_stack_provider.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:provider/provider.dart';

import '../features/operation/operation_habit_renderer.dart';
import '../features/operation/operation_task_renderer.dart';

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

  Widget _buildStatsCard(OperationStackProvider operationStack) {
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
                    _buildStatItem(
                      '总操作',
                      totalOperations.toString(),
                      Icons.history,
                      Colors.blue,
                    ),
                    _buildStatItem(
                      '任务操作',
                      (stats['task_add'] ?? 0) +
                          (stats['task_update'] ?? 0) +
                          (stats['task_delete'] ?? 0),
                      Icons.task,
                      Colors.orange,
                    ),
                    _buildStatItem(
                      '习惯操作',
                      (stats['habit_add'] ?? 0) +
                          (stats['habit_update'] ?? 0) +
                          (stats['habit_delete'] ?? 0),
                      Icons.psychology,
                      Colors.purple,
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
    String label,
    dynamic value,
    IconData icon,
    Color color,
  ) => Container(
    padding: const EdgeInsets.all(16),
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
    };

    final labels = {OperationTarget.task: '任务', OperationTarget.habit: '习惯'};
    final icons = {
      OperationTarget.task: Icons.task,
      OperationTarget.habit: Icons.psychology,
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('筛选操作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 操作类型筛选
              DropdownButtonFormField<OperationType?>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: '操作类型',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(child: Text('全部')),
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
                initialValue: _selectedTarget,
                decoration: const InputDecoration(
                  labelText: '目标类型',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(child: Text('全部')),
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getOperationColor(operation.type).withValues(alpha: 0.1),
                      _getOperationColor(
                        operation.type,
                      ).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getOperationColor(operation.type),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getOperationIcon(operation.type),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            operation.description,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_getOperationTypeLabel(operation.type)} · ${_getOperationTargetLabel(operation.target)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 内容区域
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 操作信息
                      _buildInfoRow(
                        '操作时间',
                        _formatTimestamp(operation.timestamp),
                      ),
                      _buildInfoRow('目标ID', operation.targetId.toString()),

                      const SizedBox(height: 20),

                      // 操作前数据
                      if (operation.previousData != null) ...[
                        const Text(
                          '操作前数据',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDataRenderer(
                          operation.previousData!,
                          operation.target,
                          true,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 操作后数据
                      if (operation.newData != null) ...[
                        const Text(
                          '操作后数据',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDataRenderer(
                          operation.newData!,
                          operation.target,
                          false,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // 底部按钮
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('关闭'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _undoSpecificOperation(operation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('撤回操作'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _undoSpecificOperation(Operation operation) async {
    Navigator.of(context).pop(); // 关闭详情对话框

    final operationStack = context.read<OperationStackProvider>();
    final success = await operationStack.undoOperation(operation);

    if (success) {
      if (mounted) {
        _messageService.showSuccess('操作已撤回');
      }
    } else if (mounted) {
      _messageService.showError('撤回失败');
    }
  }

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  Widget _buildDataRenderer(
    String jsonData,
    OperationTarget target,
    bool isPreviousData,
  ) {
    try {
      final data = jsonDecode(jsonData);

      if (target == OperationTarget.task) {
        // 创建Task对象
        final task = _createTaskFromJson(data);
        if (task != null) {
          return OperationTaskRenderer(
            task: task,
            isPreviousData: isPreviousData,
          );
        }
      } else if (target == OperationTarget.habit) {
        // 创建Habit对象
        final habit = _createHabitFromJson(data);
        if (habit != null) {
          return OperationHabitRenderer(
            habit: habit,
            isPreviousData: isPreviousData,
          );
        }
      }
    } catch (e) {
      // JSON解析失败，显示原始数据
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

    // 如果无法解析，显示原始数据
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

  Task? _createTaskFromJson(Map<String, dynamic> data) {
    try {
      // 这里简化处理，实际应该根据Task的完整结构来创建
      return Task(
        name: data['name']?.toString() ?? '',
        description: data['description']?.toString() ?? '',
        isDone: data['isDone'] == true,
        rrule: data['rrule']?.toString().isEmpty == true
            ? null
            : data['rrule']?.toString(),
        startTime: data['startTime'] != null
            ? DateTime.parse(data['startTime'])
            : null,
        endTime: data['endTime'] != null
            ? DateTime.parse(data['endTime'])
            : null,
        checklistId: data['checklistId'] == 0 ? null : data['checklistId'],
        isAllDay: data['isAllDay'] == true,
      )..id = data['id'] ?? 0;
    } catch (e) {
      return null;
    }
  }

  Habit? _createHabitFromJson(Map<String, dynamic> data) {
    try {
      return Habit(
        name: data['name']?.toString() ?? '',
        icon: data['icon']?.toString() ?? '',
        remindTime: data['remindTime'] != null
            ? DateTime.parse(data['remindTime'])
            : DateTime.now(),
        checkInCount: data['checkInCount'] ?? 1,
        currentCheckInCount: data['currentCheckInCount'] ?? 0,
        startDate: data['startDate'] != null
            ? DateTime.parse(data['startDate'])
            : DateTime.now(),
        totalCheckInCount: data['totalCheckInCount'] ?? 0,
        longestContinuousCheckInDays: data['longestContinuousCheckInDays'] ?? 0,
        rrule: data['rrule']?.toString().isEmpty == true
            ? null
            : data['rrule']?.toString(),
      )..id = data['id'] ?? 0;
    } catch (e) {
      return null;
    }
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
