import 'package:flutter/foundation.dart';
import '../models/operation.dart';
import '../../../../core/di/locator.dart';

// ==================================================================
// 领域撤销委托接口定义
// ==================================================================

/// 领域撤销委托接口：各业务模块只需实现此接口并注册，即可获得撤销/重做联动支持。
abstract class DomainOperationReverter {
  Future<bool> revertAdd(int id);
  Future<bool> revertDelete(int id, String? previousData);
  Future<bool> revertUpdate(int id, String? previousData, String description);
}

// ==================================================================
// 多态还原注册器
// ==================================================================

/// 实体注册器：维护 OperationTarget → DomainOperationReverter 的映射。
/// 实现了操作引擎与具体业务实体的完全解耦。
class EntityRegistry {
  final Map<OperationTarget, DomainOperationReverter> _reverters = {};

  /// 注册目标类型对应的领域撤销适配器
  void register(OperationTarget target, DomainOperationReverter reverter) {
    _reverters[target] = reverter;
  }

  /// 获取领域撤销适配器
  DomainOperationReverter? getReverter(OperationTarget target) =>
      _reverters[target];
}

// ==================================================================
// 统一撤销适配器
// ==================================================================

/// 抽象撤销适配器合同
abstract class OperationReverter {
  Future<bool> revert(Operation operation);
}

/// 基于 EntityRegistry 注册中心的通用泛化撤销适配器
class GenericOperationReverter implements OperationReverter {
  GenericOperationReverter({EntityRegistry? entityRegistry})
    : _entityRegistry = entityRegistry ?? getIt<EntityRegistry>();

  final EntityRegistry _entityRegistry;

  @override
  Future<bool> revert(Operation operation) async {
    try {
      final reverter = _entityRegistry.getReverter(operation.target);

      if (reverter == null) {
        debugPrint('未为 target=${operation.target} 注册领域撤销适配器，无法撤销');
        return false;
      }

      switch (operation.type) {
        case OperationType.add:
          return await reverter.revertAdd(operation.targetId);
        case OperationType.delete:
          return await reverter.revertDelete(
            operation.targetId,
            operation.previousData,
          );
        case OperationType.update:
          return await reverter.revertUpdate(
            operation.targetId,
            operation.previousData,
            operation.description,
          );
      }
    } catch (e) {
      debugPrint('GenericOperationReverter 撤销操作执行失败: $e');
      return false;
    }
  }
}
