# Isar 本地数据库数据模型规范

本项目使用 Isar Database 作为核心本地存储，表结构均采用 Dart 强类型 Entity 描述。

## 1. 核心表及其约束关系
* **Task (任务表)**:
  - 索引: `startTime`, `endTime`, `checklistId`, `priority`
  - 联合复合索引: `isDone` + `startTime`, `isDone` + `endTime`
  - 嵌套属性: `checkpoints` (内嵌 `CheckPoint` 实体列表)
* **Checklist (清单表)**:
  - 属性: `name` (加索引), `colorValue`
* **Habit (习惯表)**:
  - 属性: `name`, `startDate`, `isArchived`
* **HabitCheckInRecord (打卡日志表)**:
  - 索引: `habitId`, `checkInTime` (进行快速区间过滤)
* **TomatoRecord (番茄专注历史表)**:
  - 索引: `taskId`, `customTomatoId`, `startTime`
* **Operation (操作堆栈快照表)**:
  - 索引: `timestamp` (时间倒序索引)

## 2. Isar 数据库自动迁移规则
1. **无损增加列/表**:
   在对应模型类内增加字段后，直接在终端执行代码生成器：
   `dart run build_runner build --delete-conflicting-outputs`
   Isar 会在启动时（`initializeIsar` 步骤内）读取新的 Schema 描述并静默升级，为新字段赋默认值。
2. **破坏性更新（如重命名列）**:
   若直接修改类成员名称，Isar 无法智能判断映射。建议通过给新列重命名，并在升级代码内编写旧数据读取逻辑做逻辑重构；
   或者在重大破坏性更新时，升级 `pubspec.yaml` 对应版本并引导清除数据。
