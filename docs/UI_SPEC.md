# Weeko Design System 规范

最后更新：2026-08-31（Asia/Shanghai）

> 路线纠偏：本文记录的是先前误建 Weeko-native 工程的 UI 方案，当前仅作历史资料保存。WakeUp 6.0.23 还原母体尚未建立；在母体可编译、可安装并完成行为基线前，暂停 Compose、Design System、课程详情和任何页面替换。本文件不授权创建第二套页面或迁移 UI。

## 阶段 3 范围（历史记录，当前冻结）

本阶段只建立 Compose 与传统 View/XML 共存所需的设计系统和独立测试页，不替换核心课程表，不引入 Room、DataStore、ViewModel 或新的业务页面。传统页面仍然可以继续运行；Compose 通过独立 Activity 验证接入方式。

## 主题与颜色

Weeko 使用低饱和蓝色作为基础品牌色。`WeekoTheme` 默认使用固定的 Weeko Light/Dark `ColorScheme`，并保留 `dynamicColor` 可选参数。只有调用方明确传入 `dynamicColor = true` 且系统为 Android 12（API 31）或更高版本时，才使用 Material You 动态颜色。

课程卡片不使用 `primary` 或动态主题色推导颜色。`WeekoCoursePalette` 提供稳定的 Blue、Sage、Amber、Plum、Coral 基础色，`WeekoCourseCard` 直接使用传入颜色，并根据亮度选择可读的前景色，因此浅色/深色系统主题不会改变课程本身的颜色语义。

Compose 与 XML 主题保持平行：传统 View 使用资源主题 `Theme.Weeko`，Compose 页面在根部包裹 `WeekoTheme`。两者共享品牌方向，但不要求在本阶段把 XML 颜色资源映射成 Compose 业务状态。

## 设计令牌

| 类别 | 当前约定 |
| --- | --- |
| 字体 | SansSerif；display 36/44sp，headline 24/32sp，title 22/28sp 或 16/24sp，body 16/24sp、14/20sp，label 14/20sp |
| 形状 | extraSmall 8dp、small 12dp、medium 16dp、large 24dp、extraLarge 28dp |
| 间距 | xxs 4dp、xs 8dp、sm 12dp、md 16dp、lg 24dp、xl 32dp、xxl 48dp；页面边距 20dp，区块间距 24dp |
| 触控 | 按钮和图标按钮最小触控尺寸 48dp |
| 表面 | 页面使用 `surface`，普通卡片默认使用 `surfaceContainerLow`；避免页面散落硬编码阴影和渐变 |

令牌集中在 `WeekoTheme.kt`。页面不应直接复制颜色和间距常量；如果未来出现新的重复语义，先扩展令牌再使用。

## 通用组件

组件位于 `app/src/main/java/io/github/mxwf/weeko/designsystem/WeekoComponents.kt`：

| 组件 | 用途 |
| --- | --- |
| `WeekoButton` / `WeekoOutlinedButton` | 主要和次要操作，遵循 48dp 最小高度 |
| `WeekoCard` | Tonal Surface 卡片，可选点击行为，内容使用 `ColumnScope` |
| `WeekoCourseCard` | 使用稳定课程颜色的课程信息卡片 |
| `WeekoDialog` | 带确认/取消操作的 Material 3 对话框 |
| `WeekoBottomSheet` | 课程详情等渐进式内容的 Modal Bottom Sheet |
| `WeekoToolbar` | Material 3 顶部栏，可选返回按钮和操作区 |
| `WeekoEmptyState` | 图标、标题、说明和可选操作的空状态 |
| `WeekoLoading` | 进度指示器，带合并后的加载语义和可选说明 |

组件只处理呈现和交互回调，不访问数据库、Preferences、网络或 WakeUp 适配器。课程卡片的颜色由调用方/未来领域模型决定，不由主题重写。

## 阶段 4A/4B 课程详情

`feature/coursedetail` 当前包含纯展示组件、真实数据 Route 和 Preview-only 样例：

- `CourseDetailUiState` 是 `@Immutable` sealed interface，包含 `Loading`、`Content`、`NotFound` 和 `Error`；`Content` 字段为课程名、稳定课程颜色、教室、教师、星期、时间、节次、周次和备注。
- `CourseDetailBottomSheet` 是无业务状态的纯回调组件，接收 `onDismissRequest`、`onEdit` 和 `onDelete`；它不访问数据层，也不执行删除事务。
- 使用 Material 3 `ModalBottomSheet`、`extraLarge` 圆角、低 Tonal Elevation 和可滚动内容。课程名、教室优先展示，教师/时间次之，节次、周次和备注作为补充信息。
- 空备注不显示空卡片；长文本自然换行并可滚动。删除动作使用主题 `error` 色，确认由上层 `WeekoDialog` 负责。
- 示例只放在 `CourseDetailPreviewSamples`，供四个 Preview 和 `CourseDetailPreviewActivity` 使用，不进入正式数据入口。

`CourseDetailRoute` 是真实数据的 presentation 入口：只接收已经按课程 ID 构造的 `CourseDetailViewModel`，收集 StateFlow 和一次性事件，并把 `Content` 交给 Bottom Sheet。ViewModel 通过 `CourseDetailRepository` 读取 `CourseDetailRecord`，删除确认后调用同一 Repository 的级联删除；Compose 层不访问 Room、Preferences、网络或 WakeUp adapter。当前 Route 尚未被课程表页面调用，编辑事件也只能转发给未来的编辑入口。

当前 `MainActivity` 支持 `EXTRA_COURSE_ID` 作为正式宿主契约：不带参数时保持传统基线页面，带参数时在同一 Activity 中显示真实课程详情 Bottom Sheet；编辑事件打开应用内 `CourseEditorActivity`，只传课程 ID，保存后返回详情页。该契约不传递完整实体，也不把 Preview 样例带入生产入口。

## 课程编辑页

`CourseEditorRoute` 是编辑已有课程的全屏 Compose 页面，按“基础信息、上课时间与周次、外观、提醒、备注”分组。课程名、课程号、学分、教师、教室、星期、起止节次、离散周次、自定义时间、稳定颜色和备注均映射到真实 Weeko 模型；上课安排支持新增和移除，保存由 `CourseEditorViewModel` 校验后交给 `CourseEditorRepository` 的单事务更新。提醒区目前只说明 Reminder 模型尚未接入，不提供虚假的开关。

编辑器接收的参数仍只有 `EXTRA_COURSE_ID`。取消通过 ViewModel 事件返回，保存成功后 Activity 结束，详情页由 Room Flow 自动刷新。添加新课程需要先有课表选择和稳定的 scheduleId 调用方，当前不伪造添加入口。

## 混合接入方式

当前入口保持传统 View Activity：

```text
MainActivity（android.app.Activity + LinearLayout/TextView/Button）
  └─ 显式 Intent → DesignSystemPreviewActivity（ComponentActivity + setContent）
                              └─ WeekoTheme → WeekoDesignSystemGallery
```

`DesignSystemPreviewActivity` 在 Manifest 中为 `exported=false`，只由应用内部入口打开。没有删除或替换旧 XML；当前最小工程没有可复用的 WakeUp XML 源码，因此先以传统 View 基线验证共存。未来替换单个页面时，可以在原 Fragment 中使用 `ComposeView`，或在 Compose 中使用 `AndroidView`，但必须继续复用现有数据边界并单页验收。

## 预览与测试页

`DesignSystemGallery.kt` 提供独立 `WeekoDesignSystemGallery`，运行时包含：Tonal Surface Card、课程卡片、Dialog、Bottom Sheet、Empty State 和 Loading。课程详情原型另外提供独立测试 Activity。文件同时提供 375×812 的浅色预览、深色预览和 812×375 的横屏预览；课程详情文件提供浅色、深色、长文本和空备注四个 Preview。

真机验证通过应用首页的“打开设计系统预览”按钮进入测试页；UIAutomator 已观察到 `组件预览`、`高等数学`、`显示 Dialog`、`显示 Sheet`、`还没有课程` 和 `加载本地课表…`，并实际打开过 Dialog 与 Bottom Sheet。

## 可访问性与后续约束

- 图标按钮提供内容描述；空状态中的装饰图标不重复读出。
- Loading 容器提供合并的“正在加载”语义，避免读屏逐个朗读内部实现。
- 信息不能只靠颜色表达；课程卡片必须同时保留课程名、时间、教室等文字信息。
- 后续页面需要在浅色、深色、动态字体、横竖屏和系统安全区下复核；本阶段只建立令牌和预览覆盖。
- 当前不实现课程表、今日页、导入导出、提醒持久化、Widget 或设置页面；课程详情和编辑已有课程已接入真实数据，课程表调用方、添加新课程和 Reminder 仍待后续阶段。
