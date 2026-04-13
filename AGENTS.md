# AGENTS.md

## 适用范围

本文件适用于仓库根目录 `C:\code\AndroidApp\my_dida` 及其全部子目录。

## 项目概览

- 项目类型：Flutter 应用。
- 主要技术栈：`provider`、`get_it`、`go_router`、`isar_community`。
- 当前代码以本地数据持久化和任务管理为核心，包含待办、习惯、清单、日历、操作栈等模块。

## 目录职责

- `lib/pages`：页面级 UI，负责页面布局、路由承接、事件分发和订阅 Provider 状态。
- `lib/features`：可复用 UI 组件，按业务域拆分，例如 `calendar`、`dialogs`、`task_detail`、`pickers`。
- `lib/provider`：页面状态与交互协调层，负责持有页面状态、把 UI 事件转换为应用动作、协调调用 Service/Repository，并通知界面刷新。
- `lib/services`：业务逻辑层，负责规则校验、业务编排、异常转换、跨 Repository 协同。
- `lib/repository`：数据访问层，负责 Isar 查询、写入、监听等持久化交互。
- `lib/model/entity`：持久化实体，与 Isar schema 对应。
- `lib/model/vo`：面向 UI 或业务聚合的视图对象。
- `lib/shared`：共享代码目录，放置跨项目复用的基础能力，例如通用Widget、工具函数、常量定义、错误定义、基础类型或通用适配逻辑。该目录不依赖任何项目内代码，仅作为基础能力被调用。
- `lib/core`：通用错误定义、校验器等基础能力。
- `lib/config`：依赖注入、日志、应用级初始化配置。
- `lib/constants`：常量定义，避免散落的 magic number / magic string。
- `lib/utils`：纯工具函数，避免承载具体业务状态。
- `test`：测试代码，按被测模块就近或镜像组织。

## 分层架构约束

项目采用分层架构，分为 UI 层、Provider 层、Service 层、Repository 层。

### UI 层

- 负责渲染页面、响应用户交互、展示状态。
- 页面应优先依赖 `Provider` 暴露的数据和行为完成交互，不直接承载复杂业务规则。
- UI 只负责渲染、事件分发和状态订阅，不直接编排跨实体业务流程。
- 数据提供类型的 UI 页面，按照函数式编程风格设计，保持输入、输出和状态转换清晰，例如时间选择器、日期选择器、重复规则选择器。

### Widget 设计约束

- Widget 分为通用 Widget 和专用 Widget 两类。
- 通用 Widget：面向可复用场景设计，按照函数式编程风格组织，保持输入、输出和状态转换清晰，例如时间选择器、日期选择器、重复规则选择器。
- 专用 Widget：仅服务于某个特定 page，由通用 Widget 与少量页面定制 Widget 组合而成，不承载跨页面复用职责。
- 构建一个新 page 时，优先检查现有通用 Widget 是否已有可复用实现，避免重复造轮子。
- 如果现有通用 Widget 不足以支撑需求，应先按功能边界和独立性把 page 拆分为多个职责清晰的 Widget，再分别细化实现。
- 优先将具备复用价值、输入输出清晰的部分抽象为通用 Widget，再在 page 内组装成专用 Widget。
- 页面实现应优先采用“通用 Widget 复用 + 专用 Widget 组装”的方式，而不是在 page 中堆叠大块内联 UI 逻辑。

### Provider 层

- 负责页面状态持有、界面交互协调，以及在调用 Service/Repository 后触发 `notifyListeners()`。
- 负责把 UI 事件转换为可执行的应用动作，对单个页面或单个交互场景聚合展示状态。
- Provider 可以组合多个 Service，为同一页面提供统一的状态入口，但不定义核心业务规则。
- Provider 不直接承载复杂校验、领域规则和跨实体业务编排；新增此类逻辑应优先下沉到 Service。
- 若因历史实现暂时直接调用 Repository，应视为存量兼容；新增逻辑优先经由 Service，再由 Provider 驱动界面刷新。
- Provider 不负责控件渲染细节、主题判断和布局分支，不把 `BuildContext` 作为业务逻辑依赖。

### Service 层

- 负责纯业务逻辑，包括参数校验、领域规则验证、跨实体协同、异常语义封装。
- Service 可以组合多个 Repository，也可以记录业务操作日志。
- 新业务规则优先放在 Service，不要下沉到 UI、Provider，也不要直接写进 Repository。
- Service 不负责页面状态缓存、`notifyListeners()`、当前页面展示态筛选，也不负责控件渲染、`BuildContext` 传递、主题或布局判断。

### Repository 层

- 负责与 Isar 或其他持久层交互。
- Repository 应聚焦数据读写、查询条件封装、监听流封装，不承载业务决策。
- 不在 Repository 中编排跨领域业务流程，不在 Repository 中直接处理界面状态，也不承担 Provider 的状态同步职责。

## 当前工程约定

- 项目当前同时存在 `pages/features`、`provider`、`services`、`repository` 的职责划分，后续新增代码必须继续遵守该边界。
- 依赖注入统一通过 `lib/config/locator.dart` 中的 `GetIt` 管理；新增全局单例时优先在此注册。
- 状态管理以 `provider` 为主；新增页面状态优先复用现有 Provider 模式，而不是再引入新的状态管理方案。
- 路由统一收敛到 `lib/router/goRouter.dart`。
- 数据实体修改后，如涉及 Isar schema，必须同步处理生成代码。
- 涉及 Dart/Flutter 项目的分析、符号检索、格式化、修复、测试等工程操作时，优先使用已接入的 `dart MCP` 能力，而不是依赖大段源码扫描或纯手工推断；如 `dart MCP` 无法覆盖，再退回常规文件检索与代码修改流程。
- 默认避免执行全量 `dart format .`、全量 `flutter analyze` 或其他覆盖整个仓库的高耗时校验；优先基于本次改动范围做局部格式化与局部分析，仅在跨目录重构、全局依赖变更、实体或生成代码调整等确有必要时再扩大校验范围。

## 编码规范

- 遵循 `analysis_options.yaml` 中已有 lint 规则，保持 `flutter analyze` 可通过。
- 优先复用已有常量、校验器、工具类，不要重复定义相同语义的常量和校验逻辑。
- `lib` 目录下的跨目录导入，默认使用 `package:my_dida/...` 形式，不使用多层 `../` 相对路径；仅同目录或紧邻局部文件可保留简短相对导入。
- 复杂业务逻辑写入 Service；Provider 仅承担页面状态协调、交互编排和界面刷新职责，避免继续膨胀为业务层替代物。
- 新增异步逻辑必须显式处理异常边界，避免把底层异常直接暴露到 UI。
- 新增公共方法时，命名要体现业务语义，不使用 `doThing`、`handleData` 这类泛化命名。
- 时间、重复规则、任务状态等核心领域逻辑，优先复用 `lib/utils`、`lib/core/validators`、`lib/constants` 中现有能力。

## 命名与文件约定

- 新文件名优先使用 Dart/Flutter 社区常见的 `snake_case.dart`。
- 类名、枚举名、扩展名使用 `UpperCamelCase`。
- 方法名、变量名使用 `lowerCamelCase`。

## 生成文件约束

- `*.g.dart` 属于生成文件，除非明确必要，不直接手改。
- 修改 Isar 实体后，应通过 `dart run build_runner build` 更新生成文件，而不是人工同步。

## Git 规范

- 执行一次完整的功能扩展、代码重构、bug 修复等“需要修改代码”的操作前，应先基于当前工作区状态进行一次 `git commit`，避免新任务与未归档改动混杂。
- 提交信息必须符合 `Conventional Commits` 规范，例如 `feat: ...`、`fix: ...`、`refactor: ...`、`docs: ...`、`test: ...`。
- 若工作区中存在与当前任务无关的改动，不要擅自覆盖或清理；应先通过一次独立提交将其归档，再开始新的代码修改。
- 在一次任务内，提交粒度应与可回滚的变更单元保持一致，避免把互不相关的修改合并到同一次提交中。

## 测试与验证

- 没有明确要求，则不进行任何测试，但需要给出人工核对的场景建议。
- 如果有明确要求，则按照以下步骤进行测试：
  - 涉及业务逻辑调整时，优先补充或更新 `test` 目录中的测试。
  - 至少保证改动范围内的关键流程可运行；若未执行测试，需要在交付说明中明确指出。
  - 若修改 Provider、Service、Repository 的边界行为，需重点验证数据读写、状态刷新和页面联动是否仍然正确。

## 修改建议

- 新增功能时，优先按“实体/仓储/服务/Provider/UI”固定链路补齐，而不是把逻辑直接堆在页面里。
- 对现有代码进行重构时，应以“职责更清晰、耦合更低、行为不变”为目标，避免一次性大范围搬运目录。
- 如果发现现有实现已经违反分层约束，新的改动应优先避免继续扩大问题；可以在局部修正，但不要顺手引入更大范围的不兼容重构。

## 禁止事项

- 不要在 UI 层直接操作 Isar。
- 不要在 Repository 层写校验驱动的业务规则。
- 不要引入新的全局状态方案来替代当前 `provider + get_it` 体系，除非有明确任务要求。
- 不要随意修改自动生成文件、构建产物或与当前任务无关的历史命名。
