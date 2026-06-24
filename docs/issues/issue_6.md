# Issue #6: “番茄钟” 运行阶段优化

## 1. 属性分类与推荐状态
* **分类 (Category)**: `enhancement` (需求增强)
* **状态 (State)**: `ready-for-agent` (可交由 Agent 自动修复)

---

## 2. 诊断分析
### 关键文件与行数
1. `lib/core/router/go_router.dart`
   * 发生位置: 第 85 - 108 行 (底部导航栏的 `BottomNavigationBar` 项目)。
2. `lib/features/tomato/pages/tomato_timer_full_screen_page.dart`
   * 发生位置: 全屏计时详情页面整体。
3. `lib/features/tomato/providers/tomato_provider.dart`
   * 发生位置: 番茄钟状态管理类。

### 原因解析
1. 现有底部导航栏中的番茄钟 Icon 是静态的：`BottomNavigationBarItem(icon: Icon(Icons.timer_outlined), label: '番茄钟')`，不能基于后台计时进度实时变化。
2. 全屏番茄详情页面比较基础，仅支持固定的倒计时，缺乏：
   * 屏幕常亮保持切换功能。
   * 正向计时和反向计时切换。
   * 黑暗模式切换，以及在黑暗模式下的纯黑 (AMOLED) 与深灰双样式配置。

---

## 3. 修复方案
### 1. 底部导航栏动态 icon
在 `go_router.dart` 里的 `bottomNavigationBar` 中，使用 `Consumer<TomatoProvider>` 替换番茄钟的 `BottomNavigationBarItem`。
当 `TomatoProvider.isRunning` 为 true 且不是 `idle` 状态时，绘制带 `CircularProgressIndicator` 进度圈的动态 Icon。

### 2. 全屏计时页功能增强
* **屏幕常亮**：引入 `wakelock_plus` 插件。在详情页右上角增加“灯泡”控制 icon。当点击开启常亮时，执行 `WakelockPlus.enable()`；关闭时执行 `WakelockPlus.disable()`。页面退出 `dispose` 时也要确保关闭常亮。
* **正反计时**：在 `TomatoProvider` 增加 `bool countUpMode = false;` 和 `toggleCountUpMode()`。在全屏页如果为 `countUpMode`，显示已用时长：`totalDuration - duration`；否则显示剩余时长 `duration`。
* **黑暗模式与双样式**：在计时页添加本地变量：`bool isDarkMode = false;`，`int darkStyle = 0;` (0 代表纯黑，1 代表深灰)。点击屏幕空白区域进行轮转切换：白天背景 -> 纯黑 -> 深灰 -> 白天背景。
根据当前的样式变量，为页面提供动态的背景和前景 Text 颜色配置。
