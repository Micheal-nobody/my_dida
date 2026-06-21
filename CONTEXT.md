# Domain Context: My Dida (我的滴答)

本文档是“My Dida”项目的核心领域上下文，定义了项目的业务背景、通用语言（Glossary）、技术栈以及核心架构决策。

---

## 1. 业务背景 (Business Context)

"My Dida"（我的滴答）是一款面向个人效能管理的 Flutter 移动应用程序（类似于滴答清单/TickTick）。它旨在帮助用户管理日常待办任务、建立和维持良好习惯、通过番茄钟进行专注时间管理，并通过多维度的日历和四象限视图来规划和回顾日程。

---

## 2. 通用语言与核心实体 (Ubiquitous Language)

为了在代码、工单和讨论中保持术语一致，特定义以下核心领域词汇：

* **任务 (Task)**：用户需要完成的具体待办事项。
  * 对应实体：`lib/model/entity/task.dart`
  * 属性包括：标题、描述、开始/截止时间、重复规则（基于 RRule）、优先级、关联清单 ID，以及关联的提醒计划。
* **清单 (Checklist)**：任务的分组容器，用户可以自定义清单来归类任务（例如“工作”、“生活”）。
  * 对应实体：`lib/model/entity/checklist.dart`
* **检查点 (CheckPoint)**：任务内部的细分步骤（子任务），以嵌入集合形式直接存储在 `Task` 实体中，不支持跨任务共享。
  * 对应实体：`lib/model/entity/check_point.dart`
* **习惯 (Habit)**：用户期望长期培养的行为（如“早起”、“背单词”）。
  * 对应实体：`lib/model/entity/habit.dart`
  * 具有独立的打卡频次、提醒时间，并记录当前连续打卡天数（currentStreak）与历史最长打卡天数。
* **打卡记录 (HabitCheckInRecord)**：每次习惯打卡所产生的历史记录，包含打卡的时间戳。
  * 对应实体：`lib/model/entity/habit_check_in_record.dart`
* **番茄记录 (TomatoRecord)**：用户使用番茄钟进行专注的历史记录，包括专注的时长、开始时间以及关联的任务。
  * 对应实体：`lib/model/entity/tomato_record.dart`
* **操作 (Operation)**：记录用户对任务或习惯进行增、删、改等敏感操作的历史快照，用于支持撤销与重做。
  * 对应实体：`lib/model/entity/operation.dart`
* **提醒计划 (TaskReminderPlan)**：定义任务在何时以何种方式向用户发送通知的配置值对象。
  * 对应 VO：`lib/model/vo/task_reminder_plan.dart`

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
* `lib/pages/`：路由绑定的完整视图层页面（如 `CalendarPage`、`HabitsPage` 等）。
* `lib/features/`：细粒度的 UI 功能子模块、卡片组件（`cards/`）与交互弹窗（`dialogs/`）。
* `lib/provider/`：状态管理层，作为 UI 视图层与底层 Service / Repository 之间的桥梁。
* `lib/model/`：领域数据模型，包含 Isar 实体（`entity/`）与视图展示层的值对象（`vo/`）。
* `lib/repository/`：数据访问层，封装了针对 Isar 数据库各个 Table 的增删改查。
* `lib/services/`：核心业务逻辑服务，如重复任务的日程投影投影服务、通知调度服务等。
* `lib/config/`：全局应用配置（日志、定位器等）。
* `lib/router/`：路由配置文件。
* `lib/constants/`：尺寸、颜色、图标等静态常量配置。
* `lib/core/`：核心校验逻辑与异常基类。
* `lib/shared/`：跨页面的公共 UI 控件。

### 4.2 撤销与重做设计 (Undo/Redo System)
由 `OperationStackProvider` 统一管理用户的操作历史。通过保存 `Operation` 实体（其中含有修改前后的 JSON 状态快照），由 `GenericOperationReverter` 进行解析回滚，在业务层实现轻量级的命令撤销与重做。

### 4.3 提醒服务的端口与适配器模式 (Ports and Adapters)
`TaskReminderService`（业务逻辑）不直接依赖具体的本地通知组件，而是面向 `TaskReminderSchedulerPort` 接口（端口）进行编程。具体的提醒发送行为由 `FlutterLocalTaskReminderScheduler`（适配器）来实现，该设计极大地提高了业务逻辑的可测试性，并隔离了平台底层插件。

---

## 5. 架构决策记录 (ADRs)
有关详细的底层技术方案和决策动机，请参阅架构决策记录目录：
* [ADR-0001: 使用 Isar 数据库进行本地结构化存储](docs/adr/0001-use-isar-database-for-local-storage.md)
* [ADR-0002: 使用 Provider 进行应用级与页面级状态管理](docs/adr/0002-state-management-via-provider.md)
* [ADR-0003: 采用基于命令模式的操作栈实现撤销重做系统](docs/adr/0003-command-pattern-for-undoredo-operation-stack.md)
* [ADR-0004: 通过调度器端口解耦任务定时提醒与底层通知服务](docs/adr/0004-decoupled-reminders-via-scheduler-port.md)
