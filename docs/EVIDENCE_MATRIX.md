# WakeUp 6.0.23 兼容证据矩阵

最后更新：2026-08-31（Asia/Shanghai）

> 路线校正（2026-08-31）：本文现在服务于 WakeUp 6.0.23 还原母体，不再支持“新建 Weeko 原生工程”的路线。研究对象仅为仓库根目录的 `wakeup6.0.23.apk`；当前 `app/` 与 `adapter/wakeup/` 是误建的 Weeko-native 实验代码，不能替代母体，也不能据此修改 WakeUp 行为。反编译结果只用于证据核对，不等于可编译源码。

本文是阶段 0 还原基线的证据索引。所有结论按“已确认、合理推断、未知”分级；在 WakeUp 母体可编译前，不建立新的领域模型、Room schema、UI 或身份。

## 证据等级与工具

- **已确认**：APK Manifest、资源、DEX/Room 生成代码或两个独立静态证据能够直接支持。
- **合理推断**：混淆名称不可读，但调用参数、SQL 或上下游行为能够支持语义；实现前仍需测试固定。
- **未知**：缺少真实数据、对应历史版本或可运行环境，不能形成兼容承诺。

研究 APK 大小为 6,082,176 bytes，SHA-256 为 `50EDBC7C7C3458DD0D97436F15A6AC1E69AFBE107054F53B63A0327E52DBB476`。使用 JADX 1.5.6、apktool 2.10.0、Android build-tools 36 的 `aapt2` 和 SDK `apkanalyzer` 交叉检查。JADX 完成输出但报告 66 个反编译错误，因此协程状态机和少量合成类不能只凭 Java 结果下结论。`apkanalyzer manifest print` 在设置 JDK 21 后成功；Manifest 结论由 `aapt2`、`apkanalyzer` 与 apktool 解码结果互证。JADX 输出位于 `.stage4a-jadx/`，apktool 输出位于 `.restoration-apktool/`。

## 总览矩阵

| 主题 | 结论 | 状态 | 主要证据 | 剩余缺口 |
| --- | --- | --- | --- | --- |
| APK 身份 | `com.suda.yzune.wakeupschedule`，6.0.23/263，min 21，target 35 | 已确认 | aapt2 badging、apktool Manifest | 无 |
| 数据库 | Room schema version 11，数据库名 `wakeup`，六张业务表 | 已确认 | `AppDatabase_Impl` delegate、数据库 builder | 条件路径开关的业务含义未知 |
| 迁移 | 注册 7→8→9→10→11；SQL 见下文 | 已确认 | `AppDatabase`、builder、四个 Migration 实现 | 缺 v7/v8/v9/v10 真实数据库回放 |
| Preferences | `config`、`multi_language`、`table{id}_config`、`time{id}_config`、`widget{id}_config` | 已确认 | SharedPreferences 工具和配置类 | 动态键与全部历史废弃键未知 |
| WakeUp 文件 | UTF-8，五个按行分隔的 JSON 值 | 已确认 | 导出 ViewModel、导入 ViewModel、Gson 模型 | 缺不同历史版本及损坏样本 |
| Provider | authority 与 11 条路径、只读 JSON Cursor 协议 | 已确认 | Manifest、`ScheduleContentProvider`、UriMatcher | 第三方调用兼容性缺运行样本 |
| Widget | 六个 provider、三个 RemoteViews service、30 分钟至 3 小时刷新周期 | 已确认 | Manifest、appwidget XML、provider 代码 | 无法在原应用中完成交互回归 |
| 提醒 | `AlarmManager` 精确闹钟负责课程提醒，WorkManager 不负责课程提醒 | 已确认 | `TodayCourseAppWidget`、Manifest | 重启后的闹钟恢复行为未知 |
| WorkManager | Honor/Vivo 建议任务为一次性任务 | 已确认 | App 初始化、Worker 调度代码 | 厂商服务端行为未知 |
| Parser | 输入由 HTML/JSON/网络响应等适配器自管，统一输出 Course/TimeTable | 已确认 | Parser 接口、序列化模型、ParserProxy | 每所学校的完整协议和失败语义未知 |
| 网络 | APK 同时包含 Ktor 与 Retrofit/OkHttp；账号导入位于学校适配器边界 | 已确认 | 网络辅助类、学校登录类 | 未抓包；服务可用性和证书策略未知 |
| 公开历史源码 | 官方历史仓库只可作结构背景，不对应 6.0.23 | 已确认 | GitHub 仓库页面 | 未发现明确 LICENSE，禁止复制 |

## Room v11 schema

数据库 builder 默认使用名称 `wakeup`。当一个被混淆的功能开关为真且 API ≥ 24 时，路径改为 `<dataDir>/databases/db/wakeup`，并创建 `<dataDir>/databases/db`。已确认开启 multi-instance invalidation。开关的产品语义为**未知**，不能据此推断数据库一定处于哪个路径。

Room delegate 直接给出 schema version `11`、identity hash `83d09007d416f0577c3ca29ba87dd2ce` 和 legacy hash `9f7c0883d4451e55f07f47cefed99748`。v11 建表 SQL 如下：

```sql
CREATE TABLE IF NOT EXISTS `CourseBaseBean` (
  `id` INTEGER NOT NULL,
  `courseName` TEXT NOT NULL,
  `color` TEXT NOT NULL,
  `tableId` INTEGER NOT NULL,
  `note` TEXT NOT NULL,
  `credit` REAL NOT NULL,
  PRIMARY KEY(`id`, `tableId`),
  FOREIGN KEY(`tableId`) REFERENCES `TableBean`(`id`)
    ON UPDATE CASCADE ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS `index_CourseBaseBean_tableId`
  ON `CourseBaseBean` (`tableId`);

CREATE TABLE IF NOT EXISTS `CourseDetailBean` (
  `id` INTEGER NOT NULL,
  `day` INTEGER NOT NULL,
  `room` TEXT,
  `teacher` TEXT,
  `startNode` INTEGER NOT NULL,
  `step` INTEGER NOT NULL,
  `startWeek` INTEGER NOT NULL,
  `endWeek` INTEGER NOT NULL,
  `type` INTEGER NOT NULL,
  `tableId` INTEGER NOT NULL,
  `level` INTEGER NOT NULL,
  `ownTime` INTEGER NOT NULL,
  `startTime` TEXT NOT NULL,
  `endTime` TEXT NOT NULL,
  PRIMARY KEY(`day`, `startNode`, `startWeek`, `type`, `tableId`, `id`, `ownTime`, `startTime`),
  FOREIGN KEY(`id`, `tableId`) REFERENCES `CourseBaseBean`(`id`, `tableId`)
    ON UPDATE CASCADE ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS `index_CourseDetailBean_id_tableId`
  ON `CourseDetailBean` (`id`, `tableId`);

CREATE TABLE IF NOT EXISTS `AppWidgetBean` (
  `id` INTEGER NOT NULL,
  `baseType` INTEGER NOT NULL,
  `detailType` INTEGER NOT NULL,
  `info` TEXT NOT NULL,
  PRIMARY KEY(`id`)
);

CREATE TABLE IF NOT EXISTS `TimeTableBean` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  `name` TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS `TimeDetailBean` (
  `node` INTEGER NOT NULL,
  `startTime` TEXT NOT NULL,
  `endTime` TEXT NOT NULL,
  `timeTable` INTEGER NOT NULL,
  PRIMARY KEY(`node`, `timeTable`),
  FOREIGN KEY(`timeTable`) REFERENCES `TimeTableBean`(`id`)
    ON UPDATE CASCADE ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS `index_TimeDetailBean_timeTable`
  ON `TimeDetailBean` (`timeTable`);

CREATE TABLE IF NOT EXISTS `TableBean` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  `timeTable` INTEGER NOT NULL,
  `type` INTEGER NOT NULL,
  FOREIGN KEY(`timeTable`) REFERENCES `TimeTableBean`(`id`)
    ON UPDATE CASCADE ON DELETE SET DEFAULT
);
CREATE INDEX IF NOT EXISTS `index_TableBean_timeTable`
  ON `TableBean` (`timeTable`);
```

主键、索引和外键均为**已确认**。`TableBean.timeTable` 的外键使用 `SET DEFAULT`，但 v11 建表 SQL 没有为该列声明显式 DEFAULT；SQLite/Room 在删除被引用行时的实际结果必须用真实数据库验证，标记为**高风险未知**。

## 完整 Migration 链

builder 按顺序注册 7→8、8→9、9→10、10→11。8→9 和 9→10 的实现被 R8 合并到名为 `androidx.work.impl.OooO` 的类中，但构造参数和 builder 注册版本明确证明它们是应用数据库迁移，不是 WorkManager 自身数据库迁移。

### 7→8

```sql
CREATE TABLE TimeTableBean (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, name TEXT NOT NULL);
INSERT INTO TimeTableBean VALUES(1, '默认');
CREATE TABLE TableBean (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  tableName TEXT NOT NULL,
  nodes INTEGER NOT NULL DEFAULT 11,
  background TEXT NOT NULL DEFAULT '',
  timeTable INTEGER NOT NULL DEFAULT 1,
  startDate TEXT NOT NULL DEFAULT '2019-02-25',
  maxWeek INTEGER NOT NULL DEFAULT 30,
  itemHeight INTEGER NOT NULL DEFAULT 56,
  itemAlpha INTEGER NOT NULL DEFAULT 50,
  itemTextSize INTEGER NOT NULL DEFAULT 12,
  widgetItemHeight INTEGER NOT NULL DEFAULT 56,
  widgetItemAlpha INTEGER NOT NULL DEFAULT 50,
  widgetItemTextSize INTEGER NOT NULL DEFAULT 12,
  strokeColor INTEGER NOT NULL DEFAULT 0x80ffffff,
  widgetStrokeColor INTEGER NOT NULL DEFAULT 0x80ffffff,
  textColor INTEGER NOT NULL DEFAULT 0xff000000,
  widgetTextColor INTEGER NOT NULL DEFAULT 0xff000000,
  courseTextColor INTEGER NOT NULL DEFAULT 0xff000000,
  widgetCourseTextColor INTEGER NOT NULL DEFAULT 0xff000000,
  showSat INTEGER NOT NULL DEFAULT 1,
  showSun INTEGER NOT NULL DEFAULT 1,
  sundayFirst INTEGER NOT NULL DEFAULT 0,
  showOtherWeekCourse INTEGER NOT NULL DEFAULT 0,
  showTime INTEGER NOT NULL DEFAULT 0,
  type INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (timeTable) REFERENCES TimeTableBean (id)
    ON DELETE SET DEFAULT ON UPDATE CASCADE
);
CREATE INDEX index_TableBean_id_timeTable ON TableBean (timeTable ASC);

ALTER TABLE CourseBaseBean RENAME TO CourseBaseBean_old;
CREATE TABLE CourseBaseBean(
  id INTEGER NOT NULL, courseName TEXT NOT NULL, color TEXT NOT NULL, tableId INTEGER NOT NULL,
  PRIMARY KEY (id, tableId),
  FOREIGN KEY (tableId) REFERENCES TableBean (id) ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO TableBean (tableName) VALUES('');
INSERT INTO TableBean (tableName) VALUES('情侣课表');
INSERT INTO CourseBaseBean (id, courseName, color, tableId)
  SELECT id, courseName, color, CASE WHEN tableName = '' THEN 1 ELSE 2 END FROM CourseBaseBean_old;
CREATE INDEX index_CourseBaseBean_tableId ON CourseBaseBean (tableId ASC);
DROP TABLE CourseBaseBean_old;

DROP INDEX index_CourseDetailBean_id_tableName;
ALTER TABLE CourseDetailBean RENAME TO CourseDetailBean_old;
CREATE TABLE CourseDetailBean (
  id INTEGER NOT NULL, day INTEGER NOT NULL, room TEXT, teacher TEXT,
  startNode INTEGER NOT NULL, step INTEGER NOT NULL,
  startWeek INTEGER NOT NULL, endWeek INTEGER NOT NULL, type INTEGER NOT NULL,
  tableId INTEGER NOT NULL,
  PRIMARY KEY (day, startNode, startWeek, type, tableId, id),
  FOREIGN KEY (id, tableId) REFERENCES CourseBaseBean (id, tableId)
    ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO CourseDetailBean
  (id, day, room, teacher, startNode, step, startWeek, endWeek, type, tableId)
  SELECT id, day, room, teacher, startNode, step, startWeek, endWeek, type,
         CASE WHEN tableName = '' THEN 1 ELSE 2 END
  FROM CourseDetailBean_old;
CREATE INDEX index_CourseDetailBean_id_tableId ON CourseDetailBean (id ASC, tableId ASC);
DROP TABLE CourseDetailBean_old;

ALTER TABLE TimeDetailBean RENAME TO TimeDetailBean_old;
CREATE TABLE TimeDetailBean (
  node INTEGER NOT NULL, startTime TEXT NOT NULL, endTime TEXT NOT NULL,
  timeTable INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (node, timeTable),
  FOREIGN KEY (timeTable) REFERENCES TimeTableBean (id) ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO TimeDetailBean (node, startTime, endTime)
  SELECT node, startTime, endTime FROM TimeDetailBean_old;
CREATE INDEX index_TimeDetailBean_id_timeTable ON TimeDetailBean(timeTable ASC);
DROP TABLE TimeDetailBean_old;
ALTER TABLE TimeTableBean ADD COLUMN sameLen INTEGER NOT NULL DEFAULT 1;
ALTER TABLE TimeTableBean ADD COLUMN courseLen INTEGER NOT NULL DEFAULT 50;
```

注意：7→8 创建的 `index_TableBean_id_timeTable` 与 `index_TimeDetailBean_id_timeTable` 名称含不存在的 `id` 字样，但索引列分别确实是 `timeTable`。这是 APK 原 SQL，不在证据文档中“修正”。

### 8→9

迁移先读取旧 `TableBean` 的展示字段，并写入 `table{id}_config` 和 `widget{id}_config`；当前主课表 id 写入 `config/show_table_id`。随后执行：

```sql
DROP INDEX IF EXISTS index_TableBean_timeTable;
ALTER TABLE TableBean RENAME TO TableBean_old;
CREATE TABLE TableBean (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  timeTable INTEGER NOT NULL DEFAULT 1,
  type INTEGER NOT NULL,
  FOREIGN KEY (timeTable) REFERENCES TimeTableBean (id) ON DELETE SET DEFAULT ON UPDATE CASCADE
);
INSERT INTO TableBean (id, timeTable, type) SELECT id, timeTable, type FROM TableBean_old;
CREATE INDEX index_TableBean_timeTable ON TableBean(timeTable ASC);
DROP TABLE TableBean_old;

DROP INDEX IF EXISTS index_CourseBaseBean_tableId;
ALTER TABLE CourseBaseBean RENAME TO CourseBaseBean_old;
CREATE TABLE CourseBaseBean(
  id INTEGER NOT NULL, courseName TEXT NOT NULL, color TEXT NOT NULL, tableId INTEGER NOT NULL,
  PRIMARY KEY (id, tableId),
  FOREIGN KEY (tableId) REFERENCES TableBean (id) ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO CourseBaseBean (id, courseName, color, tableId)
  SELECT id, courseName, color, tableId FROM CourseBaseBean_old;
CREATE INDEX index_CourseBaseBean_tableId ON CourseBaseBean(tableId ASC);
DROP TABLE CourseBaseBean_old;

DROP INDEX IF EXISTS index_CourseDetailBean_id_tableId;
ALTER TABLE CourseDetailBean RENAME TO CourseDetailBean_old;
CREATE TABLE CourseDetailBean (
  id INTEGER NOT NULL, day INTEGER NOT NULL, room TEXT, teacher TEXT,
  startNode INTEGER NOT NULL, step INTEGER NOT NULL,
  startWeek INTEGER NOT NULL, endWeek INTEGER NOT NULL, type INTEGER NOT NULL,
  tableId INTEGER NOT NULL,
  PRIMARY KEY (day, startNode, startWeek, type, tableId, id),
  FOREIGN KEY (id, tableId) REFERENCES CourseBaseBean (id, tableId)
    ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO CourseDetailBean
  (id, day, room, teacher, startNode, step, startWeek, endWeek, type, tableId)
  SELECT id, day, room, teacher, startNode, step, startWeek, endWeek, type, tableId
  FROM CourseDetailBean_old;
CREATE INDEX index_CourseDetailBean_id_tableId ON CourseDetailBean (id ASC, tableId ASC);
DROP TABLE CourseDetailBean_old;
```

Preferences 搬迁字段包括 `tableName`、`nodes`、`background`、`startDate`、`maxWeek`、item/widget 尺寸和透明度、文字/描边/课程文字色、`showSat`、`showSun`、`sundayFirst`、`showOtherWeekCourse`、`showTime`，以及从全局配置继承的 `schedule_teacher`、`schedule_detail_time`、`appwidget_bg`、`appwidget_bg_color`。这是事务外部副作用，必须作为兼容风险单独测试。

### 9→10

迁移先把 `TimeTableBean.sameLen/courseLen` 写入 `time{id}_config` 的 `sameCourseLen/courseLen`，再执行：

```sql
CREATE TABLE TimeTableBean_new (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL
);
INSERT INTO TimeTableBean_new (id, name) SELECT id, name FROM TimeTableBean;
DROP TABLE TimeTableBean;
ALTER TABLE TimeTableBean_new RENAME TO TimeTableBean;

DROP INDEX IF EXISTS index_CourseBaseBean_tableId;
CREATE TABLE CourseBaseBean_new (
  id INTEGER NOT NULL, courseName TEXT NOT NULL, color TEXT NOT NULL, tableId INTEGER NOT NULL,
  note TEXT NOT NULL DEFAULT '', credit REAL NOT NULL DEFAULT 0.0,
  PRIMARY KEY (id, tableId),
  FOREIGN KEY (tableId) REFERENCES TableBean (id) ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO CourseBaseBean_new (id, courseName, color, tableId)
  SELECT id, courseName, color, tableId FROM CourseBaseBean;
DROP TABLE CourseBaseBean;
ALTER TABLE CourseBaseBean_new RENAME TO CourseBaseBean;
CREATE INDEX index_CourseBaseBean_tableId ON CourseBaseBean(tableId ASC);

DROP INDEX IF EXISTS index_CourseDetailBean_id_tableId;
CREATE TABLE CourseDetailBean_new (
  id INTEGER NOT NULL, day INTEGER NOT NULL, room TEXT, teacher TEXT,
  startNode INTEGER NOT NULL, step INTEGER NOT NULL,
  startWeek INTEGER NOT NULL, endWeek INTEGER NOT NULL, type INTEGER NOT NULL,
  tableId INTEGER NOT NULL, level INTEGER NOT NULL DEFAULT 0,
  ownTime INTEGER NOT NULL DEFAULT 0,
  startTime TEXT NOT NULL DEFAULT '', endTime TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (day, startNode, startWeek, type, tableId, id),
  FOREIGN KEY (id, tableId) REFERENCES CourseBaseBean (id, tableId)
    ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO CourseDetailBean_new
  (id, day, room, teacher, startNode, step, startWeek, endWeek, type, tableId)
  SELECT id, day, room, teacher, startNode, step, startWeek, endWeek, type, tableId
  FROM CourseDetailBean;
DROP TABLE CourseDetailBean;
ALTER TABLE CourseDetailBean_new RENAME TO CourseDetailBean;
CREATE INDEX index_CourseDetailBean_id_tableId ON CourseDetailBean (id ASC, tableId ASC);
```

该迁移实现用宽泛 `catch (Exception)` 显示 Toast 后返回，可能留下未完成迁移；这是**已确认的高风险旧行为**。Weeko 不复制这一错误处理。

### 10→11

```sql
DROP INDEX IF EXISTS index_CourseDetailBean_id_tableId;
CREATE TABLE CourseDetailBean_new (
  id INTEGER NOT NULL, day INTEGER NOT NULL, room TEXT, teacher TEXT,
  startNode INTEGER NOT NULL, step INTEGER NOT NULL,
  startWeek INTEGER NOT NULL, endWeek INTEGER NOT NULL, type INTEGER NOT NULL,
  tableId INTEGER NOT NULL, level INTEGER NOT NULL DEFAULT 0,
  ownTime INTEGER NOT NULL DEFAULT 0,
  startTime TEXT NOT NULL DEFAULT '', endTime TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (day, startNode, startWeek, type, tableId, id, ownTime, startTime),
  FOREIGN KEY (id, tableId) REFERENCES CourseBaseBean (id, tableId)
    ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO CourseDetailBean_new
  (id, day, room, teacher, startNode, step, startWeek, endWeek, type, tableId,
   level, ownTime, startTime, endTime)
  SELECT id, day, room, teacher, startNode, step, startWeek, endWeek, type, tableId,
         level, ownTime, startTime, endTime
  FROM CourseDetailBean;
DROP TABLE CourseDetailBean;
ALTER TABLE CourseDetailBean_new RENAME TO CourseDetailBean;
CREATE INDEX index_CourseDetailBean_id_tableId
  ON CourseDetailBean (id ASC, tableId ASC);
```

## SharedPreferences 证据

| 文件 | 已确认键与默认值 | 状态 |
| --- | --- | --- |
| `multi_language` | `language_type="system"` | 已确认 |
| `config` | `has_intro=false`、`dynamic_colors=false`、`day_night_theme=2`、`language_setting=0`、`show_table_id=1`（另有清理调用默认 0）、`schedule_blank_area=true`、`schedule_pre_load=true`、`show_empty_view=true`、`course_reminder=false`、`reminder_min=20`、`reminder_on_going=false`、`silence_mode=0`、`silence_reminder=false`、`clock_dark_mode=true`、`screen_aod=false`、`prevent_burn=false`、`import_school=null`、`edu_type=0`、`select_week_mode=0`、`time_picker_input_mode=0` | 已确认 |
| `table{id}_config` | `tableName="未命名"`、`nodes=20`、`background=""`、`startDate="2025-9-1"`、`maxWeek=20`、`order=-1`，以及下述样式公共键 | 已确认 |
| `time{id}_config` | `sameCourseLen=false`、`courseLen=50`、`sameBreakLen=false`、`breakLen=10` | 已确认 |
| `widget{id}_config` | `tableId=0`、`appwidget_bg=true`、`appwidget_bg_color=-654311425`、`appwidget_bg_pic=""`、`showHeaderArea=true`、`showButton=true`、`showDate=true`、`showColor=true`，以及样式公共键 | 已确认 |
| table/widget 样式公共键 | `itemHeight=64`、`itemAlpha=50`、`headerTextSize=12`、`itemTextSize=12`、`strokeColor=-2130706433`、`textColor=-16777216`、`courseTextColor=-1`、`showSat=true`、`showSun=true`、`showOtherWeekCourse=true`、`schedule_location=true`、`schedule_teacher=true`、`schedule_detail_time=true`、`showTime=false`、`radius=4`、`otherWeekCourseAlpha=50`、`showRoomPrefix=true`、`showGrid=false`、`useDottedLine=false`、`strokeColorCompose=false`、`textColorCompose=false`、水平/垂直居中均为 false | 已确认 |

DEX 中恢复到的其余 `config` 字面量读取及调用点默认值如下，均为**已确认的调用默认值**，不代表不同调用点一定一致：

| 类别 | 键与默认值 |
| --- | --- |
| 生命周期/外观 | `has_feedback_honor=false`、`has_feedback_vivo=false`、`show_donate=false`、`s_update=true`、`open_times=0` |
| 课表基础 | `course=""`、`has_count=false`、`has_adjust=false`、`suda_life=true`、`hmos_form_tips=false`、`own_time_tips=false` |
| 空状态/显示 | `empty_view_image=""`、`item_height=56`、`classNum=11`、`sb_weeks=30`、`sb_alpha=60`、`sb_text_size=12`、`s_show=false`、`s_show_time_detail=false`、`s_show_sat=true`、`s_show_weekend=true`、`s_sunday_first=false`、`s_stroke=true`、`s_color=false`、`pic_uri=""` |
| Widget 旧全局样式 | `widget_item_height=56`、`sb_widget_alpha=60`、`sb_widget_text_size=12`、`s_widget_color=false`、`s_colorful_day_widget=true` |
| 导入/WebView | `intro_school_list=false`、`is_webview_desktop_mode=false`、`newShuweiJson=""`、`not_show_shuwei_refresh_tips=false` |
| 作息初始化 | `isInitTimeTable=false` |

还确认了 `last_version_code`、`dark_mode_cover`、`course_end_reminder`、`reminder_end_before` 等写入/资源关联键，但没有恢复出唯一可靠默认读取值，状态为**未知**。`import_school` 的调用默认值为 null，这仅表示未选学校，不应在 Weeko 中持久化为字符串 `"null"`。

`course_end_reminder` 和 `reminder_end_before` 的写入点已确认，但 APK 的可恢复 Java 调用中没有可靠默认读取值，故默认值为**未知**。`show_timetable_error` 在不同调用点以 true/false 作为默认值，不能指定唯一默认。动态文件名、第三方库自有 Preferences 和历史已删除键尚未穷尽；因此不能把这张表当成直接搬迁全部私有数据的协议。

## `.wakeup_schedule` 证据

文件是 UTF-8 文本，导出使用 SAF `ACTION_CREATE_DOCUMENT`、MIME `application/octet-stream`、默认文件名 `<tableName>.wakeup_schedule`。内容恰好按以下顺序写入五个 JSON 值，每个值后换行：

1. `TimeTableCompat`：`id,name,sameLen,courseLen,sameBreakLen,theBreakLen`。
2. `TimeDetailBean[]`：`node,startTime,endTime,timeTable`。
3. `TableCompat`：`id,tableName,nodes,background,timeTable,startDate,maxWeek,itemHeight,itemAlpha,itemTextSize,widgetItemHeight,widgetItemAlpha,widgetItemTextSize,strokeColor,widgetStrokeColor,textColor,widgetTextColor,courseTextColor,widgetCourseTextColor,showSat,showSun,sundayFirst,showOtherWeekCourse,showTime,type`。
4. `CourseBaseBean[]`：`id,courseName,color,tableId,note,credit`。
5. `CourseDetailBean[]`：`id,day,room,teacher,startNode,step,startWeek,endWeek,type,tableId,level,ownTime,startTime,endTime`。

导入代码按行读取并固定访问索引 0…4。APK 是否接受额外尾行、空行、BOM 或 CRLF 不能由反编译稳定确认，均为**未知**。仓库中的样本是 Weeko 自建 synthetic fixture，只证明当前 adapter 行为，不是 WakeUp 真实导出证据。

`type=0/1/2` 分别表示全部周/单周/双周是由查询选择和周次奇偶分支共同支持的**合理推断**；正式兼容测试必须用三类真实导出样本确认。跨版本差异同样未知。数据库迁移表明 note、credit、自定义时间字段在 v9→v10 才进入数据库，但这不能自动证明历史导出文件的字段版本。

## Intent、Provider 与系统组件

Manifest 已确认：launcher 为导出的 `SplashActivity`；深链为 `wakeupschedule://main`；导出的 `LoginWebActivity` 接收 `.wakeup_schedule`、HTML 和 CSV 相关 VIEW Intent。Provider authority 为 `com.suda.yzune.wakeupschedule.provider`。

Provider UriMatcher 路径及 code：`show_table_id`(1)、`table_config/#`(2)、`course_list/#`(3)、`table_list`(4)、`refresh`(5)、`scrollable`(6)、`next_course_list/#`(7)、`has_init`(8)、`course_list`(9)、`next_course_list`(10)、`vivo_intent_entity`(11)。绝大多数查询返回列 `code,data`，其中 `data` 为 JSON；`scrollable` 返回 `value`。`insert/update/delete` 为 no-op。调用方存在包名 allowlist，未授权路径返回 code 2001。以上均为**已确认**，但 Weeko 不复用旧 authority 或协议。

应用自定义 action 已确认：`WAKEUP_REMIND_COURSE`、`WAKEUP_CANCEL_REMINDER`、`WAKEUP_NEXT_DAY`、`WAKEUP_BACK_TIME`、`WAKEUP_NEXT_WEEK`、`WAKEUP_BACK_WEEK`。Weeko 后续必须定义自身命名空间 action。

六个 Widget provider 为 `ScheduleAppWidget`、`TodayCourseAppWidget`、`TodayListAppWidget`、`TodayAndNextDayAppWidget`、`TodayListAppWidgetMIUI`、`TodayModernAppWidgetMIUI`；RemoteViews service 为 `ScheduleAppWidgetService`、`TodayColorfulService`、`TodayModernService`。XML 更新周期分别为 3 小时、2 小时或 30 分钟。MIUI provider 使用 `:widgetProvider` 进程。

通知渠道为 `schedule_reminder`（课程提醒，importance 4）和 `news`（公告，importance 2）。课程提醒由 `TodayCourseAppWidget` 使用 `RTC_WAKEUP` 调度；API < 23 调 `setExact`，API ≥ 23 调 `setExactAndAllowWhileIdle`，API ≥ 31 检查 `canScheduleExactAlarms`，无资格时关闭 `course_reminder`。没有证据表明 WorkManager 调度课程提醒。

自有 WorkManager 任务为 Honor/Vivo 建议数据的一次性 Worker；已确认名称/标签 `honor_feedback` 与 `vivo_feedback`。Manifest 有 AndroidX `RescheduleReceiver`，但没有找到 WakeUp 自有的开机后课程闹钟重建入口，因此闹钟重启恢复行为为**未知**。

## Parser 输入输出和网络边界

Parser 接口经调用关系可映射为：课程列表（suspend）、课表名、开学日期、最大周数、每天节数和可选 `TimeTable`。混淆方法名不可作为公开契约；语义由 `ParserProxy` 的字段映射支持。

统一输出模型是：

- `Course(name, day, room="", teacher="", startNode, endNode, startWeek, endWeek, type, credit=0, note="", startTime="", endTime="")`；
- `TimeTable(name, timeList)`；
- `TimeDetail(node, startTime, endTime)`；
- `WeekBean(start, end, type)`。

`ParserProxy` 将相邻节次合并，按课程名建立 CourseBase，再生成 CourseDetail，并对星期、节次和周次做有限归一化。旧导入链最终直接调用 DAO/ImportViewModel 写入，没有发现统一 `ScheduleDraft → Preview → Transaction` 边界；这是**已确认的架构事实**，不应复制到 Weeko。

输入边界由各适配器持有，包含 HTML、JSON、分享文本、WebView 页面源码、Cookie 和学校 HTTP 响应。APK 同时打包 Ktor 与 Retrofit/OkHttp：通用 parser/fetcher 使用 Ktor 风格 suspend 请求，部分学校登录（例如苏大）使用 Retrofit，同类 JLU/NWPU 适配器直接组装请求并在对象字段中暂存 Cookie。未发现足以证明账号、Cookie、Token 永久写入 Room/SharedPreferences 的证据；结论为**未知**，不能写成“不会持久化”。

## 公开历史源码边界

公开仓库 [`YZune/WakeUpSchedule`](https://github.com/YZune/WakeUpSchedule) 的 `master` 当前指向提交 `5d43928`（2018-04-07）；其 `app/build.gradle` 为版本 2.10、compile/target 27、GreenDAO 3.2.2，明显早于 6.0.23 APK 的 Room v11/target 35。仓库树未发现 LICENSE/COPYING/NOTICE 文件，授权范围为**未知**。因此只允许用于理解早期命名和结构，不能拿它替代 6.0.23，也没有从公开源码或反编译输出复制实现。

## 下一阶段前仍阻塞的证据

### 本轮重组黑盒补充

apktool 2.10.0 从 `.restoration-apktool/` 成功重组出 `build/wakeup-rebuilt-unsigned.apk`（6,264,671 bytes，SHA-256 `D57707FA03A6E3FC3925900066FC04ED17A9D1AE8D68DD237292E4DE0B79BCEE`），使用本机 debug keystore 签名后生成 `build/wakeup-rebuilt-debug.apk`（6,362,137 bytes，SHA-256 `D8B569980EA0945C9F243C01FC3F432BB221DB4F99A595F6BAF77D7155A651FE`）并安装到设备 `3fde7e33`。重组包保持旧 package/version，并进入 `com.suda.yzune.wakeupschedule.schedule.ScheduleActivity`；UIAutomator 看到日期、周次、节次时间和“本周没有课程哦”，没有立即出现应用进程崩溃。原始签名 APK 的一次直接启动曾在 `android.app.ConfigurationController.updateLocaleListFromAppContext` 抛出 `Resources.getConfiguration()` NPE；由于设备上的旧包已被重组签名包更新，当前结果不能作为原签名 APK 的等价运行结论。需在干净设备上对原始签名 APK 与重组包做 A/B，才能解释差异。

资源还原诊断：JADX 导出工程的首个 `mergeDebugResources` 错误是 `.9.png` 九宫格资源尺寸/边框无效；将九宫格改名为普通 PNG 的隔离副本继续在 `processDebugResources` 触发 enum/dimension/flags 原始数值错误。依据 APK 中的版本元数据，候选工程已逐项恢复 AndroidX Core 1.16.0、AppCompat 1.7.0、Material 1.12.0、Toasty 1.5.2 的同名资源，并按 Android SDK 35 属性表将反编译整数写回合法 XML 名称；原文件备份在 `build/evidence-deps/`。因此候选的 `mergeDebugResources`、`processDebugResources` 均已**确认通过**，未改动业务源码、Manifest、数据库或 UI 设计。改用 apktool 解出的资源时，隔离副本首个错误变为 41 个含 `$` 的文件名（例如 `$avd_hide_password__0.xml`），并发现 `ic_launcher_background.xml` 将 drawable 引用写入 `android:fillColor`；这些仍是**已确认的反编译资源损失**，不代表可以直接批量改名或替换原行为。

源码还原阻塞：完整 `:app:assembleDebug --rerun-tasks` 在资源阶段通过后进入 `compileDebugJavaWithJavac`。依据 smali 已消除 Activity/Fragment、ActionMenuView、WorkManager、Room、SlidingPaneLayout、iCalendar、QuickSideBar、Glide 等前一批 13 个类、RecyclerView 的首批局部类型错误、ksoup 四个 enum/状态机结构错误，以及 Material/Huawei、文件校验/流类型、生成式 R 类、课程映射和日期监听器错误。这是**已确认的 JADX 输出不可编译**，不是运行行为证据；下一步必须按 smali、原始 DEX 和依赖版本逐类恢复，不能用全局替换、假类或删除旧功能绕过。

### r20 还原构建快照与 r21 最终复核（2026-08-31）

`build/evidence-deps/wakeup-restoration-compile-20260831-r20.log` 记录最后一批源码恢复后的错误快照；r21 最终 `assembleDebug` 日志为 `build/evidence-deps/wakeup-restoration-assemble-20260831-r21.log`。两次均确认 `mergeDebugResources`、`processDebugResources`、`processDebugMainManifest` 通过，`compileDebugJavaWithJavac` 失败，javac 输出上限为 100 个错误，未生成 Gradle WakeUp 母体 APK。当前首批错误文件为 `course_add/AddCourseActivity.java:553`、`dao/OooO0O0.java:29,31,89,605,760`、`schedule/ScheduleActivity$shareScheduleOnline$1.java:52,56,59`、`schedule_import/LoginWebFragment$refreshCode$1.java:120–133` 及 `schedule_import/LoginWebFragment.java:1093–1133`。还原源码仍有 65 个文件、295 处行首 `??` 占位（仅为静态计数，不代表全部语义错误）。已修复类的原始源码备份和每批日志位于 `build/evidence-deps/`；这些局部恢复只允许继续编译诊断，不证明行为等价。

### r22–r26 还原构建快照（2026-08-31）

以下结论来自同一 `.wakeup-restoration/` 候选，均属于**已确认的编译证据**，不等同于运行时行为证明：

1. r22 依据 `AddCourseActivity` smali 中 `ArrayList<Integer>` 的创建和调用签名恢复 `OoooO2` 声明；`AddCourseActivity.java:553` 不再出现在首批错误。
2. r23 依据 DAO 实现类 `o00O0O` 的接口、字段和方法描述符恢复 `dao/OooO0O0.java` 局部声明与显式转换；DAO 首批错误不再出现。
3. r24 依据分享协程 smali 的 `o00oO0o`/`int` 寄存器及异常控制流恢复 `ScheduleActivity$shareScheduleOnline$1.java`；该协程错误不再出现。
4. r25 依据 `LoginWebFragment$refreshCode$1.smali` 的 `L$0/L$1` 字段和 `check-cast` 恢复 Bitmap、byte[]、String、TextInputEditText 局部，并为学校名称截取结果补上确定赋值；该协程错误不再出现。日志：`build/evidence-deps/wakeup-restoration-compile-20260831-r25.log`。
5. r26 完整 `:app:assembleDebug --rerun-tasks` 的资源、Manifest、重复类、签名配置和 `processDebugResources` 通过；`compileDebugJavaWithJavac` 仍失败，Javac 输出 100 个错误和 3 个 Java 8 source/target 警告，当前首批错误集中在 `schedule_import/LoginWebFragment.java:1093–1169` 的 `??` 声明。日志：`build/evidence-deps/wakeup-restoration-assemble-20260831-r26.log`。

当前静态统计为 61 个 Java 文件、281 处行首 `??` 占位；这是还原工作量指标，不是全部编译错误数量。所有 r22–r25 修改均保留 `build/evidence-deps/source-before-*` 备份。下一轮必须先从 `LoginWebFragment.java` 对应方法的 smali/字段描述符恢复一个独立错误组；证据不足时保持阻塞，不使用全局类型替换、假类或删除旧功能。

1. WakeUp 6.0.23 真实导出的普通、单双周、自定义时间、空课表和多作息 `.wakeup_schedule` 样本。
2. 至少两个更早版本的真实导出，用于确认缺字段、默认值和行数差异。
3. v7、v8、v9、v10、v11 脱敏数据库及对应 Preferences 快照，用于回放迁移副作用。
4. 损坏、截断、非法日期、重复主键、跨表引用错误和未知尾行样本。
5. 可正常启动 WakeUp 的设备或模拟器，用于导入预览、失败原子性、Widget 点击、提醒取消和重启恢复验证。
6. Provider 第三方调用方的实际 Cursor 样本；旧账号/网络导入需要合法测试账号与可访问服务。
