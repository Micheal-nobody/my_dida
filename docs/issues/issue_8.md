# Issue #8: 添加任务时时间无法被正确添加

## 1. 属性分类与推荐状态
* **分类 (Category)**: `bug` (缺陷)
* **状态 (State)**: `ready-for-agent` (可交由 Agent 自动修复)

---

## 2. 诊断分析
### 关键文件与行数
1. `lib/features/tasks/widgets/add_task_dialog.dart`
   * 发生位置: 第 394 - 461 行 (`_buildTaskFromForm` 方法中)。
2. `lib/shared/widgets/datetime/calendar_widget.dart`
   * 发生位置: 第 129 - 132 行。

### 原因解析
1. **无法在添加时添加具体时间**：
   在 `_buildTaskFromForm` 中，它将输入表单拼装为 `Task` 对象。在组合开始时间 `finalStart` 和结束时间 `finalEnd` 时：
   当 `isAllDay` 为 `false` 且 `startTime` 不为空时，如果使用 `_dateTimePickerValue.startTime`，代码却仅仅考虑了：
   `_dateTimePickerValue.startDate ?? _dateTimePickerValue.selectedDate`，并根据全天条件进行处理。这导致非全天具体时间没有合并到 `finalStart` 中，或者直接丢失了时间段的分秒值，致使存库时仅保留了日期，失去了具体分秒。
2. **日历/列表修改时间后 Picker 不实时刷新**：
   在 `calendar_widget.dart:129` 处，当用户通过点击“时间”选项行从 `CustomTimePicker` 选取了具体时间返回时，代码调用了：
   `_updateValue(_value.copyWith(selectedTime: pickedTime, rrule: _value.rrule));`
   因为没将 `isTimeOnlyDate: false` 进行重置，系统沿用了之前 input 的 `isTimeOnlyDate = true` 的状态。而在渲染 `SelectionRow` 时间栏时，因为 `isTimeOnlyDate` 依旧为 `true`，导致 `SelectionRow` 把值算为“无”，让用户感到选择时间失败。

---

## 3. 修复方案
### 修改逻辑
1. **修复 `_buildTaskFromForm` 时间拼接**：
   在 `_dateTimePickerValue.startTime` 不为 null 且 `isAllDay` 不为 true 的判定分支里，用 `DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute)` 正确构建带有具体小时分秒的 `finalStart`（`finalEnd` 同理）。
2. **修复 `calendar_widget.dart` 中的 isTimeOnlyDate 重置**：
   在 pickedTime 确认返回时，强制将 `isTimeOnlyDate` 更新为 `false`：
   ```dart
   _updateValue(
     _value.copyWith(
       selectedTime: pickedTime, 
       rrule: _value.rrule, 
       isTimeOnlyDate: false, // 设为 false
     ),
   );
   ```
