import 'package:flutter/material.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';

class OperationFilterDialog extends StatefulWidget {
  final OperationType? initialType;
  final OperationTarget? initialTarget;
  final Function(OperationType? type, OperationTarget? target) onFilterSelected;

  const OperationFilterDialog({
    super.key,
    this.initialType,
    this.initialTarget,
    required this.onFilterSelected,
  });

  @override
  State<OperationFilterDialog> createState() => _OperationFilterDialogState();
}

class _OperationFilterDialogState extends State<OperationFilterDialog> {
  OperationType? _selectedType;
  OperationTarget? _selectedTarget;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedTarget = widget.initialTarget;
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            });
          },
          child: const Text('重置'),
        ),
        TextButton(
          onPressed: () {
            widget.onFilterSelected(_selectedType, _selectedTarget);
            Navigator.of(context).pop();
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
