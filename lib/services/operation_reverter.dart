import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/locator.dart';
import '../model/entity/operation.dart';
import '../model/entity/revertible_entity.dart';
import '../model/entity/task.dart';
import '../model/entity/habit.dart';
import '../model/entity/habit_check_in_record.dart';
import '../repository/base_repository.dart';
import '../repository/task_repository.dart';
import '../repository/habit_check_in_record_repository.dart';

// ==================================================================
// 多态还原注册器
// ==================================================================

/// 实体工厂别名：从 JSON Map 反序列化还原为实体实例
typedef EntityFactory = RevertibleEntity Function(Map<String, dynamic> json);

/// 实体注册器：维护 OperationTarget → (实体工厂, 仓储实例) 的映射
/// 当引入新的可撤销实体，只需在此注册一对目标和工厂，无需编写新的 Reverter 子类。
class EntityRegistry {
  final Map<OperationTarget, _EntityEntry> _entries = {};

  /// 注册目标类型对应的实体工厂与仓储
  void register<T extends RevertibleEntity>(
    OperationTarget target,
    EntityFactory factory,
    BaseRepository<T> repository,
  ) {
    _entries[target] = _EntityEntry(factory, repository);
  }

  /// 获取工厂
  EntityFactory? getFactory(OperationTarget target) =>
      _entries[target]?.factory;

  /// 获取仓储
  BaseRepository? getRepository(OperationTarget target) =>
      _entries[target]?.repository;
}

class _EntityEntry {
  final EntityFactory factory;
  final BaseRepository repository;

  const _EntityEntry(this.factory, this.repository);
}

// ==================================================================
// 统一撤销适配器
// ==================================================================

/// 抽象撤销适配器合同
abstract class OperationReverter {
  Future<bool> revert(Operation operation);
}

/// 基于 EntityRegistry 的泛化撤销适配器：任何实体只需注册即可获得撤销支持。
class GenericOperationReverter implements OperationReverter {
  GenericOperationReverter({EntityRegistry? entityRegistry})
    : _entityRegistry = entityRegistry ?? getIt<EntityRegistry>();

  final EntityRegistry _entityRegistry;

  @override
  Future<bool> revert(Operation operation) async {
    try {
      final repository = _entityRegistry.getRepository(operation.target);
      final factory = _entityRegistry.getFactory(operation.target);

      if (repository == null || factory == null) {
        debugPrint('未为 target=${operation.target} 注册实体，无法撤销');
        return false;
      }

      switch (operation.type) {
        case OperationType.add:
          // 如果是撤销添加 Task，并且在删除前它有 parentTaskId，需要从父任务的 subTaskIds 中删除它。
          if (operation.target == OperationTarget.task) {
            final taskRepo = getIt<TaskRepository>();
            final taskToDelete = await taskRepo.selectById(operation.targetId);
            if (taskToDelete != null && taskToDelete.parentTaskId != null) {
              final parent = await taskRepo.selectById(taskToDelete.parentTaskId!);
              if (parent != null) {
                final newIds = List<int>.from(parent.subTaskIds)..remove(taskToDelete.id);
                await taskRepo.update(parent..subTaskIds = newIds);
              }
            }
          }
          // 撤销添加：直接删除实体
          await repository.deleteById(operation.targetId);
          break;

        case OperationType.delete:
          // 撤销删除：反序列化 previousData 重建并还原写入
          if (operation.previousData != null) {
            final decoded = jsonDecode(operation.previousData!);

            // 对 Habit 进行特化解析（支持打包 records 的复杂 JSON）
            if (operation.target == OperationTarget.habit &&
                decoded is Map<String, dynamic> &&
                decoded.containsKey('habit')) {
              final habit = factory(decoded['habit'] as Map<String, dynamic>);
              await repository.insert(habit);

              // 恢复习惯打卡记录列表
              final recordRepo = getIt<HabitCheckInRecordRepository>();
              final List<dynamic> recordsJson = decoded['records'] ?? [];
              for (final rJson in recordsJson) {
                if (rJson is Map<String, dynamic>) {
                  final record = HabitCheckInRecord.fromJson(rJson);
                  await recordRepo.addRecord(record);
                }
              }
            } else {
              // 常规的反序列化
              final entity = factory(decoded);
              await repository.insert(entity);

              // 如果是 Task 并且有 parentTaskId，需要在父任务的 subTaskIds 中连回它
              if (entity is Task && entity.parentTaskId != null) {
                final taskRepo = getIt<TaskRepository>();
                final parent = await taskRepo.selectById(entity.parentTaskId!);
                if (parent != null) {
                  final newIds = List<int>.from(parent.subTaskIds);
                  if (!newIds.contains(entity.id)) {
                    newIds.add(entity.id);
                    await taskRepo.update(parent..subTaskIds = newIds);
                  }
                }
              }
            }
          } else {
            return false;
          }
          break;

        case OperationType.update:
          // 撤销更新：反序列化 previousData 快照并用 update 还原
          if (operation.previousData != null) {
            final entity = factory(jsonDecode(operation.previousData!));
            await repository.update(entity);

            // 如果是 Habit，检查打卡/跳过是否要删掉今天新增的打卡记录
            if (entity is Habit) {
              final isSkip = operation.description.contains('跳过');
              final isCheckIn = operation.description.contains('打卡');
              if (isSkip || isCheckIn) {
                final recordRepo = getIt<HabitCheckInRecordRepository>();
                final records = await recordRepo.getRecordsByHabitId(entity.id);
                final today = DateTime.now();
                final todayRecords = records.where((r) {
                  return r.isSkip == isSkip &&
                      r.checkInTime.year == today.year &&
                      r.checkInTime.month == today.month &&
                      r.checkInTime.day == today.day;
                }).toList();
                if (todayRecords.isNotEmpty) {
                  todayRecords.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
                  await recordRepo.deleteRecord(todayRecords.first.id);
                }
              }
            }
          } else {
            return false;
          }
          break;
      }
      return true;
    } catch (e) {
      debugPrint('GenericOperationReverter 撤销操作执行失败: $e');
      return false;
    }
  }
}
