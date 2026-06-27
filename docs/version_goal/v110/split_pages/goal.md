# 页面拆分优化目标 (goal.md)

## 1. 页面分析

对 `lib/features/` 目录下所有 `_page.dart` 页面的行数进行分析统计：

1. `lib/features/operation_undo/pages/operation_page.dart` (1062行) - **极其臃肿**
2. `lib/features/calendar/pages/calendar_page.dart` (929行) - **中度臃肿**（但已具备一些子Widget，且业务重度集中，本次暂作为次要拆分对象）
3. `lib/features/habits/pages/habit_data_summary_page.dart` (698行) - **中度臃肿**。包含大量的图形绘制（柱状图、热力网格图等绘画类）以及打卡时间线数据渲染，没有合理的组件提取。
4. `lib/features/tasks/pages/search_page.dart` (681行) - **中度臃肿**。包含搜索历史管理交互、过滤芯片列表交互、复杂的卡片展示与高亮匹配逻辑。

### 诊断结论与优化方向
* **`operation_page.dart`**：原1062行。内部包含了繁琐的实体转换逻辑、大型详情 Dialog 逻辑、过滤 dialog 以及统计卡片组件。本次将重新拆分。
* **`habit_data_summary_page.dart`**：原698行。页面底部的 Painters 和 tab 子汇总过于庞大。可以通过提取子汇总组件（`HabitDaySummary`、`HabitWeekSummary`、`HabitMonthSummary`）或者图表组件，显著简化文件行数。
* **`search_page.dart`**：原681行。可以通过剥离高亮富文本组件、过滤 Chip 栏以及历史记录区域，使其逻辑更加轻量。

---

## 2. 预期结果与拆分方案

### A. 对 `operation_page.dart` 的拆分方案
1. **新建 `operation_filter_dialog.dart`**
   * 路径：`lib/features/operation_undo/widgets/operation_filter_dialog.dart`
   * 职责：封装操作类型的筛选弹窗交互及状态过滤逻辑。
2. **新建 `operation_stats_card.dart`**
   * 路径：`lib/features/operation_undo/widgets/operation_stats_card.dart`
   * 职责：渲染操作历史统计卡片。
3. **新建 `operation_detail_dialog.dart`**
   * 路径：`lib/features/operation_undo/widgets/operation_detail_dialog.dart`
   * 职责：封装操作详情 Dialog，包含操作前数据与操作后数据对比的渲染逻辑，并将从 JSON 构建实体的逻辑移入。

### B. 对 `habit_data_summary_page.dart` 的拆分方案
1. **新建 `habit_summary_painters.dart`**
   * 路径：`lib/features/habits/widgets/habit_summary_painters.dart`
   * 职责：转移 `_WeekBarChartPainter` 和 `_HeatmapGridPainter` 的实现，减少主页面在绘制几何图形上的杂音。
2. **在 widgets/ 文件夹中提取 `habit_day_summary_section.dart`**
   * 路径：`lib/features/habits/widgets/habit_day_summary_section.dart`
   * 职责：渲染“日汇总”界面，包括今日完成比例卡片、今日习惯清单列表和今日打卡时间线。
3. **在 widgets/ 文件夹中提取 `habit_week_summary_section.dart` 与 `habit_month_summary_section.dart`**
   * 路径：`lib/features/habits/widgets/habit_week_summary_section.dart`，`lib/features/habits/widgets/habit_month_summary_section.dart`
   * 职责：分别封装周趋势和热力图月汇总部分。

### C. 对 `search_page.dart` 的拆分方案
1. **新建 `search_filter_chips.dart`**
   * 路径：`lib/features/tasks/widgets/search_filter_chips.dart`
   * 职责：封装顶部的状态 ChoiceChips 与类型 FilterChips 按钮排布。
2. **新建 `search_history_section.dart`**
   * 路径：`lib/features/tasks/widgets/search_history_section.dart`
   * 职责：渲染历史搜索列表、清除历史动作和空白提醒。
3. **新建 `highlighted_text.dart`**
   * 路径：`lib/shared/widgets/text/highlighted_text.dart` 或 `lib/features/tasks/widgets/highlighted_text.dart`
   * 职责：高亮分段匹配富文本。

---

## 3. 重构执行记录（已完成）
* [ ] 拆分重构 `operation_page.dart`
* [ ] 拆分重构 `habit_data_summary_page.dart`
* [ ] 拆分重构 `search_page.dart`
* [ ] 运行本地测试并保证 100% 通过。
