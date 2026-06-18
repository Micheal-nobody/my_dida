# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 约束与规范
* **使用中文输出**：与用户的所有沟通、讨论、解答都必须使用中文。
* **优先使用 Dart MCP 工具**：Dart MCP 服务器已连接（`claude mcp list` 确认），涉及 Dart/Flutter 操作（代码分析、运行测试、代码格式化、应用启动、热重载、Flutter Driver 等）时，应优先使用 Dart MCP 提供的工具，而非直接通过 Bash 执行 shell 命令。

## 常用开发命令
* 运行/构建应用：`flutter run`
* 代码静态检查：`flutter analyze`
* 代码格式化：`dart format .`
* 运行所有测试：`flutter test`
* 运行单个测试：`flutter test <file_path>` (例如 `flutter test test/task_service_test.dart`)
* 代码与数据模型类生成：`dart run build_runner build` (可追加 `--delete-conflicting-outputs` 参数来强制覆盖冲突文件)

## 代码架构介绍
* **状态管理 (State Management)**：采用 `provider` 库包装核心状态。`ChecklistProvider`、`HabitProvider`、`OperationStackProvider` 以及 `TaskProvider` 在 `lib/main.dart` 中完成注册。其中 `TaskProvider` 基于 `ChangeNotifierProxyProvider` 监听 `ChecklistProvider` 的当前清单变化并进行对应的联动更新。
* **依赖注入 (Dependency Injection)**：在 `lib/config/locator.dart` 中使用 `locator (GetIt)` 进行注册和管理。初始化并注入 `Isar` 数据库实例，同时注册了各个仓储类 (Repositories)、通知服务、本地提醒以及业务服务单例。
* **数据库与实体模型 (Database & Entities)**：使用 Isar 数据库 (`isar_community`)。实体定义位于 `lib/model/entity/` 目录中，依赖 build_runner 自动生成对应的 Isar 数据表结构文件 (`*.g.dart`)。
* **路由管理 (Routing)**：使用 `go_router` 库，具体配置主要定义在 `lib/router/go_router.dart` 中。
* **通知与提醒 (Notifications & Reminders)**：基于 `flutter_local_notifications` 封装了 `NotificationService`，并通过 `TaskReminderService` 结合具体的 `TaskReminderSchedulerPort` 实现对于任务通知和本地提醒的调度管理。
* **操作历史与撤销重做 (Undo/Redo System)**：通过 `OperationStackProvider` 控制并管理用户的操作历史（如任务、习惯的增加、删除和修改），实现业务逻辑上的撤销和重做。
