# ADR 0002: 使用 Provider 进行应用级与页面级状态管理

## 状态
已接受 (Accepted)

## 背景
“My Dida” 包含多个功能模块（待办、日历、四象限、习惯、番茄钟），这些模块之间存在深度的状态联动。
例如：
* 用户在侧边栏中切换当前选中的清单（`currentChecklist`）时，主界面的待办任务列表需要级联过滤，仅显示该清单下的任务。
* 侧边栏的清单列表需要动态统计每个清单内未完成任务的数量。
* 在番茄专注界面完成一次番茄钟后，需要级联更新关联任务的累计专注时间。

为了让视图层（UI）与底层的数据访问层（Repository）解耦，并实现高效的多层状态更新，我们需要一个成熟的状态管理方案。

## 决策
我们决策使用 **`provider`** 库作为核心的状态管理框架。

具体的设计模式如下：
1. **全局状态注入**：在 `lib/main.dart` 中，使用 `MultiProvider` 注入全局状态单例，如 `ChecklistProvider`、`HabitProvider`、`TomatoProvider` 等。
2. **读写分离与单一职责**：
   - 每个 Provider 主要负责其对应业务实体的内存状态维护，并在数据改变时调用 `notifyListeners()`。
   - 视图组件通过 `context.watch<T>()` 渲染 UI，通过 `context.read<T>()` 调用业务方法。
3. **Provider 级联联动 (Dependency Injection & ProxyProvider)**：
   - 针对 `TaskProvider` 需要监听 `ChecklistProvider` 的当前选中清单的场景，在 `MultiProvider` 中采用 `ChangeNotifierProxyProvider<ChecklistProvider, TaskProvider>`。
   - 当 `ChecklistProvider` 变更当前清单时，`update` 方法会自动触发，重新调用 `TaskProvider.updateCurrentTasks` 方法，以自动过滤并呈现相应清单下的任务。

## 后果
* **正面影响**：
  - 代码层次结构清晰：UI 只负责展示和用户手势响应，复杂的业务状态和联动流转集中在 Provider 层处理。
  - 数据响应式更新：得益于 `ProxyProvider` 的级联监听，开发者不需要手动在各个页面之间传递事件总线或回调，状态自动同步。
* **负面影响**：
  - 如果 Provider 的职责划分不当，可能会导致不必要的子组件重建。需要注意使用 `Selector` 或在特定场景只 `read` 而不 `watch`，以优化渲染性能。
