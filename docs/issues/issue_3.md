# Issue #3: 任务成功删除时提示“任务不存在或已删除”

## 1. 属性分类与推荐状态
* **分类 (Category)**: `bug` (缺陷)
* **状态 (State)**: `ready-for-agent` (可交由 Agent 自动修复)

---

## 2. 诊断分析
### 关键文件与行数
* `lib/features/tasks/pages/task_detail_page.dart`
  * 发生位置: 第 93 - 108 行 (`initState` 中的 stream listener)。

### 原因解析
在任务详情页的 `initState` 中，为了监听 Isar 数据库中当前 Task 详情实体的变动，页面监听了一个 Stream：
```dart
_taskSub = _taskProvider.watchTaskById(widget.taskId).listen((t) {
  ...
  if (t == null && !_didShowMissingTaskMessage) {
    _didShowMissingTaskMessage = true;
    getIt<AppMessageService>().showWarning('任务不存在或已删除');
  }
});
```
当用户在详情页里主动点击“删除”按钮时，数据库中的 Task 数据被移去，这导致 watch 监听到的 stream 立刻触发吐出 `null`。
但详情页可能还处于关闭动画中、或还没有来得及被 Navigator 卸载 Pop 掉。由于 `_didShowMissingTaskMessage` 为 `false` 且 `t == null`，上面的监听逻辑便被触发，显示了误导性的“任务不存在或已删除”警告弹窗。

---

## 3. 修复方案
### 修改逻辑
我们需要区分“被其他端或后台意外删除”与“用户主动在该详情页中点击删除”这两种行为。
1. 在 `_TaskDetailPageState` 中增加一个 `bool _isDeletingActively = false;` 变量。
2. 当用户主动点击删除按钮触发删除动作前，将 `_isDeletingActively` 置为 `true`。同时，可在发起删除操作前直接调用 `_taskSub?.cancel()` 取消监听，以此彻底避免该监听抛出数据更新。
3. 在监听回调的警告触发前，增加对该标志位的检验：
   ```dart
   if (t == null && !_didShowMissingTaskMessage && !_isDeletingActively) {
     _didShowMissingTaskMessage = true;
     getIt<AppMessageService>().showWarning('任务不存在或已删除');
   }
   ```
