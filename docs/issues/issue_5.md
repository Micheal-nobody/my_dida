# Issue #5: 简要add_task_dialog 提供向上拖拽自动变为 extended add_task_dialog 的功能

## 1. 属性分类与推荐状态
* **分类 (Category)**: `enhancement` (需求增强)
* **状态 (State)**: `ready-for-agent` (可交由 Agent 自动修复)

---

## 2. 诊断分析
### 关键文件与行数
* `lib/features/tasks/widgets/add_task_dialog.dart`
  * 发生位置: 第 582 行 (`_buildBottomSheetLayout` 方法中)

### 原因解析
当 `AddTaskDialog` 处于简要 BottomSheet 状态时（`_isFullScreen` 为 `false`），它是由 `_buildBottomSheetLayout` 进行展现的。
现有的交互仅支持点击对话框右上角的 "全屏" 按钮来转化为全屏模式，没有任何手势机制可以在用户拖拽或向上轻扫对话框整体时将其自动放大和展开为全屏。

---

## 3. 修复方案
### 修改逻辑
为了实现向上拖拽或轻扫转化为全屏，可在简要 BottomSheet 布局的最外层容器上添加手势监听。
1. 使用 `GestureDetector` 包裹 `_buildBottomSheetLayout` 返回的根 `Container`。
2. 监听 `onVerticalDragUpdate` 与 `onVerticalDragEnd`。
3. 当检测到累积的向上滑动距离大于特定值（例如向上滑动 `dy` 超过了 `-40`），或者向上的瞬间滑动速率大于特定值时，触发状态转换。
4. 状态转换逻辑应当与右上角全屏编辑按钮的逻辑保持一致：关闭当前 BottomSheet，并在当前 Turn 内 Push 开启全屏模式下的 `AddTaskDialog` 并传入当前已经输入的状态数据。

### 核心修改参考
```dart
Widget _buildBottomSheetLayout(BuildContext context) {
  double totalDragY = 0;
  return GestureDetector(
    onVerticalDragUpdate: (details) {
      // 向上滑动 dy 为负数
      totalDragY += details.primaryDelta ?? 0;
    },
    onVerticalDragEnd: (details) {
      if (totalDragY < -40 || (details.primaryVelocity ?? 0) < -300) {
        // 自动触发全屏转换
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTaskDialog(
              initialIsFullScreen: true,
              presetTask: _buildTaskFromForm(
                taskName: _textController.text.trim(),
                checklistProvider: context.read<ChecklistProvider>(),
              ),
              parentTask: parentTask,
            ),
          ),
        );
      }
      totalDragY = 0;
    },
    child: Container(
      // 现有布局内容...
    ),
  );
}
```
