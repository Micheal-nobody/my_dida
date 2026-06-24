# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 约束与规范
* **使用中文输出**：与用户的所有沟通、讨论、解答都必须使用中文。

## 常用开发命令
* 运行/构建应用 (多环境)：
  * 开发环境：`flutter run -t lib/main_dev.dart`
  * 测试环境：`flutter run -t lib/main_test.dart`
  * 生产环境：`flutter run -t lib/main_prod.dart`
  * 构建生产环境 APK：`flutter build apk -t lib/main_prod.dart --release`
* 代码静态检查：`flutter analyze`
* 代码格式化：`dart format .`
* 运行所有测试：`flutter test`
* 运行单个测试：`flutter test <file_path>` (例如 `flutter test test/task_service_test.dart`)
* 代码与数据模型类生成：`dart run build_runner build` (可追加 `--delete-conflicting-outputs` 参数来强制覆盖冲突文件)

## 核心目录职责划分
* `lib/features/`：细粒度的、按业务领域隔离的功能模块（包括 `tasks`、`habits`、`tomato`、`calendar`、`checklist`、`settings`、`operation_undo`）。每个模块内部采用分层组织（`models/` , `repositories/` , `providers/` , `services/` , `pages/` , `widgets/`），不同业务模块隔离，禁止直接跨模块操作数据库。
* `lib/core/`：系统级、无业务逻辑的基础设施（核心路由表、依赖注入 DI 容器、全局日志 logger、统一输入验证、通用错误、全局 AppMessageUI 提示）。同时包含三套环境的隔离配置。
* `lib/shared/`：跨业务模块复用的公共 UI 小部件（如公共选择组件、网格布局）和实体基类。

## 代码架构介绍
* **环境隔离 (Environment Isolation)**：采用抽象配置类 `AppConfig`，通过 `lib/main_dev.dart` , `lib/main_test.dart` , `lib/main_prod.dart` 实现开发、测试、生产环境隔离，不硬编码环境变量。
* **状态管理 (State Management)**：采用 `provider` 库包装核心状态。`ChecklistProvider`、`CalendarPageProvider`、`HabitProvider`、`TomatoProvider`、`SidebarConfigProvider`、`OperationStackProvider` 以及 `TaskProvider` 在各模块定义并注册在 `lib/main.dart` 的 MultiProvider 中。
* **依赖注入 (Dependency Injection)**：在 `lib/core/di/locator.dart` 中使用 `locator (GetIt)` 进行注册和管理。根据当前运行的 `AppConfig` 初始化注入 `Isar` 数据库实例，并注册各个仓储类 (Repositories)、服务单例与领域撤销管理器。
* **数据库与实体模型 (Database & Entities)**：使用 Isar 数据库 (`isar_community`)。实体定义位于各模块的 `models/` 目录中，依赖 build_runner 自动生成对应的 Isar 数据表结构文件 (`*.g.dart`)。
* **路由管理 (Routing)**：使用 `go_router` 库，配置定义在 `lib/core/router/go_router.dart` 中。
* **操作历史与撤销重做 (Undo/Redo System)**：通过操作栈控制用户的操作历史。引入 `DomainOperationReverter` 领域撤销委托接口，各业务模块（`tasks`、`habits`）注册具体实现至 `EntityRegistry`，由 `GenericOperationReverter` 实现真正的领域边界隔离。

## Agent skills

### Issue tracker

本仓库的问题与产品需求文档均以GitHub工单形式管理。外部提交的合并请求不纳入工单分类处理范围。详情参见`docs/agents/issue-tracker.md`。

### Triage labels

使用标准工单分类标签体系（`needs-triage`待分类、`needs-info`需补充信息、`ready-for-agent`可交由自动化处理、`ready-for-human`需人工处理、`wontfix`不予修复）。详情参见`docs/agents/triage-labels.md`。

### Domain docs

采用单一上下文文档架构（仓库根目录放置全局`CONTEXT.md`文件 + `docs/adr/`架构决策记录目录）。详情参见`docs/agents/domain.md`。
