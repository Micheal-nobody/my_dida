import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/features/habits/models/habit.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';
import 'package:my_dida/features/operation_undo/providers/operation_stack_provider.dart';
import 'package:my_dida/features/operation_undo/widgets/operation_checklist_renderer.dart';
import 'package:my_dida/features/operation_undo/widgets/operation_habit_renderer.dart';
import 'package:my_dida/features/operation_undo/widgets/operation_task_renderer.dart';
import 'package:my_dida/features/tasks/models/repeat_pattern.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:provider/provider.dart';

class OperationDetailDialog extends StatelessWidget {
  final Operation operation;
  final Function(String message) showSuccess;
  final Function(String message) showError;

  const OperationDetailDialog({
    super.key,
    required this.operation,
    required this.showSuccess,
    required this.showError,
  });

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
      case OperationTarget.checklist:
        return '清单';
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

  void _undoSpecificOperation(BuildContext context) async {
    Navigator.of(context).pop(); // 关闭详情对话框

    final operationStack = context.read<OperationStackProvider>();
    final success = await operationStack.undoOperation(operation);

    if (success) {
      showSuccess('操作已撤回');
    } else {
      showError('撤回失败');
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
        final task = _createTaskFromJson(data);
        if (task != null) {
          return OperationTaskRenderer(
            task: task,
            isPreviousData: isPreviousData,
          );
        }
      } else if (target == OperationTarget.habit) {
        final habit = _createHabitFromJson(data);
        if (habit != null) {
          return OperationHabitRenderer(
            habit: habit,
            isPreviousData: isPreviousData,
          );
        }
      } else if (target == OperationTarget.checklist) {
        final checklist = _createChecklistFromJson(data);
        if (checklist != null) {
          return OperationChecklistRenderer(
            checklist: checklist,
            isPreviousData: isPreviousData,
          );
        }
      }
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
      return Task(
        name: data['name']?.toString() ?? '',
        description: data['description']?.toString() ?? '',
        isDone: data['isDone'] == true,
        rrule: RepeatPattern.parse(
          data['rrule']?.toString().isEmpty == true
              ? null
              : data['rrule']?.toString(),
        ),
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
        rrule: RepeatPattern.parse(
          data['rrule']?.toString().isEmpty == true
              ? null
              : data['rrule']?.toString(),
        ),
      )..id = data['id'] ?? 0;
    } catch (e) {
      return null;
    }
  }

  Checklist? _createChecklistFromJson(Map<String, dynamic> data) {
    try {
      final checklistData = data.containsKey('checklist')
          ? data['checklist'] as Map<String, dynamic>
          : data;
      return Checklist(
        name: checklistData['name']?.toString() ?? '',
        colorValue: checklistData['colorValue'] ?? 0xFFFF9800,
      )..id = checklistData['id'] ?? 0;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                    _getOperationColor(operation.type).withValues(alpha: 0.05),
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
                    onPressed: () => _undoSpecificOperation(context),
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
    );
  }
}
