import 'package:flutter/widgets.dart';
import 'package:my_dida/features/operation_undo/models/operation.dart';

/// 数据渲染器接口，用于将 Operation 中的 JSON 数据渲染为 Widget
abstract class OperationDataRenderer {
  Widget render(
    BuildContext context,
    String jsonData, {
    required bool isPreviousData,
  });
}

/// 渲染器注册表，负责 OperationTarget -> OperationDataRenderer 的映射与注册
class OperationRendererRegistry {
  final Map<OperationTarget, OperationDataRenderer> _renderers = {};

  /// 注册目标类型对应的渲染器
  void register(OperationTarget target, OperationDataRenderer renderer) {
    _renderers[target] = renderer;
  }

  /// 获取目标类型对应的渲染器
  OperationDataRenderer? getRenderer(OperationTarget target) =>
      _renderers[target];
}
