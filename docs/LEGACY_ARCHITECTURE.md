# WakeUp 6.0.23 旧架构盘点

最后更新：2026-08-31（静态审计证据来自 2026-08-30 APK 分析，黑盒验证来自连接设备）。

> 路线纠偏（2026-08-31）：本文只作为 WakeUp 6.0.23 还原证据，不再把 WakeUp 视为 Weeko 的外部数据源。仓库中的 `app/` 是误建的 Weeko-native 实验，不是旧架构实现；下文的 Activity/Fragment/Room/Widget 关系必须先恢复为可编译母体，才能进入渐进重构。原包名、签名、Provider、Widget、通知和 WorkManager 身份在还原阶段保持不变。

## 1. 文档性质

本文是对 `wakeup6.0.23.apk` 的静态重构基线，不是 WakeUp 原始源码的复原。类名中出现 `o0000O`、`OooOo00` 等名称，是 JADX 在混淆代码上的结果；下文同时给出可识别的业务名和 JADX 名称。Manifest、Room 生成 schema、资源字符串和多个调用点相互印证的内容标为“已确认”；只来自单个反编译方法或无法还原泛型的内容标为“待确认”。

## 2. 包、进程与应用入口

APK 应用身份为 `com.suda.yzune.wakeupschedule`，标签为 `WakeUp课程表`。启动 Activity 是导出的 `SplashActivity`。Manifest 还声明了 `:widgetProvider` 进程供部分 MIUI Widget 使用；其余主要页面运行在默认应用进程。应用开启 `allowBackup`、Rtl 支持和全局 `cleartextTrafficPermitted=true` 的 network security 配置，并请求通知、精确闹钟、振动、唤醒锁、网络、开机完成和厂商相关权限。Weeko 不应继承这些身份或权限默认值。

从入口到核心页面的关系可以概括为：

```text
App.onCreate
  ├─ 时区/WebView/语言/夜间模式/动态颜色
  ├─ SharedPreferences("config")
  ├─ NotificationChannel(schedule_reminder, news)
  ├─ 日期与时间变化 Receiver ──> Widget/状态刷新
  └─ Honor/Vivo WorkManager 建议任务

SplashActivity ──(深链参数)──> ScheduleActivity
ScheduleActivity ──> ScheduleViewModel(o0000O) ──> Room DAO/AppDatabase
       ├─> AddCourseActivity / 课程编辑 Fragment
       ├─> ScheduleManageActivity / ScheduleSettingsActivity
       ├─> SchoolListActivity / LoginWebActivity / 导入流程
       ├─> ClockActivity / 设置 / 关于 / 捐赠
       └─> WakeUp 兼容导出 / ICS

导入 Activity/Fragment ──> ImportViewModel(OooOo00)
       ──> ParserProxy(o00Oo0) ──> 学校 Parser/HTTP/WebView
       ──> CourseBaseBean + CourseDetailBean + Time* ──> DAO

Widget Receiver/RemoteViews Service ──> Preferences + DAO
ScheduleContentProvider ──> 受限调用方 ──> DAO/课表状态
TodayCourseAppWidget ──> AlarmManager ──> 通知 channel schedule_reminder
```

## 3. Activity、Fragment 与主要页面

### 3.1 基础层

`BaseActivity` 继承 AppCompat，集中处理语言上下文、边到边和系统栏；`BaseTitleActivity`、`BaseBlurTitleActivity` 和 `BaseListActivity` 提供标题栏、模糊标题或程序化 CoordinatorLayout/AppBar/RecyclerView。基础 Fragment（JADX 名称 `base_view.OooO00o`）提供生命周期协程启动能力。它们是传统 View 页面共享的基础，不是 Compose 基础设施。

### 3.2 页面与职责

| 页面/组件 | 作用与关系 | Manifest/风险备注 |
| --- | --- | --- |
| `SplashActivity` | 启动初始化后进入 `ScheduleActivity`；读取 `id`、`week`、`day`、`courseId`、`startNode`、`ownTime`、`startTime`、`action` 等深链参数 | 导出启动入口；外部行为不可随意改 |
| `ScheduleActivity` | 周课表、当前表/周、菜单、课程点击；打开编辑、管理、设置、导入和时钟 | 核心页面；依赖 ViewModel/DAO/Preferences |
| `CourseDetailBottomSheet` | 课程详情、编辑/删除入口 | 与课程 id、detail id 和当前周耦合 |
| `AddCourseActivity` | 手工添加课程；配合 `SelectDateRangeFragment`、`SelectTimeFragment`、`SelectWeekFragment` | 写入 CourseBase/Detail，属于高风险写路径 |
| `ScheduleManageActivity`、`ScheduleManageFragment`、`CourseManageFragment` | 多课表/课程管理、删除或切换表 | 影响当前表和 Widget |
| `ScheduleSettingsActivity`、`ScheduleSettingsFragment` | 课表显示与配置入口；包含 `TableConfigFragment`、`ToolsFragment`、`MainStyleFragment`、`IntroAppWidgetFragment` | 风格 key 和 Widget 配置是兼容面 |
| `SettingsActivity`、`AdvancedSettingsActivity` | 全局偏好、权限、提醒、厂商/高级开关 | 精确闹钟、通知、网络/反馈入口 |
| `TimeSettingsActivity`、`TimeSettingsFragment`、`TimeTableFragment` | 作息表和节次时间编辑；`selectedId` 记录选中作息 | 影响 CourseDetail 的时间展示和提醒 |
| `SchoolListActivity`、`ImportSettingFragment`、`SchoolInfoFragment` | 选择学校和导入方式 | Parser 选择由 `edu_type` 等偏好驱动 |
| `LoginWebActivity`、`LoginWebFragment`、`WebViewLoginFragment` | 学校登录、Cookie/JavaScript、HTML 取数 | 外部网络和账号会话，高风险；部分入口导出 |
| `FileImportFragment`、`ExcelImportFragment`、`HtmlImportFragment`、`CodeImportFragment` | WakeUp 文件、CSV/“Excel”、HTML、分享文本导入 | 当前实现可能绕过显式 Draft/Preview，待源码确认 |
| `ClockActivity` | 横屏时钟/课堂辅助 | 独立页面，读取 `clock_dark_mode` 等偏好 |
| `SudaLifeActivity`、`BathFragment`、`EmptyRoomFragment` | 苏大生活、浴室/空教室等附加功能 | 非核心课表；网络和学校服务依赖 |
| `ModifyScheduleToolActivity` | 维护/修正课表的工具入口 | 导出组件，操作应单独回归 |
| `WidgetStyleConfigActivity`、`WeekScheduleAppWidgetConfigActivity` | Widget 样式或周 Widget 配置 | AppWidget 系统契约，不宜与普通页面一起迁移 |
| `AboutActivity`、`DonateActivity`、`IntroYoungActivity` | 关于、捐赠、引导 | 功能外围；厂商/支付链接待源码确认 |

## 4. Room 数据库

### 4.1 数据表

Room 生成实现的实体列表确认包含六张应用表：

| Entity | 主要字段 | 主键/关系 |
| --- | --- | --- |
| `CourseBaseBean` | `id:Int`、`courseName:String`、`color:String`、`tableId:Int`、`note:String`、`credit:Float` | `id` 主键；`tableId` 有索引。保存课程本体 |
| `CourseDetailBean` | `id`、`day`、`room?`、`teacher?`、`startNode`、`step`、`startWeek`、`endWeek`、`type`、`tableId`、`level`、`ownTime`、`startTime`、`endTime` | 静态 SQL 显示复合主键包含 `day,startNode,startWeek,type,tableId,id,ownTime,startTime`；`(id,tableId)` 外键指向 CourseBase，级联删除 |
| `TimeTableBean` | `id`、`name` | 作息表主表；被 `TableBean`、`TimeDetailBean` 引用 |
| `TimeDetailBean` | `node`、`startTime`、`endTime`、`timeTable` | 复合主键 `(node,timeTable)`；作息表外键级联 |
| `TableBean` | `id`、`timeTable`、`type` | `id` 自增主键；`timeTable` 外键指向 TimeTable，删除策略为 `SET DEFAULT`；有 `timeTable` 索引 |
| `AppWidgetBean` | `id`、`baseType`、`detailType`、`info` | Widget 运行/配置元数据；确切语义需源码确认 |

课程详情的 `startWeek/endWeek` 和 `type` 是旧模型的周次/单双周表达，不能在没有迁移设计和样本数据前替换。当前模型的字段、主键、索引和外键是兼容边界，不是 Weeko 新领域模型。

### 4.2 数据库构建

`AppDatabase` 以静态单例持有数据库实例，DAO 包括课程、作息表、课表和节次时间访问。常规数据库名为 `wakeup`；在特定 API/配置下，构建器使用 `<dataDir>/databases/db/wakeup`。生成 schema 已确认 version 11，迁移注册链为 7→8→9→10→11，完整 SQL 见 `EVIDENCE_MATRIX.md`；事务注解和真实数据库回放仍需源码/样本确认。任何实体重命名、外键删除策略或路径改变，都必须先做真实数据库迁移测试。

## 5. SharedPreferences

偏好通过一个集中工具调用 `Context.getSharedPreferences(name, 0)`。主要文件和用途如下；列表是静态分析得到的关键键，不宣称穷尽所有动态键。

| 文件/命名规则 | 关键键或用途 |
| --- | --- |
| `config` | 引导/版本：`has_intro`、`last_version_code` 等；主题：`dynamic_colors`、`day_night_theme`、`dark_mode_cover`、`language_setting`；课表入口：`show_table_id`、`schedule_blank_area`、`schedule_pre_load`、`show_empty_view`、`empty_view_image`；提醒：`course_reminder`、`reminder_min`、`course_end_reminder`、`silence_reminder`、`silence_mode`、`reminder_on_going`；导入：`import_school`、`edu_type`；时钟/显示：`clock_dark_mode`、`screen_aod`、`prevent_burn`、`show_timetable_error`；初始化/服务开关：`isInitTimeTable`、`open_times`、`suda_life`、`show_donate` 等 |
| `multi_language` | `language_type` |
| `table{ID}_config` | `tableName`、`nodes`、`background`、`startDate`、`maxWeek`、`order`、`sundayFirst`；并承载 `ScheduleStyleConfig` 的课程文字、网格、透明度、圆角、周末、地点/教师/时间显示等 key |
| `time{ID}_config` | `breakLen`、`courseLen`、`sameBreakLen`、`sameCourseLen` |
| `widget{ID}_config` | `appwidget_bg_pic`、`appwidget_bg_color`、`appwidget_bg`、`showButton`、`showColor`、`showDate`、`showHeaderArea`、`tableId` |
| 旧兼容配置（名称由旧工具类传入） | `s_color`、`s_show_sat`、`s_show_time_detail`、`s_show_weekend`、`s_show`、`s_stroke`、`s_sunday_first`、`s_widget_color`、`classNum`、`item_height`、`sb_alpha`、`sb_text_size`、`sb_weeks`、`sb_widget_alpha`、`sb_widget_text_size`、`widget_item_height`、`pic_uri` 等，疑似迁移/旧版本兼容键 |
| 颜色选择器配置 | `show_alpha`、`hue`、`sat`、`val`、`alpha` |
| 其他运行键 | `TimeTableFragment` 使用 `selectedId`；Widget 运行时使用 `appWidgetMinWidth`、`isMiuiWidgetSupported`、`s_colorful_day_widget` |

偏好默认值、写入时序和清理策略尚未有源码证据。迁移时必须保留未知键，不能把它们直接当作可删除缓存。

## 6. Widget、Provider、通知与 Alarm

### 6.1 Widget

Manifest 中的 WakeUp Widget 接收器包括 `ScheduleAppWidget`、`TodayCourseAppWidget`、`TodayListAppWidget`、`TodayAndNextDayAppWidget`、`TodayListAppWidgetMIUI`、`TodayModernAppWidgetMIUI`。RemoteViews 服务包括 `ScheduleAppWidgetService`、`TodayColorfulService`、`TodayModernService`。不同 Widget 的更新周期在 XML 元数据中约为 30 分钟、2 小时或 3 小时，实际更新还受日期/时间 Receiver 和手动刷新影响。MIUI 组件可能在 `:widgetProvider` 进程中运行。

Widget 直接读取当前表、当前教学周、`table{ID}_config`、课程/作息 DAO，并依据 `show_table_id`、`course_reminder` 等全局键构造 RemoteViews。Widget 组件名称、action、RemoteViews service、PendingIntent 和 `AppWidgetBean` 不能在迁移阶段随意更改，否则桌面上已有实例可能失效。

### 6.2 ContentProvider

`ScheduleContentProvider` 的 authority 为 `com.suda.yzune.wakeupschedule.provider`，并对调用方包名做允许列表检查。静态路径包括：

- `show_table_id`
- `table_config/#`
- `course_list/#`
- `table_list`
- `refresh`
- `scrollable`
- `has_init`
- `next_course_list/#`
- `course_list`
- `next_course_list`
- `vivo_intent_entity`

这是外部契约，不应仅依据当前 UI 是否使用而删除。具体列名、Cursor schema、写入权限和允许包列表需要源码/运行时测试确认。

### 6.3 通知与 Alarm

`App.onCreate` 在 API 26 及以上创建 `schedule_reminder`（课程提醒，重要性 4）和 `news`（公告，重要性 2）通知渠道。`TodayCourseAppWidget` 在启用 `course_reminder` 时为每节课程设置一个提醒：API 23 以上使用 `setExactAndAllowWhileIdle`，更低版本使用 `setExact`；API 31 以上检查 `canScheduleExactAlarms`，没有权限时可能关闭课程提醒。提醒 action 为 `WAKEUP_REMIND_COURSE`，取消 action 为 `WAKEUP_CANCEL_REMINDER`，通知 id 使用课程索引。

Manifest 还请求 `SCHEDULE_EXACT_ALARM`、`POST_NOTIFICATIONS`、`VIBRATE`、`WAKE_LOCK`、`ACCESS_NOTIFICATION_POLICY` 和电池优化相关权限。提醒的 PendingIntent 字段、通知 id、channel id、取消广播和开机/时间变化重排都属于高风险兼容面。

### 6.4 WorkManager

AndroidX Startup 自动初始化 WorkManager；Manifest 包含 WorkManager 的系统服务/Receiver。WakeUp 自有 Worker 主要是 `HonorSuggestionWorker` 和 `VivoSuggestionWorker`（CoroutineWorker），由工具类按 Honor/Vivo/iQOO 能力、引导状态和 API 条件安排，工作名可确认包含 `honor_feedback`，Vivo 任务的唯一名在反编译中未可靠恢复。当前证据不支持“WorkManager 负责课程提醒”的说法；课程提醒由 AlarmManager 完成。

## 7. 导入、导出与教务 Parser

### 7.1 导入入口

导入页面由 `SchoolListActivity`、`ImportSettingFragment`、`FileImportFragment`、`ExcelImportFragment`、`HtmlImportFragment`、`CodeImportFragment` 等组成，共享 activity-scoped `ImportViewModel`（JADX 名称 `OooOo00`）。ViewModel 构造时持有课表、课程、作息表和节次 DAO，并根据 `edu_type`/学校类型选择 Parser。

已确认的入口行为：

- WakeUp 文件入口检查 URI 路径包含 `wakeup_schedule`，读取内容后进入写库方法。
- 名为 `importFromExcel` 的方法静态检查的是 `csv` 路径；界面使用 `text/*` 选择文件。方法名与格式不一致，必须用真实源码和样本文件确认。
- WebView/HTML/分享文本入口经过学校选择、Cookie/JavaScript 或 Parser，再转换为内部 Course 列表。
- 当前反编译路径表现为解析后直接得到 base/detail 列表并写 DAO；没有足够证据证明存在统一的 Draft、预览和单事务确认边界。Weeko 需要把这视为待修复的架构差异，而不是照搬行为。

### 7.2 Parser 与统一中间模型

`ParserProxy`（JADX 类 `schedule_import.o00Oo0`）包装 Parser 接口，读取 `TimeTable`、课程和可选元数据，合并连续节次，分配课程 id/颜色，并转换为 `CourseBaseBean` 与 `CourseDetailBean`。Parser 基础模型包含：

- `Course(name, day, room, teacher, startNode, endNode, startWeek, endWeek, type, credit, note, startTime, endTime)`；
- `TimeTable(name, timeList)`；
- `TimeDetail(node, startTime, endTime)`；
- `WeekBean(start, end, type)`。

学校/服务适配器分布在 `schedule_import.login_school` 和 `schedule_parser`，可识别的实现包括 AHSTU、HUST MobileHub、JLU UIMS、JXAU、NAU、NWPU、SUSTech、SudaXK、HFU、JJVU 等。登录页面会调用学校专用方法，如 `getAHSTUSchedule`、`getSUSTechSchedule`、`getSudaSchedule`、`getNWPUSchedule`；这些 Parser 对外部页面、Cookie 和接口格式高度敏感，属于高风险。

### 7.3 导出

`ScheduleActivity` 通过 Storage Access Framework 的 `ACTION_CREATE_DOCUMENT` 请求用户选择目标文件。WakeUp 兼容备份使用 `application/octet-stream`，默认文件名为 `<tableName>.wakeup_schedule`；ViewModel 用 Gson 序列化课程、课表和时间配置后写入 URI。ICS 使用 Biweekly 生成 iCalendar 2.0，产品标识静态出现为 `-//YZune//WakeUpSchedule//EN`，并结合课程时间和提醒分钟生成事件。CSV 类/包存在，但当前 APK 静态证据无法保证所有导出/导入方向都已完成。

导入/导出都必须以样本文件回归。不能因为 Weeko 内部模型更合理，就直接改变 WakeUp 兼容文件字段、周次语义、时间格式或 ICS UID/重复规则。

## 8. 网络层与外部服务

`schedule_parser` 中有懒初始化的 Ktor Client 及 suspend HTTP GET 帮助类；APK 同时嵌入 Retrofit、OkHttp/Okio、Gson，学校登录/适配器可能使用其中一部分。静态 URL 包含学校专用 HTTP/HTTPS 地址、`schedule-data.netlify.app`、`i.wakeup.fun` 和 `www.wakeup.fun` 等。Manifest 的 network security 配置允许明文流量。

由于没有运行时抓包和源代码，无法把某个 URL、库或调用归属到每一个学校 Parser，也无法判断服务当前是否可用。账号密码、WebView Cookie 和 Token 的存储位置同样不能从本次静态审计安全推断；这部分在 Weeko 重构中必须按最小权限和短生命周期重新审查。

## 9. 构建、资源与依赖迹象

APK 资源引用显示约 51 个应用布局 ID，页面以 XML/ViewBinding/DataBinding 为主，另有程序化列表/布局。APK `META-INF` 版本信息可见 AppCompat 1.7.0、Fragment 1.6.2、Lifecycle 2.9.0、Navigation 2.9.0、Room 2.7.1、WorkManager 2.10.1、Material Components 1.12.0、Coroutines 1.10.2、Core KTX 1.16.0、SQLite 2.5.0、ConstraintLayout 2.2.1 等；还包含 ThreeTen backport、Glide、Balloon、Biweekly、Huawei/荣耀/Vivo 集成。它们是打包产物证据，不是当前 Gradle 声明，不能直接复制为 Weeko 依赖清单。

JADX 导出资源中的九宫格和属性类型不能直接通过 AAPT2；apktool 资源还出现 `$` 文件名及 drawable/color 类型错写。`.wakeup-restoration/` 因此仍是候选工作区，不是可编译源码。公开 [`YZune/WakeUpSchedule`](https://github.com/YZune/WakeUpSchedule) 的 master 提交 `5d43928`（2018-04-07）仅代表 2.10/GreenDAO 历史结构，且未发现 LICENSE/COPYING/NOTICE；不作为 6.0.23 实现来源。

## 10. 需要源代码确认的事项

以下项目在当前 APK 证据下保持开放：确切 Gradle module/package、Room 当前版本和迁移 SQL、DAO 方法与事务注解、Preference 全量键及默认值、Parser 的完整学校映射和网络请求、WakeUp 文件 schema 版本、ICS 的 UID/重复规则、Provider Cursor 列和写权限、签名/发布配置、测试覆盖率，以及厂商组件运行条件。它们应作为下一阶段的验收清单，而不是通过猜测补全。

## 11. 当前 Weeko 代码边界（非权威实验）

本节所述 `app`、Weeko Room、课程详情/editor 和 `adapter/wakeup` 都是误建实验，不属于 WakeUp 还原母体；保留但冻结，不作为旧功能等价实现或还原依赖。

当前 Weeko 源工程不是上述旧架构的源码恢复。现有 `app` 保留负责显示基线文案的传统 View `MainActivity`，并新增不替换旧页面的 `DesignSystemPreviewActivity`（Compose `setContent`）和非生产 `CourseDetailPreviewActivity`；同时已有独立的 Weeko Room version 1、`RoomWeekoRepository`、`CourseDetailViewModel` 和真实数据 `CourseDetailRoute`，但尚未接入正式课程表导航。课程详情 Bottom Sheet 仍只渲染显式传入的 UiState，不访问 Room。`adapter:wakeup` 是唯一有行为测试的兼容功能区，阶段 2 本轮仅将其格式模型移动到 `WakeUpScheduleModels.kt`，解析器仍通过 `WakeUpScheduleDraft` 输出同样的数据，未改变解析和校验行为。

因此本文列出的旧类不能直接作为 Weeko 的重构对象。阶段 3 的设计系统、阶段 4A 的课程详情原型、阶段 4B 的真实数据 Route 和编辑已有课程页面都不读取 WakeUp 私有数据库，也不改变旧页面；它们只依赖 Weeko 自己的 Repository 接口。没有真实课程表调用方和添加课程契约前，不宣称完整课表功能已完成，也不继续拆分 APK 中无法编译的旧 Activity/Fragment/Repository/Manager。
