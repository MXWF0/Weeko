# WakeUp 6.0.23 数据模型还原基线

最后更新：2026-08-31（Asia/Shanghai）

## 当前规则

本文件在路线纠偏后只记录 WakeUp 旧数据结构和还原约束。阶段 0 禁止新建或迁移 Weeko 领域模型、Room Entity、Repository 和业务流程。原先文档中定义的 `Semester`、`Schedule`、`Course`、`CourseSession`、`SessionWeek`、`TimeProfile`、`TimeSlot` 以及 Weeko Room version 1 属于误建 Weeko-native 实验方案，当前冻结，不是功能母体，也不代表已经完成数据迁移。

## WakeUp Room v11（权威兼容边界）

APK 生成代码确认数据库 schema version 为 11，identity hash 为 `83d09007d416f0577c3ca29ba87dd2ce`。业务表及其关系为：

```text
TableBean
├─ TimeTableBean
│  └─ TimeDetailBean
├─ CourseBaseBean
└─ CourseDetailBean
AppWidgetBean（独立记录，引用当前课表/Widget 配置）
```

表名、列名、主键、索引、外键和完整 SQL 以 [EVIDENCE_MATRIX.md](EVIDENCE_MATRIX.md) 的 v11 schema 和 7→11 Migration 小节为准。当前已确认：

- 数据库名通常为 `wakeup`；API 24+ 的条件分支使用 `<dataDir>/databases/db/wakeup`。
- 迁移链注册为 7→8、8→9（WorkManager）、9→10（WorkManager）、10→11。
- `CourseBaseBean` 保存课程主体；`CourseDetailBean` 保存课表中的具体上课安排、周次/单双周和教师/教室等字段。
- `TimeTableBean`、`TimeDetailBean` 保存作息及节次；`TableBean` 保存课表元数据；`AppWidgetBean` 保存 Widget 配置状态。
- 旧 `(tableId, id)` 等键、级联关系和迁移列不能在还原阶段改成 UUID、离散周表或新的外键策略。

## SharedPreferences 数据边界

旧应用至少使用 `multi_language`、`config`、`table{id}_config`、`time{id}_config` 和 `widget{id}_config`。它们分别影响语言、全局显示/提醒、课表选择、作息和 Widget。动态键、默认值和已确认的读取位置见证据矩阵；未知键不能凭空补全或删除。

## 外部文件模型

`.wakeup_schedule` 不是 Room 数据库转储，而是五个按行分隔的 JSON 值：

```text
1. TimeTableCompat
2. TimeDetailBean[]
3. TableCompat
4. CourseBaseBean[]
5. CourseDetailBean[]
```

字段顺序、Gson 类型和当前 APK 的导入/导出调用位置已在 [COMPATIBILITY.md](COMPATIBILITY.md) 与 [EVIDENCE_MATRIX.md](EVIDENCE_MATRIX.md) 记录。真实样本和历史版本差异尚未取得；当前 `adapter/wakeup` 的 hand-written 模型和 synthetic fixture 不能反向定义旧 schema。

## 还原阶段数据操作原则

```text
APK / smali / 资源证据
        ↓
恢复旧 Entity、DAO、Migration、Preferences 访问
        ↓
保持 WakeUp 原有读写和文件顺序
        ↓
有真实样本后再做行为回归
```

本阶段不执行 `WakeUp → ScheduleDraft → Validation → Preview → Transaction` 的新导入设计；那是后续在母体可运行之后的重构边界，不能用来绕过旧数据库或导入行为。也不建立 Weeko Room schema、假 Repository、测试假数据或新的删除/级联语义。

## 仍需补齐的证据

1. v7/v8/v9/v10 真实数据库快照及迁移回放结果。
2. 一份脱敏的 6.0.23 `.wakeup_schedule`、空课表、复杂周次、非法/截断文件样本。
3. 动态 Preferences 键的完整清单和默认值验证。
4. Provider Cursor 列、Widget 状态和提醒记录与数据库的运行时关联。

## 当前误建代码说明

`app/src/main/java/io/github/mxwf/weeko/model`、`database`、`data` 和 `adapter/wakeup` 仍保留，避免未经确认的破坏性删除；它们被标记为非权威隔离代码。只有 WakeUp 母体能编译、安装并完成最小行为回归后，才评估哪些测试或纯工具代码可以复用。

