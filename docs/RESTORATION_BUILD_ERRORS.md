# WakeUp 6.0.23 还原候选构建错误

最后更新：2026-09-01（Asia/Shanghai）

## R2 依赖替换闸门结果（2026-09-01）

在不改变旧包名、Room v11、资源、UI 和业务源码的前提下，先备份了当前构建日志和
Gradle 配置到 `build/evidence-deps/r2-preflight/`。APK 的 75 个
`META-INF/*.version` 已提取；APK 内没有 `.pom` 或 `.module`。完整依赖版本、源码
归属和停止理由见 [R2_DEPENDENCY_GATE.md](R2_DEPENDENCY_GATE.md)。

本轮完成三组 AndroidX 家族实验，均只排除对应 `sourceSets` 路径并接入 APK 确认
版本，未删除第三方源码：

- AppCompat：`androidx.appcompat:appcompat:1.7.0`，日志
  `build/evidence-deps/r2-appcompat-compile-20260901-escalated.log`。
- Fragment：`androidx.fragment:fragment:1.6.2` 与 `fragment-ktx:1.6.2`，日志
  `build/evidence-deps/r2-final-g2-fragment-20260901.log`。
- ViewPager2：`androidx.viewpager2:viewpager2:1.0.0`，日志
  `build/evidence-deps/r2-final-g3-viewpager2-20260901.log`。

三次官方 POM/AAR 均成功解析，但都在 Java 编译前于 `mergeDebugResources` 触发
`InvalidPathException`（`...app-mergeDebugResources-21:/values/values.xml` 或
`...app-mergeDebugResources-5:/values/values.xml`），所以没有可比较的 Java 错误
下降，WakeUp 自有错误数均为“未到达编译”，不是 0。三组 POM 的传递版本也分别与
APK 版本文件不一致。恢复后复跑日志为
`build/evidence-deps/r2-final-restored-baseline-20260901.log`，仍是 r57 的 100 个
错误、43 个 Java 路径。

由于 AndroidX/Room/WorkManager 反编译源码大量调用 `Ooo*`、`o00*` 等混淆内部
类型，三组实验均未减少错误，R2 已达到最终验证上限并停止修补。Gradle 源码仍未
生成 APK，因此本轮不执行新的安装验证；此前 apktool 重组包的运行结果不计入源码
构建成功。

本阶段最终 Go/No-Go 为 **NO-GO**：三组依赖家族均未推进到 Java 编译，且扩展诊断仍
量化出 1,910 个源码路径（其中 WakeUp 自有包 96 个）。因此停止逐文件修补；Weeko-native
最小测试版只能作为用户另行确认后的路线，本轮不改名、不改包、不发布任何 APK。

## 当前有效基线：r57 标准构建 + r58 扩展诊断（2026-09-01）

本轮目标是补齐 Parser 的明确反编译阻塞并复核旧包二进制。对照
`.restoration-apktool/smali/`、JADX simple 输出和原有字段/调用签名，完成了以下局部恢复：

- `schedule_parser/fetcher/OooO00o.OooO00o`：恢复 FSTVC StudyPlan 请求、分页协程状态和序列化返回；修改前副本为 `build/evidence-deps/r2-parser-backups/OooO00o-before-fstvc-restore.java`。
- `schedule_parser/parser/o0OOO0o.OooO0o`：恢复 NPU/XLS 表格行、单元格换行、星期/节次/周次和课程列表生成；副本为 `build/evidence-deps/r2-parser-backups/o0OOO0o-before-restore.java`。
- `schedule_parser/parser/OooO00o.Oooo0o0`：恢复 HTML `xkjbgzszGridIdGrid` 表格解析；原始 JADX 参考副本保留为 `build/evidence-deps/r2-parser-backups/OooO00o-before-html-restore.java`。
- `schedule_parser/parser/o0O0O00.OooO0o`：依据 NWPU smali 恢复学期、表头、上课时间和校区计数逻辑，并补回 smali 明确要求的 `(String, int)` 构造函数；副本为 `.wakeup-restoration/build/evidence-deps/r2-parser-backups/o0O0O00-before-restore.java`。

源码检查显示 Parser 目录中已没有 `UnsupportedOperationException("Method not decompiled")`，全工程行首 `??` 为 0。Parser 中仍有 134 处 JADX 生成的 `throw null`，另有一处仅存在于 JADX 注释中的类型推断警告；这些没有独立 smali/运行证据，未擅自改写。

全工程仍有 22 处可执行的 `UnsupportedOperationException("Method not decompiled")`，分布在 Ktor、Room、协程/序列化、AndroidX Fragment/CoordinatorLayout、Huawei 建议 Worker 及设置保存协程等非 Parser 类；它们属于后续逐方法恢复队列，不能用空实现替代。

`:app:assembleDebug --rerun-tasks`（r57；标准输出 `build/evidence-deps/wakeup-restoration-assemble-20260901-r57-clean.log`，错误流为同名 `.err.log`）仍在 `compileDebugJavaWithJavac` 失败；`mergeDebugResources`、`processDebugMainManifest`、`processDebugResources` 通过。Javac 默认上限输出 100 个错误，去重后首批涉及 43 个文件，全部落在 AndroidX/第三方/混淆源码（appcompat、fragment、media、transition、viewpager、ksoup/Kotlin 运行时和若干混淆包）；首批输出没有 Parser 或 `com.suda.yzune.wakeupschedule` 应用包路径。

为确认首批错误之后是否还有 Parser 阻塞，r58 临时对 `:app:compileDebugJavaWithJavac --rerun-tasks` 加入 `-Xmaxerrs 10000`（日志 `build/evidence-deps/wakeup-restoration-compile-20260901-r58-maxerrors.log`，错误流为同名 `.err.log`）。输出达到 10,000 条错误、去重后 1,910 个源码路径；Parser 路径错误为 0，WakeUp 应用包路径仍有 96 个。该编译参数已移除，未保留在 Gradle 配置中。

因此，Parser 的“显式未反编译方法”阻塞已清理，但不能据此宣称 Parser 行为等价或 Gradle 母体可构建；当前首个阻塞已转为第三方/混淆源码的结构性错误（循环继承、重复方法、缺失嵌套类型和缺失 AndroidX window 类）。

### 二进制复核

由未修改的 `.restoration-apktool/` 生成并签名的 `build/wakeup-rebuilt-r50-debug.apk`（SHA-256 `A146E17D9FF4EE32676039640A836621033C1FC2755C310320807EF3C3C89CEA`）通过 zipalign 和 apksigner v1/v2/v3；`aapt2 dump badging` 确认包名 `com.suda.yzune.wakeupschedule`、versionCode 263、versionName 6.0.23、launcher `SplashActivity`。这只是原 DEX smali 的重组二进制，不是 Gradle 源母体构建结果。

本轮设备已恢复可用：`adb devices -l` 返回 `3fde7e33 device`（机型 `22081212C`）。在不清除数据、不卸载原包的前提下执行 `adb install -r build/wakeup-rebuilt-r50-debug.apk` 返回 `Success`，包名仍为 `com.suda.yzune.wakeupschedule`，`versionCode=263`、`versionName=6.0.23`。强制停止后执行 `am start -W -n com.suda.yzune.wakeupschedule/.SplashActivity` 返回 `Status: ok`、`LaunchState: COLD`、`Activity: .../.schedule.ScheduleActivity`、`TotalTime: 769`；crash buffer 未出现该包的 `FATAL EXCEPTION`/`AndroidRuntime`。

本轮黑盒冒烟结果：ScheduleActivity 显示 `2026/9/1`、`第 18 周`、节次 1–10 的时间和“本周没有课程哦”；`dumpsys dbinfo com.suda.yzune.wakeupschedule` 显示 Room 数据库 `/data/user/0/com.suda.yzune.wakeupschedule/databases/wakeup` 为 `Open: true`，`room_master_table` identity 查询及 `tablebean`、`timedetailbean`、`coursebasebean natural join coursedetailbean` 查询均成功。点击功能面板的“全局设置”进入 `.settings.SettingsActivity` 并显示设置内容；导入入口依次显示“从教务导入/从文件导入/从分享口令”和“从 CSV/从 HTML/从备份”，选择 CSV 后进入 `.schedule_import.LoginWebActivity`，勾选说明并打开系统文件选择器 `com.android.fileexplorer/.picker.PickMainNavigatorActivity`，取消后返回课表，未写入导入数据。`run-as` 因 APK 未标记 debuggable 而拒绝，本轮数据库证据使用 `dumpsys dbinfo`，不修改应用私有文件。

> r26–r56 记录保留为恢复轨迹；其中列出的已修复类不再代表当前阻塞。当前有效标准构建基线为 r57，r58 仅为扩展错误量化诊断。

## 验证命令

工作目录：`.wakeup-restoration/`。使用 JDK 21、Android SDK build-tools 36 和 Gradle 9.5.0：

```text
gradle --no-daemon --gradle-user-home E:\codex\Weeko\.gradle-build --project-dir E:\codex\Weeko\.wakeup-restoration --project-cache-dir E:\codex\Weeko\.wakeup-restoration-gradle :app:assembleDebug --rerun-tasks --console=plain
```

## 已通过的任务

- `mergeDebugResources`：通过。
- `processDebugResources`：通过。
- `processDebugMainManifest`：通过；仅有旧 `package` 属性和 `extractNativeLibs` 升级警告。

## 当前失败任务

`compileDebugJavaWithJavac` 仍失败。r57 默认错误上限输出 100 条错误和 3 个 Java 8 source/target 警告，Gradle 结果为 `BUILD FAILED`，未产生可维护的 Gradle WakeUp 还原 APK；r58 的 10,000 错误扩展诊断已在上方单独记录。

最新一次错误的可复现文件/行号如下；它们不是业务语义结论，只是反编译源码无法被 Java 编译器接受的证据。已经按 smali 恢复的类不再列为当前阻塞。

| 文件 | 行号 | 错误形态 |
| --- | ---: | --- |
| `androidx/activity/ComponentActivity.java` | 42, 48, 138, 221 | JADX 将 `OooO0OO`/`OooO0O0` 外部包类型错误解析为不存在的嵌套类型 |
| `androidx/window/layout/*.java` | 多处 | `androidx.window.sidecar` 与 `androidx.window.extensions` 的 APK 类未被 JADX 输出，正式依赖版本尚未由 APK 证据确认 |
| `androidx/room/*.java`, `androidx/work/impl/WorkDatabase_Impl.java` | 多处 | Room/WorkManager 生成类引用缺失的混淆嵌套类型 |
| `kotlinx/coroutines/flow/o00Oo0.java` | 100–112 | SharedFlow 协程局部类型曾由 JADX 丢失；r40 已恢复为可解析声明，但尚未到达独立编译验证 |
| `p170o00o0Ooo/*.java`, `o000Oo0/o00O0O.java`, `o000O00/o00Oo0.java` | 多处 | JADX 生成重复 `clone`/方法，属于结构性反编译损失，不是 Parser 逻辑错误 |

Parser 侧本轮已按对应 smali、字段描述符和调用签名恢复 `o000O0Oo`、`o000OOo`、`o00O0O`、`o00oO0o`、`old_qz/OooO00o`、`oo0o0Oo`、`zf/OooO0O0`、`parser/OooOOO` 和 `parser/OooOOO0`；`rg` 当前统计 WakeUp 自有包和全工程均为 **0 行**行首 `??`，且 r40 错误输出中没有 `schedule_parser` 或 `com/suda/yzune/wakeupschedule` 文件。剩余是 90 个第三方/混淆文件的 200 条错误，不能在没有 mapping/原始依赖源码时批量猜测。

### 2026-08-31 r35–r40 Parser 及阻塞推进

- r35–r39：依据 `.restoration-apktool/smali/com/suda/yzune/wakeupschedule/schedule_parser/` 的寄存器复用恢复 Parser 方法；对布尔/整数、集合/数组和协程 continuation 做了局部拆分。每个修改前均保留在 `.wakeup-restoration/build/evidence-deps/r2-parser-backups/`，未改数据库、Manifest、导入行格式或网络边界。
- r40：对剩余可确认的第三方局部完成最小类型修复（Glide RequestCoordinator、OkHttp TLS 数组、ConstraintLayout 位标志、AndroidX listener、Room/HTTP2 对象等），并重跑完整任务。资源、Manifest、重复类、签名配置和 `processDebugResources` 继续通过；Java 首个阻塞移至第三方类名冲突/缺失嵌套类型。日志为 `build/evidence-deps/wakeup-restoration-assemble-20260831-r40.log`。
- 当前源码质量检查：全工程行首 `??` 为 0；Parser 文件没有出现在 r40 javac 错误中。该结果只证明语法占位已清除，不证明第三方类结构或整体行为等价。

### apktool 可运行二进制验证（2026-08-31）

使用未修改的 `.restoration-apktool/`（smali、Manifest 和资源）重新执行 apktool 2.10.0 build，生成 `build/wakeup-rebuilt-r40-unsigned.apk`（SHA-256 `AD5E3681EB24AFC9A28F22C73AD94E9F0D2B691B093B0BBA02C6740118D97A78`）；使用本机 Android debug keystore、zipalign 和 apksigner 生成 `build/wakeup-rebuilt-r40-debug.apk`（SHA-256 `6293DE75BAC4AD5873E639C7D1EA74677318F30037C219FE02A9E047F6019F70`）。`aapt2 dump badging` 确认旧包名、6.0.23/263 和 launcher `SplashActivity`；zipalign 和 apksigner v1/v2/v3 验证通过。该 APK 使用原始 DEX 的 smali 重组，不代表 Gradle 源母体已构建。

本轮执行 `adb devices` 无设备/模拟器连接，故无法在当前会话重新执行 install、Splash→ScheduleActivity、Room v11 或课程表/设置/导入冒烟。此前设备 `3fde7e33` 上的 apktool 重组包安装/进入 `ScheduleActivity` 证据仍保留在 `EVIDENCE_MATRIX.md`，不能当作本轮实时结果。

### 2026-08-31 r22–r26 还原构建复核

- r22：依据 `AddCourseActivity` 对应 smali 的 `ArrayList<Integer>` 使用，恢复 `OoooO2` 局部声明；该文件不再出现在首批错误中。
- r23：依据 DAO 实现类 `o00O0O` 的字段、接口和调用签名，恢复 `dao/OooO0O0` 中的局部类型和显式转换；DAO 错误不再出现。
- r24：依据分享协程 smali 的 `o00oO0o`/`int` 寄存器和异常控制流，恢复 `ScheduleActivity$shareScheduleOnline$1` 的声明及非法外层 catch 语句；该协程错误不再出现。
- r25：依据 `LoginWebFragment$refreshCode$1.smali` 的字段描述符和 `check-cast`，恢复 Bitmap、byte[]、String、TextInputEditText 局部，并修复学校名称截取结果的确定赋值；该协程错误不再出现。日志为 `build/evidence-deps/wakeup-restoration-compile-20260831-r25.log`。
- r26：重新运行完整 `:app:assembleDebug --rerun-tasks`。资源、Manifest、重复类、签名配置和 `processDebugResources` 均通过；`compileDebugJavaWithJavac` 仍失败，Javac 输出 100 个错误和 3 个 Java 8 source/target 警告，当前首批错误全部集中在 `LoginWebFragment.java:1093–1169` 的未恢复 `??` 声明。日志为 `build/evidence-deps/wakeup-restoration-assemble-20260831-r26.log`。

以上每批均保留 `build/evidence-deps/source-before-*` 备份。它们只证明错误面向继续推进，不证明反编译实现已经达到行为等价；`LoginWebFragment.java` 需要下一轮按对应方法的 smali 逐寄存器恢复，当前不做全局类型猜测。

## 2026-08-31 类级恢复复核

在不改变 Manifest、数据库、导入格式或业务控制流的前提下，依据对应 smali 对以下反编译局部类型进行了最小恢复：

- `androidx/activity/o00O0O.java`、`androidx/fragment/app/o0000OO0.java`：回调局部恢复为 `o000000O` 接口并保留显式转换。
- `androidx/appcompat/widget/ActionMenuView.java`、`androidx/appcompat/widget/o00O0OOO.java`：分别恢复整数局部和 `o00O00` 菜单视图局部。
- `androidx/work/Oooo0.java`、`androidx/work/impl/workers/ConstraintTrackingWorker$runWorker$2.java`：按 smali 的 `invoke`/协程标签寄存器拆分恢复；后者将 `label` 与 `o00O0000` Job 分开声明。
- `androidx/room/coroutines/OooO0o.java`、`androidx/slidingpanelayout/widget/SlidingPaneLayout.java`、`biweekly/io/text/ICalReader.java`：恢复对象、布尔和 `SyntaxStyle`/`String` 局部，不改分支。
- `com/bigkoo/quicksidebar/QuickSideBarView.java`、`com/bumptech/glide/request/OooO00o.java`、`p041Oooooo/o0000O0O.java`、`p041Oooooo/o00O00O.java`：按字段描述符和调用接口恢复 lazy、回调、数组及 Glide 监听器局部。
- `androidx/recyclerview/widget/RecyclerView.java`：依据字段描述符、`getLayoutManager()` 返回类型和 smali 中的整型位标志，恢复 `OooOOOo()` 与 `onTouchEvent()` 中 6 处寄存器占位；布尔值保留为 `0/1` 整型位运算语义，布局管理器恢复为 `o000O00`。原文件备份为 `build/evidence-deps/source-before-recyclerview.java`。

这些修改的原文件备份位于 `build/evidence-deps/source-before-*` 目录、`source-before-ConstraintTrackingWorker.java`、`source-after-*.java` 以及 `source-before-ksoup-enums/`，对应 smali 证据仍保留在 `.restoration-apktool/smali/`。它们只证明源码可以继续进入编译阶段，不证明反编译实现已经完成行为等价恢复。

### 2026-08-31 ksoup 枚举恢复复核

依据 `.restoration-apktool/smali/com/fleeksoft/ksoup/` 中的 `.class public final enum`/`<clinit>` 证据，将 JADX 错误输出的 `Entities$EscapeMode`、`Entities$CoreCharset`、`HtmlTreeBuilderState`、`TokeniserState` 恢复为 Java enum：保留 APK 中的常量顺序、实体表构造、状态机方法和 `EnumEntries` helper；移除 JADX 伪造的 `new`、缺失寄存器数组和手写 `values()/valueOf()`。没有引入外部实现，也没有改变业务控制流。

早期完整输出保存于 `build/evidence-deps/wakeup-restoration-compile-20260831-r9.log`。r20 在此基础上又按 smali 恢复了 Huawei analytics/framework/receiver、CreateFileUtil、ReadApkFileUtil、hatool `w`、Material timepicker、生成式 R 类、ScheduleActivity 课程映射、SelectTime/SelectDateRange 及其日期监听器；r22–r25 又越过 AddCourse、DAO、分享协程和 `LoginWebFragment$refreshCode$1` 的首批错误。r26 最终复核仍通过资源和 Manifest 处理，但 `compileDebugJavaWithJavac` 被 `LoginWebFragment.java` 中的非法 Java 阻塞，未生成可安装的 Gradle WakeUp 母体 APK。

### 2026-08-31 Material/Huawei 小批次恢复

依据 `.restoration-apktool/smali/` 中的字段描述符、接口声明和 `<clinit>` 顺序，完成了以下最小源码恢复：

- `com/google/android/material/chip/Chip.java`：把 smali 中参与位运算的布尔结果恢复为整型 `0/1` 局部。
- `com/google/android/material/navigation/NavigationView.java`：按寄存器写入和调用签名恢复整型局部及布尔条件。
- `com/huawei/agconnect/https/e.java`：APK 明确为带运行时字段的接口；将非法静态代码块改为合法接口字段初始化，保留线程池参数和线程命名格式。
- `com/huawei/hms/analytics/aq.java`：APK 明确为带正则、国家码/标签数组的接口；按 smali 初始化顺序恢复为合法接口字段表达式。

原文件备份位于 `build/evidence-deps/source-before-material/` 和 `build/evidence-deps/source-before-huawei/`。这些项只修复 Java 语法/类型表达，不改变 Manifest、Room、导入格式或应用流程；r9 及后续日志确认它们已从首批错误中消失，但不构成行为等价证明。

### 2026-08-31 r10–r20 恢复复核

依据对应 smali 和生成资源证据，r10–r20 逐批完成以下最小恢复：Material timepicker 局部；Huawei analytics 匿名回调、receiver 回调、framework `List` 局部、文件哈希校验和流类型；删除无法编译的 JADX 生成 `R.java` 以交由 Android Gradle Plugin 从资源生成；恢复 `ScheduleActivity`/`CourseDetailBottomSheet` 的课程映射类型、`SelectTimeFragment` 的时间选择类型，以及 `SelectDateRangeFragment` 的日期监听器合成类。每批均保留 `build/evidence-deps/source-before-*` 备份并重新运行 javac。r20 只证明错误面向应用包导入/DAO/协程代码推进，不能证明行为等价。

### 2026-08-31 R1 r27–r33 还原构建复核

- r27–r30：保留原始源码备份，按对应 smali 逐文件处理 `LoginWebFragment` 主方法及 WebView 回调组；没有移动第三方源码、替换依赖或添加兼容空壳。
- r31：完整 `:app:assembleDebug --rerun-tasks` 通过资源、Manifest、重复类和签名配置处理；Java 首个错误移入 `schedule_parser/parser/o00000.java`，WebView 组不再出现在首批错误中。
- r32：依据 `o00000.smali` 恢复一个 Parser 方法的 ArrayList/int 局部；Java 首个错误移入 `schedule_parser/parser/o00000O0.java` 等 Parser 文件。
- r33：依据 `o00000O0.smali` 恢复 3 个方法的寄存器类型拆分（含 boolean/int 复用）；资源、Manifest、重复类和签名配置继续通过，但 `compileDebugJavaWithJavac` 仍以 100 个错误、3 个 Java 8 source/target 警告失败。日志为 `build/evidence-deps/wakeup-restoration-assemble-20260831-r33.log`。
- r34：未修改源码，仅重新运行完整 `:app:assembleDebug --rerun-tasks` 作为当前状态复核；资源、Manifest、重复类和签名配置继续通过，`compileDebugJavaWithJavac` 仍以同一组 Parser `??` 错误、100 个错误和 3 个 Java 8 source/target 警告失败。日志为 `build/evidence-deps/wakeup-restoration-assemble-20260831-r34.log`。

上述 r34 记录已被 r35–r40 推进结果取代：Parser 占位已清除，当前阻塞为第三方/混淆源码结构缺失。每组修改均保留在 `build/evidence-deps/source-before-*`、`build/evidence-deps/r1-webview-backups/` 或 `.wakeup-restoration/build/evidence-deps/r2-parser-backups/`；仍缺少原始源码或 mapping，不能保证通过逐方法猜测保持整体行为。

## R1 结论与后续边界

当前 `.wakeup-restoration/` 仍是唯一旧包名 WakeUp 母体候选，但其 Gradle 源工程尚不能通过 `compileDebugJavaWithJavac`，因此尚未产出可维护的 Gradle APK；本轮可安装运行的是由 `.restoration-apktool/` 重组并签名的 `build/wakeup-rebuilt-r50-debug.apk`。恢复在技术上仍可能继续，但需要 6.0.23 对应原始源码/mapping、明确第三方依赖版本，或经用户确认后开展高成本的逐方法 smali 审计；不能把 apktool 二进制运行成功等同于源码母体已恢复。后续若继续，只能一次选择一个可由 DEX/smali、字段描述符或已确认依赖版本证明的错误组，并在每组后重跑 `assembleDebug`，不添加假类、假 Repository、替代页面或新的应用身份。构建成功前不得进行 SharedPreferences 页面重构。
