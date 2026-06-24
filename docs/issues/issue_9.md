# Issue #9: 标签功能增强

## 1. 属性分类与推荐状态
* **分类 (Category)**: `enhancement` (需求增强)
* **状态 (State)**: `ready-for-agent` (可交由 Agent 自动修复)

---

## 2. 诊断分析
### 关键文件与行数
* `lib/features/tasks/widgets/add_task_dialog.dart`
  * 发生位置: 第 259 - 296 行 (`_editTags` 方法中)。

### 原因解析
在当前的 `AddTaskDialog` 中，标签编辑功能仅仅是通过 `showDialog` 唤起一个弹窗。
在弹窗内，用户必须使用手打输入，并且手写输入的中英文“逗号”来对输入的字符串进行分割，用户体验非常落后：
* 没有标签列表推荐，容易写错。
* UI 突兀，与下方简洁大方的 BottomSheet 风格不一致。

---

## 3. 修复方案
### 修改逻辑
参考项目中各种选择弹框的良好设计，应当将标签编辑升级为一个专用的标签管理 BottomSheet：
1. 替换 `showDialog` 为 `showModalBottomSheet`。
2. 内部渲染包含：
   * “当前已选标签” 的 Chip 列表（支持快捷点击 Chip 上的 “X” 按钮删除）。
   * “所有/历史常用标签” 的轻量级列表以供快捷勾选或点击，标签数据可从 `TaskProvider` 中获取（通过遍历所有现有任务的 tags 并去重来获得历史标签集，或者在 `TaskProvider` 中增加标签管理支持）。
   * 一个简单的输入文本框，键入回车后自动在 Chip 列表里生成新的标签。
3. 提供“保存/取消”按钮在确认后回调返回给 Dialog。
