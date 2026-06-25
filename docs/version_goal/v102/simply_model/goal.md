# Dart 中类似 Java Lombok 的库及 Model 优化方案推荐

## 1. Dart 中是否存在类似于 Java Lombok 的库？

在 Java 生态中，Lombok 主要是通过注解处理器（Annotation Processor）在编译期自动生成样板代码（如 Getter/Setter、Constructor、toString、equals、hashCode、Builder/With 等）。

在 Dart 生态中，由于语言特性的不同（例如 Dart 本身已经隐式生成了 Getter/Setter，且支持命名可选参数、初始化列表等），我们通常不需要像 Java 那样为简单的 getter/setter 引入繁重的库。但对于更复杂的开发需求（如值相等性、不可变数据类、深拷贝、JSON 序列化），Dart 拥有类似的方案：

### 核心替代方案对比：

| 库名称 | 对应 Lombok 的功能 | 优点 | 缺点 |
| :--- | :--- | :--- | :--- |
| **Freezed** | `@With` / `@Builder` / `@EqualsAndHashCode` / `@ToString` | 目前 Flutter 社区最推荐的**不可变数据类（Value Object）**生成库。支持深拷贝、值相等性比较、`toString()` 以及强大的联合体（Union）和模式匹配。与 `json_serializable` 完美集成。 | 只能生成不可变对象。由于使用 `build_runner` 生成代码，可能会带来少许的编译开销。 |
| **Built Value** | `@Builder` | Google 官方维护，提供强不可变的 Value Object 和类似 Java 的 Builder 链式调用模式。 | API 编写过于繁琐，模板代码量较大，上手成本比 Freezed 高。 |
| **Equatable** | `@EqualsAndHashCode` | 专注于提供值相等性比较。**不需要代码生成**，仅通过重写 `props` 属性即可实现成员变量的 `==` 和 `hashCode` 比较。 | 仅限相等性比较，无法生成 `copyWith` 或 JSON 序列化方法。 |
| **Json Serializable** | 专注于 JSON 序列化（`fromJson`/`toJson`） | Flutter 官方团队推荐的 JSON 序列化生成器。 | 仅仅处理 JSON 映射，不提供其它数据类特性。 |
| **Dart Macros (宏)** | Lombok 级别的无缝体验 | Dart 3 正在开发的新特性（目前处于实验性预览阶段），类似 Java 的注解处理器，未来能够实现“零 `build_runner`”的代码自动生成（如 `@JsonCodable`）。 | 目前尚未稳定，不建议用于生产环境。 |

---

## 2. 本项目 `lib/` 目录下 Models 的分析

通过对项目中 `lib/features/**/models/` 目录下的核心数据模型进行检索与分析，我们发现目前的 Models 分为两大核心阵营：

### A 阵营：Isar 数据库持久化实体（如 `Task`, `Habit`, `Checklist`）
* **特点分析**：
  - 均使用了 `@Collection()` 注解，被 Isar 数据库框架纳管。
  - 需要配合 `isar_community_generator` 进行编译期代码生成（生成 `*.g.dart` 以支持持久化和 Query 查询）。
  - **关键限制**：Isar 的实体属性必须是**可变的（Mutable）**，因为 Isar 在读写、更新以及模型映射时依赖于字段的 setter 方法和字段的直接修改。同时，由于它们都继承自 `RevertibleEntity` 这一包含了可变 `Id id` 的基类，这就与以**不可变性（Immutability）**为核心的 `Freezed` 存在天然冲突。
  - **代码现状**：目前这些类中手写了 `copyWith`、`toJson`、`fromJson` 和 `toString`。
* **推荐方案**：
  - **维持现状，不引入 Freezed。**
  - **理由**：由于 Isar 本身属于可变数据模型设计，如果强制引入 Freezed 会导致极大的代码冲突和类型转换成本。目前的“手写 `copyWith` / `fromJson` + Isar 自动生成 `*.g.dart`”是结合 Isar 数据库最稳定、最常见的最佳实践。

### B 阵营：业务值对象与非持久化 DTO（如 `ChecklistVo`, `TomatoTicker`, `TaskCalendarViewData`）
* **特点分析**：
  - 这些类只在内存或 UI 层中流转，不需要存入 Isar 数据库。
  - 属性绝大多数是只读的（`final`），不需要可变状态。
  - 经常需要对其进行克隆修改（`copyWith`）、值相等性判定（例如为了让 Bloc/Provider 判断状态是否变化而决定是否重建 Widget）。
* **推荐方案**：
  - **推荐使用 `Freezed` 库进行重构。**
  - **理由**：能够自动化消除大量的 `copyWith`、`operator ==`、`hashCode` 和 `toString` 样板代码，提高开发效率并规避手写导致的低级错误。

---

## 3. 落地建议与结论

1. **针对持久化实体层（Isar Entities）**：**不推荐**使用类似 Lombok 的 Freezed 等库，继续保持当前的手写可变模型设计，以获得与 Isar 最好的兼容性。
2. **针对纯业务逻辑/状态管理层（Value Objects / UI States）**：**推荐引入 `Freezed`**。如果将来项目中有大量复杂的不可变数据对象或联合类型（Union Classes），可以使用 Freezed 来消灭样板代码。
3. **针对宏（Macros）的关注**：建议持续关注 Dart 宏（Macros）的演进，一旦宏在 Dart 稳定版本正式发布，可第一时间采用官方宏方案实现类似 Java Lombok 的零开销代码生成。
