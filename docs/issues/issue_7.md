# Issue #7: 简要任务添加 dialog 输入时样式异常

## 1. 属性分类与推荐状态
* **分类 (Category)**: `bug` (缺陷)
* **状态 (State)**: `ready-for-agent` (可交由 Agent 自动修复)

---

## 2. 诊断分析
### 关键文件与行数
* `lib/features/tasks/widgets/add_task_dialog.dart`
  * 发生位置: 第 582 - 589 行 (`_buildBottomSheetLayout` 方法中根 Container)。

### 原因解析
目前的简要 `AddTaskDialog` 的根布局被渲染在 BottomSheet 中，在软键盘被呼起时，对话框虽然通过 `padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)` 进行了避让，但由于根容器缺少最大高度高度约束，容器在软键盘挤压时会被强制向上顶开，甚至撑满整个手机物理屏幕，丧失了底部悬浮精炼卡片的视觉定位。

---

## 3. 修复方案
### 修改逻辑
为了保证即使是在软键盘顶起时，简要输入弹窗也能妥善限制在合理高度内（不覆盖顶部大部分区域），必须给其根容器强加明确的高度限制。
1. 在 `_buildBottomSheetLayout` 的 `Container` 属性里设置 `constraints` 最大高度限制。
2. 设置 `maxHeight` 为手机屏幕的合理高度比例（例如：`MediaQuery.of(context).size.height * 0.45` 或者是 `0.5`）。
3. 保证输入框可以滚动：容器里已包含 `SingleChildScrollView`，所以加高度限制能完美使超出的内容在限制框内平滑滚动。

### 核心修改参考
```dart
Widget _buildBottomSheetLayout(BuildContext context) => Container(
  constraints: BoxConstraints(
    maxHeight: MediaQuery.of(context).size.height * 0.48, // 加此最大高度限制
  ),
  padding: EdgeInsets.only(
    left: 16,
    right: 16,
    top: 16,
    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
  ),
  decoration: const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  child: SingleChildScrollView(
    // 子组件不变...
  ),
);
```
