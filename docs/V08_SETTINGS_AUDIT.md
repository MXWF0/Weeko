# Weeko v0.8 设置与信息架构审计（Stage 0）

日期：2026-09-07  
范围：只读盘点 v0.6 候选包及 v0.7 补丁层中的设置入口、Activity、Fragment、Dialog、XML、Compose、SharedPreferences/DataStore、课表数据、时间表、小部件、提醒、导入导出、分享和关于页面。  
阶段结论：Stage 0 完成；本文件只记录事实、重复关系、迁移闸门和待确认问题，不启动 Stage 1，也不授权删除旧入口或旧键。

## 成功标准与方法

成功标准是：每一类可见设置都能定位到页面和实际控制对象，能区分全局、课表、时间表、小部件实例和 Room 数据；能指出重复入口、静态遗留键和无法由当前证据确认的语义；能给出后续信息架构迁移位置及删除前置条件。

本次审计采用只读检索和反编译交叉核对，材料包括：

- `.weeko-v0.6-apktool/` 中的 Manifest、资源、navigation XML、strings、smali/反编译结果；
- `.stage4a-jadx/` 中的 Java 源、Room 实体/DAO、SharedPreferences 包装类、Activity 和 Fragment；
- 当前 `app/src/main` 的 Kotlin/Compose 源码及现有文档，用来区分“旧运行时事实”和“当前重建实验”；
- 已有 v0.7 导航审计、数据模型和兼容性文档，用来核对入口名称、数据库和 Intent 边界。

“已确认”表示页面代码、资源和写入/启动链互相吻合；“推断”表示可由现有目标结构映射但尚未在新 UI 实机验收；“待确认”表示当前材料不足，不能据此合并或删除。旧 APK 的反编译名称可能经过 JADX 混淆还原，因此以资源 ID、SharedPreferences 键、Activity/DAO 调用链为主要证据。

## 入口拓扑

### 全局设置

`SettingsActivity` 是全局设置入口，动态组装 RecyclerView 列表，不是 AndroidX Preference XML。当前可见分组包括“常规”“后台运行”“其他/隐私”等。它可以进入 `ScheduleSettingsActivity`（当前课表/课表设置）、`AdvancedSettingsActivity`（高级功能），并直接读写 `config` 与 `multi_language`。

`AdvancedSettingsActivity` 继续以动态列表承载“外观”“课程提醒”“课程转移”等内容。启用课程提醒时会检查精确闹钟、通知权限和日课小部件，并触发小部件更新；这不是单纯的布尔值切换。

### 课表设置

`nav_schedule_settings.xml` 的起点是 `ScheduleSettingsFragment`（课表设置），目标页为：

| 资源/页面 | 当前语义 |
| --- | --- |
| `TableConfigFragment` | 课表数据：名称、上课时间、开学日期、当前周、一天课程节数、周数、课程管理 |
| `MainStyleFragment` | 课表外观：背景、网格、日期/时间栏、课程文字和卡片样式 |
| `IntroAppWidgetFragment` | 桌面小部件说明、添加、调整大小、样式和厂商限制提示 |
| `ToolsFragment` | 实用工具；当前反编译列表为空 |

`ScheduleSettingsFragment` 自身已经显示课表数据和一部分外观快捷项，因此与 `TableConfigFragment`、`MainStyleFragment` 形成复合页与子页并存。课表管理继续通过 `ScheduleManageActivity` 处理课表切换、复制、重命名、删除、排序及课程列表。

### 时间表

`nav_time_settings.xml` 从 `TimeTableFragment`（时间表列表）进入 `TimeSettingsFragment`（编辑时间表）。时间表名称、每节起止时间、统一课程时长/课间时长等设置写入时间表配置并与 Room 中的 `TimeTableBean`、`TimeDetailBean` 关联。删除、复制和保存都有菜单或确认对话框。页面提示明确指出：一天显示多少节课属于“课表数据”的“一天课程节数”，不是时间表编辑页的另一个设置。

### 小部件

`WidgetStyleConfigActivity`、`WeekScheduleAppWidgetConfigActivity` 及周课表/今日课表配置 Fragment 为每个 AppWidget 实例建立 `widget{id}_config`。它们复制大量 `ScheduleStyleConfig` 样式键，同时增加小部件专属的日期、按钮、背景和表头开关。小部件在 `tableId=0` 时会回退到全局 `config` 的 `show_table_id`；因此小部件配置不是一份可随意丢弃的临时 UI 状态。

### 导入、导出、分享与关于

导出菜单包含备份文件、iCal、在线分享和分享应用；导入菜单包含教务/网页、备份文件、CSV/Excel、HTML 和分享口令。导入流程由 `ImportSettingFragment`、`ImportViewModel`、`LoginWebActivity`、`SchoolListActivity`、`FileImportFragment`、`ExcelImportFragment`、`HtmlImportFragment` 和 `CodeImportFragment` 组成，既写 Room 课表/课程/时间表，也写学校和导入状态配置。

`AboutActivity`/补丁层 `WeekoAboutActivity` 承载版本、联系方式、致谢、应用分享、反馈、开源许可、隐私和用户协议。它不应与设置状态合并。分享应用与课表数据在线分享也必须保持不同语义。

## 存储边界

旧运行时使用 `utils/OooO0o` 对 `Context.getSharedPreferences(name, 0)` 的薄封装；检索不到 `DataStore`、`createDataStore` 或 `PreferenceDataStore`。因此本轮不能假定存在 DataStore 迁移链。当前 `app/src/main` 的 Compose 设计系统是重建实验，不代表旧设置已经迁移到 Compose。

| 存储层 | 已确认内容 | 迁移约束 |
| --- | --- | --- |
| `config` | 全局当前课表、主题/显示、更新、空白区域、空状态、后台运行、提醒、导航栏颜色、时钟兼容键等 | 保留未知键；不能把 per-table 或 per-widget 键写入这里 |
| `multi_language` | `language_type`；与 `config` 中的 `language_setting` 并存 | 先确认两者读取优先级，再决定统一入口 |
| `table{id}_config` | `TableConfig` 和 `ScheduleStyleConfig`：名称、节数、日期、周数、背景、网格、日期/时间栏、课程文字/描边/透明度/圆角等 | `id=-1` 是“将本课表配置设为默认”的特殊副本，不能按普通课表删除 |
| `time{id}_config` | `breakLen`、`courseLen`、`sameBreakLen`、`sameCourseLen` 等时间表配置 | 与 `TimeTableBean/TimeDetailBean` 的 Room 关系一起迁移 |
| `widget{id}_config` | `tableId`、`appwidget_bg_pic`、`appwidget_bg_color`、`appwidget_bg`、`showButton`、`showColor`、`showDate`、`showHeaderArea` 及复制的课表样式键 | 以 AppWidget 实例 ID 区分；需保留 `tableId=0` 的回退行为 |
| Room `wakeup` | `CourseBaseBean`、`CourseDetailBean`、`TimeTableBean`、`TimeDetailBean`、`TableBean`、`AppWidgetBean` 等 | 旧数据库名称、路径、版本、实体关系和 Intent extra 均属兼容边界 |

## 设置项审计表

下表的“实际控制对象”指代码最终影响的模型、页面、系统权限或小部件，而不是列表项本身。“是（子集）”表示两个页面写的是同一键或同一行为；“否（实例化）”表示虽然样式相似，但小部件有独立实例配置，不应简单去重。

### 课表数据、外观与小部件

| 当前设置项 | 所在页面 | 实际控制对象 | 数据存储位置 | 是否重复 | 建议迁移位置 | 风险 |
| --- | --- | --- | --- | --- | --- | --- |
| 当前课表选择 | 全局设置；课表管理；小部件回退 | `show_table_id` 及当前 `TableBean` | `config.show_table_id`；当前课表关联在 Room | 是（入口重复） | 左侧菜单“切换/管理课表”；右侧设置只保留说明 | 高：切换与管理若拆成两个入口，可能出现不同当前课表 |
| 课表名称 | `ScheduleSettingsFragment`、`TableConfigFragment`、课表管理 | `TableConfig.tableName` | `table{id}_config`；列表元数据在 Room | 是（页面重复） | 课表管理详情 → 课表数据 | 中：保存时必须保持同一 table id |
| 上课时间/时间表关联 | `ScheduleSettingsFragment`、`TableConfigFragment` | 当前课表的 `TimeTableBean` 关联和编辑入口 | Room 关联；`time{id}_config` | 是（页面重复） | 课表数据 → 时间表 | 高：误当成节数设置会改变既有课表时间 |
| 开学日期 | `ScheduleSettingsFragment`、`TableConfigFragment` | `TableConfig.startDate` 与周次计算 | `table{id}_config.startDate` | 是（页面重复） | 课表数据 | 高：日期变化会重算当前周和课程显示 |
| 当前周 | `ScheduleSettingsFragment`、主课表周次操作 | 当前周计算/显示 | 课表运行时状态（与 `TableConfig`/周次逻辑相关） | 是（入口重复） | 左侧菜单“调整周数/回到当前周” | 高：需区分手动当前周与按日期回到本周 |
| 一天课程节数（nodes） | `ScheduleSettingsFragment`、`TableConfigFragment` | `TableConfig.nodes` 和课程显示行数 | `table{id}_config.nodes` | 是（页面重复） | 课表数据 | 高：改变后需核对课程、时间表和导入数据边界 |
| 课表总周数 | `ScheduleSettingsFragment`、`TableConfigFragment` | `TableConfig.maxWeek` | `table{id}_config.maxWeek` | 是（页面重复） | 课表数据 | 中：导入或复制课表时需保留周数 |
| 课程管理 | `ScheduleSettingsFragment`、`ScheduleManageActivity` | `CourseManageFragment` 的课程增删改 | Room `CourseBase/Detail` DAO | 是（入口重复） | 左侧菜单“课表管理” → 课程列表 | 高：删除前须实机确认新增、编辑、当前课表上下文 |
| 周六/周日显示 | `ScheduleSettingsFragment` 快捷项、`MainStyleFragment`、周/今日小部件 | `showSat`、`showSun` | `table{id}_config`；小部件复制到 `widget{id}_config` | 是（子集） | 课表外观；小部件允许实例覆盖 | 中：全局课表值与实例覆盖可能不一致 |
| 其他周课程显示 | `ScheduleSettingsFragment`、`MainStyleFragment`、小部件 | `showOtherWeekCourse`、透明度 | `table{id}_config` / `widget{id}_config` | 是（子集） | 课表外观；小部件实例设置 | 中：透明度和可见开关不是同一语义 |
| 课表背景图片/颜色 | `MainStyleFragment`、周/今日小部件 | 课表背景与小部件背景绘制 | `table{id}_config.background`；`widget{id}_config.appwidget_bg*` | 是（语义相近、作用域不同） | 课表外观；小部件外观 | 高：不能把小部件背景覆盖到课表背景 |
| 网格、时间栏、表头 | `MainStyleFragment`、周/今日小部件 | `showGrid`、`showTime`、表头色/大小等绘制属性 | `table{id}_config` / `widget{id}_config` | 是（子集） | 课表外观；小部件实例外观 | 中：复制键时需保留 Compose/旧描边兼容键 |
| 课程文字、描边、透明度、圆角、字号 | `MainStyleFragment`、周/今日小部件 | `ScheduleStyleConfig` 绘制参数 | `table{id}_config` / `widget{id}_config` | 是（子集） | 课表外观；小部件实例外观 | 高：颜色、alpha、字号的默认值变更会整页重绘 |
| 课程居中、时间/地点/教师/@教室前缀 | `MainStyleFragment`、周/今日小部件 | 文本布局和课程详情拼接 | `table{id}_config` / `widget{id}_config` | 是（子集） | 课表外观；小部件实例外观 | 中：`schedule_location`、`schedule_teacher`、`showRoomPrefix` 不能合并成一个开关 |
| 将本课表配置设为默认 | `ScheduleSettingsFragment` | 复制 `TableConfig` 到默认配置 | `table-1_config`（代码语义为 id `-1`） | 否（特殊动作） | 课表数据菜单中的“设为默认” | 高：不能把 `-1` 当真实课表或在迁移时清理 |
| 添加/固定小部件 | 全局设置、`AdvancedSettingsActivity`、`IntroAppWidgetFragment` | 系统 pin/add AppWidget、实例配置入口 | `AppWidgetBean`、`widget{id}_config`、系统 AppWidget 状态 | 是（入口重复） | 左侧菜单或设置中的“小部件”单一入口，教程作为帮助 | 高：权限、厂商限制和实例状态不能只迁移视觉入口 |
| 小部件日期/按钮/表头/背景开关 | 周/今日小部件配置页 | `showDate`、`showButton`、`showHeaderArea`、`showBg`/`showColor` | `widget{id}_config` | 否（实例设置） | 小部件实例外观 | 中：今日和周课表的可见区域不同，不能强行共用布局 |

### 提醒、常规显示与系统设置

| 当前设置项 | 所在页面 | 实际控制对象 | 数据存储位置 | 是否重复 | 建议迁移位置 | 风险 |
| --- | --- | --- | --- | --- | --- | --- |
| 课程提醒总开关 | `AdvancedSettingsActivity` → 课程提醒 | Alarm/通知调度、所有小部件刷新 | `config.course_reminder`；系统精确闹钟/通知权限 | 否（但有前置条件） | 右侧设置 → 通知与提醒 | 高：开启会检查权限、日课小部件并更新 providers |
| 上课中提醒 | `AdvancedSettingsActivity` | `reminder_on_going` 调度策略 | `config.reminder_on_going` | 否 | 通知与提醒 | 中：与总开关联动，不能只迁移 UI 状态 |
| 提前提醒分钟数 | `AdvancedSettingsActivity` | `reminder_min` 的闹钟时间 | `config.reminder_min` | 否 | 通知与提醒 | 中：需保留旧数值和边界行为 |
| 静音模式/静音提醒 | `AdvancedSettingsActivity` 对话框 | `silence_mode`、`silence_reminder` 的时段/策略 | `config.silence_mode`、`config.silence_reminder` | 否（同一组） | 通知与提醒 → 静音时段 | 高：静音策略可能影响已有 Alarm，迁移前须验证取消/重排 |
| 下课提醒 | 旧 handler/字符串，当前列表未确认显示 | `course_end_reminder` | `config.course_end_reminder` | 是（幽灵键） | 通知与提醒的独立子项，确认可见性后再决定保留 | 高：未知旧用户仍可能依赖该键；不可因无列表行而删除 |
| 下课前分钟数 | 旧 handler/字符串，当前列表未确认显示 | `reminder_end_before` | `config.reminder_end_before` | 是（幽灵键） | 与下课提醒同组 | 高：必须先确认调度代码是否仍读取 |
| 精确闹钟权限 | 课程提醒页 | Android `SCHEDULE_EXACT_ALARM` 状态 | 系统权限，不是业务偏好 | 否 | 通知与提醒的权限说明 | 高：不能把权限状态写回偏好并假设已授权 |
| 通知权限/通知样式 | 课程提醒页 | `POST_NOTIFICATIONS` 与系统通知设置 | 系统权限/系统设置 | 否 | 通知与提醒 → 系统权限 | 高：返回后需重新读取系统状态 |
| 后台自启动、电池优化 | 全局设置“后台运行” | 系统自启动页、忽略电池优化、唤醒能力 | 系统设置；`config` 仅保存兼容项 | 是（多个入口） | 设置 → 后台运行 | 高：厂商页面不可保证统一 Intent，需按设备实测 |
| 自动更新 | 全局设置 | `s_update` 的更新任务 | `config.s_update` | 否 | 设置 → 数据/更新 | 中：不要与课表刷新或小部件刷新混为一项 |
| 课表空白区域 | 全局设置 | `schedule_blank_area` 的布局间距/触摸区域 | `config.schedule_blank_area` | 否 | 设置 → 课表显示 | 中：改变可点击空白区会影响课程编辑发现性 |
| 空状态视图 | 全局设置 | `show_empty_view`、自定义空状态图片 | `config.show_empty_view`、`config.empty_view_image` | 是（同一行为的两个控件） | 设置 → 课表显示 | 中：长按重置图片的行为需保留 |
| 课表错误提示 | 全局设置 | `show_timetable_error` 的错误提示显示 | `config.show_timetable_error` | 否 | 设置 → 课表显示 | 低：隐藏错误会降低可诊断性 |
| Suda Life | 全局设置 | `suda_life` 入口/服务显示 | `config.suda_life` | 否（入口待定） | 设置 → 实验/扩展功能 | 中：需确认服务是否仍在目标版本范围 |
| 语言 | 全局设置语言项 | 文案语言和语言类型 | `config.language_setting`、`multi_language.language_type` | 是（双键） | 设置 → 语言 | 高：先确认读取优先级、迁移方向和重启/重建 Activity 行为 |
| 日夜/显示模式 | 全局设置显示模式 | Day/Night 主题策略 | `config.day_night_theme` | 否 | 设置 → 外观/主题 | 高：不能与系统深色模式或时钟深色模式混写 |
| 动态颜色 | `AdvancedSettingsActivity` 外观 | Material 动态取色 | `config.dynamic_colors` | 否 | 设置 → 外观/主题 | 中：需明确 Android 版本和无动态色设备的表现 |
| 导航栏颜色 | 高级外观/旧兼容处理 | 系统导航栏及覆盖色 | `config.nav_bar_color` | 否 | 设置 → 外观/主题 → 系统栏 | 中：与 `dark_mode_cover` 等旧兼容键存在潜在交互 |
| 清除 WebView 缓存 | 全局设置 | WebView 缓存删除一次性动作 | WebView 系统缓存；无业务偏好 | 否（动作） | 设置 → 隐私/数据 | 中：不能误做成长期“开关” |
| 隐私、用户协议 | 全局设置/关于 | 打开静态或 Web 页面 | 资源/URL，不是业务偏好 | 是（入口重复） | 右侧菜单“关于”或设置中的法律信息 | 低：链接和返回栈需分别验收 |

### 时间表、时钟与兼容键

| 当前设置项 | 所在页面 | 实际控制对象 | 数据存储位置 | 是否重复 | 建议迁移位置 | 风险 |
| --- | --- | --- | --- | --- | --- | --- |
| 时间表名称 | `TimeTableFragment`、`TimeSettingsFragment` | `TimeTableBean` 名称 | Room；关联 `time{id}_config` | 是（列表/编辑页） | 课表数据 → 时间表 | 中：复制和重命名需区分 |
| 每节起止时间 | `TimeSettingsFragment` | `TimeDetailBean` 各节起止时间 | Room 时间明细；`time{id}_config` 时长参数 | 否（编辑页内多行） | 时间表编辑 | 高：最多可配置约 60 节，不能因 UI 收缩丢行 |
| 统一课程/课间时长 | `TimeSettingsFragment` | `sameCourseLen`、`courseLen`、`sameBreakLen`、`breakLen` | `time{id}_config` | 否 | 时间表编辑 | 高：统一时长与逐节起止时间互相影响 |
| 时间表复制/删除 | `TimeTableFragment` 菜单 | Room 记录及对应偏好 | Room + `time{id}_config` | 否（动作） | 时间表列表菜单 | 高：删除前须确认课表关联与取消策略 |
| 时钟深色模式 | `ClockActivity`/时钟相关入口；具体设置页待定位 | 时钟显示配色 | `config.clock_dark_mode` | 待确认 | 独立时钟设置 | 中：不能假定属于课表主题 |
| AOD/防烧屏 | `ClockActivity`/时钟相关入口；具体设置页待定位 | `screen_aod`、`prevent_burn` 显示策略 | `config.screen_aod`、`config.prevent_burn` | 待确认 | 独立时钟设置 → 显示/设备 | 高：涉及屏幕常亮和硬件功耗，必须保留系统行为 |
| 旧颜色、初始化和兼容键 | 多个旧页面/处理器 | 旧版本读取、升级和颜色选择器兼容 | `config` 中 `s_color` 等旧键、`isInitTimeTable`、`open_times` 等 | 是（静态遗留） | 迁移层内部保留，不直接暴露 | 高：当前未读不等于可删除；需先做全局读取审计 |

### 导入、导出、分享与关于

| 当前设置项 | 所在页面 | 实际控制对象 | 数据存储位置 | 是否重复 | 建议迁移位置 | 风险 |
| --- | --- | --- | --- | --- | --- | --- |
| 备份导出 | 主课表分享/导出菜单 | SAF 输出 `.wakeup_schedule`，内容含课表/课程/时间表和必要配置 | 文件；Room 数据序列化；导出格式兼容 | 否（动作） | 右侧菜单 → 分享/备份 | 高：扩展名、MIME 和字段格式不能改 |
| iCal 导出 | 主课表分享/导出菜单 | 生成日历文件 | 文件/分享 Intent | 否 | 右侧菜单 → 分享/导出 | 中：时区、周次和课程时间需回归验证 |
| 在线分享 | 主课表分享/导出菜单 | 远端分享链路/分享口令 | 网络服务及口令；本地可能写临时状态 | 否 | 右侧菜单 → 分享 | 高：不得与“分享应用”共用文案或数据入口 |
| 分享应用 | 主课表分享菜单、关于页 | 系统分享应用链接/包信息 | Intent/静态资源 | 是（入口重复） | 右侧菜单 → 关于/分享应用 | 低：保留一个可发现入口即可 |
| 教务/网页导入 | 主课表导入菜单、`LoginWebActivity`、`SchoolListActivity` | 登录、学校选择、课程解析和 Room 写入 | Room；`config` 的学校/登录/导入状态键 | 是（多级入口） | 左侧课表管理 → 导入 → 教务 | 高：登录 WebView、学校 URL 和 Cookie 状态不能丢 |
| 备份文件导入 | 导入菜单、`FileImportFragment` | 读取旧备份并恢复课表/课程/时间表 | 文件 + Room + 必要 `config` | 否（动作） | 左侧课表管理 → 导入 → 备份 | 高：必须维持旧 `.wakeup_schedule` 解析兼容 |
| CSV/Excel 导入 | `ExcelImportFragment` | 表格解析、课程和时间映射 | Room；临时文件/解析配置 | 否 | 左侧课表管理 → 导入 → CSV/Excel | 高：列映射错误会产生静默错课，需保留错误提示 |
| HTML 导入 | `HtmlImportFragment` | HTML 课程表解析 | Room；网页/文件输入 | 否 | 左侧课表管理 → 导入 → HTML | 中：不同学校模板不可由通用设置替代 |
| 分享口令导入 | `CodeImportFragment` | 解析分享口令并创建/合并课表 | Room；网络响应和导入状态 | 否 | 左侧课表管理 → 导入 → 分享口令 | 高：合并/覆盖策略必须保持原语义 |
| 版本、联系方式、致谢、反馈、许可、隐私 | `AboutActivity`/`WeekoAboutActivity` | 静态信息、系统邮件/链接/法律页面 | 资源、URL、Intent | 是（关于与全局设置部分重复） | 右侧菜单 → 关于 | 低：不应迁入业务设置存储 |

## Dialog、XML 与 Compose 盘点

### XML 与动态列表

- `nav_schedule_settings.xml`、`nav_time_settings.xml` 定义导航关系；`activity_settings_host.xml` 和 `activity_time_settings.xml` 只是动态 NavHost 容器。
- 旧设置页主体由动态 RecyclerView/list item 和 `R.string` 文案组装，未发现 `PreferenceScreen` 或同等“每个设置一份 XML”的结构。
- 相关 XML 包含 `dialog_edit_text.xml`、`dialog_slider.xml`、`dialog_with_checkbox.xml`、`fragment_color_picker.xml`、`fragment_base_dialog`，以及 Activity/Fragment 宿主和菜单资源。XML 负责承载通用对话框和导航，不等于设置数据模型。

### Dialog 与菜单

已确认或可由调用链定位的交互包括：课表名称、时间表名称、开学日期、语言、显示模式、颜色选择器、滑块（字号/透明度/圆角）、小部件课表选择/样式/颜色、保存/退出确认、课表/时间表删除确认、复制、导入教程/确认/错误和课程删除/修改。Material 3 的选择、Alert、TimePicker 与旧通用 Dialog 并存；迁移时应先保留动作语义，再统一视觉。

### Compose

当前 `app/src/main` 的 Compose 代码主要是 `WeekoTheme.kt`、`WeekoComponents.kt` 及预览/Gallery、`DesignSystemPreviewActivity`、`CourseDetailPreviewActivity`。本次检索没有发现设置页面或设置持久化接入，也没有发现 DataStore。因此不能把 Compose 预览当作 v0.7 旧设置已实现的证据。后续若用 Compose 重建，必须从本审计的作用域和键映射接入，而不是另建一套平行偏好。

## 重复关系与迁移建议

1. **课表数据重复**：`ScheduleSettingsFragment` 已经展示名称、时间表、开学日期、当前周、节数、周数和课程管理；`TableConfigFragment` 再次展示同一组。建议保留一个“课表数据”详情页，入口只在课表管理/课表设置中明确出现。
2. **课表外观重复**：`ScheduleSettingsFragment` 的周末、其他周、卡片高度/圆角快捷项是 `MainStyleFragment` 的子集。建议快捷项改为摘要或深链，不再维护第二套写入逻辑。
3. **小部件样式相似但不等价**：小部件复制课表样式键，同时拥有实例级背景、日期、按钮和表头开关。建议使用“继承课表样式 + 实例覆盖”的明确模型，不能直接删除 `widget{id}_config`。
4. **背景字段作用域重复**：课表背景和小部件背景都叫背景，但绘制对象不同。建议在 UI 上分别命名“课表背景”和“小部件背景”，存储也继续分离。
5. **添加小部件入口重复**：全局设置、高级设置和教程页都能引导添加/固定小部件。建议设置页保留一个动作，教程页只承担说明；删除前必须实机验证 pin、手动添加、配置回访和厂商限制路径。
6. **提醒入口集中但副作用较多**：提醒项集中在高级设置，开启时还触及系统权限、日课小部件和 providers。后续应迁入通知与提醒组，并把权限状态、业务开关、调度结果分别显示。
7. **当前课表入口交叉**：全局设置、课表管理和小部件回退都涉及当前课表。建议左侧菜单负责切换/管理，右侧设置只保留“默认课表/显示”说明，避免两个页面都提供看似独立的当前课表选择。
8. **导入、导出、分享不可合并为一个“分享”开关**：备份/iCal/在线分享/分享应用的对象和格式不同；导入还会改写 Room 和学校状态。建议在导航层统一收纳，在动作层保持独立文案和确认。

## 迁移闸门与兼容要求

- 不改 `config`、`multi_language`、`table{id}_config`、`time{id}_config`、`widget{id}_config` 的文件名、键名、类型和默认语义；未知键先保留。
- 不改旧 Room 数据库 `wakeup` 的名称/路径、版本、实体关系、导入导出格式或已有 Activity Intent extra。当前重建实验中的 `weeko.db` 不能被当作旧库替代。
- 先建立“读取来源 → 规范值 → 写回来源”的单向映射，再合并页面；尤其是 `language_setting` 与 `multi_language.language_type`、课表全局值与小部件实例覆盖、`tableId=0` 回退、id `-1` 默认配置。
- 系统权限不是 SharedPreferences：精确闹钟、通知、后台自启动和电池优化都必须在返回页面后重新读取，不能只显示上次点击结果。
- 任何删除入口前，必须在目标导航中实机验证等价能力、返回栈、当前课表上下文、空状态/错误提示和小部件回访；本 Stage 0 不做删除。
- `course_end_reminder`、`reminder_end_before`、旧颜色/初始化/兼容键即使当前列表未显示，也不能在没有全量读取审计和升级测试前清理。
- 导入/导出和在线分享属于数据兼容边界，迁移设置页面不能顺便改变文件格式、分享口令或学校解析链路。

## 待确认问题

1. `config.language_setting` 与 `multi_language.language_type` 的真实读取优先级、写入时机和旧版本兼容策略是什么？
2. `course_end_reminder`、`reminder_end_before` 当前调度代码是否仍读取？当前列表缺失是有意隐藏还是反编译不完整？
3. 主课表背景、主题背景、导航栏颜色和小部件背景的默认值/覆盖优先级是否有用户可见差异？
4. `ClockActivity` 的时钟设置入口是否仍可从主导航到达，`clock_dark_mode`、`screen_aod`、`prevent_burn` 是否应属于 Weeko v0.8 范围？
5. `ScheduleSettingsFragment` 与 `TableConfigFragment` 的保存/返回栈是否完全相同，是否存在仅一页才写入的字段？
6. 小部件周视图和今日视图哪些字段必须独立，哪些字段可以安全地继承课表样式？
7. 目标左侧菜单中的“课表管理”和“切换/管理课表”如何定边界，导入应放在课表管理还是右侧分享/更多菜单？
8. 当前 Compose 重建是否会复用旧 XML 动态列表的文案和 accessibility 语义，还是另有 UI 规范；在未决定前不应并行实现两套设置页。
9. 备份、iCal、在线分享和分享应用在目标右侧菜单中的最终分组及返回栈是否已经由产品确认？

## Stage 0 结论

旧设置不是一个平面列表，而是全局偏好、每课表配置、时间表记录、小部件实例配置、系统权限和 Room 数据的组合。最明确的重复集中在课表数据、课表外观快捷项、添加小部件和当前课表入口；最需要兼容保护的是提醒副作用、幽灵提醒键、语言双键、`tableId=0`/`-1` 特殊语义以及导入导出格式。

本轮仅新增本审计文档，未修改源码、资源、APK、数据库、偏好键、Intent、业务逻辑或 UI；不应据此开始 Stage 1 以外的实现工作。下一阶段应先用本表确定规范信息架构和迁移映射，再逐项做可发现性与回归验收。
