import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_dida/features/checklist/models/checklist.dart';
import 'package:my_dida/features/operation_undo/services/operation_data_renderer.dart';

/// 清单数据渲染器实现
class ChecklistOperationDataRenderer implements OperationDataRenderer {
  @override
  Widget render(
    BuildContext context,
    String jsonData, {
    required bool isPreviousData,
  }) {
    try {
      final decoded = jsonDecode(jsonData);
      // 处理删除清单操作中的嵌套 checklist 数据，或者普通的 checklist 数据
      final checklistMap =
          decoded is Map<String, dynamic> && decoded.containsKey('checklist')
          ? decoded['checklist'] as Map<String, dynamic>
          : decoded as Map<String, dynamic>;

      final checklist = Checklist.fromJson(checklistMap);
      return OperationChecklistRenderer(
        checklist: checklist,
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

/// 用于在操作详情中渲染 Checklist 的组件
class OperationChecklistRenderer extends StatelessWidget {
  const OperationChecklistRenderer({
    required this.checklist,
    super.key,
    this.isPreviousData = false,
  });

  final Checklist checklist;
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
    child: Row(
      children: [
        // 清单颜色圆点
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Color(checklist.colorValue),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // 清单名称
        Expanded(
          child: Text(
            checklist.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // 实体类型标识
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.teal[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '清单',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.teal[700],
            ),
          ),
        ),
      ],
    ),
  );
}
