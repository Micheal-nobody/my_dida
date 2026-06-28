import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:my_dida/shared/models/revertible_entity.dart';

part 'operation.g.dart';

/// 操作类型枚举
enum OperationType {
  add, // 添加
  delete, // 删除
  update, // 更新
}

/// 操作目标类型枚举
enum OperationTarget {
  task, // 任务
  habit, // 习惯
  checklist, // 清单
}

@Collection()
class Operation {
  Operation({
    required this.type,
    required this.target,
    required this.timestamp,
    required this.description,
    required this.targetId,
    this.previousData,
    this.newData,
  });

  Id id = Isar.autoIncrement;

  /// 操作类型
  @enumerated
  OperationType type;

  /// 操作目标类型
  @enumerated
  OperationTarget target;

  /// 操作时间戳
  @Index()
  DateTime timestamp;

  /// 操作描述
  String description;

  /// 操作目标的ID
  int targetId;

  /// 操作前的数据（用于撤回，JSON字符串）
  String? previousData;

  /// 操作后的数据（用于撤回，JSON字符串）
  String? newData;

  // ==================================================================
  // 多态创建工厂方法，基于 RevertibleEntity 抽象接口
  // ==================================================================

  /// 创建添加清单操作
  static Operation createAddChecklistOperation(RevertibleEntity entity) =>
      Operation(
        type: OperationType.add,
        target: OperationTarget.checklist,
        timestamp: DateTime.now(),
        description: _buildDescription('添加', entity),
        targetId: entity.id,
        newData: _entityToJson(entity),
      );

  /// 创建删除清单操作，包含被影响任务ID列表
  static Operation createDeleteChecklistOperation(
    RevertibleEntity entity,
    List<int> affectedTaskIds,
  ) => Operation(
    type: OperationType.delete,
    target: OperationTarget.checklist,
    timestamp: DateTime.now(),
    description: _buildDescription('删除', entity),
    targetId: entity.id,
    previousData: jsonEncode({
      'checklist': entity.toJson(),
      'affectedTaskIds': affectedTaskIds,
    }),
  );

  /// 创建更新清单操作
  static Operation createUpdateChecklistOperation(
    RevertibleEntity oldEntity,
    RevertibleEntity newEntity,
    String changeDescription,
  ) => Operation(
    type: OperationType.update,
    target: OperationTarget.checklist,
    timestamp: DateTime.now(),
    description: changeDescription,
    targetId: newEntity.id,
    previousData: _entityToJson(oldEntity),
    newData: _entityToJson(newEntity),
  );

  /// 创建添加任务操作
  static Operation createAddTaskOperation(RevertibleEntity entity) => Operation(
    type: OperationType.add,
    target: OperationTarget.task,
    timestamp: DateTime.now(),
    description: _buildDescription('添加', entity),
    targetId: entity.id,
    newData: _entityToJson(entity),
  );

  /// 创建删除任务操作
  static Operation createDeleteTaskOperation(RevertibleEntity entity) =>
      Operation(
        type: OperationType.delete,
        target: OperationTarget.task,
        timestamp: DateTime.now(),
        description: _buildDescription('删除', entity),
        targetId: entity.id,
        previousData: _entityToJson(entity),
      );

  /// 创建更新任务操作
  static Operation createUpdateTaskOperation(
    RevertibleEntity oldEntity,
    RevertibleEntity newEntity,
    String changeDescription,
  ) => Operation(
    type: OperationType.update,
    target: OperationTarget.task,
    timestamp: DateTime.now(),
    description: changeDescription,
    targetId: newEntity.id,
    previousData: _entityToJson(oldEntity),
    newData: _entityToJson(newEntity),
  );

  /// 创建添加习惯操作
  static Operation createAddHabitOperation(RevertibleEntity entity) =>
      Operation(
        type: OperationType.add,
        target: OperationTarget.habit,
        timestamp: DateTime.now(),
        description: _buildDescription('添加', entity),
        targetId: entity.id,
        newData: _entityToJson(entity),
      );

  /// 创建删除习惯操作
  static Operation createDeleteHabitOperation(RevertibleEntity entity) =>
      Operation(
        type: OperationType.delete,
        target: OperationTarget.habit,
        timestamp: DateTime.now(),
        description: _buildDescription('删除', entity),
        targetId: entity.id,
        previousData: _entityToJson(entity),
      );

  /// 创建更新习惯操作
  static Operation createUpdateHabitOperation(
    RevertibleEntity oldEntity,
    RevertibleEntity newEntity,
    String changeDescription,
  ) => Operation(
    type: OperationType.update,
    target: OperationTarget.habit,
    timestamp: DateTime.now(),
    description: changeDescription,
    targetId: newEntity.id,
    previousData: _entityToJson(oldEntity),
    newData: _entityToJson(newEntity),
  );

  /// 统一的基于 RevertibleEntity 的 JSON 序列化
  static String _entityToJson(RevertibleEntity entity) =>
      jsonEncode(entity.toJson());

  /// 构建通用描述（因为 RevertibleEntity 声明了 displayName getter，可以更通用的方式）
  static String _buildDescription(String action, RevertibleEntity entity) =>
      '$action了"${entity.displayName}"';

  @override
  String toString() =>
      'Operation{id: $id, type: $type, target: $target, timestamp: $timestamp, description: $description, targetId: $targetId}';
}
