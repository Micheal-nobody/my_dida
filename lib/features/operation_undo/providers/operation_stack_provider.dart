import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/logger/logger.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';
import 'package:my_dida/features/operation_undo/services/operation_reverter.dart';

/// 操作栈管理器
class OperationStackProvider with ChangeNotifier {
  OperationStackProvider() : _isar = getIt<Isar>();
  static const int _maxOperations = 50; // 最大操作数量
  List<Operation> _operations = [];
  final Isar _isar;

  /// 获取所有操作
  List<Operation> get operations => List.unmodifiable(_operations);

  /// 获取最近的操作
  List<Operation> get recentOperations => _operations.take(20).toList();

  /// 是否有可撤回的操作
  bool get canUndo => _operations.isNotEmpty;

  /// 初始化操作栈（从数据库加载）
  Future<void> initialize() async {
    try {
      final operations = await _isar.operations
          .where()
          .sortByTimestampDesc()
          .limit(_maxOperations)
          .findAll();

      // 清理和修复可能存在的格式错误的JSON数据
      final List<Operation> cleanedOperations = [];
      for (final operation in operations) {
        try {
          // 尝试解析JSON以验证格式
          if (operation.previousData != null) {
            jsonDecode(operation.previousData!);
          }
          if (operation.newData != null) {
            jsonDecode(operation.newData!);
          }
          cleanedOperations.add(operation);
        } catch (e) {
          debugPrint('发现格式错误的操作数据，跳过: ${operation.description}');
          // 删除格式错误的操作
          await _isar.writeTxn(() async {
            await _isar.operations.delete(operation.id);
          });
        }
      }

      _operations = cleanedOperations;
      notifyListeners();
    } catch (e) {
      logger.e('初始化操作栈失败: $e');
    }
  }

  /// 添加操作到栈中
  Future<void> addOperation(Operation operation) async {
    try {
      // 保存到数据库
      await _isar.writeTxn(() async {
        await _isar.operations.put(operation);
      });

      // 添加到内存栈
      _operations.insert(0, operation);

      // 限制栈大小
      if (_operations.length > _maxOperations) {
        final operationsToRemove = _operations.skip(_maxOperations).toList();
        _operations = _operations.take(_maxOperations).toList();

        // 从数据库删除多余的操作
        await _isar.writeTxn(() async {
          for (final op in operationsToRemove) {
            await _isar.operations.delete(op.id);
          }
        });
      }

      notifyListeners();
    } catch (e) {
      logger.e('添加操作失败: $e');
    }
  }

  /// 撤回最近的操作
  Future<bool> undo() async {
    if (_operations.isEmpty) {
      return false;
    }

    try {
      final operation = _operations.first;
      final reverter = getIt<OperationReverter>();
      final success = await reverter.revert(operation);

      if (success) {
        // 从栈中移除操作
        _operations.removeAt(0);

        // 从数据库删除操作记录
        await _isar.writeTxn(() async {
          await _isar.operations.delete(operation.id);
        });

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      logger.e('撤回操作失败: $e');
      return false;
    }
  }

  /// 撤回指定的操作
  Future<bool> undoOperation(Operation operation) async {
    try {
      final reverter = getIt<OperationReverter>();
      final success = await reverter.revert(operation);

      if (success) {
        // 从栈中移除操作
        _operations.removeWhere((op) => op.id == operation.id);

        // 从数据库删除操作记录
        await _isar.writeTxn(() async {
          await _isar.operations.delete(operation.id);
        });

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      logger.e('撤回指定操作失败: $e');
      return false;
    }
  }

  /// 清空操作栈
  Future<void> clearOperations() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.operations.clear();
      });

      _operations.clear();
      notifyListeners();
    } catch (e) {
      logger.e('清空操作栈失败: $e');
    }
  }

  /// 获取操作统计信息
  Map<String, int> getOperationStats() {
    final stats = <String, int>{};

    for (final operation in _operations) {
      final key = '${operation.target.name}_${operation.type.name}';
      stats[key] = (stats[key] ?? 0) + 1;
    }

    return stats;
  }

  /// 根据时间范围过滤操作
  List<Operation> getOperationsByTimeRange(DateTime start, DateTime end) =>
      _operations
          .where(
            (op) => op.timestamp.isAfter(start) && op.timestamp.isBefore(end),
          )
          .toList();

  /// 根据操作类型过滤操作
  List<Operation> getOperationsByType(OperationType type) =>
      _operations.where((op) => op.type == type).toList();

  /// 根据目标类型过滤操作
  List<Operation> getOperationsByTarget(OperationTarget target) =>
      _operations.where((op) => op.target == target).toList();

  /// 根据描述搜索操作
  List<Operation> searchOperations(String query) {
    if (query.isEmpty) return _operations;

    final lowerQuery = query.toLowerCase();
    return _operations
        .where((op) => op.description.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// 批量撤回操作（撤回最近N个操作）
  Future<int> undoMultiple(int count) async {
    int successCount = 0;
    for (int i = 0; i < count && _operations.isNotEmpty; i++) {
      final success = await undo();
      if (success) {
        successCount++;
      } else {
        break; // 如果撤回失败，停止批量撤回
      }
    }
    return successCount;
  }

  /// 获取操作详情
  Map<String, dynamic> getOperationDetails(Operation operation) => {
    'id': operation.id,
    'type': operation.type.name,
    'target': operation.target.name,
    'timestamp': operation.timestamp.toIso8601String(),
    'description': operation.description,
    'targetId': operation.targetId,
    'hasPreviousData': operation.previousData != null,
    'hasNewData': operation.newData != null,
  };

  /// 导出操作历史为JSON
  String exportOperationsAsJson() {
    final List<Map<String, dynamic>> operationsJson = _operations
        .map(
          (op) => {
            'id': op.id,
            'type': op.type.name,
            'target': op.target.name,
            'timestamp': op.timestamp.toIso8601String(),
            'description': op.description,
            'targetId': op.targetId,
            'hasPreviousData': op.previousData != null,
            'hasNewData': op.newData != null,
          },
        )
        .toList();

    return jsonEncode({
      'exportTime': DateTime.now().toIso8601String(),
      'totalOperations': operationsJson.length,
      'operations': operationsJson,
    });
  }

  /// 获取指定 ID 的操作
  Future<Operation?> getOperationById(int id) async {
    try {
      return await _isar.operations.get(id);
    } catch (e) {
      logger.e('获取操作记录失败: $e');
      return null;
    }
  }

  /// 删除指定 ID 的操作
  Future<bool> deleteOperationById(int id) async {
    try {
      final success = await _isar.writeTxn(
        () async => _isar.operations.delete(id),
      );
      if (success) {
        _operations.removeWhere((op) => op.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      logger.e('删除操作记录失败: $e');
      return false;
    }
  }
}
