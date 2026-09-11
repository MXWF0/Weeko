# Weeko / WakeUp 项目状态

## V1.0.1 导入与首次引导热修复（2026-09-11）

v1.0.1 已完成正式签名构建和设备回归：`io.github.mxwf.weeko` 的
`versionCode=13`、`versionName=1.0.1`，正式 APK SHA-256 为
`A2D0E9406E0B8861D28CCF52010C7F06DE6E62BB31AF3AFC1E2EEC9A7098CF18`。本轮只修复后台
清理后的首次引导持久化和导入引导链：`has_intro` 完成写入改为同步落盘，导入提示直接
衔接现有“更多操作”入口；数据库、备份格式、Widget 和旧 Activity/Provider/Receiver
名称未改写。

在设备 `3fde7e33` 上，首次教程完成后强制停止并重启不再出现隐私/引导提示；从“导入课程
→ 从文件导入 → 从备份”选择 `sample.wakeup_schedule` 返回“导入成功(ﾟ▽ﾟ)/”。构建和
回归证据、已知边界见 [`docs/V1.0.1_RELEASE_REPORT.md`](docs/V1.0.1_RELEASE_REPORT.md)。
正式构建入口为 [`tools/build-weeko-v101-release.ps1`](tools/build-weeko-v101-release.ps1)。

最后更新：2026-09-11（Asia/Shanghai）

## V0.6 维护基础（2026-09-05）

`build/v0.6/Weeko-v0.6.0-test1.apk` 已完成本地可重复构建和设备回归：包名为
`io.github.mxwf.weeko`，versionCode `6`，versionName `0.6.0-test1`，SHA-256 为
`3A4F0E8C11727B8A0A3DB0A31C752490F0CC5DFB2D6C58B8D248C27474B6D5B1`，固定 v2 证书
摘要为 `E114CA20A1DD4726E83FF511C290AD30278D37E09703AB1BC788405BBC759E21`。
候选包在设备 `3fde7e33` 上完成冷启动、核心课程操作、设置、导入导出回环和 About
验证；Weeko 进程无新增 FATAL/ANR。构建、设备日志和 APK 仅保存在本地 `build/` 并由
`.gitignore` 排除。

本阶段不提交、不推送、不创建 Release；远程 `main` 只读 HEAD 仍为
`3fa042a820b8102f705b783752017d13e76357e4`。WakeUp 残留及未覆盖项见
`docs/WAKEUP_RESIDUALS.md` 和 `docs/V06_ACCEPTANCE.md`。

最后更新：2026-09-05（Asia/Shanghai）

## V0.7 Fluent UI 迁移支线（2026-09-07）

Fluent UI Stage 1–5 已完成：入口拆分、周 rail、顶部/浮层样式和全量设备回归均通过。
最终 debug 验证包为 `build/v0.8/Weeko-v0.7.0-fluent-stage5-debug.apk`，SHA-256 为
`EA99466E03F57DBACCA1C50B2F23AAB8A7EFB1F8BDAB68B161410FC9F21F4B0C`。迁移只接入现有
WakeUp Activity、周切换和菜单链，不复制或改写课程、数据库、导入导出、提醒和 Widget
业务；设备回归证据与各阶段脚本见 `docs/V07_FLUENT_STAGE*_REPORT.md` 和 `build/v0.8/`。
该包仅用于本地 debug 验证，不是发布签名包。

最后更新：2026-09-07（Asia/Shanghai）

## 当前路线

项目固定采用 WakeUp 6.0.23 作为唯一功能母体：

```text
WakeUp APK → 证据型反编译 → 可编译/可运行旧工程 → 原地渐进重构 → Weeko
```

当前仓库没有 WakeUp 原始 Gradle 工程或源码。`app/` 和 `adapter/wakeup/` 是先前误建的 Weeko-native 实验代码，已经停止扩展但暂不删除；它们不能替代旧 Activity、Fragment、Room、Preferences、Widget、Alarm、WorkManager、导入导出或 Parser。JADX 已在隔离目录 `.wakeup-restoration/` 生成原包名 Gradle 候选；官方依赖资源和 SDK 属性值已逐项恢复，资源处理通过，依据 smali 也已恢复一批局部类型、RecyclerView、ksoup 四个 enum 结构以及 Material/Huawei 两组接口/类型结构，但源码编译仍被剩余 Material、Huawei、应用包和反编译 R 类错误阻塞。公开 2018 年 GreenDAO 工程仅作历史对照，不作为 6.0.23 母体。

## 当前阶段：还原基线

本阶段只做：

- 审查仓库、APK、反编译输出和文件归属；
- 使用 aapt2、apkanalyzer、apktool、JADX 建立可追溯证据；
- 保留 WakeUp 包名、数据库结构、文件格式和已有行为边界；
- 逐组恢复 Gradle、Manifest、资源和必要源码，使旧母体逐步可构建；
- 修复影响构建的基础问题，运行 Debug 构建和安装验证；
- 更新状态、架构、数据、兼容和路线文档。

本阶段禁止：新建替代应用、删除误建 Weeko 代码、迁移 Compose、重设计领域模型或 Room、全局替换包名、伪造 Repository/数据/页面、修改 WakeUp 导入导出和系统组件行为。

## 研究输入与工具结果

| 项目 | 结果 |
| --- | --- |
| APK | `wakeup6.0.23.apk`，6,082,176 bytes |
| SHA-256 | `50EDBC7C7C3458DD0D97436F15A6AC1E69AFBE107054F53B63A0327E52DBB476` |
| 身份 | `com.suda.yzune.wakeupschedule`，versionName `6.0.23`，versionCode `263` |
| 静态工具 | aapt2、apkanalyzer、apktool 2.10.0、JADX 1.5.6 |
| JADX | 输出约 678 个 app Java 文件，报告 66 个错误；不可直接作为源码 |
| apktool | Manifest、资源和 8,406 个 smali 文件解码成功 |
| Git | `.git` 不存在，无分支、提交或 diff |

## 目录归属

| 路径 | 归属 | 决定 |
| --- | --- | --- |
| `wakeup6.0.23.apk` | WakeUp 原始研究输入 | 只读保留 |
| `.stage4a-jadx/` | JADX 证据 | 隔离，不编译 |
| `.restoration-apktool/` | apktool 证据 | 隔离，不作为 module |
| `app/` | Weeko-native 误建实验 | 不删除，冻结并隔离 |
| `adapter/wakeup/` | 手工 parser 候选 | 保留，不宣称真实兼容 |
| `.wakeup-restoration/` | JADX 导出的 WakeUp Gradle 候选 | 唯一还原母体候选，逐组修复，不接入 `app` |
| `docs/` | 证据与规划 | 持续维护 |

完整分类、还原程度、风险和下一组最小工作见 [docs/RESTORATION_BASELINE.md](docs/RESTORATION_BASELINE.md)。

## 本轮验证

根工程本次执行 `:adapter:wakeup:test :app:testDebugUnitTest :app:assembleDebug` 在配置阶段失败，原因是无法解析 `com.android.tools.build:gradle:9.3.0`；因此没有新的误建 Weeko APK 构建结果。还原候选的 `:app:processDebugResources --rerun-tasks` 已通过；`:app:assembleDebug --rerun-tasks` 在 `compileDebugJavaWithJavac` 首批 100 个错误处失败。按 smali 恢复的类已从首批错误中消失，当前阻塞为剩余 Material、Huawei、应用包和反编译 R 类非法 Java，因此没有 WakeUp Gradle APK 可安装。apktool 重组并 debug 签名的旧包仍可安装进入 `ScheduleActivity`，但不等于可维护母体；原 WakeUp launcher 的黑盒差异仍受系统 locale 绑定阶段 NPE 影响。

## 成功标准

阶段结束前，仓库必须能明确指出 WakeUp 还原母体的位置和证据来源；若母体可构建，则完成 Debug 构建、安装和 launcher 验证；若暂时不可构建，则记录完整错误、阻塞原因和下一组最小修复。没有达成前，不进入 UI、身份或数据迁移阶段。
