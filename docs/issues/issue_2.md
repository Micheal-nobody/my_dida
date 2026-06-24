# Issue #2: calender_page 渲染任务无论是否具有具体时间都只会被渲染在“无具体时间区域”

## 1. 属性分类与推荐状态
* **分类 (Category)**: `bug` (缺陷)
* **状态 (State)**: `ready-for-agent` (可交由 Agent 自动修复)

---

## 2. 诊断分析
### 关键文件与行数
1. `lib/features/calendar/services/task_calendar_projection_service.dart` 
   * 发生位置: 第 202 - 209 行 (`_shouldRenderInAllDaySection`)
2. `lib/features/tasks/widgets/task_date_time_picker.dart`
   * 发生位置: 第 35 行
3. `lib/shared/widgets/datetime/custom_date_time_picker.dart`
   * 发生位置: 第 166 - 179 行 (`_normalizeValue`)

### 原因解析
1. 在 `task_calendar_projection_service.dart` 中，其筛选全天展示部分的规则为：
   ```dart
   bool _shouldRenderInAllDaySection(Task task) {
     if (task.startTime == null) return true;
     return task.isAllDay || (task.startTime!.hour == 0 && task.startTime!.minute == 0);
   }
   ```
   这就导致了一个致命 bug：如果一个非全天任务（例如：具体设置在 00:00 - 01:00 进行的任务），它的 `startTime` 的小时和分钟是 0，它也会被错误判定并强行丢到 "AllDay"（全天/无具体时间）区域，而不在 00:00 刻度对应的网格行里显示。
2. 当在 Calendar 视图里点击已渲染卡片并修改时间时，`task_date_time_picker.dart` 会通过 `taskProvider.execute(UpdateTimeRange(task, startTime, endTime))` 更新时间。但由于在创建 `UpdateTimeRange` 操作时，没有传入 `isAllDay` 的参数，因此底层默认沿用了原有的 `isAllDay` 值（这往往是 `true`），导致修改完后依旧被当作全天任务渲染。
3. `CustomDateTimePicker` 在内部执行时间数据标准化 `_normalizeValue` 时，没有对 `isAllDay` 状态进行复制和保存，从而丢失了时间是否为“全天”的选择。

---

## 3. 修复方案
### 修改逻辑
1. 简化 `_shouldRenderInAllDaySection` 过滤条件，使其仅受 `task.isAllDay` 字段决定（或者在 `startTime == null` 时为真）：
   ```dart
   bool _shouldRenderInAllDaySection(Task task) {
     if (task.startTime == null) return true;
     return task.isAllDay;
   }
   ```
2. 修复 `task_date_time_picker.dart:35`：在触发 `UpdateTimeRange` 时，把解析出的 `timeInfo.isAllDay` 状态带上：
   ```dart
   await taskProvider.execute(UpdateTimeRange(task, startTime, endTime, isAllDay: timeInfo.isAllDay));
   ```
3. 在 `custom_date_time_picker.dart` 的 `_normalizeValue` 里，加入 `isAllDay` 字段逻辑：
   ```dart
   isAllDay: _tabController.index == 0 ? (_value.startTime == null) : _value.isAllDay
   ```
   以此将选择后的全天状态准确传递出去。
