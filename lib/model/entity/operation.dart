import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:my_dida/model/entity/habit.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/entity/revertible_entity.dart';

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

  /// 创建打卡操作
  static Operation createCheckInOperation(Habit habit) => Operation(
    type: OperationType.update,
    target: OperationTarget.habit,
    timestamp: DateTime.now(),
    description: '完成了习惯"${habit.name}"的打卡',
    targetId: habit.id,
    previousData: _entityToJson(habit),
    newData: _entityToJson(
      Habit(
        name: habit.name,
        icon: habit.icon,
        remindTime: habit.remindTime,
        checkInCount: habit.checkInCount,
        currentCheckInCount: habit.currentCheckInCount + 1,
        startDate: habit.startDate,
        totalCheckInCount: habit.totalCheckInCount + 1,
        longestContinuousCheckInDays: habit.longestContinuousCheckInDays,
        rrule: habit.rrule,
      )..id = habit.id,
    ),
  );

  /// 创建撤回打卡操作
  static Operation createUndoCheckInOperation(Habit habit) => Operation(
    type: OperationType.update,
    target: OperationTarget.habit,
    timestamp: DateTime.now(),
    description: '撤回了习惯"${habit.name}"的打卡',
    targetId: habit.id,
    previousData: _entityToJson(habit),
    newData: _entityToJson(
      Habit(
        name: habit.name,
        icon: habit.icon,
        remindTime: habit.remindTime,
        checkInCount: habit.checkInCount,
        currentCheckInCount: habit.currentCheckInCount - 1,
        startDate: habit.startDate,
        totalCheckInCount: habit.totalCheckInCount > 0
            ? habit.totalCheckInCount - 1
            : 0,
        longestContinuousCheckInDays: habit.longestContinuousCheckInDays,
        rrule: habit.rrule,
      )..id = habit.id,
    ),
  );

  /// 统一的基于 RevertibleEntity 的 JSON 序列化
  static String _entityToJson(RevertibleEntity entity) =>
      jsonEncode(entity.toJson());

  /// 构建通用描述（因为 RevertibleEntity 未声明 getter name，需要更通用的方式）
  static String _buildDescription(String action, RevertibleEntity entity) {
    // 对已知实体提取 name 字段；无法取得时回退
    final name = _tryGetEntityName(entity) ?? '未知';
    return '${action}了"$name"';
  }

  static String? _tryGetEntityName(RevertibleEntity entity) {
    if (entity is Task) return entity.name;
    if (entity is Habit) return entity.name;
    return null;
  }

  @override
  String toString() =>
      'Operation{id: $id, type: $type, target: $target, timestamp: $timestamp, description: $description, targetId: $targetId}';
}
