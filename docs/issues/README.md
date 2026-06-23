# Issue Triage 归档索引

本目录记录了对当前仓库中 10 个 open issues 的详细技术诊断、修复思路及 Triage 推荐分类方案。

由于 GitHub 写权限受限，我们在此维护一个本地 Issues Triage 状态清单以辅助团队或自动化 Agent 后续高效修复问题。

## Triage 索引清单

| 编号 | Issue 标题 | 类别 | 推荐 Triage 状态 | 详细诊断文档 |
| :--- | :--- | :--- | :--- | :--- |
| **#1** | calender_page 的网格没有覆盖整个时间轴 | `bug` | `resolved` | [issue_1.md](issue_1.md) |
| **#2** | calender_page 渲染任务无论是否具有具体时间都只会被渲染在“无具体时间区域” | `bug` | `resolved` | [issue_2.md](issue_2.md) |
| **#3** | 任务成功删除时提示“任务不存在或已删除” | `bug` | `resolved` | [issue_3.md](issue_3.md) |
| **#4** | 增强“习惯”可配置的能力 | `enhancement` | `resolved` | [issue_4.md](issue_4.md) |
| **#5** | 简要add_task_dialog 提供向上拖拽自动变为 extended add_task_dialog 的功能 | `enhancement` | `resolved` | [issue_5.md](issue_5.md) |
| **#6** | “番茄钟” 运行阶段优化 | `enhancement` | `resolved` | [issue_6.md](issue_6.md) |
| **#7** | 简要任务添加 dialog 输入时样式异常 | `bug` | `resolved` | [issue_7.md](issue_7.md) |
| **#8** | 添加任务时时间无法被正确添加 | `bug` | `resolved` | [issue_8.md](issue_8.md) |
| **#9** | 标签功能增强 | `enhancement` | `resolved` | [issue_9.md](issue_9.md) |
| **#10** | add task 逻辑优化 | `enhancement` | `resolved` | [issue_10.md](issue_10.md) |

---

## Triage 规范说明
* 所有推荐为 `ready-for-agent` 的 Issue 均具备明确的原因分析和修复方案，可交由 AI Agent 进行自动化重构。
* 推荐为 `ready-for-human` 的 Issue 涉及到复杂表结构扩展、交互重大重构或需要设计决策，建议由人类开发者主导开发。
