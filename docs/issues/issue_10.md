# Issue #10: add task 逻辑优化

## 1. 属性分类与推荐状态
* **分类 (Category)**: `enhancement` (需求增强)
* **状态 (State)**: `ready-for-agent` (可交由 Agent 自动修复)

---

## 2. 诊断分析
### 关键文件与行数
1. `lib/features/tasks/widgets/add_task_dialog.dart`
   * 发生位置: 第 612 - 628 行 (`_buildBottomSheetLayout` 中全屏按钮 onTap)。
2. `lib/features/tasks/pages/task_detail_page.dart`
   * 发生位置: 详情页排版整体。

### 原因解析
1. **自动创建并进入详情页**：
   在简要模式的 `AddTaskDialog` 中，点击右上角“全屏展开”按钮时，它采用的逻辑是 Pop 掉当前的简要模式框并 Push 开启全屏模式的 `AddTaskDialog`：
   ```dart
   Navigator.pop(context);
   Navigator.push(context, MaterialPageRoute(builder: (context) => AddTaskDialog(initialIsFullScreen: true, presetTask: ...)));
   ```
   然而产品需求为：“进入 extended 状态时自动触发任务创建，并且直接进入详情页 `task_detail_page`”。我们需要在这里扭转行为。
2. **优化详情页样式**：
   需改善 `task_detail_page.dart` 样式的视觉一致性，确保时间栏显示、优先级图标、勾选按钮样式与整体 App 风格深度契合。

---

## 3. 修复方案
### 修改逻辑
1. **更改全屏编辑触发的行为**：
   在“全屏展开”按钮的 `onPressed` 动作中，不用再打开全屏的 `AddTaskDialog`，而是直接调用表单构建并保存的逻辑：
   * 构建 `newTask` 实体。
   * 调用 `context.read<TaskProvider>().execute(AddTask(newTask))` 存库（或通过 provider 获取创建后的 Task 实体以获取 ID）。
   * 关闭当前简要 Dialog：`Navigator.pop(context)`。
   * 立即呼出任务详情 BottomSheet，传入存库后的 Task 对象：`TaskDetailPage.show(context, savedTask)`。
2. **样式细节重构**：
   对照设计规格，优化 `task_detail/widgets/` 的各个子布局样式。
