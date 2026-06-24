# Issue #1: calender_page 的网格没有覆盖整个时间轴

## 1. 属性分类与推荐状态
* **分类 (Category)**: `bug` (缺陷)
* **状态 (State)**: `ready-for-agent` (可交由 Agent 自动修复)

---

## 2. 诊断分析
### 关键文件与行数
* `lib/features/calendar/widgets/calendar_widgets/virtualized_calendar_time_area.dart`
  * 发生位置: 第 210 - 224 行。

### 原因解析
在 `VirtualizedCalendarTimeArea` 的布局中，存在以下逻辑：
1. 本身定义了一个内部 `_scrollController` 并在 `ListView.builder` 中使用它。
2. 该 `ListView.builder` 的 `itemCount` 为 `activeHours.length`（通常为 24 小时）。
3. 问题在于，包含这个 `ListView.builder` 的父容器被设置了固定的高度 `widget.timeAreaHeight`，且父级在 `calendar_page` 的 `SingleChildScrollView` 中一起滚动。所以内层的 `ListView` 根本不需要滚动（也没有滚动交互发生），其 `scrollOffset` 永远为 0。
4. 导致 `_getVisibleHours` 在判定哪些 Index 应该渲染时，永远只判定前 12 - 13 个小时（0点到13点）是可见的，而 14:00 之后的小时行全被判定为不可见。
5. 判定为不可见的小时行，会被直接渲染成一个空容器：`SizedBox(height: _hourHeight)`，导致它里面的背景网格没有画出来，成了空白背景。

---

## 3. 修复方案
### 修改逻辑
由于一天的总小时数固定为 24，在性能上完全没有必要进行如此复杂的虚拟化 ListView 渲染。
1. 建议移除 `ListView.builder` 及其虚拟化逻辑。
2. 直接改用 `Column` + `List.generate` 静态展开所有的 24 小时行，不再调用 `_getVisibleHours`。
3. 移除无用的 `_scrollController`、`_getVisibleHours` 助手方法。

### 核心修改代码片段参考
```dart
// 修改前：
ListView.builder(
  controller: _scrollController,
  itemCount: activeHours.length,
  itemExtent: _hourHeight,
  itemBuilder: (context, index) {
    final visibleIndices = _getVisibleHours(activeHours);
    if (!visibleIndices.contains(index)) {
      return SizedBox(height: _hourHeight);
    }
    final actualHour = activeHours[index];
    return _buildHourRow(actualHour, availableWidth);
  },
)

// 修改后：
SingleChildScrollView(
  physics: const NeverScrollableScrollPhysics(), // 避免与外层冲突
  child: Column(
    children: List.generate(activeHours.length, (index) {
      final actualHour = activeHours[index];
      return _buildHourRow(actualHour, availableWidth);
    }),
  ),
)
```
