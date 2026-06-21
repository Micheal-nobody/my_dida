# ADR 0003: 采用基于命令模式的操作栈实现撤销重做系统

## 状态
已接受 (Accepted)

## 背景
作为一个高效能清单应用，用户高频地进行任务的添加、勾选完成、修改截止时间、甚至删除操作。误触是一个很常见的现象。为了提供优秀的用户体验，需要支持对于用户关键敏感操作的“撤销 (Undo)”与“重做 (Redo)”功能。

实现撤销重做有两种常见模式：
1. **全量快照模式**：每次状态变化保存整个数据库或内存的快照。优点是实现简单，缺点是内存/磁盘开销极大。
2. **命令模式 (Command Pattern) / 状态记录模式**：只记录操作的动作类型（新增/修改/删除）以及修改前后状态的 Diff，撤销时根据操作类型和数据差异进行反向还原。

## 决策
我们决策使用**命令模式结合操作日志记录表**来构建撤销重做系统。

核心架构设计如下：
1. **Isar 实体 `Operation`**：
   - 对应实体为 `lib/model/entity/operation.dart`。
   - 每次用户执行关键操作时，系统都会向本地 Isar 数据库的 Operation 表插入一条记录。
   - 字段包括：`actionType` (动作类型: add, delete, update 等)、`targetType` (目标对象: task, habit 等)、`beforeState` (修改前的数据 JSON 字符串) 和 `afterState` (修改后的数据 JSON 字符串)。
2. **统一撤销重做机制 (`OperationStackProvider`)**：
   - `OperationStackProvider` 负责统一管理内存中的操作栈。
   - 初始化时从 Isar 中拉取最近的操作日志。当用户触发撤销（Undo）时，获取栈顶的 `Operation` 记录，将其分发给 `GenericOperationReverter` 进行处理。
3. **泛型反向处理器 (`GenericOperationReverter`)**：
   - 根据 `Operation` 内部记录的还原状态，定位对应的仓储（Repository），执行反向的数据修改、重新添加或还原删除操作，从而使数据库恢复至修改前的状态。

## 后果
* **正面影响**：
  - 存储开销低：仅记录单次操作涉及的数据 Diff (前置状态/后置状态)，不影响应用性能。
  - 数据持久化：即使应用重启，由于操作日志被持久化在 Isar 中，用户仍然可以撤销上一次打开应用时的操作。
  - 解耦良好：视图层只需要在最下方弹出一个 Snackbar，提供一个 "撤销" 按钮并调用 `OperationStackProvider.undo()`，无需关心底层数据是如何恢复的。
* **负面影响**：
  - 每当引入新的实体类型或新的操作逻辑时，均需要在 `GenericOperationReverter` 中扩展还原逻辑，增加了新功能开发的适配成本。
