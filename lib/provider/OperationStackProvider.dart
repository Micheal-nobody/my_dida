import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:my_dida/config/locator.dart';
import 'package:my_dida/model/entity/Operation.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/model/entity/Habit.dart';
import 'package:my_dida/model/entity/CheckPoint.dart';
import 'package:my_dida/repository/TaskRepository.dart';
import 'package:my_dida/repository/HabitRepository.dart';

/// 操作栈管理器
class OperationStackProvider with ChangeNotifier {
  static const int _maxOperations = 50; // 最大操作数量
  List<Operation> _operations = [];
  final Isar _isar;

  OperationStackProvider() : _isar = locator<Isar>();

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
      List<Operation> cleanedOperations = [];
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
      debugPrint('初始化操作栈失败: $e');
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
      debugPrint('添加操作失败: $e');
    }
  }

  /// 撤回最近的操作
  Future<bool> undo() async {
    if (_operations.isEmpty) {
      return false;
    }

    try {
      final operation = _operations.first;
      bool success = false;

      switch (operation.target) {
        case OperationTarget.task:
          success = await _undoTaskOperation(operation);
          break;
        case OperationTarget.habit:
          success = await _undoHabitOperation(operation);
          break;
      }

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
      debugPrint('撤回操作失败: $e');
      return false;
    }
  }

  /// 撤回任务操作
  Future<bool> _undoTaskOperation(Operation operation) async {
    try {
      final taskRepository = locator<TaskRepository>();

      switch (operation.type) {
        case OperationType.add:
          // 撤回添加操作：删除任务
          await taskRepository.deleteById(operation.targetId);
          break;

        case OperationType.delete:
          // 撤回删除操作：恢复任务
          if (operation.previousData != null) {
            final task = await _recreateTaskFromData(operation.previousData!);
            if (task != null) {
              await taskRepository.addData(task);
            } else {
              return false;
            }
          }
          break;

        case OperationType.update:
          // 撤回更新操作：恢复旧值
          if (operation.previousData != null) {
            final task = await _recreateTaskFromData(operation.previousData!);
            if (task != null) {
              await taskRepository.update(task);
            } else {
              return false;
            }
          }
          break;
      }

      return true;
    } catch (e) {
      debugPrint('撤回任务操作失败: $e');
      return false;
    }
  }

  /// 撤回习惯操作
  Future<bool> _undoHabitOperation(Operation operation) async {
    try {
      final habitRepository = locator<HabitRepository>();

      switch (operation.type) {
        case OperationType.add:
          // 撤回添加操作：删除习惯
          await habitRepository.deleteById(operation.targetId);
          break;

        case OperationType.delete:
          // 撤回删除操作：恢复习惯
          if (operation.previousData != null) {
            final habit = await _recreateHabitFromData(operation.previousData!);
            if (habit != null) {
              await habitRepository.addHabit(habit);
            } else {
              return false;
            }
          }
          break;

        case OperationType.update:
          // 撤回更新操作：恢复旧值
          if (operation.previousData != null) {
            final habit = await _recreateHabitFromData(operation.previousData!);
            if (habit != null) {
              await habitRepository.addHabit(habit); // 使用addHabit来更新
            } else {
              return false;
            }
          }
          break;
      }

      return true;
    } catch (e) {
      debugPrint('撤回习惯操作失败: $e');
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
      debugPrint('清空操作栈失败: $e');
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
  List<Operation> getOperationsByTimeRange(DateTime start, DateTime end) {
    return _operations
        .where(
          (op) => op.timestamp.isAfter(start) && op.timestamp.isBefore(end),
        )
        .toList();
  }

  /// 根据操作类型过滤操作
  List<Operation> getOperationsByType(OperationType type) {
    return _operations.where((op) => op.type == type).toList();
  }

  /// 根据目标类型过滤操作
  List<Operation> getOperationsByTarget(OperationTarget target) {
    return _operations.where((op) => op.target == target).toList();
  }

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
  Map<String, dynamic> getOperationDetails(Operation operation) {
    return {
      'id': operation.id,
      'type': operation.type.name,
      'target': operation.target.name,
      'timestamp': operation.timestamp.toIso8601String(),
      'description': operation.description,
      'targetId': operation.targetId,
      'hasPreviousData': operation.previousData != null,
      'hasNewData': operation.newData != null,
    };
  }

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

  /// 从JSON数据重新创建Task对象
  Future<Task?> _recreateTaskFromData(String jsonData) async {
    try {
      debugPrint('开始解析Task JSON: $jsonData');

      // 清理JSON数据，移除可能的格式问题
      String cleanedJson = jsonData.trim();

      // 如果JSON格式有问题，尝试修复
      if (cleanedJson.contains('\n') || cleanedJson.contains('    ')) {
        debugPrint('检测到多行JSON格式，尝试修复...');
        // 移除换行符和多余空格
        cleanedJson = cleanedJson
            .replaceAll('\n', '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }

      // 检查checkpoints字段是否完整
      if (cleanedJson.contains('"checkpoints":') &&
          !cleanedJson.contains('"checkpoints":[')) {
        debugPrint('检测到checkpoints字段格式问题，尝试修复...');
        cleanedJson = cleanedJson.replaceAll(
          '"checkpoints":',
          '"checkpoints":[]',
        );
      }

      debugPrint('清理后的JSON: $cleanedJson');

      final Map<String, dynamic> data = jsonDecode(cleanedJson);

      // 解析检查点
      List<CheckPoint> checkpoints = [];
      if (data['checkpoints'] != null && data['checkpoints'] is List) {
        final List<dynamic> checkpointList = data['checkpoints'];
        checkpoints = checkpointList.map((cp) {
          if (cp is Map<String, dynamic>) {
            return CheckPoint(
              name: cp['name']?.toString() ?? '',
              isDone: cp['isDone'] == true,
            );
          }
          return CheckPoint(name: '');
        }).toList();
      }

      // 解析子任务ID列表
      List<int> subTaskIds = [];
      if (data['subTaskIds'] != null && data['subTaskIds'] is List) {
        subTaskIds = (data['subTaskIds'] as List).cast<int>();
      }

      // 解析时间
      DateTime? startTime;
      if (data['startTime'] != null &&
          data['startTime'].toString().isNotEmpty) {
        startTime = DateTime.parse(data['startTime']);
      }

      DateTime? endTime;
      if (data['endTime'] != null && data['endTime'].toString().isNotEmpty) {
        endTime = DateTime.parse(data['endTime']);
      }

      // 创建Task对象
      final task = Task(
        name: data['name']?.toString() ?? '',
        description: data['description']?.toString() ?? '',
        isDone: data['isDone'] == true,
        rrule: data['rrule']?.toString().isEmpty == true
            ? null
            : data['rrule']?.toString(),
        checkpoints: checkpoints,
        startTime: startTime,
        endTime: endTime,
        parentTaskId: data['parentTaskId'] == 0 ? null : data['parentTaskId'],
        subTaskIds: subTaskIds,
        belongingBoxId: data['belongingBoxId'] == 0
            ? null
            : data['belongingBoxId'],
      );

      // 设置ID
      task.id = data['id'] ?? Isar.autoIncrement;

      debugPrint('成功重新创建Task: ${task.name}');
      return task;
    } catch (e) {
      debugPrint('重新创建Task失败: $e');
      return null;
    }
  }

  /// 从JSON数据重新创建Habit对象
  Future<Habit?> _recreateHabitFromData(String jsonData) async {
    try {
      debugPrint('开始解析Habit JSON: $jsonData');
      final Map<String, dynamic> data = jsonDecode(jsonData);

      // 解析时间
      DateTime remindTime;
      if (data['remindTime'] != null &&
          data['remindTime'].toString().isNotEmpty) {
        remindTime = DateTime.parse(data['remindTime']);
      } else {
        remindTime = DateTime.now(); // 默认值
      }

      DateTime startDate;
      if (data['startDate'] != null &&
          data['startDate'].toString().isNotEmpty) {
        startDate = DateTime.parse(data['startDate']);
      } else {
        startDate = DateTime.now(); // 默认值
      }

      // 创建Habit对象
      final habit = Habit(
        name: data['name']?.toString() ?? '',
        icon: data['icon']?.toString() ?? '',
        remindTime: remindTime,
        checkInCount: data['checkInCount'] ?? 1,
        currentCheckInCount: data['currentCheckInCount'] ?? 0,
        startDate: startDate,
        totalCheckInCount: data['totalCheckInCount'] ?? 0,
        longestContinuousCheckInDays: data['longestContinuousCheckInDays'] ?? 0,
        rrule: data['rrule']?.toString().isEmpty == true
            ? null
            : data['rrule']?.toString(),
      );

      // 设置ID
      habit.id = data['id'] ?? Isar.autoIncrement;

      debugPrint('成功重新创建Habit: ${habit.name}');
      return habit;
    } catch (e) {
      debugPrint('重新创建Habit失败: $e');
      return null;
    }
  }
}
