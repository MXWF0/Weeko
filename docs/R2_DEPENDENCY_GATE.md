# R2 依赖替换可行性闸门

最后更新：2026-09-01（Asia/Shanghai）

本记录只评估 `.wakeup-restoration` 这个 WakeUp 6.0.23 原包名候选，不改变
`applicationId`、Room v11、资源、UI 或用户行为。实验配置已在每次构建后撤回。

## 固定证据

| 证据 | 结果 |
| --- | --- |
| APK | `wakeup6.0.23.apk`，6,082,176 bytes，SHA-256 `50EDBC7C7C3458DD0D97436F15A6AC1E69AFBE107054F53B63A0327E52DBB476` |
| APK 版本元数据 | 75 个 `META-INF/*.version`，提取到 `build/evidence-deps/r2-meta-inf/META-INF/` |
| APK 内 POM/Gradle module | 未发现 `.pom`、`.module`、`pom.properties` 或 `pom.xml`；不能把 APK 内缺失的 POM 当成已确认依赖 |
| 官方 POM | 三组实验均从官方 Maven 取得对应 POM/AAR；AppCompat POM 路径为 `.gradle-build/caches/modules-2/files-2.1/androidx.appcompat/appcompat/1.7.0/76610e8108032c24b855d5772957e511599af921/appcompat-1.7.0.pom`，SHA-256 `A57B428F428A9337D7B483A2162A570D4E672BCEFF411A6465E53E8747506AC3`；属于官方 Maven 证据而非 APK 内证据 |
| 源码候选 | `.wakeup-restoration/app/src/main/java`，6756 个 Java 文件；没有 Kotlin 源文件 |
| 基线构建 | r57：`compileDebugJavaWithJavac` 报告 100 个错误、去重 43 个 Java 路径；r58 临时 `-Xmaxerrs 10000`：10000 个错误、去重 1910 个路径，其中 WakeUp 包 96 个路径 |
| 备份/日志 | 构建脚本快照在 `build/evidence-deps/r2-preflight/` 和 `build/evidence-deps/r2-final/`；三组实验日志分别为 `r2-appcompat-compile-20260901-escalated.log`、`r2-final-g2-fragment-20260901.log`、`r2-final-g3-viewpager2-20260901.log`，恢复基线为 `r2-final-restored-baseline-20260901.log` |

`META-INF/*.version` 是 APK 打包时留下的组件版本线索，不等于完整的 Gradle
锁定文件。`androidx.arch.core_core-runtime.version` 的内容是
`task ':arch:core:core-runtime:writeVersionFile' property 'version'`，标记为
无效版本；`androidx.databinding_*` 也只有插件生成的版本文件，坐标和运行时范围
不能仅凭该文件推断。

## APK 版本清单（按家族归并）

| 家族/坐标前缀 | APK 版本文件确认的版本 |
| --- | --- |
| `androidx.activity` | activity、activity-ktx 1.8.0 |
| `androidx.appcompat` | appcompat、appcompat-resources 1.7.0 |
| `androidx.annotation` | annotation-experimental 1.4.1 |
| `androidx.arch.core` | core-runtime：无效/未知 |
| `androidx.asynclayoutinflater`, `cardview` | 1.0.0 |
| `androidx.constraintlayout` | 2.2.1 |
| `androidx.coordinatorlayout` | 1.1.0 |
| `androidx.core` | core、core-ktx 1.16.0；core-viewtree 1.0.0 |
| `androidx.cursoradapter`, `documentfile`, `dynamicanimation`, `interpolator`, `loader`, `localbroadcastmanager`, `media`, `print`, `swiperefreshlayout` | 1.0.0 |
| `androidx.customview` | 1.1.0 |
| `androidx.databinding` | library 8.0.0；viewbinding 8.9.0（坐标范围未知） |
| `androidx.drawerlayout` | 1.1.1 |
| `androidx.emoji2` | emoji2、views-helper 1.3.0 |
| `androidx.exifinterface` | 1.3.3 |
| `androidx.fragment` | fragment、fragment-ktx 1.6.2 |
| `androidx.legacy` | legacy-support-core-ui、core-utils、v4 1.0.0 |
| `androidx.lifecycle` | livedata、runtime、process、service、viewmodel、savedstate 及 ktx 变体 2.9.0 |
| `androidx.navigation` | common、fragment、runtime、ui 及 ktx 变体 2.9.0 |
| `androidx.profileinstaller` | 1.4.0 |
| `androidx.recyclerview` | 1.2.1 |
| `androidx.room` | room-runtime、room-ktx 2.7.1 |
| `androidx.savedstate` | savedstate、savedstate-ktx 1.3.0 |
| `androidx.slidingpanelayout` | 1.2.0 |
| `androidx.sqlite` | sqlite、sqlite-framework 2.5.0 |
| `androidx.startup` | 1.1.1 |
| `androidx.tracing` | tracing、tracing-ktx 1.2.0 |
| `androidx.transition` | 1.5.0 |
| `androidx.vectordrawable` | vectordrawable、vectordrawable-animated 1.1.0 |
| `androidx.versionedparcelable` | 1.1.1 |
| `androidx.viewpager`, `androidx.viewpager2` | 1.0.0 |
| `androidx.window` | 1.0.0 |
| `androidx.work` | work-runtime、work-runtime-ktx 2.10.1 |
| `com.google.android.material` | material 1.12.0 |
| `org.jetbrains.kotlinx:kotlinx-coroutines-*` | android、core、slf4j 1.10.2 |

正式坐标仍需以对应版本的官方 POM/module 为准；除三组临时实验外，本轮没有
把上述线索写入 Gradle。

## 源码归属与混淆证据

- WakeUp 自有包 `com/suda/yzune/wakeupschedule/**`：679 个 Java 文件。该目录把
  反编译的业务类、Room 生成类和 Kotlin 合成类混在一起；可直接识别的
  `AppDatabase_Impl.java` 为 1 个，`$$serializer.java` 为 52 个，带 `$` 的合成/协程
  类为 281 个（有重叠，不作加总）。
- 第三方/反编译依赖：6077 个 Java 文件。主要目录计数为 AndroidX 1165、
  `com/google` 373、Kotlinx 214、Kotlin 115、Biweekly 293、Ktor 260、OkHttp 55、
  Retrofit 48、`org` 171；源码没有删除，仍保留原路径。
- AndroidX 源码不是可直接替换的官方源码：`androidx/appcompat` 221 个文件中
  163 个文件名是 `Ooo*`/`o00*` 等混淆名称；fragment 88/56、viewpager2 25/14、
  room 111/66、work 137/84 也有同样特征。
- 调用证据：`App.java:16` 导入 `androidx.appcompat.app.o00Oo0`，
  `AppDatabase_Impl.java:3` 导入 `androidx.room.OooOOO`，
  `androidx/appcompat/widget/OooOO0.java:8` 将类声明为
  `OooOO0.o0O0O00`，`ViewPager2.java:16–18` 依赖
  `androidx.recyclerview` 的混淆类。这些并非 AppCompat/Room 官方公开类型；
  用正式 AAR 替换后，保留的 WakeUp 调用无法由公开 API 自动满足。

## 依赖家族实验

### G0：恢复前基线（已确认）

配置没有任何外部 implementation 依赖，全部反编译源码参与编译。r57 的
`assembleDebug --rerun-tasks` 在 Java 编译阶段报告 100 个错误、43 个路径；r58
扩展诊断报告 10000 个错误、1910 个路径，WakeUp 自有包 96 个路径。首批错误包含
缺失混淆嵌套类型、循环继承和重复方法。

### G1：AndroidX AppCompat

临时改动如下：

```groovy
android {
    sourceSets {
        main { java { exclude 'androidx/appcompat/**' } }
    }
}
dependencies {
    implementation 'androidx.appcompat:appcompat:1.7.0'
}
```

并临时设置 `android.useAndroidX=true` 以允许 AGP 接受正式 AndroidX AAR。官方
POM 解析成功，但其传递依赖要求 Fragment 1.5.4、Core 1.13.0、Lifecycle 2.6.1
等，和 APK 版本文件中的 Fragment 1.6.2、Core 1.16.0、Lifecycle 2.9.0 不一致。
接着在组合反编译资源与正式 AAR 时 `mergeDebugResources` 失败，错误为：

```text
java.nio.file.InvalidPathException: Illegal char <:> at index 56:
com.suda.yzune.wakeupschedule.app-mergeDebugResources-21:/values/values.xml
```

因此本组没有到达 `compileDebugJavaWithJavac`，Java 错误数和 WakeUp 自有错误数
不可测（不是 0）；新增冲突为 1 个资源合并非法路径。没有删除
`androidx/appcompat/**` 源文件，实验配置随后全部撤回。

### G2：AndroidX Fragment

从 G0 基线开始，临时排除 `androidx/fragment/**`，加入：

```groovy
implementation 'androidx.fragment:fragment:1.6.2'
implementation 'androidx.fragment:fragment-ktx:1.6.2'
```

对应官方 POM/AAR 均已解析。POM 的传递依赖包含 Activity 1.7.2、Core KTX 1.2.0、
Lifecycle 2.6.1、SavedState 1.2.1 等，和 APK 版本文件中的 Activity 1.8.0、Core
1.16.0、Lifecycle 2.9.0、SavedState 1.3.0 不一致。完整构建日志为
`build/evidence-deps/r2-final-g2-fragment-20260901.log`；在 Java 编译前同样于
`mergeDebugResources` 失败，错误为 `InvalidPathException`，路径为
`com.suda.yzune.wakeupschedule.app-mergeDebugResources-21:/values/values.xml`。
Java 错误和 WakeUp 自有错误均未到达编译，不能记为 0。

### G3：AndroidX ViewPager2

从 G0 基线开始，临时排除 `androidx/viewpager2/**`，加入：

```groovy
implementation 'androidx.viewpager2:viewpager2:1.0.0'
```

官方 POM 的传递依赖固定到 Fragment 1.1.0、RecyclerView 1.1.0、Core 1.1.0，和 APK
版本文件中的 Fragment 1.6.2、RecyclerView 1.2.1、Core 1.16.0 不一致。完整构建
日志为 `build/evidence-deps/r2-final-g3-viewpager2-20260901.log`；仍未到达 Java
编译，在 `mergeDebugResources` 报同类 `InvalidPathException`，本次路径为
`com.suda.yzune.wakeupschedule.app-mergeDebugResources-5:/values/values.xml`。
Java 错误和 WakeUp 自有错误均未到达编译，不能记为 0。

### 恢复后基线

恢复配置后再次运行完整任务（`build/evidence-deps/r2-final-restored-baseline-20260901.log`），
仍为 100 个错误、43 个 Java 路径，首个任务和错误形态与 G0 一致，证明实验没有
留下依赖或 AndroidX 属性副作用。

### 量化汇总

| 运行 | Java 编译是否启动 | Javac 错误总数 | 去重 Java 路径 | WakeUp 自有路径 | 新增冲突 |
| --- | --- | ---: | ---: | ---: | --- |
| G0/r57 基线 | 是 | 100 | 43 | 0（默认上限首批） | 无 |
| r58 扩展诊断 | 是 | 10000（上限） | 1910 | 96 | 无新增依赖 |
| G1 AppCompat | 否 | — | — | — | `mergeDebugResources` 非法路径 |
| G2 Fragment | 否 | — | — | — | `mergeDebugResources` 非法路径 |
| G3 ViewPager2 | 否 | — | — | — | `mergeDebugResources` 非法路径 |
| R2 最终恢复基线 | 是 | 100 | 43 | 0（默认上限首批） | 无 |

## 闸门结论

本轮完成三组正式依赖家族的最终验证，未超过上限：

1. 三组正式 AAR 均可从官方 Maven 解析，但 APK 内没有 POM；三组 POM 的传递版本
   也分别与 APK `META-INF/*.version` 存在冲突。
2. G1、G2、G3 的 Java 编译均未启动，三次都在资源合并阶段出现非法路径；因此
   没有一组实现错误下降，更不能证明“排除源码家族 + 正式依赖”可以恢复母体。
3. r58 扩展诊断量化了 10000 个错误、1910 个路径，其中 WakeUp 自有包 96 个；
   AndroidX/Room/WorkManager 源码还大量调用 `Ooo*`、`o00*` 等混淆内部类型。
   没有原始 mapping 或可编译原始源码时，继续替换会把未知类型伪装成公开 API。

结论：**三组正式依赖均未通过，WakeUp 源码快速恢复最终可行性验证失败，R2
停止修补。**
第三方源码未删除，未创建伪兼容类、空实现或全局替换；`.wakeup-restoration`
仍保持旧包名和 Room v11。由于 Gradle 源码没有生成 APK，本轮没有安装新的
Gradle APK，也没有把此前 apktool 重组包的运行结果冒充源码构建成功。

下一阶段若继续，应先取得原始源码/mapping 或逐类恢复缺失的混淆内部类型，并为
资源重组建立独立可复现步骤；在此之前不进入 Weeko 改名、Compose 或数据库迁移。

## 最终 Go/No-Go 判定

**NO-GO。** 三个正式依赖家族均已按要求完成验证，但没有一个能把构建推进到
有限、可由 smali 还原的 WakeUp 自有代码错误；它们全部在 Java 编译前触发资源
合并非法路径。基线仍是 100 个错误/43 个路径，扩展诊断仍是 10000 个错误/1910
个路径（WakeUp 自有 96 个路径）。因此不继续逐文件修补，不安装或发布任何新的
APK。

## 可选路线与 Weeko-native 最小测试版边界

| 路线 | 适用条件 | 结果/代价 |
| --- | --- | --- |
| 取得原始 6.0.23 源码、mapping 和依赖锁定 | 需要最高行为兼容性 | 重新建立真正的 Gradle 母体，优先推荐；当前 APK/源码证据可作为回归基线 |
| 保留当前母体，逐类按 DEX/smali 恢复 | 无法取得原始工程 | 面向 1910 个阻塞路径的高成本工程，不能承诺快速可构建；不再用正式依赖替换或猜测兼容类 |
| 另行确认 Weeko-native 测试版 | 接受与 WakeUp 独立安装和迁移成本 | 不改动当前母体；需用户明确批准后再建立测试包和发布流程 |

若选择第三条路线，建议 v0.1 测试版只包含：本地单学期/单课表、手动课程增删改、
周视图与今日/下一节课程、可配置节次时间，以及 WakeUp 文件导入的“解析→预览→
确认→事务写入”闭环。提醒、Widget、ICS/CSV、教务网络 Parser、账号体系、云同步、
正式包名迁移和生产发布均不纳入最小测试版；这些边界只是候选范围，本轮没有创建、
改名、打包或发布 Weeko-native APK。
