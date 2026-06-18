import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/locator.dart';
import '../model/entity/operation.dart';
import '../model/entity/revertible_entity.dart';
import '../repository/base_repository.dart';

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
  EntityFactory? getFactory(OperationTarget target) => _entries[target]?.factory;

  /// 获取仓储
  BaseRepository? getRepository(OperationTarget target) => _entries[target]?.repository;
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
          // 撤销添加：直接删除实体
          await repository.deleteById(operation.targetId);
          break;

        case OperationType.delete:
          // 撤销删除：反序列化 previousData 重建并还原写入
          if (operation.previousData != null) {
            final entity = factory(jsonDecode(operation.previousData!));
            await repository.insert(entity);
          } else {
            return false;
          }
          break;

        case OperationType.update:
          // 撤销更新：反序列化 previousData 快照并用 update 还原
          if (operation.previousData != null) {
            final entity = factory(jsonDecode(operation.previousData!));
            await repository.update(entity);
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
