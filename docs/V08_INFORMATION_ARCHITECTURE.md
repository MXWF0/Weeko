# Weeko v0.8 信息架构（Stage 1）

日期：2026-09-09

依据：`V08_SETTINGS_AUDIT.md`、WakeUp 6.0.23 反编译代码、现有 v0.7 导航与补丁链。

阶段结论：本文件只确定入口、分类、功能归属和兼容映射；不修改页面、功能、存储、数据库或补丁链。

## 目标与成功标准

v0.8 将原先混合在“全局设置”“课表设置”“高级功能”和课表管理页面中的功能，整理为三个有明确作用域的区域：课表数据、当前课表外观、Weeko 全局设置。

Stage 1 的成功标准是：

1. 用户能从主课程表理解每个入口会修改什么。
2. 每项现有功能都有唯一的规范归属，页面快捷入口不再被误认为第二份配置。
3. 每项迁移都能追溯到原页面、原调用逻辑与原存储位置。
4. 关于和分享保持独立操作；导入属于课表数据操作，不混入全局设置。
5. 后续阶段只移动入口和复用原逻辑，不建立第二套设置或存储系统。

## 用户从哪里进入

Weeko 的用户入口仍是 WakeUp 母体中的主课程表 `ScheduleActivity`。`app/` 下的 Compose 工程是实验性重建，不是 v0.8 的运行入口，也不参与本阶段架构。

主课程表的规范入口分为三组：

| 主入口 | 面向用户的含义 | 进入后的范围 |
| --- | --- | --- |
| 左侧菜单 | 当前正在使用课表时的高频操作 | 调整周数、回到当前周、切换课表；“管理课表”只作为前往完整管理页的链接 |
| 右侧菜单 → 课表管理 | 修改当前课表及课表集合 | 课表信息、课程管理、作息时间、多课表管理、课表外观，以及新建/导入等课表数据动作 |
| 右侧菜单 → 设置 | 修改整个 Weeko 的行为 | 外观与主题、课程表显示、通知与提醒、桌面小组件、后台运行、语言、数据与隐私、高级设置 |
| 右侧菜单 → 分享 | 对当前课表或应用执行分享/导出 | 备份导出、iCal、在线分享、分享应用；它不是设置分类 |
| 右侧菜单 → 关于 | 查看应用信息与支持入口 | 版本、联系方式、致谢、反馈、开源许可等；它不是设置分类 |

2026-09-09 实机上的 v0.7 基线入口为：左侧“修改当前周 / 切换/管理课表 / 调整上课时间”，右侧“课表管理 / 分享 / 设置 / 关于 Weeko”。规范架构会把“调整上课时间”归入“课表管理 → 作息时间”，并把左侧“切换/管理课表”收窄为高频切换；这些是 Stage 2–4 的迁移目标，本阶段不改变实机菜单。

### 左侧“切换课表”和右侧“课表管理”的边界

左侧入口最终应命名为“切换课表”，只做当前课表选择，保留一个“管理课表”链接。右侧“课表管理”是完整管理中心，负责编辑数据、管理课程、作息和多个课表。这样用户可以快速切换，又不会看到两个含义相同的“管理”入口。

在 Stage 4 完成等价验证前，旧快捷入口可以暂时保留；本文件定义的是规范入口，不授权现在删除旧入口。

## 规范信息架构

```text
主课程表 ScheduleActivity
├─ 左侧菜单：课表操作
│  ├─ 调整周数
│  ├─ 回到当前周（仅需要时显示）
│  └─ 切换课表
│     └─ 管理课表 → 右侧菜单 / 课表管理 / 多课表管理
└─ 右侧菜单
   ├─ 课表管理
   │  ├─ 课表信息
   │  ├─ 课程管理
   │  ├─ 作息时间
   │  ├─ 多课表管理
   │  ├─ 课表外观
   │  └─ 课表数据动作：新建、导入、设为默认
   ├─ 分享（独立操作）
   ├─ 设置
   │  ├─ 外观与主题
   │  ├─ 课程表显示
   │  ├─ 通知与提醒
   │  ├─ 桌面小组件
   │  ├─ 后台运行
   │  ├─ 语言
   │  ├─ 数据与隐私
   │  └─ 高级设置
   └─ 关于（独立页面）
```

### 课表管理

| 分类 | 用户理解 | 收纳内容 | 继续使用的原实现 |
| --- | --- | --- | --- |
| 课表信息 | “这张课表本身是什么” | 名称、开学日期、当前周、总周数、每日节数、关联作息；“设为默认”是页面动作 | `ScheduleSettingsActivity` 宿主、`TableConfigFragment`、原 `TableConfig` |
| 课程管理 | “这张课表里有哪些课” | 课程列表、新增、编辑、删除课程 | `ScheduleManageActivity` 的 `courseManageFragment`、`AddCourseActivity`、原 DAO |
| 作息时间 | “每节课几点开始和结束” | 作息表选择、名称、逐节时间、统一课程/课间时长、复制与删除作息表 | `TimeSettingsActivity`、`TimeTableFragment`、`TimeSettingsFragment` |
| 多课表管理 | “管理所有课表” | 切换、新建、复制、重命名、删除、排序 | `ScheduleManageActivity` 的课表管理导航与原 DAO |
| 课表外观 | “只改变当前课表的样子” | 背景、周末、其他周课程、网格、日期/时间栏、课程文字、卡片、字号、透明度、圆角 | `MainStyleFragment`、原 `ScheduleStyleConfig` |

“导入课表”是课表数据动作，可放在课表管理首页的操作区或菜单中，不新增第六个设置分类。教务、备份文件、CSV/Excel、HTML、分享口令仍是彼此独立的导入分支。

### Weeko 设置

| 分类 | 用户理解 | 收纳内容 | 明确不属于这里的内容 |
| --- | --- | --- | --- |
| 外观与主题 | “整个 Weeko 的显示模式” | 日夜模式、动态颜色、系统栏颜色 | 当前课表背景、课程卡片样式、小部件实例背景 |
| 课程表显示 | “所有课表页面的通用显示行为” | 底部空白区域、空状态及图片、课表错误提示 | 当前课表的周末、网格、字号等外观 |
| 通知与提醒 | “课程通知及其系统条件” | 总开关、上课中提醒、提前分钟数、静音策略、通知样式、精确闹钟/通知权限；隐藏的下课提醒键只保留兼容 | 普通显示开关、小部件外观 |
| 桌面小组件 | “添加和管理桌面组件” | 添加/固定说明、现有实例入口、实例配置说明 | 把 `widget{id}_config` 合并进当前课表外观 |
| 后台运行 | “让提醒和组件稳定工作” | 自启动、电池优化、厂商后台设置 | 用一个偏好值伪造系统授权状态 |
| 语言 | “Weeko 使用什么语言” | 跟随系统、中文、English | 拆分为两个用户可见设置 |
| 数据与隐私 | “本地缓存和法律信息” | 清除 WebView 缓存、隐私政策、用户协议 | 课表导入、课表备份、在线分享 |
| 高级设置 | “低频或实验性能力” | 按日期转移课程、Suda Life/扩展入口、自动检查更新；时钟/AOD 项仅在确认仍可达后收纳 | 仅因旧页面名叫“高级功能”就整体照搬旧分类 |

桌面小组件在全局设置中只有统一入口，但每个实例仍通过系统添加流程进入原配置页面。小组件样式和当前课表外观相似，不代表两者是同一作用域。

### 独立操作与页面

| 入口 | 保持独立的原因 | 包含内容 |
| --- | --- | --- |
| 分享 | 它执行导出、网络分享或系统 Intent，不是长期设置 | 备份导出、iCal 导出、在线分享、分享应用 |
| 关于 | 它提供产品身份和支持信息，不控制业务状态 | 版本、检查更新、联系方式、致谢、反馈、开源许可；法律信息以“数据与隐私”为规范入口，可从关于页链接过去 |

“分享应用”与“在线分享课表”必须使用不同文案。前者分享应用链接，后者处理课表数据和分享口令。

## 三类作用域的判断规则

| 作用域 | 判断问题 | 典型存储 | 示例 |
| --- | --- | --- | --- |
| 课表数据 | 切换课表后，这项内容是否随课表改变，并决定课程或时间数据？ | Room `wakeup`、`table{id}_config`、`time{id}_config` | 名称、开学日期、周数、每日节数、课程、作息、多课表、导入 |
| 当前课表外观 | 切换课表后，这项显示样式是否可以不同？ | `table{id}_config` 中的 `ScheduleStyleConfig` 字段 | 背景、周末、网格、表头、文字、透明度、圆角 |
| Weeko 全局设置 | 这项选择是否应影响整个应用，而不是一张课表？ | `config`、`multi_language`、真实系统设置 | 主题、通用显示、提醒、后台运行、语言、隐私 |

补充规则：`widget{id}_config` 是第四种实例级作用域。它可以读取或复制课表样式，但必须继续按 AppWidget ID 独立保存。系统权限是第五种外部状态，页面恢复时必须重新读取真实状态。

## 旧入口到新入口映射

下表中的“原调用逻辑”表示后续应直接复用的业务入口或对象，不要求 Stage 1 改名内部类。名称映射只影响用户可见的信息架构。

### 课表数据与当前课表外观

| 旧入口/设置项 | 新入口 | 原调用逻辑 | 原存储位置 |
| --- | --- | --- | --- |
| 日期区“修改当前周” | 左侧菜单 → 调整周数 | `ScheduleActivity` 原周次调整逻辑 | 原周次运行逻辑与当前课表上下文，不改算法 |
| 日期区“回到当前周” | 左侧菜单 → 回到当前周 | `ScheduleActivity` 原按日期恢复当前周逻辑 | 原周次运行逻辑，不新增键 |
| 全局设置“当前课表”、底部课表卡片 | 左侧菜单 → 切换课表 | 原 `show_table_id` 切换及 `TableBean` 查询 | `config.show_table_id` + Room `TableBean` |
| 底部“管理”/课表卡片管理 | 课表管理 → 多课表管理 | `ScheduleManageActivity` 原导航 | Room `TableBean`；相关 per-table 偏好保持原名 |
| 新建、复制、重命名、删除、排序课表 | 课表管理 → 多课表管理 | `ScheduleManageActivity` 原课表列表动作 | Room + `table{id}_config`；删除约束沿用原逻辑 |
| `ScheduleSettingsFragment` 的课表名称 | 课表管理 → 课表信息 → 名称 | 统一复用 `TableConfigFragment` 的名称编辑与保存逻辑 | `table{id}_config`；Room 列表元数据继续按原逻辑同步 |
| `TableConfigFragment` 的课表名称 | 课表管理 → 课表信息 → 名称 | `TableConfigFragment` 原编辑对话框 | `table{id}_config` |
| 两页中的开学日期 | 课表管理 → 课表信息 → 开学日期 | 原 Material DatePicker 与 `TableConfig` 写回 | `table{id}_config.startDate` |
| 两页中的当前周 | 课表管理 → 课表信息 → 当前周；高频入口仍在左侧 | 原 `TableConfig`/周次逻辑 | 原键与算法不变 |
| 两页中的一天课程节数 | 课表管理 → 课表信息 → 每日节数 | 原滑块及 `TableConfig.nodes` 写回 | `table{id}_config.nodes` |
| 两页中的课表总周数 | 课表管理 → 课表信息 → 总周数 | 原滑块及 `TableConfig.maxWeek` 写回 | `table{id}_config.maxWeek` |
| 两页中的上课时间/时间表 | 课表管理 → 作息时间 | `TimeSettingsActivity` → `TimeTableFragment` → `TimeSettingsFragment` | Room `TimeTableBean`/`TimeDetailBean` + `time{id}_config` |
| 左侧菜单“调整上课时间” | 课表管理 → 作息时间 | 继续进入原 `TimeSettingsActivity`，左侧快捷入口只在等价验证后移除 | Room `TimeTableBean`/`TimeDetailBean` + `time{id}_config` |
| 时间表名称 | 课表管理 → 作息时间 → 编辑作息 | 原时间表重命名/编辑逻辑 | Room + 对应 `time{id}_config` |
| 每节起止时间 | 课表管理 → 作息时间 → 编辑作息 | `TimeSettingsFragment` 原逐节编辑逻辑 | Room `TimeDetailBean` |
| 统一课程/课间时长 | 课表管理 → 作息时间 → 编辑作息 | `TimeSettingsFragment` 原联动逻辑 | `time{id}_config`: `sameCourseLen`、`courseLen`、`sameBreakLen`、`breakLen` |
| 时间表复制、删除 | 课表管理 → 作息时间 → 更多操作 | `TimeTableFragment` 原菜单与确认逻辑 | Room + `time{id}_config` |
| 两页中的课程管理、旧独立添加课程 | 课表管理 → 课程管理 | `ScheduleManageActivity(selectedTableId)` → `courseManageFragment` → `AddCourseActivity` | Room `CourseBaseBean`/`CourseDetailBean` |
| `ScheduleSettingsFragment` 的课表数据 | 课表管理 → 课表信息 | 改为规范入口/摘要，实际编辑统一进入 `TableConfigFragment` 原逻辑 | `table{id}_config` + Room，不复制状态 |
| `ScheduleSettingsFragment` 的外观快捷项 | 课表管理 → 课表外观 | 改为摘要/深链，实际编辑统一复用 `MainStyleFragment` | `table{id}_config` |
| 周六、周日显示 | 课表管理 → 课表外观 → 日期与范围 | `MainStyleFragment` 原开关 | `table{id}_config.showSat/showSun` |
| 其他周课程显示及透明度 | 课表管理 → 课表外观 → 课程显示 | `MainStyleFragment` 原开关/滑块 | `table{id}_config` 中原样式键 |
| 课表背景图片/颜色 | 课表管理 → 课表外观 → 课表背景 | `MainStyleFragment` 原选图/颜色逻辑 | `table{id}_config.background` 等原键 |
| 网格、日期栏、时间栏、表头 | 课表管理 → 课表外观 → 网格与栏位 | `MainStyleFragment` 原设置逻辑 | `table{id}_config` 中原 `ScheduleStyleConfig` 键 |
| 课程文字、地点/教师、前缀、居中 | 课表管理 → 课表外观 → 课程文字 | `MainStyleFragment` 原开关与文本绘制逻辑 | `table{id}_config` 中原键 |
| 卡片高度、字号、透明度、圆角、描边 | 课表管理 → 课表外观 → 课程卡片 | `MainStyleFragment` 原滑块/颜色逻辑 | `table{id}_config` 中原键及旧描边兼容键 |
| 将本课表配置设为默认 | 课表管理 → 课表信息 → 更多 → 设为默认 | `ScheduleSettingsFragment` 原复制动作 | `table-1_config`，id `-1` 特殊语义不变 |
| 教务/网页导入 | 课表管理 → 导入课表 → 教务系统 | 原 `LoginWebActivity`、`SchoolListActivity` 与导入 ViewModel | Room + 原学校、登录、导入状态键 |
| 备份文件导入 | 课表管理 → 导入课表 → 备份文件 | `FileImportFragment` 原解析/恢复逻辑 | 文件 + Room + 原必要配置 |
| CSV/Excel 导入 | 课表管理 → 导入课表 → CSV/Excel | `ExcelImportFragment` 原解析逻辑 | Room + 原临时解析状态 |
| HTML 导入 | 课表管理 → 导入课表 → HTML | `HtmlImportFragment` 原解析逻辑 | Room + 原网页/文件输入 |
| 分享口令导入 | 课表管理 → 导入课表 → 分享口令 | `CodeImportFragment` 原网络与写入逻辑 | Room + 原网络/导入状态 |

### Weeko 全局设置

| 旧入口/设置项 | 新入口 | 原调用逻辑 | 原存储位置 |
| --- | --- | --- | --- |
| 全局设置“显示模式” | 设置 → 外观与主题 → 显示模式 | `SettingsActivity` 原选项与重建/重启行为 | `config.day_night_theme` |
| 高级功能“动态颜色” | 设置 → 外观与主题 → 动态颜色 | `AdvancedSettingsActivity` 原版本判断与写回 | `config.dynamic_colors` |
| 高级外观“导航栏颜色” | 设置 → 外观与主题 → 系统栏 | 原颜色选择及 alpha 约束 | `config.nav_bar_color`，旧兼容键保留 |
| 全局设置“课表空白区域” | 设置 → 课程表显示 → 底部空白区域 | `SettingsActivity` 原开关 | `config.schedule_blank_area` |
| 全局设置“空状态视图” | 设置 → 课程表显示 → 空状态 | `SettingsActivity` 原开关 | `config.show_empty_view` |
| 高级功能“空状态图片” | 设置 → 课程表显示 → 空状态图片 | `AdvancedSettingsActivity` 原选图与长按恢复 | `config.empty_view_image` |
| 全局设置“课表错误提示” | 设置 → 课程表显示 → 错误提示 | `SettingsActivity` 原开关 | `config.show_timetable_error` |
| 课程提醒总开关 | 设置 → 通知与提醒 → 课程提醒 | `AdvancedSettingsActivity` 原权限检查、Alarm 条件、小部件检查及 providers 更新 | `config.course_reminder` + 真实系统权限/Alarm 状态 |
| 上课中提醒 | 设置 → 通知与提醒 → 上课中提醒 | `AdvancedSettingsActivity` 原写回及小部件刷新 | `config.reminder_on_going` |
| 提前提醒分钟数 | 设置 → 通知与提醒 → 提前时间 | 原 0–120 分钟滑块与调度逻辑 | `config.reminder_min` |
| 静音模式/静音提醒 | 设置 → 通知与提醒 → 静音策略 | 原对话框与提醒调度逻辑 | `config.silence_mode`、`config.silence_reminder` |
| 下课提醒/下课前分钟数（当前入口未确认） | 不新增可见入口；在通知与提醒兼容层保留 | 原调度代码确认前不迁移、不删除 | `config.course_end_reminder`、`config.reminder_end_before` |
| 精确闹钟权限 | 设置 → 通知与提醒 → 系统权限 | 原 `AlarmManager.canScheduleExactAlarms()` 与系统设置 Intent | 系统状态，不写成偏好 |
| 通知权限/通知样式 | 设置 → 通知与提醒 → 系统权限/通知样式 | 原运行时权限与系统通知设置 Intent | 系统状态/系统通知设置 |
| 全局、高级、教程中的添加小部件 | 设置 → 桌面小组件 → 添加小组件 | 原 pin/add AppWidget 调用；教程作为帮助内容 | 系统 AppWidget 状态 + Room `AppWidgetBean` |
| 周/今日小部件配置 | 设置 → 桌面小组件 → 对应实例；系统添加流程仍可直接进入 | `WidgetStyleConfigActivity`、`WeekScheduleAppWidgetConfigActivity` 及原配置 Fragment | `widget{id}_config`，按 AppWidget ID 独立 |
| 小部件选择课表 | 桌面小组件 → 实例 → 课表 | 原实例选择逻辑 | `widget{id}_config.tableId`；`tableId=0` 回退 `config.show_table_id` |
| 小部件背景、日期、按钮、表头、样式 | 桌面小组件 → 实例 → 外观与内容 | 原 Widget 配置页，不复用课表写回 | `widget{id}_config` 中原键 |
| 全局设置“后台自启动” | 设置 → 后台运行 → 自启动 | `SettingsActivity`/提醒页原厂商系统 Intent | 真实系统状态；原兼容项保留 |
| 忽略电池优化 | 设置 → 后台运行 → 电池优化 | 原 `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` Intent | 真实系统状态 |
| 全局设置“语言” | 设置 → 语言 | `SettingsActivity` 原语言选择与 Activity 重建行为 | `config.language_setting` + `multi_language.language_type` 双键原语义 |
| 清除 WebView 缓存 | 设置 → 数据与隐私 → 清除网页缓存 | `SettingsActivity` 原一次性清理动作 | WebView 系统缓存，无长期偏好 |
| 隐私政策、用户协议 | 设置 → 数据与隐私 | 原静态/Web 页面 Intent | 资源或 URL，无业务偏好 |
| 高级功能“按日期转移课程” | 设置 → 高级设置 → 按日期转移课程 | `AdvancedSettingsActivity` 原入口 | Room 原课程数据与原业务逻辑 |
| 全局设置“Suda Life” | 设置 → 高级设置 → 扩展功能 | `SettingsActivity` 原入口；服务可达性待后续验证 | `config.suda_life` |
| 全局设置“自动检查更新” | 设置 → 高级设置 → 自动检查更新 | `SettingsActivity` 原更新任务开关 | `config.s_update` |
| 时钟深色模式、AOD、防烧屏（入口待确认） | 设置 → 高级设置 → 时钟与常亮（仅确认可达后显示） | `ClockActivity` 原逻辑 | `config.clock_dark_mode`、`screen_aod`、`prevent_burn` |
| 旧颜色、初始化与兼容键 | 不提供用户入口 | 原读取/升级兼容路径 | `config` 中原键，禁止因未显示而清理 |

### 分享与关于

| 旧入口/设置项 | 新入口 | 原调用逻辑 | 原存储位置 |
| --- | --- | --- | --- |
| 顶部分享菜单“备份导出” | 右侧菜单 → 分享 → 导出备份 | 原 SAF `.wakeup_schedule` 序列化流程 | 文件 + Room/配置读取；格式不变 |
| iCal 导出 | 右侧菜单 → 分享 → 导出 iCal | 原日历生成与系统分享 Intent | 文件/Intent；时区和周次算法不变 |
| 在线分享 | 右侧菜单 → 分享 → 在线分享课表 | 原在线服务与口令链路 | 网络服务 + 原临时状态 |
| 分享应用 | 右侧菜单 → 分享 → 分享 Weeko | 原系统分享 Intent | 应用链接/包信息，无课表设置 |
| 底部“关于 Weeko” | 右侧菜单 → 关于 | `AboutActivity` / `WeekoAboutActivity` 桥接页 | 资源、URL、Intent |
| 版本、联系方式、致谢、反馈、开源许可 | 右侧菜单 → 关于 | 原 About 页面对应动作 | 资源、URL、Intent |
| 关于页中的隐私/协议 | 关于 → 数据与隐私（链接） | 继续打开原法律页面，规范入口归入设置 | 资源或 URL |

## 页面与调用链保留原则

Stage 2 和 Stage 3 可以调整列表、标题、导航目标和页面归属，但必须满足以下原则：

1. `ScheduleSettingsActivity` 可以继续作为课表管理相关页面的 NavHost；内部类名无需为了新标题重命名。
2. `TableConfigFragment` 是“课表信息”的规范编辑逻辑；`ScheduleSettingsFragment` 中重复项只能在等价验证后改为入口或摘要。
3. `ScheduleManageActivity` 同时具备课表集合和课程列表能力。传入 `selectedTableId` 时进入当前课表课程列表的行为必须保留。
4. `TimeSettingsActivity` 及 `nav_time_settings.xml` 的列表到编辑页关系保持不变，只调整从课表管理进入它的可见路径。
5. `SettingsActivity` 可以成为八个全局分类的统一入口；`AdvancedSettingsActivity` 的原处理逻辑可以由新分类调用，不因页面重组而复制。
6. Widget 实例配置页继续由系统添加流程和 AppWidget ID 驱动，设置页只提供统一入口和说明。
7. 关于、分享、导入仍调用原 Activity、Fragment、Intent 和 ViewModel，不改格式或网络链路。

## 返回路径规范

| 页面 | 返回后应到达 |
| --- | --- |
| 课表信息、课程管理、作息时间、课表外观、多课表管理 | 课表管理首页；若由左侧快速切换进入管理，则仍返回课表管理首页 |
| 作息编辑 | 作息时间列表，再返回课表管理 |
| 课程新增/编辑 | 当前课表的课程管理列表，保持原 `selectedTableId` |
| 全局设置的二级分类 | 设置首页，再返回主课程表 |
| Widget 实例配置 | 遵循系统 AppWidget 配置返回契约；从设置查看实例时返回桌面小组件分类 |
| 分享动作 | 关闭系统分享/文件选择后回到主课程表 |
| 关于 | 回到主课程表右侧菜单所在页面，不进入设置返回栈 |

返回栈规范描述的是 Stage 2–5 的验收目标，本阶段不修改现有返回行为。

## 兼容边界

以下内容不是信息架构清理对象：

- SharedPreferences 文件名：`config`、`multi_language`、`table{id}_config`、`time{id}_config`、`widget{id}_config`。
- 任意既有 key、类型、默认值和写入副作用，包括语言双键、提醒兼容键和旧颜色/初始化键。
- `table-1_config` 的 id `-1` 默认配置语义。
- Widget 的 `tableId=0` → `config.show_table_id` 回退，以及每个 AppWidget ID 的实例配置。
- Room 数据库 `wakeup` 的名称、路径、版本、实体、DAO、Migration 和关系。
- 课程提醒的 Alarm、通知权限、系统设置、小部件存在性检查和 providers 更新。
- 周次算法、导入导出格式、学校解析、分享口令、Intent extra 和网络服务调用。
- 主课程表视觉、v0.7 导航布局及 Fluent 2 的整体迁移。后续只对本轮新增或重组的设置内容逐步适配 Fluent 2。

## 后续阶段实施边界

| 阶段 | 允许做什么 | 不允许提前做什么 |
| --- | --- | --- |
| Stage 2 | 按本架构重组课表管理入口，复用原数据、作息、课程和多课表逻辑 | 不改全局设置，不删除未验证的重复入口 |
| Stage 3 | 按八类重组全局设置，保持所有 key、默认值、副作用和系统状态读取 | 不清理兼容键，不伪造权限状态 |
| Stage 4 | 在替代入口实机等价后删除重复入口、统一标题和返回路径，清理失效提示 | 不删除数据库字段、内部类名、key、格式或 Migration |
| Stage 5 | 完整回归并建立 `V08_RELEASE_REPORT.md` | 不以静态检查代替关键实机流程 |

## Stage 1 验证结论

本架构覆盖了 Stage 0 审计中的课表数据、外观、提醒、小部件、后台、语言、时间表、导入导出、分享、关于、时钟和兼容键。所有新入口均映射到原调用逻辑与原存储位置，没有为同一功能设计第二套状态。

集中验证结果：

- 当前 WakeUp 补丁链通过 `tools/build-weeko-v08-fluent-stage10-debug.ps1` 完整构建，产物为 `build/v0.8/Weeko-v0.7.0-fluent-stage10-debug.apk`，SHA-256 为 `99C3F94A38252E38F8903288103DCE049CDE08DF709F502B8932235C7F33EF0F`。产物沿用既有 v0.7 文件名，不在本阶段改版本命名。
- APK 以覆盖安装方式成功安装到实机 Xiaomi 22081212C（设备代号 `diting`），保留原应用数据。
- 从 `SplashActivity` 冷启动成功进入 `ScheduleActivity`；主课程表、日期、周次和课程内容正常显示。
- 左侧菜单成功显示“修改当前周 / 切换/管理课表 / 调整上课时间”；右侧菜单成功显示“课表管理 / 分享 / 设置 / 关于 Weeko”。
- 由右侧菜单进入设置成功，旧 `SettingsActivity` 的“全局设置”、当前课表、语言、显示主题、小部件和课程表显示项可见；返回主课程表正常，无启动 Crash。
- 本阶段没有实现新分类页面，因此实机验证只证明现有运行基线未受文档变更影响；新入口等价性必须在 Stage 2–5 分别验证，不能把本结果当作迁移完成。

本阶段只新增本文件。没有修改源码、资源、Manifest、APK、补丁脚本、SharedPreferences、Room、系统权限、业务逻辑或主课程表 UI；也没有使用 `app/` 下的实验性 Compose 工程作为 v0.8 主体。
