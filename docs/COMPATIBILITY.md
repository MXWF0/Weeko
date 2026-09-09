# WakeUp 6.0.23 兼容边界

最后更新：2026-08-31（Asia/Shanghai）

## 路线说明

兼容目标不是把 WakeUp 当作外部数据源重新实现 Weeko，而是先恢复 WakeUp 6.0.23 的可运行母体，再在同一工程中渐进修改。当前 `io.github.mxwf.weeko` 工程和 `adapter/wakeup` parser 都是误建实验代码，不能作为旧行为的证明。阶段 0 不修改包名、数据库、文件格式、Provider、Widget、提醒或 Parser 语义。

完整静态证据和结论等级见 [EVIDENCE_MATRIX.md](EVIDENCE_MATRIX.md)，目录和阻塞项见 [RESTORATION_BASELINE.md](RESTORATION_BASELINE.md)。

## WakeUp 身份与系统边界

6.0.23 的包名为 `com.suda.yzune.wakeupschedule`，versionCode `263`，versionName `6.0.23`，launcher 为 `SplashActivity`，数据库/Preferences/Provider/Widget 等均绑定旧包名。Provider authority 是 `com.suda.yzune.wakeupschedule.provider`，AndroidX Startup authority 是 `com.suda.yzune.wakeupschedule.androidx-startup`，深链为 `wakeupschedule://main`。旧 action 使用 `WAKEUP_*` 前缀。

这些名称在还原阶段必须原样保留。不要为了“Weeko 身份”全局替换包名；applicationId 改变会使 Android 把应用视为新应用，无法通过普通 APK 更新自动继承 WakeUp 私有数据。身份改造只能在母体可运行、数据迁移方案和兼容窗口明确后单独进行。

## `.wakeup_schedule` 文件

APK 已确认的 6.0.23 文件是 UTF-8、五个按行分隔的 JSON 值：

1. `TimeTableCompat`；
2. `TimeDetailBean[]`；
3. `TableCompat`；
4. `CourseBaseBean[]`；
5. `CourseDetailBean[]`。

当前没有真实脱敏样本、历史版本样本或损坏样本。`adapter/wakeup` 中的解析器只应视为手工候选/测试夹具，不能宣称与原 APK 等价，也不得让它决定 Room schema。真实兼容性必须以母体导入/导出行为和样本回归为准。

## Room 与 Preferences

旧 Room schema version 11，六张业务表、数据库路径分支和 7→11 Migration SQL 已在 [DATA_MODEL.md](DATA_MODEL.md) 和证据矩阵记录。`config`、`multi_language`、`table{id}_config`、`time{id}_config`、`widget{id}_config` 及其动态键是旧显示、作息、Widget 和提醒边界；不能以 Weeko Room v1 或新的 UUID 模型替代。

## Widget、通知、Alarm、WorkManager

APK 声明六个 Widget provider、三个 RemoteViews service、MIUI `:widgetProvider` 进程；课程提醒依赖 AlarmManager，WorkManager 由 AndroidX 初始化并承载厂商相关任务。旧通知 channel、action、PendingIntent/request code、刷新周期、Provider URI 和组件 exported 属性都属于高风险兼容面。原始签名 APK 的一次设备启动在系统 locale 绑定阶段出现 NPE；apktool 重组并 debug 签名的 APK 可进入旧 `ScheduleActivity`，但这两种安装状态的差异尚未解释，Widget/提醒黑盒回归仍不完整。

## 导入、Parser 和网络

旧导入入口 `schedule_import.LoginWebActivity` 接受 `.wakeup_schedule`、HTML 和 CSV 的 VIEW intent。Parser 输出包含旧 `Course`、`TimeTable`、`TimeDetail`、`WeekBean` 等模型；APK 同时包含 Ktor 和 Retrofit/OkHttp。没有原始 Gradle、学校映射和账号测试时，不凭经验恢复网络边界，不把密码、Cookie、Token 或 Session 写入新存储。

## 兼容等级（当前）

| 能力 | 状态 | 说明 |
| --- | --- | --- |
| 静态身份/组件证据 | 已确认 | aapt2、apkanalyzer、apktool 互证 |
| Room schema/迁移证据 | 已确认（静态） | 未完成真实旧库回放 |
| 文件行结构 | 已确认（结构） | 未取得真实/历史/损坏样本 |
| 原 APK 正常启动与页面行为 | 部分完成/差异待解释 | 原始签名包曾出现系统 locale 绑定 NPE；重组包可进入旧 `ScheduleActivity` |
| 可编译 WakeUp 母体 | 未建立 | 仓库没有旧 Gradle/源码；当前 `app` 非母体 |
| `adapter/wakeup` 真实兼容 | 未宣称 | 仅 hand-written parser + synthetic fixture |

## 下一阶段门槛

先在独立还原目录恢复原包名下的 Gradle、资源、Manifest 和最小 launcher，使 WakeUp 母体 `assembleDebug` 通过并可安装。随后用真实 APK/样本逐个验证数据库、导入导出、Widget、提醒和 Parser。没有这些回归边界前，不进行 Compose、Weeko 身份、数据模型迁移或新页面开发。
