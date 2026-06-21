# ADR 0004: 通过调度器端口解耦任务定时提醒与底层通知服务

## 状态
已接受 (Accepted)

## 背景
“My Dida” 拥有完善的任务提醒功能，支持单次提醒、多次提醒、每天/每周/每月重复提醒。提醒的本质是操作系统级的本地通知定时调度，在 Flutter 生态中，主要是通过 `flutter_local_notifications` 插件与底层 iOS/Android 的 AlarmManager/UNUserNotificationCenter 交互。

然而，第三方通知插件往往具有以下痛点：
* 插件 API 复杂且平台相关性强，代码难以编写单元测试（Unit Test）。
* 如果将来插件维护停止，或者需要替换为更强大的第三方通知引擎（如 WorkManager 或 Firebase Cloud Messaging），业务层代码将面临大规模重构。

## 决策
我们决策在提醒服务中采用 **端口-适配器（Ports and Adapters，即六边形架构）** 模式。

具体设计如下：
1. **定义端口接口 (`TaskReminderSchedulerPort`)**：
   - 位于 `lib/services/task_reminder_scheduler_port.dart`。
   - 作为一个抽象接口类，定义了核心的方法，例如：
     - `Future<void> scheduleTaskReminder(Task task)`：为任务安排一个本地定时通知。
     - `Future<void> cancelTaskReminder(int taskId)`：取消某个任务的所有已调度通知。
     - `Future<void> cancelAllReminders()`：取消所有通知。
   - 这一层完全使用领域模型对象（如 `Task` 实体），没有任何第三方插件依赖。
2. **实现具体适配器 (`FlutterLocalTaskReminderScheduler`)**：
   - 位于 `lib/services/flutter_local_task_reminder_scheduler.dart`。
   - 它是 `TaskReminderSchedulerPort` 的子类，内部包裹并依赖了 `flutter_local_notifications`。
3. **依赖注入容器解耦**：
   - 在 `lib/config/locator.dart` 中，我们通过 `locator.registerLazySingleton<TaskReminderSchedulerPort>(...)` 注册具体的适配器。
   - 业务逻辑层 `TaskReminderService` 仅通过 `locator<TaskReminderSchedulerPort>()` 拿到接口，对其进行调用，完全感知不到具体的通知引擎细节。

## 后果
* **正面影响**：
  - **业务逻辑可测性**：在编写 `TaskReminderService` 的单元测试时，我们可以极易地提供一个 `NoopTaskReminderScheduler` 或模拟的 `MockTaskReminderScheduler` 注入到 locator 中，完全不需要模拟真实的通知运行环境。
  - **容易替换**：如果未来更换通知技术（例如替换为 WorkManager 进行精准闹钟调度），只需新增一个实现了 `TaskReminderSchedulerPort` 的适配器并在 `locator.dart` 中替换注册，无须修改任何核心业务代码。
* **负面影响**：
  - 增加了一层抽象接口和注册关系，需要开发者在梳理调用链路时跨越接口定义。
