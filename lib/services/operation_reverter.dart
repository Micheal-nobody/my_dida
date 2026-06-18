import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/locator.dart';
import '../model/entity/habit.dart';
import '../model/entity/operation.dart';
import '../model/entity/task.dart';
import '../repository/habit_repository.dart';
import '../repository/task_repository.dart';

/// 抽象撤销适配器合同
abstract class OperationReverter {
  Future<bool> revert(Operation operation);
}

/// 针对任务操作的撤销重做实现类
class TaskOperationReverter implements OperationReverter {
  TaskOperationReverter({TaskRepository? taskRepository})
      : _taskRepository = taskRepository ?? getIt<TaskRepository>();

  final TaskRepository _taskRepository;

  @override
  Future<bool> revert(Operation operation) async {
    try {
      switch (operation.type) {
        case OperationType.add:
          // 撤锁添加操作：利用 targetId 直接从数据库中彻底抹除该任务即可
          await _taskRepository.deleteById(operation.targetId);
          break;

        case OperationType.delete:
          // 撤锁删除操作：利用 previousData 记录的完整任务快照反序列化重建并还原写入
          if (operation.previousData != null) {
            final task = Task.fromJson(jsonDecode(operation.previousData!));
            await _taskRepository.addData(task);
          } else {
            return false;
          }
          break;

        case OperationType.update:
          // 撤锁更新操作：将任务数据还原为修改前的 snapshot 快照（即 previousData）并更新
          if (operation.previousData != null) {
            final task = Task.fromJson(jsonDecode(operation.previousData!));
            await _taskRepository.update(task);
          } else {
            return false;
          }
          break;
      }
      return true;
    } catch (e) {
      debugPrint('TaskOperationReverter 撤销操作执行失败: $e');
      return false;
    }
  }
}

/// 针对习惯操作的撤销重做实现类
class HabitOperationReverter implements OperationReverter {
  HabitOperationReverter({HabitRepository? habitRepository})
      : _habitRepository = habitRepository ?? getIt<HabitRepository>();

  final HabitRepository _habitRepository;

  @override
  Future<bool> revert(Operation operation) async {
    try {
      switch (operation.type) {
        case OperationType.add:
          // 撤锁添加操作：直接删除已经添加的习惯
          await _habitRepository.deleteHabit(operation.targetId);
          break;

        case OperationType.delete:
          // 撤锁删除操作：利用 previousData 数据反序列化重建并写回
          if (operation.previousData != null) {
            final habit = Habit.fromJson(jsonDecode(operation.previousData!));
            await _habitRepository.addHabit(habit);
          } else {
            return false;
          }
          break;

        case OperationType.update:
          // 撤锁更新操作：将习惯数据还原至 previousData 保存的历史状态并更新（调用新引入的 updateHabit）
          if (operation.previousData != null) {
            final habit = Habit.fromJson(jsonDecode(operation.previousData!));
            await _habitRepository.updateHabit(habit);
          } else {
            return false;
          }
          break;
      }
      return true;
    } catch (e) {
      debugPrint('HabitOperationReverter 撤销操作执行失败: $e');
      return false;
    }
  }
}
