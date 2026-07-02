# Domain Context: My Dida (我的滴答)

本文档是“My Dida”项目的核心领域上下文，定义了项目的业务背景、通用语言（Glossary）、技术栈以及核心架构决策。

---

## 1. 业务背景 (Business Context)

"My Dida"（我的滴答）是一款面向个人效能管理的 Flutter 移动应用程序（类似于滴答清单/TickTick）。它旨在帮助用户管理日常待办任务、建立和维持良好习惯、通过番茄钟进行专注时间管理，并通过多维度的日历与四象限视图来规划和回顾日程。

---

## 2. 通用语言与核心实体 (Ubiquitous Language)

为了在代码、工单和讨论中保持术语一致，特定义以下核心领域词汇：

* **任务 (Task)**：用户需要完成的具体待办事项。
  * 对应实体：`lib/features/tasks/models/task.dart`
  * 属性包括：标题、描述、开始/截止时间、重复规则（基于 RRule）、优先级、关联清单 ID，以及关联的提醒计划。
* **清单 (Checklist)**：任务的分组容器，用户可以自定义清单来归类任务（例如“工作”、“生活”）。
  * 对应实体：`lib/features/checklist/models/checklist.dart`
* **智能清单 (SmartList) 与清单值对象 (ChecklistVO)**：智能清单用于按照特定业务逻辑动态过滤任务（如“今天”、“明天”、“最近7天”、“所有”、“已完成”、“垃圾箱”、“收集箱”）。它在底层通过负数 ID 区分，但在 UI 交互与数据层中，通过 `ChecklistVO` 值对象对物理清单与智能清单进行统一封装和表达。
  * 对应值对象：`lib/features/checklist/models/checklist_vo.dart`
* **检查点 (CheckPoint)**：任务内部的细分步骤（子任务），以嵌入集合形式直接存储在 `Task` 实体中，不支持跨任务共享。
  * 对应实体：`lib/features/tasks/models/check_point.dart`
* **习惯 (Habit)**：用户期望长期培养的行为（如“早起”、“背单词”）。
  * 对应实体：`lib/features/habits/models/habit.dart`
  * 支持三种打卡类型（`HabitType`：是/否打卡、次数打卡、时间打卡），并关联了单次目标值（targetValue）与当前值（currentValue）。具有独立的提醒时间，并记录当前累计打卡次数（currentCheckInCount）、总打卡次数与历史最长连续打卡天数。
* **打卡记录 (HabitCheckInRecord)**：每次习惯打卡所产生的历史记录，包含打卡的时间戳。
  * 对应实体：`lib/features/habits/models/habit_check_in_record.dart`
* **番茄记录 (TomatoRecord)**：用户使用番茄钟进行专注的历史记录，包括专注的时长、开始时间、是否完成以及关联的任务。
  * 对应实体：`lib/features/tomato/models/tomato_record.dart`
* **自定义番茄 (CustomTomato)**：用户配置的个性化番茄钟模板，包含自定义名称与专注时间。
  * 对应实体：`lib/features/tomato/models/custom_tomato.dart`
* **操作 (Operation)**：记录用户对任务、习惯或清单进行增、删、改等敏感操作的历史快照，用于支持撤销与重做。
  * 对应实体：`lib/features/operation_undo/models/operation.dart`
* **提醒计划 (TaskReminderPlan)**：定义任务在何时以何种方式向用户发送通知的配置值对象。
  * 对应 VO：`lib/features/tasks/models/task_reminder_plan.dart`

---

## 3. 技术栈 (Technical Stack)

* **UI 开发框架**：Flutter
* **本地数据库**：Isar 数据库 (`isar_community`) - 强类型、支持嵌入对象、ACID 事务，通过 `build_runner` 生成结构代码。
* **状态管理**：Provider 状态管理库 - 使用 `MultiProvider` 集中注册，使用 `ChangeNotifierProxyProvider` 处理不同状态之间的依赖联动。
* **依赖注入**：GetIt (`locator.dart`) - 用于管理仓储层和服务层单例的初始化与获取。
* **路由管理**：GoRouter - 提供声明式路由，支持参数化页面导航。
* **本地通知服务**：`flutter_local_notifications` - 实现定时提醒与即时通知。

---

## 4. 架构设计与核心模式

### 4.1 核心目录划分与职责
* `lib/features/`：细粒度的、按业务领域隔离的功能模块（包括 `tasks`、`habits`、`tomato`、`calendar`、`checklist`、`settings`、`operation_undo`）。每个模块内部采用分层组织：
  - `models/`：领域数据模型，包含 Isar 实体与值对象（VO）。
  - `repositories/`：数据访问层，封装了针对对应数据表的增删改查。
  - `providers/`：状态管理层，作为 UI 视图层与底层 Service/Repository 之间的桥梁。
  - `services/`：核心业务逻辑服务（如通知发送、重复任务投影等）。
  - `pages/`：路由绑定的完整视图层页面（如 `TaskPage`、`HabitsPage`、`TomatoPage` 等）。
  - `widgets/`：模块内部复用的 UI 组件（如卡片组件与交互弹窗等）。
* `lib/core/`：系统级、无业务逻辑基础设施：
  - `config/`：全局应用环境隔离配置（开发、测试、生产环境）。
  - `di/`：依赖注入（GetIt）定位器配置。
  - `logger/`：全局日志工具。
  - `router/`：基于 `go_router` 的核心路由表。
  - `ui/`：全局提示等 UI 交互辅助服务。
* `lib/shared/`：跨业务模块复用的公共 UI 小部件（如公共选择组件、自定义日期选择器）和实体基类。

### 4.2 撤销与重做设计 (Undo/Redo System)
由 `OperationStackProvider` 统一管理用户的操作历史。系统通过将用户对任务、习惯、清单的敏感操作序列化为 `Operation` 实体并持久化存储在 Isar 中。
为了实现撤销逻辑与具体业务实体以及 UI 表现的完全解耦，系统采用了双重注册机制：
* **还原解耦 (`EntityRegistry`)**：定义了通用撤销委托接口 `DomainOperationReverter`。各业务模块只需向 `EntityRegistry` 注册对应的撤销逻辑实现，统一的 `GenericOperationReverter` 即可通过泛型反射自动分发执行还原（如 `TaskOperationReverter`）。
* **渲染解耦 (`OperationRendererRegistry`)**：定义了数据渲染器接口 `OperationDataRenderer`。各业务模块向注册表注册其渲染卡片逻辑，撤销历史列表在呈现快照时动态获取并渲染，避免了撤销历史 UI 直接硬编码依赖各个业务实体的细节。

### 4.3 提醒服务的端口与适配器模式 (Ports and Adapters)
`TaskReminderService`（业务逻辑）不直接依赖具体的本地通知组件，而是面向 `TaskReminderSchedulerPort` 接口（端口）进行编程。具体的提醒发送行为由 `FlutterLocalTaskReminderScheduler`（适配器）来实现，该设计极大地提高了业务逻辑的可测试性，并隔离了平台底层插件。

### 4.4 领域事件总线模式 (Event Bus)
系统设计了全局的 `EventBus` 总线实现解耦式的模块联动通信。当某个业务模块发生关键状态变更时（例如关联番茄钟的完成状态、清单的删除与恢复等），模块不会同步调用其他业务模块的逻辑，而是异步发出领域事件（例如 `ChecklistDeletedEvent`），由对应的领域协同监听器（如 `TaskEventListener`）进行统一捕获并做出相应的状态调整。这确保了核心模块之间具有极高的自闭合度。

---

## 5. 架构决策记录 (ADRs)
有关详细的底层技术方案与决策动机，请参阅架构决策记录目录：
* [ADR-0001: 使用 Isar 数据库进行本地结构化存储](docs/adr/0001-use-isar-database-for-local-storage.md)
* [ADR-0002: 使用 Provider 进行应用级与页面级状态管理](docs/adr/0002-state-management-via-provider.md)
* [ADR-0003: 采用基于命令模式的操作栈实现撤销重做系统](docs/adr/0003-command-pattern-for-undoredo-operation-stack.md)
* [ADR-0004: 通过调度器端口解耦任务定时提醒与底层通知服务](docs/adr/0004-decoupled-reminders-via-scheduler-port.md)
