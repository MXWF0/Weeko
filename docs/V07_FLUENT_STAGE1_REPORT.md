# Weeko v0.7 Fluent UI Stage 1 报告

日期：2026-09-06（Asia/Shanghai）  
状态：Stage 1 已完成；本阶段只审计调用链、冻结视觉规范并完成基线构建/设备验证，未修改业务或 UI 实现。

## 目标与成功标准

本轮迁移的目标是让 v0.7 顶部 UI 逐步采用 Fluent 风格，同时保留现有 Android View 动态布局和 WakeUp 行为母体。Stage 1 的成功标准是：

- 入口、菜单、覆盖层和周 UI 的现有调用链可追溯到反编译证据；
- 明确下一阶段可执行的颜色、排版、触控、图标、动效和无障碍契约；
- 基线 APK 可以重建、安装并冷启动，设备 UI 树和截图可复核；
- 不在审计阶段改动课程数据、导入导出、提醒、Widget 或周算法。

## 验证方法与基线

静态审计使用 v0.7 Stage 6 的 apktool 输出 `build/v0.7/repro-apktool-stage6`，重点检查 `ScheduleActivity`、动态绑定器 `o00000`、点击分发器 `o00oO0o`/`o0OOO0o` 及 Material3 主题资源。运行基线由 [`tools/build-weeko-v07-stage6-debug.ps1`](../tools/build-weeko-v07-stage6-debug.ps1) 重建：

| 项目 | 结果 |
| --- | --- |
| APK | [`Weeko-v0.7.0-stage6-debug.apk`](../build/v0.7/Weeko-v0.7.0-stage6-debug.apk) |
| 包 / 版本 | `io.github.mxwf.weeko` / `versionCode=7` / `versionName=0.7.0-stage6` |
| SHA-256 | `BFE5FD7FD65D5CE383D4A26304A70D457FD63E8E4BAE8DE648B76B016DC1BD0A` |
| 构建与签名 | apktool 重组、zipalign、`apksigner verify` v1/v2/v3 均通过；debug 签名，仅作验证包 |
| 设备 | `3fde7e33`，`1220×2712`，Android density `480`（3×） |
| 冷启动 | 清空本轮 logcat 后启动 `ScheduleActivity`；未出现新增 FATAL 或 ANR |

主页面基线 UI 树：[`device-ui-v08-fluent-stage1-main.xml`](../build/v0.8/device-ui-v08-fluent-stage1-main.xml)；对应截图：[`v08-fluent-stage1-main.png`](../build/v0.8/v08-fluent-stage1-main.png)。菜单和日期入口证据保存在：

- 左侧菜单：[`device-ui-v08-fluent-stage1-left.xml`](../build/v0.8/device-ui-v08-fluent-stage1-left.xml)、[`v08-fluent-stage1-left.png`](../build/v0.8/v08-fluent-stage1-left.png)；
- 右侧菜单：[`device-ui-v08-fluent-stage1-right.xml`](../build/v0.8/device-ui-v08-fluent-stage1-right.xml)、[`v08-fluent-stage1-right.png`](../build/v0.8/v08-fluent-stage1-right.png)；
- 日期入口：[`device-ui-v08-fluent-stage1-date.xml`](../build/v0.8/device-ui-v08-fluent-stage1-date.xml)、[`v08-fluent-stage1-date.png`](../build/v0.8/v08-fluent-stage1-date.png)。

## 调用链审计

### 顶部入口

| 入口 | 现有绑定 | 当前行为 | 下一阶段目标 |
| --- | --- | --- | --- |
| `weeko_nav_left` | `ScheduleActivity.onCreate` → `o00oO0o(8)` | 打开旧三项左菜单 | 保留入口，改为“修改当前周 / 切换/管理课表 / 调整上课时间” |
| 日期 `anko_tv_date` | `o00oO0o(8)` | 与左侧导航共用旧菜单；设备点击已复现 | 日期直接回到当前周，不再打开左菜单 |
| 周数 `anko_tv_week`、星期 `anko_tv_weekday` | `o00oO0o(8)` | 与日期共用同一分发代码 | 保留周浏览语义，视觉上归入周 rail；不复制周状态 |
| `anko_ib_add` | 既有点击分支 `6` | 进入 `AddCourseActivity` | 保持不变 |
| `anko_ib_import` | 既有点击分支 `3` | 打开原有导入菜单 | 保持不变 |
| `anko_ib_more` | `o00oO0o(12)` | 打开右侧四项菜单 | 保持入口，使用 Fluent command surface |

证据位置：[`ScheduleActivity.smali`](../build/v0.7/repro-apktool-stage6/smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali) 的顶部 listener 注册段、[`o00000.smali`](../build/v0.7/repro-apktool-stage6/smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali) 的动态控件构造段。Stage 6 已移除旧底栏点击 listener；本阶段不重新引入底栏入口。

### 菜单与 Intent 分发

现有左菜单由 [`o00oO0o.smali`](../build/v0.7/repro-apktool-stage6/smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali) 默认分支构建：`weeko_nav_adjust_week` → callback `8`，`weeko_nav_switch_manage` → callback `11`，`main_back_to_current_week` → callback `9`。设备实测文案为“调整周数 / 切换/管理课表 / 回到当前周”，面板为 `[12,161][600,593]`，每行高 `144 px = 48 dp`。

右菜单由同一文件的 `stage1ShowRightMenu` 构建：`多课表管理` → `11`，`分享` → `12`，`全局设置` → `13`，`关于 Weeko` → `14`；面板为 `[620,161][1208,737]`，同样为 `48 dp` 行高。[`o0OOO0o.smali`](../build/v0.7/repro-apktool-stage6/smali/com/suda/yzune/wakeupschedule/schedule/o0OOO0o.smali) 记录了分发差异：

- callback `11` 当前启动 `ScheduleManageActivity`，并附带 `selectedTableId`，因此是当前课程表上下文的课程列表模式；
- callback `12` 回调既有分享菜单；`13` 启动 `SettingsActivity`；`14` 启动 `AboutActivity`；
- 原 callback `8` 进入 `ScheduleSettingsActivity`，callback `9` 将 `ViewPager2` 定位到当前周。

下一阶段必须先拆分“日期直接回当前周”和“导航菜单”的入口，再改文案与路由：左侧第二项的多课表入口不能复用带 `selectedTableId` 的右侧当前课程表入口；右侧第一项目标文案为“课表管理”，并进入既有 `ScheduleSettingsActivity`。分享、设置、关于和导入的业务链保持原样。

### 当前控件尺寸与覆盖层边界

主页面 UI 树的关键 bounds 为：`weeko_nav_left [0,161][96,257]`、日期 `[144,141][402,221]`、周数 `[144,221][269,277]`、星期 `[293,221][377,277]`、加号 `[716,161][812,257]`、导入 `[908,161][1004,257]`、更多 `[1100,161][1196,257]`；课程周视图 `anko_vp_schedule [0,289][1220,2712]`。因此当前顶部图标的可点击区域是 `96 px = 32 dp`，低于 Fluent 目标的 `48 dp` 最小触控区；日期文本区也与图标纵向节奏不一致。

日期点击当前确实打开左侧三项菜单，证据为 [`test-date2.xml`](../build/v0.8/test-date2.xml) 和 [`test-date2.png`](../build/v0.8/test-date2.png)。动态绑定器仍构造隐藏的 `bottom_sheet_slider_week`（Material `Slider`，步长为 1、标签格式化器和原有 thumb/track 参数），但当前 UI 树没有 `anko_bottom_sheet` 或 `bottom_sheet` 节点。它是既有周状态 UI 的边界，不应在 Fluent 迁移中复制一套周数据或改变步长/索引算法。

## Fluent 视觉规范（Stage 1 冻结）

### 设计对象

顶部区域服务于“快速扫描本周课程”和“快速到达操作”。层级顺序固定为：日期（主锚点）→ 周数/星期（当前浏览状态）→ 左右命令入口。颜色表达状态，不能代替文字；图标表达动作，不能代替可访问名称。

### 颜色与层级

沿用 `Theme.MyApp` 已有 Material3 角色，不新增硬编码颜色：

| 用途 | 角色 |
| --- | --- |
| 页面/顶部基底 | `colorSurface` / `colorSurfaceContainer` |
| 菜单和浮层 | `colorSurfaceContainerHigh`，必要时配合 `colorSurfaceContainerHighest` |
| 主文字 | `colorOnSurface` |
| 次文字、星期 | `colorOnSurfaceVariant` |
| 当前周/选中状态 | `colorPrimaryContainer` + `colorOnPrimaryContainer` |
| 操作图标、焦点边界 | `colorPrimary`、`colorOutlineVariant` |

现有 light token 实际为 `#FAF8FF` 基底、`#EEEDF4` surface container、`#E9E7EF` high container、`#1A1B21` on-surface、`#45464F` on-surface-variant、`#4C5C92` primary、`#DCE1FF` primary-container。dark 主题继续从同名角色解析，组件不得绕过主题直接写颜色。

### 顶部栏、排版与触控

- 顶部栏按状态栏 inset 后使用 `64 dp` 视觉高度；左右命令各占至少 `48×48 dp` hit target，图标视觉尺寸 `24 dp`，相邻命令间保留 `8 dp` 间距。
- 日期使用 `20 sp`、粗体/标题字重；周数和星期使用 `16 sp`；菜单命令使用 `16 sp`；辅助说明使用 `14 sp`。字体沿用系统 SansSerif，不引入新字体文件。
- 日期/周 rail 是一个可读的组合区域，文本不得被图标 hit target 挤压；长本地化文案允许换行或扩大区域，但不能缩小触控区。
- 所有可操作项均有中文 `contentDescription`/可读 label、焦点态和按下态；文字放大、深色主题和 TalkBack 不依赖截图中的颜色差异。

### 菜单与覆盖层

- 左右菜单都使用锚定 command surface：`48 dp` 最小行高、`24 dp` 图标、`16 dp` 文本、`16 dp` 水平内边距；菜单圆角 `16 dp`，低而明确的 `4 dp` elevation，边界使用 `outlineVariant` 或色阶差，不使用黑色描边。
- 按下态使用主题角色的约 `12%` 状态层；打开菜单时保留轻微 scrim，点击外部或返回键关闭，焦点顺序从锚点进入第一项并可回到锚点。
- 需要承载周选择或时间编辑的 bottom sheet 使用 `surfaceContainerHigh`、顶部 `28 dp` 圆角和同一 scrim；sheet 内部继续调用现有周/时间状态，不把视觉组件变成新的数据源。
- 菜单/对话框的进入退出动效为 `180–240 ms`，只表现层级变化；不在浮层动画中修改课程、周索引或 Intent 参数。

### 图标契约

继续使用现有 vector 资源并为每个动作补齐语义名称：左侧导航为 menu/navigation，右侧更多为 more-vert，新增课程为 add，导入为 file-download/import；菜单项使用 schedule/table、share、settings、info、calendar-week/time 等既有语义图标。禁止以 emoji、字形字符或临时位图代替图标；24 dp 图标应保持统一光学重心和 `colorOnSurfaceVariant`/`colorPrimary` 规则。

### 周 rail 与动效

周 rail 的唯一状态仍是既有整数周索引和 `ViewPager2` 周页。拖动只改变浏览周，不写入课程数据；释放后用 `180–240 ms` 的轻量 morph 连接周数/星期显示，空闲约 `3 s` 后恢复星期行；再次进入 rail 时重新启动计时器。周切换的步长、当前周计算、提醒、Widget 和持久化不改动。隐藏的既有 `Slider` 仅作为后续视觉替换的状态边界，Stage 2–5 不得复制第二套算法。

## 后续阶段与护栏

1. Stage 2：先拆分日期直达与菜单路由，校准左/右菜单文案和 Intent 参数；用 UI Automator 和 logcat 验证返回栈。
2. Stage 3：按本报告 token、64 dp 顶部栏和 48 dp hit target 重排动态 View；验证导入、加课和深色主题。
3. Stage 4：统一左右 command surface、bottom sheet/dialog 的圆角、状态层、scrim 和焦点顺序；验证分享、设置、关于和时间表入口。
4. Stage 5：实现周 rail 的视觉 morph 与空闲恢复，随后做课程数据、导入导出、提醒、Widget、深色模式和冷启动回归。

每阶段只改动该阶段所需的最小 smali/资源片段，先重放脚本再构建 debug APK；任何阶段若触及周索引、数据库、导入格式、Alarm/WorkManager 或 Widget receiver，必须停止并回到调用链审计。成功条件是静态 diff 可解释、APK 可安装、目标 UI 树可复现且无新增 FATAL/ANR。

## Stage 1 结论

Stage 1 的基线构建、冷启动、入口/菜单设备证据、静态调用链审计和 Fluent 视觉规范均已完成。当前实现仍是迁移前基线：顶部图标为 `32 dp` hit region，日期会打开旧左菜单，左右菜单仍保留旧文案；这些是后续阶段的明确待办，不应被误读为 Fluent 改造已经完成。本阶段到此停止，不提交任何业务实现改动。
