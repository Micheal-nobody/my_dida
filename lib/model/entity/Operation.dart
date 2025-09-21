import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/model/entity/Habit.dart';
part 'Operation.g.dart';

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
  Id id = Isar.autoIncrement;

  /// 操作类型
  @enumerated
  OperationType type;

  /// 操作目标类型
  @enumerated
  OperationTarget target;

  /// 操作时间戳
  DateTime timestamp;

  /// 操作描述
  String description;

  /// 操作目标的ID
  int targetId;

  /// 操作前的数据（用于撤回，JSON字符串）
  String? previousData;

  /// 操作后的数据（用于撤回，JSON字符串）
  String? newData;

  Operation({
    required this.type,
    required this.target,
    required this.timestamp,
    required this.description,
    required this.targetId,
    this.previousData,
    this.newData,
  });

  /// 创建添加任务操作
  static Operation createAddTaskOperation(Task task) {
    return Operation(
      type: OperationType.add,
      target: OperationTarget.task,
      timestamp: DateTime.now(),
      description: '添加了任务"${task.name}"',
      targetId: task.id,
      newData: _taskToJson(task),
    );
  }

  /// 创建删除任务操作
  static Operation createDeleteTaskOperation(Task task) {
    return Operation(
      type: OperationType.delete,
      target: OperationTarget.task,
      timestamp: DateTime.now(),
      description: '删除了任务"${task.name}"',
      targetId: task.id,
      previousData: _taskToJson(task),
    );
  }

  /// 创建更新任务操作
  static Operation createUpdateTaskOperation(
    Task oldTask,
    Task newTask,
    String changeDescription,
  ) {
    return Operation(
      type: OperationType.update,
      target: OperationTarget.task,
      timestamp: DateTime.now(),
      description: changeDescription,
      targetId: newTask.id,
      previousData: _taskToJson(oldTask),
      newData: _taskToJson(newTask),
    );
  }

  /// 创建添加习惯操作
  static Operation createAddHabitOperation(Habit habit) {
    return Operation(
      type: OperationType.add,
      target: OperationTarget.habit,
      timestamp: DateTime.now(),
      description: '添加了习惯"${habit.name}"',
      targetId: habit.id,
      newData: _habitToJson(habit),
    );
  }

  /// 创建删除习惯操作
  static Operation createDeleteHabitOperation(Habit habit) {
    return Operation(
      type: OperationType.delete,
      target: OperationTarget.habit,
      timestamp: DateTime.now(),
      description: '删除了习惯"${habit.name}"',
      targetId: habit.id,
      previousData: _habitToJson(habit),
    );
  }

  /// 创建更新习惯操作
  static Operation createUpdateHabitOperation(
    Habit oldHabit,
    Habit newHabit,
    String changeDescription,
  ) {
    return Operation(
      type: OperationType.update,
      target: OperationTarget.habit,
      timestamp: DateTime.now(),
      description: changeDescription,
      targetId: newHabit.id,
      previousData: _habitToJson(oldHabit),
      newData: _habitToJson(newHabit),
    );
  }

  /// 创建打卡操作
  static Operation createCheckInOperation(Habit habit) {
    return Operation(
      type: OperationType.update,
      target: OperationTarget.habit,
      timestamp: DateTime.now(),
      description: '完成了习惯"${habit.name}"的打卡',
      targetId: habit.id,
      previousData: _habitToJson(habit),
      newData: _habitToJson(
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
  }

  /// 创建撤回打卡操作
  static Operation createUndoCheckInOperation(Habit habit) {
    return Operation(
      type: OperationType.update,
      target: OperationTarget.habit,
      timestamp: DateTime.now(),
      description: '撤回了习惯"${habit.name}"的打卡',
      targetId: habit.id,
      previousData: _habitToJson(habit),
      newData: _habitToJson(
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
  }

  /// 将Task转换为JSON字符串（使用dart:convert确保正确格式）
  static String _taskToJson(Task task) {
    final Map<String, dynamic> taskMap = {
      'id': task.id,
      'name': task.name,
      'description': task.description,
      'isDone': task.isDone,
      'rrule': task.rrule,
      'startTime': task.startTime?.toIso8601String(),
      'endTime': task.endTime?.toIso8601String(),
      'parentTaskId': task.parentTaskId,
      'subTaskIds': task.subTaskIds,
      'belongingBoxId': task.belongingBoxId,
      'checkpoints': task.checkpoints
          .map((cp) => {'name': cp.name, 'isDone': cp.isDone})
          .toList(),
    };

    return jsonEncode(taskMap);
  }

  /// 将Habit转换为JSON字符串（使用dart:convert确保正确格式）
  static String _habitToJson(Habit habit) {
    final Map<String, dynamic> habitMap = {
      'id': habit.id,
      'name': habit.name,
      'icon': habit.icon,
      'remindTime': habit.remindTime.toIso8601String(),
      'checkInCount': habit.checkInCount,
      'currentCheckInCount': habit.currentCheckInCount,
      'startDate': habit.startDate.toIso8601String(),
      'totalCheckInCount': habit.totalCheckInCount,
      'longestContinuousCheckInDays': habit.longestContinuousCheckInDays,
      'rrule': habit.rrule,
    };

    return jsonEncode(habitMap);
  }

  @override
  String toString() {
    return 'Operation{id: $id, type: $type, target: $target, timestamp: $timestamp, description: $description, targetId: $targetId}';
  }
}
