# WakeUp 6.0.23 还原架构基线

最后更新：2026-08-31（Asia/Shanghai）

> 当前还原构建快照为 r26 最终复核：资源/Manifest 阶段通过，Java 编译仍阻塞。这里的架构只描述 WakeUp 6.0.23 母体，不把 `app/` 的 Weeko-native 实验代码视为替代实现。

## 当前架构结论

功能母体是 `wakeup6.0.23.apk`，不是当前 `app/` 中的 Weeko-native 实验工程。仓库目前没有 WakeUp 原始 Gradle 工程、源码或 Git 历史，因此不能把反编译 Java 直接当作可编译架构。当前工作首先是还原旧工程的构建边界和行为，再在同一母体上渐进修改。

```text
wakeup6.0.23.apk
  ├─ Manifest / resources / smali / JADX 参考
  ├─ WakeUp Room v11 + 7→11 migrations
  ├─ XML Activity/Fragment 页面
  ├─ Preferences / Widget / Alarm / WorkManager
  └─ import/export / school parser / network
          ↓ 逐项恢复
WakeUp 可编译母体
          ↓ 保持行为的局部重构
Weeko
```

证据的详细来源、结论等级和缺口见 [EVIDENCE_MATRIX.md](EVIDENCE_MATRIX.md)；目录归属、还原程度和阻塞项见 [RESTORATION_BASELINE.md](RESTORATION_BASELINE.md)。

## 当前仓库目录归属

```text
app/                       # 误建 Weeko-native 工程，不是母体；暂不删除
adapter/wakeup/             # 手工 parser 候选，不是 APK 还原源码；暂不接入母体
.stage4a-jadx/              # JADX 证据输出，非源码 module
.restoration-apktool/       # apktool Manifest/resources/smali 证据，非源码 module
.wakeup-restoration/        # JADX 导出的原包名 Gradle 候选；当前唯一旧工程候选
docs/                       # 证据、状态和路线文档
wakeup6.0.23.apk            # 不可变研究输入
```

`app/` 当前 namespace/applicationId 为 `io.github.mxwf.weeko`，启用了 Compose、Weeko Room v1 和课程详情/editor 代码；这些实现可以构建，但没有 WakeUp Activity、Fragment、DAO 或旧数据库行为，必须标记为非权威。未经确认不删除、不扩展、不把它当作还原母体。

## 已确认的旧架构关系

### Activity 与核心页面

APK Manifest 确认 launcher 为 `com.suda.yzune.wakeupschedule.SplashActivity`，主课表为 `schedule.ScheduleActivity`；课程编辑为 `course_add.AddCourseActivity`；设置、作息、课表管理、课表设置、关于和导入分别由旧包下的 Activity 承担。`schedule_import.LoginWebActivity` 还承接 `.wakeup_schedule`、HTML 和 CSV 的 VIEW intent。完整组件清单及导出属性以 apktool/`apkanalyzer` 输出为准，不在当前 Weeko `MainActivity` 上做等价假设。

### Room 与配置

旧 Room 数据库 schema version 11，业务表为 `CourseBaseBean`、`CourseDetailBean`、`AppWidgetBean`、`TimeDetailBean`、`TimeTableBean`、`TableBean`；数据库名通常为 `wakeup`，API 24+ 某条件分支使用 `<dataDir>/databases/db/wakeup`。迁移注册链为 7→8→9→10→11，SQL 已在证据矩阵保存。`config`、`multi_language`、`table{id}_config`、`time{id}_config`、`widget{id}_config` 共同影响当前表、作息、显示和 Widget。所有这些属于稳定但老旧的兼容边界，不能用当前 Weeko Room v1 替换。

### Widget、提醒和后台

APK 声明六个 Widget provider、三个 RemoteViews service、独立 `:widgetProvider` 进程的 MIUI provider，并通过 AlarmManager 处理课程提醒；WorkManager 组件主要来自 AndroidX 初始化和 Honor/Vivo 相关任务。旧 action、provider authority、PendingIntent/request code、通知 channel 和刷新周期都属于高风险系统边界。

### 导入导出、Parser 与网络

`.wakeup_schedule` 是五个按行分隔的 JSON 值；导出/导入模型围绕 `TimeTable`、`TimeDetail`、`Table`、`CourseBase`、`CourseDetail`。教务 parser 输出旧 `Course`、`TimeTable`、`TimeDetail`、`WeekBean` 等模型，APK 同时包含 Ktor 与 Retrofit/OkHttp 迹象。当前 `adapter/wakeup` 的 hand-written parser 只能作为待验证参考，不能替换或宣称等价。

## 还原期间允许的依赖方向

还原阶段不引入新的 Clean Architecture 分层，也不迁移 Compose。依赖方向只按旧工程恢复：

```text
旧 Activity/Fragment/XML
        ↓
旧 ViewModel/Manager/Repository（由证据逐项恢复）
        ↓
旧 DAO / Room v11 / SharedPreferences / Parser / Network
```

可整理的工作仅限于证据目录、Gradle/资源引用、Manifest 声明和编译错误；每次只修一组能由 Debug 构建验证的问题。不得为了通过编译删除旧页面、替换表结构、伪造 Repository、添加假数据或全局改包名。

## 构建恢复顺序

1. 固定 APK 哈希和反编译输出，保留原包名 `com.suda.yzune.wakeupschedule`。
2. 从 apktool 解码结果恢复资源目录、Manifest、launcher 和最小 Gradle 依赖。
3. 以资源引用、Manifest 类和编译器错误为边界，逐组补回必要源码/依赖；JADX 只作参考，smali/资源/Room SQL 需要交叉证据。
4. 先完成 `assembleDebug`，再安装验证 launcher；没有母体构建结果前，不开展 UI、身份、数据库迁移或业务重设计。
5. 只有在旧母体能运行并有回归样本后，才规划同一工程内的 Weeko 原地重构。

本轮已经验证 apktool 解包结果可以重组为旧 package/version 的二进制并进入 `ScheduleActivity`；这只是还原证据，不能替代 Gradle 源工程和原签名发布包。
JADX `--export-gradle` 已生成 `.wakeup-restoration/`。依据 APK 依赖版本和 Android SDK 属性表逐项恢复资源后，`mergeDebugResources`、`processDebugResources` 和 Manifest 处理已通过；随后按 smali 恢复了前一批 13 个类、RecyclerView 局部类型、ksoup 四个 enum/状态机结构、Material/Huawei 类、文件校验/流类型、生成式 R 类、ScheduleActivity/CourseDetailBottomSheet 课程映射及 SelectTime/SelectDateRange 日期监听器，r22–r25 又恢复了 AddCourse、DAO、分享协程和 `LoginWebFragment$refreshCode$1` 的确定局部类型。r26 最终 `assembleDebug` 仍在 `compileDebugJavaWithJavac` 被 `LoginWebFragment.java:1093–1169` 的非法 Java 阻塞。该候选仍不是可编译母体，不能用全局替换或假类掩盖语义缺口。公开的 `YZune/WakeUpSchedule` master（提交 `5d43928`，2018-04-07）是 2.10/GreenDAO 历史工程，不是 6.0.23，不作为实现来源。

## 非目标与风险护栏

- 不创建第二套替代应用，不将 `io.github.mxwf.weeko` 作为当前功能母体。
- 不修改 WakeUp Room schema、迁移 SQL、数据库路径、文件格式、Provider URI、Intent action、Widget、提醒或 Parser 语义。
- 不从反编译结果猜测缺失行为；结论必须标注为已确认、合理推断或未知。
- 当前误建 Weeko 代码仅作隔离对象，保留/回退/复用需在还原母体可构建后单独决策。
