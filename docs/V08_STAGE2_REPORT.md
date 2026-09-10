# Weeko v0.8 Stage 2：课表管理重构报告

日期：2026-09-09  
范围：仅完成 Stage 2；未开始 Stage 3。

## 目标与结论

本阶段把分散在 `ScheduleSettingsActivity`、`TableConfigFragment`、`ScheduleManageActivity` 和作息相关页面中的入口统一收束到“课表管理”主页。主页现在以五个 Fluent 2 风格导航项呈现“课表信息、课程管理、作息时间、多课表管理、课表外观”，并保留“将此课表配置用作默认配置”这一原有动作。

成功标准已经满足：五个入口均复用 WakeUp 6.0.23 原 Activity、Fragment、Intent extra、Preferences 和 Room 逻辑；覆盖安装后旧课表、课程与作息数据仍可见；五条进入与返回路径均通过实机测试；未新增数据库、Preference key、配置副本或转换算法。

## 实现范围

| 入口 | 复用目标 | 上下文约束 |
| --- | --- | --- |
| 课表信息 | `TableConfigFragment` | 继续使用当前 `TableBean` 与 `table{id}_config` |
| 课程管理 | `ScheduleManageActivity` 的当前课表课程列表 | 继续传递原 `selectedTableId` |
| 作息时间 | `TimeSettingsActivity` | 继续传递原 `tableData`，使用 Room 作息关联与 `time{id}_config` |
| 多课表管理 | `ScheduleManageActivity` 的课表列表 | 不传当前课表 id，保持原多课表模式 |
| 课表外观 | `MainStyleFragment` | 继续读写当前课表原外观配置 |

本阶段同时统一了用户可见标题：“课表设置”改为“课表管理”，“课表数据”改为“课表信息”，“上课时间/时间表”改为“作息时间”，“更多外观设置”改为“课表外观”。内部类名、资源 id、存储名称和序列化格式不变。

## 有意保留的重复项

`TableConfigFragment` 内仍保留课程管理与作息入口；“将此课表配置用作默认配置”仍保留在课表管理主页。它们涉及当前课表 id、返回后刷新以及默认配置 `table-1_config` 的特殊语义，在 Stage 4 完成等价性验证前不删除。这样做符合“先建立稳定新入口，再清理旧入口”的阶段边界。

## 修改文件

| 文件 | 内容 |
| --- | --- |
| `tools/replay-weeko-v08-settings-stage2-patches.ps1` | 从 Fluent Stage 10 基线重放版本、文案、五入口列表及原路由派发补丁 |
| `tools/build-weeko-v08-settings-stage2-debug.ps1` | 从 v0.6 apktool 母体重建、注入原 DEX、对齐、签名并验证 Stage 2 APK |
| `docs/V08_INFORMATION_ARCHITECTURE.md` | v0.8 信息架构、兼容边界与阶段迁移依据 |
| `docs/V08_STAGE2_REPORT.md` | 本阶段实现、构建和实机验证记录 |

## 构建验证

构建脚本从 `build/v0.6/repro-apktool` 复制干净母体并依次重放既有补丁链和 Stage 2 补丁。中文补丁脚本由 UTF-8 语义明确的 `pwsh` 执行，避免 Windows PowerShell 5.1 对无 BOM UTF-8 文本的误解码。

产物：`build/v0.8/Weeko-v0.8.0-settings-stage2-debug.apk`  
包名：`io.github.mxwf.weeko`  
版本：`versionCode 8`，`versionName 0.8.0-settings-stage2`  
大小：6,321,555 bytes  
SHA-256：`4B137C260F8C1720277AE6ACBD3F4C8079579C7C4E7D8BEEB34E715C0F67E437`

apktool 重建、zipalign 校验、aapt2 badging 和 apksigner 校验均通过；签名验证结果为 v1、v2、v3 均为 `true`。原始记录位于 `build/v0.8/settings-stage2-*.log`、`settings-stage2-apk-badging.txt` 和 `settings-stage2-release-summary.txt`。

## 实机验证

设备：`3fde7e33`，Xiaomi `22081212C`。使用 `adb install -r` 从 Stage 10 覆盖安装，未卸载应用、未清除数据。冷启动进入 `ScheduleActivity`，状态为 `ok`，`LaunchState` 为 `COLD`，耗时 765 ms。

| 验证项 | 结果 |
| --- | --- |
| 课表管理主页 | 标题与五个入口完整显示；独立默认配置动作保留 |
| 课表信息 | 进入 `TableConfigFragment`，显示旧课表“26-1”、第 2 周、10 节、18 周；返回课表管理 |
| 课程管理 | 进入 `ScheduleManageActivity` 当前课表课程模式，既有课程列表可见；返回课表管理 |
| 作息时间 | 进入 `TimeSettingsActivity`，当前课表和既有作息表关联可见；返回课表管理 |
| 多课表管理 | 进入 `ScheduleManageActivity` 多课表模式，旧有“未命名”和“26-1”两张课表可见；返回课表管理 |
| 课表外观 | 进入 `MainStyleFragment`，原预览与外观选项可见；返回课表管理 |
| 主课表返回 | 从课表管理返回后日期“2026/9/9”和“第 2 周”仍显示 |
| 数据库运行证据 | `dumpsys dbinfo` 中 `tablebean`、`timedetailbean` 和课程 natural join 查询均成功 |
| 稳定性 | 本轮 logcat 未发现目标包的 FATAL EXCEPTION、ANR、VerifyError 或 NoSuchMethodError |

额外完成亮色、深色、约 375dp 小屏宽度、1.3 倍系统字体和横屏检查。深色对比与卡片层级清晰；小屏和大字体允许摘要自然换行；横屏可纵向滚动到“课表外观”和默认配置动作，内容未被系统栏遮挡。测试结束后设备已恢复亮色、1.0 字体、竖屏锁定和原始物理分辨率。

主要截图与 UI 层级证据：`settings-stage2-hub.png`、`settings-stage2-info.png`、`settings-stage2-course.png`、`settings-stage2-time.png`、`settings-stage2-multi.png`、`settings-stage2-appearance.png`、`settings-stage2-hub-dark.png`、`settings-stage2-hub-small.png`、`settings-stage2-hub-large-text.png`、`settings-stage2-hub-landscape.png` 及同名 `*-ui.xml`，均位于 `build/v0.8/`。

## 遗留边界

Stage 2 没有删除 `TableConfigFragment` 内的重复入口，也没有调整全局设置分类。前者留给 Stage 4 在等价性回归后清理，后者属于 Stage 3。设备截图中的“文本识别”悬浮条是系统级覆盖层，不属于 Weeko 页面。
