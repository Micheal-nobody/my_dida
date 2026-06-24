# Issue #4: 增强“习惯”可配置的能力

## 1. 属性分类与推荐状态
* **分类 (Category)**: `enhancement` (需求增强)
* **状态 (State)**: `ready-for-human` (需由人工处理)

---

## 2. 诊断分析
### 关键文件与行数
* `lib/features/habits/models/habit.dart` (行数随字段扩充而定)
* `lib/features/habits/widgets/add_habit_dialog.dart` 
* `lib/features/habits/widgets/edit_habit_dialog.dart`
* `lib/features/habits/widgets/habit_check_in_dialog.dart`

### 原因解析
当前本系统的“习惯”功能偏弱：
1. 虽然习惯实体定义了 `rrule` 重复规则，但在添加和修改习惯的交互表框中没有任何入口配置重复频次，一律默认为“每天”。
2. 习惯没有区分类型。用户希望能有是/否类型、数值类型（如每日喝水 2000 毫升，单次打卡输入 250ml）以及专注时间类型（每日专注 60 分钟）。
3. 打卡弹框 `habit_check_in_dialog.dart` 不支持单次打卡录入具体数值。

该 Issue 涉及 Isar 数据库中 `Habit` 实体模型的属性扩展、生成文件的更新、以及全新打卡业务细节的设计和界面表单交互。因此更适合人工进行方案设计与表结构设计。

---

## 3. 推荐实施路线
### 1. 模型与数据库层扩展
在 `lib/features/habits/models/habit.dart` 中增加：
* `String habitType`（代表 `'yesNo'` , `'count'` , `'duration'` 三种类型之一）。
* `String? unit` (如 `'毫升'` , `'页'` 等，专用于次数型习惯)。
* 并在每次修改完后，运行 `dart run build_runner build --delete-conflicting-outputs` 重新生成 Isar 适配层。

### 2. 引入重复配置与习惯配置表单
* 在 `add_habit_dialog.dart` 中，为用户添加“习惯类型”（是/否型、次数型、时长型）和“单位”、“每次默认增量”输入输入框。
* 加入频率配置，复用 `lib/shared/widgets/datetime/custom_repeat_picker.dart` 重复规则选择器，将返回的选择映射入 `rrule`。

### 3. 多元化打卡弹框
* 优化 `habit_check_in_dialog.dart`，如果检测到习惯属于 `'count'` 或 `'duration'`，在滑动打卡按钮的上方提供一个数字加减或手动输入的输入框，允许用户每次自定义具体的数值打卡进度。
