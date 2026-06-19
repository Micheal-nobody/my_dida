# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 约束与规范
* **使用中文输出**：与用户的所有沟通、讨论、解答都必须使用中文。

## 常用开发命令
* 运行/构建应用：`flutter run`
* 代码静态检查：`flutter analyze`
* 代码格式化：`dart format .`
* 运行所有测试：`flutter test`
* 运行单个测试：`flutter test <file_path>` (例如 `flutter test test/task_service_test.dart`)
* 代码与数据模型类生成：`dart run build_runner build` (可追加 `--delete-conflicting-outputs` 参数来强制覆盖冲突文件)

## 核心目录职责划分
* `lib/pages/`：路由导航直接绑定的完整功能页面（如搜索、设置、日历、待办主页）。
* `lib/features/`：细粒度的 UI 功能子模块、卡片组件（`cards/`）与交互弹窗（`dialogs/`）。
* `lib/provider/`：全局/局部状态管理（基于 `provider` 库，作为 UI 层与业务逻辑层的纽带）。
* `lib/model/`：数据模型定义，包括 Isar 数据库的实体类（`entity/`）与界面展示 VO 数据对象（`vo/`）。
* `lib/repository/`：底层 Isar 数据库仓储数据访问层（管理各表单的数据增删改查）。
* `lib/services/`：具体业务实现服务（如日历日程投影服务、提醒发送与通知调度服务）。
* `lib/config/`：应用全局启动级配置，包括依赖注入容器（`locator.dart`）和全局日志（`logger.dart`）。
* `lib/router/`：基于 `go_router` 包装的应用程序路由表及上下文 Key。
* `lib/utils/`：通用辅助逻辑与计算工具（如日期工具、重复规则解析 RRule、搜索历史管理器）。

## 代码架构介绍
* **状态管理 (State Management)**：采用 `provider` 库包装核心状态。`ChecklistProvider`、`HabitProvider`、`OperationStackProvider` 以及 `TaskProvider` 在 `lib/main.dart` 中完成注册。其中 `TaskProvider` 基于 `ChangeNotifierProxyProvider` 监听 `ChecklistProvider` 的当前清单变化并进行对应的联动更新。
* **依赖注入 (Dependency Injection)**：在 `lib/config/locator.dart` 中使用 `locator (GetIt)` 进行注册和管理。初始化并注入 `Isar` 数据库实例，同时注册了各个仓储类 (Repositories)、通知服务、本地提醒以及业务服务单例。
* **数据库与实体模型 (Database & Entities)**：使用 Isar 数据库 (`isar_community`)。实体定义位于 `lib/model/entity/` 目录中，依赖 build_runner 自动生成对应的 Isar 数据表结构文件 (`*.g.dart`)。
* **路由管理 (Routing)**：使用 `go_router` 库，具体配置主要定义在 `lib/router/go_router.dart` 中。
* **通知与提醒 (Notifications & Reminders)**：基于 `flutter_local_notifications` 封装了 `NotificationService`，并通过 `TaskReminderService` 结合具体的 `TaskReminderSchedulerPort` 实现对于任务通知和本地提醒的调度管理。
* **操作历史与撤销重做 (Undo/Redo System)**：通过 `OperationStackProvider` 控制并管理用户的操作历史（如任务、习惯的增加、删除和修改），实现业务逻辑上的撤销和重做。
