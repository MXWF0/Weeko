# WakeUp 6.0.23 还原基线

最后更新：2026-08-31（Asia/Shanghai）

> 当前审计快照：r26 最终 `assembleDebug` 复核。还原候选的资源/Manifest 处理已通过，但 Java 编译仍失败；r21 及更早批次说明保留为历史轨迹，当前错误边界以 r26 为准。

## 路线校正

本项目不再采用“新建 Weeko 原生工程，再把 WakeUp 当作外部兼容来源”的路线。唯一功能母体固定为仓库根目录的 `wakeup6.0.23.apk`：

```text
WakeUp 6.0.23 APK
  → 证据型反编译
  → 还原 Gradle、资源、Manifest 和必要源码
  → 可编译、可安装、可运行的 WakeUp 母体
  → 原地渐进修改
  → 最终演化为 Weeko
```

本轮只建立还原基线。没有修改应用身份、Manifest、数据库 schema、业务流程、Compose/UI 或 WakeUp 文件格式；也没有删除当前误建的 Weeko 代码。

## 当前目录归属

| 路径 | 归属和证据角色 | 当前处理 | 后续建议 |
| --- | --- | --- | --- |
| `wakeup6.0.23.apk` | WakeUp 6.0.23 原始研究产物；SHA-256 `50EDBC7C7C3458DD0D97436F15A6AC1E69AFBE107054F53B63A0327E52DBB476` | 保持只读，不替换 | 作为每次还原比对的不可变基线 |
| `.stage4a-jadx/` | JADX 1.5.6 的 Java/资源证据；原包约 678 个 Java 文件，报告 66 个反编译错误 | 隔离为证据目录，不作为源码编译 | 只引用可由 APK/smali/资源互证的片段 |
| `.restoration-apktool/` | apktool 2.10.0 解出的 Manifest、资源和 8,406 个 smali 文件 | 隔离为证据目录，不作为 Gradle module | 还原资源和 Manifest 时逐项对照 |
| `.wakeup-public-source/` | 公开仓库 `YZune/WakeUpSchedule` 的历史对照；当前 master 提交 `5d43928`（2018-04-07），Gradle 为 2.10/GreenDAO | 仅作历史结构和依赖对照；未复制源码 | 与 6.0.23 APK 逐项比对，许可证文件未发现，不能当作当前母体 |
| `.wakeup-restoration/` | JADX `--export-gradle` 导出的原包名工程候选；约 6,754 个 Java 源文件（其中约 678 个为 WakeUp 应用包）和 APK 资源 | 隔离审计，不接入根工程；依赖仍是 TODO | 作为唯一旧工程候选逐组修复，不把反编译错误当成行为 |
| `app/` | 误建的 Weeko-native 实验工程；`io.github.mxwf.weeko`、Compose、Weeko Room v1 | 不删除、不接入还原母体；标记为非权威 | 等 WakeUp 母体可构建后，再决定隔离、回退或局部复用 |
| `adapter/wakeup/` | 手工编写的五行 JSON parser 和 synthetic fixture，不是 APK 的可编译源码 | 保留但不宣称兼容完成；不修改 WakeUp 行为边界 | 未来仅在真实样本和母体边界明确后评估复用 |
| `docs/` | 审计、证据和路线记录 | 本轮更新路线与状态文档 | 以本文件和 `EVIDENCE_MATRIX.md` 为还原阶段入口 |
| `build/`、`.gradle/`、`.gradle-build/`、`.kotlin/` | 构建生成物和缓存 | 不作为源码或证据 | 可由构建重新生成 |

当前目录不是 Git 仓库（`.git` 不存在），没有分支、提交或可比较 diff。目录归属只能依据文件内容、APK 证据和本次审计记录判断。

## 还原程度

| 目标 | 状态 | 结论 |
| --- | --- | --- |
| APK 身份和 Manifest | 高 | `aapt2`、`apkanalyzer`、apktool 三方确认包名 `com.suda.yzune.wakeupschedule`、版本 6.0.23/263、min 21、target 35 及组件声明 |
| DEX/资源结构 | 中高 | JADX 可输出但有 66 个错误；apktool 可得到 smali 和资源；官方依赖资源与 SDK 属性值已逐项恢复，混淆类型仍需逐项恢复 |
| apktool 重组二进制 | 已确认（本轮） | 解包结果可重新 smali/resource build、签名、安装并进入旧 `ScheduleActivity`；这不等于 Gradle 源工程 |
| Room v11 schema/迁移 | 高（静态） | 六张业务表、数据库名/路径分支、7→11 迁移 SQL 已从生成代码和 builder 记录；没有真实旧库回放 |
| Preferences、导出、Provider、Widget、Alarm、WorkManager、Parser | 中高（静态） | 证据矩阵已记录；真实数据、第三方调用和完整运行时行为仍有缺口 |
| 黑盒行为 | 低 | 研究设备启动 WakeUp 时在系统 locale 绑定阶段出现 NPE，无法据此确认正常页面行为 |
| 可编译的 WakeUp 还原母体 | 未达成（资源阶段已通过） | `.wakeup-restoration/` 的 `mergeDebugResources`、`processDebugResources` 和 Manifest 处理已通过；r22–r25 又按 smali 越过 AddCourse、DAO、分享协程和 `LoginWebFragment$refreshCode$1` 的首批错误，但 r26 的 `compileDebugJavaWithJavac` 仍被 `LoginWebFragment.java:1093–1169` 的反编译 Java 阻塞，因此没有可安装的 Gradle 母体 APK；当前可构建的 `app/` 不是母体 |
| 当前 Weeko-native 工程可构建 | 当前未复核通过 | 2026-08-31 复核在配置阶段无法解析 `com.android.tools.build:gradle:9.3.0`，因此未运行到测试/打包；该误建工程仍不是母体 |
| WakeUp 数据迁移 | 未开始 | 本阶段禁止重设计或迁移数据库；先恢复旧工程行为和格式 |

## 稳定性和风险分级

- **稳定但老旧**：APK 已确认的 Room v11 表结构、迁移 SQL、旧包名/Provider/Intent/Widget 声明、五行 `.wakeup_schedule` 外部结构。它们是兼容护栏，不能先行改名或重写。
- **可以直接整理**：反编译证据的目录分层、构建日志、文档索引、还原过程中的独立错误清单；这些不改变运行行为。
- **高风险不可随便修改**：Room schema 和迁移、数据库路径、`SharedPreferences` 动态键、导入导出字段顺序、Provider URI/Cursor、Alarm request code、通知 action/channel、Widget provider/service、教务 Parser 的网络和登录边界，以及任何混淆类的语义猜测。
- **明确误建**：`app/src/main/java/io/github/mxwf/weeko` 下的 Compose、Weeko model/database/data、课程详情/editor；它们不是 WakeUp 旧页面的替代品。未经确认不得删除，但也不得继续扩展为第二套应用。

## 已执行的证据操作

1. `aapt2 dump badging`：确认 APK 身份、权限、SDK、标签和签名相关元数据。
2. `aapt2 dump xmltree` 与 `apkanalyzer manifest print`：确认 Manifest 组件、provider authority、导入 intent-filter、Widget、WorkManager 和厂商组件；`apkanalyzer` 在设置 JDK 21 后可用。
3. `apktool 2.10.0`：成功解码 Manifest、资源和 smali，输出位于 `.restoration-apktool/`。
4. `JADX 1.5.6`：成功输出 Java 参考代码，但有 66 个错误；输出位于 `.stage4a-jadx/`。
5. 关键静态证据已索引到 [EVIDENCE_MATRIX.md](EVIDENCE_MATRIX.md) 和 [LEGACY_ARCHITECTURE.md](LEGACY_ARCHITECTURE.md)，包括 Activity/Fragment 入口、Room、Preferences、文件格式、Provider、Widget、提醒、Parser 和网络层；当前编译错误见 [RESTORATION_BUILD_ERRORS.md](RESTORATION_BUILD_ERRORS.md)。

6. 当前仓库 Debug 复核：根工程本次执行 `:adapter:wakeup:test :app:testDebugUnitTest :app:assembleDebug` 在配置阶段失败，原因是无法解析 `com.android.tools.build:gradle:9.3.0`；因此不能把旧的缓存环境成功记录当作本次结果，也没有重新安装根工程 APK。apktool 重组并使用本机 debug keystore 签名的 WakeUp APK 仍可安装并进入 `ScheduleActivity`，但设备上的 `com.suda.yzune.wakeupschedule` 此时是重组包，不能再当作原签名发布包的黑盒结果。
7. JADX `--export-gradle` 已生成 `.wakeup-restoration/`。第一次 `:app:assembleDebug` 的准确阻塞是 `mergeDebugResources`：`drawable-{hdpi,mdpi,xhdpi,xxhdpi}/abc_list_divider_mtrl_alpha.9.png` 等九宫格资源尺寸/边框无效。依据 APK 中的依赖版本证据，已将对应 AndroidX Core 1.16.0、AppCompat 1.7.0、Material 1.12.0 和 Toasty 1.5.2 的同名资源逐项恢复；原始文件备份位于 `build/evidence-deps/`。同时按 Android SDK 35 属性表修复了反编译样式中的 enum、dimension enum 和 flags 数值。`mergeDebugResources` 与 `processDebugResources` 均已通过；这些修改只涉及依赖资源和合法 XML 表达，不涉及应用业务、Manifest、数据库或 UI 设计。
8. 资源通过后的完整 `:app:assembleDebug --rerun-tasks` 进入 `compileDebugJavaWithJavac`，首批错误集中在 `androidx`、Material、Glide、biweekly、WorkManager、Huawei 和应用包等混淆/协程类的非法 `??` 临时类型、接口初始化和 R 类结构。r20 已按 smali 继续恢复 Huawei analytics/framework/receiver、文件校验/流类型、Material timepicker、生成式 R 类、ScheduleActivity/课程详情映射、SelectTime/SelectDateRange 及日期监听器；这些类已不再出现在首批错误中。`.wakeup-restoration/` 仍不是可编译母体；剩余错误不能用全局替换或假类掩盖，需按 smali 和依赖版本逐类恢复。
9. 另建的 `build/wakeup-restoration-apktool-res-test/` 仅用于比较资源来源：替换为 apktool 资源后，首个阻塞变为 41 个含 `$` 的文件名（如 `$avd_hide_password__0.xml`），并发现 `ic_launcher_background.xml` 把 drawable 资源写入 `android:fillColor`。这说明 apktool 资源也不能未经逐项校正直接作为 Gradle 源资源；该副本未纳入母体。
10. 公开对照源为 [YZune/WakeUpSchedule](https://github.com/YZune/WakeUpSchedule) 的 `master` 提交 `5d43928`（2018-04-07），其 `app/build.gradle` 显示版本 2.10、compile/target 27、GreenDAO 3.2.2，与 6.0.23 APK 的 Room v11 和 target 35 不同。仓库树中未发现 LICENSE/COPYING/NOTICE 文件，因此仅作架构演变证据，不复制其实现。
11. 资源阶段通过后，按 smali 对 `.wakeup-restoration/` 中前一批 13 个类及 RecyclerView 的非法局部类型/寄存器复用进行了最小恢复；随后按 ksoup `.class ... enum` 和 `<clinit>` 证据恢复 `Entities$EscapeMode`、`Entities$CoreCharset`、`HtmlTreeBuilderState`、`TokeniserState` 四个枚举结构。每处均保留原控制流，原文件备份位于 `build/evidence-deps/source-before-*`、`source-after-*` 和 `source-before-ksoup-enums/`；重跑 `assembleDebug` 后这些类不再出现在首批错误中。
12. 在同一边界内，依据 `.restoration-apktool/smali/` 的接口字段、寄存器位运算和 `<clinit>` 顺序恢复 Material `Chip`、`NavigationView` 以及 Huawei `agconnect.https.e`、`analytics.aq` 的最小 Java 结构；备份位于 `build/evidence-deps/source-before-material/` 和 `source-before-huawei/`。r9 日志确认这些类已从首批错误中消失，r20 又确认 Huawei 及生成式 R/课程映射/日期监听器批次已越过；当前阻塞集中到 AddCourse、DAO、分享协程和 LoginWebFragment 导入代码。这些修改仅证明源码可继续进入编译阶段，不是行为等价证明。

13. r21 最终 `compileDebugJavaWithJavac` 日志为 `BUILD FAILED`，javac 首批 100 个错误；这是 r22–r25 之前的历史快照，不能代表当前阻塞集合。完整输出见 `build/evidence-deps/wakeup-restoration-assemble-20260831-r21.log`。
14. r22–r25 依据对应 smali 逐组恢复了 AddCourse、DAO、分享协程和 `LoginWebFragment$refreshCode$1` 的可确认局部类型，并为每组保留 `build/evidence-deps/source-before-*` 备份。r26 完整 `:app:assembleDebug --rerun-tasks` 的资源、Manifest 和签名配置阶段通过，`compileDebugJavaWithJavac` 仍以 100 个错误、3 个 Java 8 source/target 警告失败；当前首批全部集中在 `LoginWebFragment.java:1093–1169` 的 `??` 声明。当前静态统计为 61 个文件、281 处行首 `??` 占位；详细日志见 `build/evidence-deps/wakeup-restoration-assemble-20260831-r26.log`。该结果不能推断未显示的全部错误，也不能用全局替换消除占位。

## 还原阻塞项

1. 没有 WakeUp 原始 Gradle、资源源码、ProGuard/R8 mapping 或可直接编译的 Java/Kotlin 源码。
2. 混淆 DEX 中部分协程、合成类和依赖生成代码不能直接由 JADX 还原；smali 只能作为逐项证据。
3. 没有真实 `.wakeup_schedule` 文件、不同历史版本样本或旧数据库快照，无法回放迁移和验证边界失败行为。
4. 原始签名 APK 的一次直接启动曾在系统 locale 绑定阶段出现 NPE；重组包能启动并显示旧 XML 课表页，但原签名 APK 与重组包的差异仍未知，需要干净设备和 A/B 安装才能解释签名/安装状态差异。
5. JADX 导出的源码不是可编译源码：首批编译错误包括非法 `??` 类型占位、混淆库内部类和 Kotlin 协程/枚举状态机语法，当前没有 R8 mapping 或原始源码可直接替换。
6. APK 资源是已编译资源表的反编译结果，不同工具生成的源 XML 均存在不可直接编译的名称、九宫格边框或属性类型；本轮仅接受有依赖 AAR/SDK 属性表和原始资源表支持的逐项修复，不能批量重命名或替换。
7. JADX 源码当前统计有 61 个文件包含行首 `??` 占位，共 281 处；r26 构建只显示 javac 首批 100 个错误，是编译器输出上限而不是全部错误。缺少原始源码或 mapping 的类必须继续按 smali 逐项确认，不能将首批以外的占位批量替换。

## 下一组最小可验证工作

下一阶段仍只处理 `.wakeup-restoration/` 的源码还原：每次选择一个 Material/Huawei/应用包/R 错误组，以 DEX/smali、字段描述符或已确认依赖版本为证据；若证据不足则保留错误并报告阻塞。每组后运行 `assembleDebug`。若缺少足够证据则不建立假类、假 Repository 或空壳入口；只有 Gradle 母体真正可安装后，才进行 launcher 和页面回归。不得在母体构建前扩展当前 Weeko-native 页面、迁移 Room、切换 Compose 或修改身份。
