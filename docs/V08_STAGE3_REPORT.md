# Weeko v0.8 Stage 3：设置扁平化与全局视觉统一报告

日期：2026-09-10  
范围：Stage 3 设置中心、全局图标与主题、课程表 Fluent 2 调色、竖屏约束；未开始 Stage 4。

## 结论

Stage 3 已把原有多层设置入口压缩为单页设置控制台，按“外观、课程表显示、提醒与后台、桌面与语言、数据与更多”五组纵向展示。原设置对象、Preference key、系统 Intent 和业务处理器保持不变；动态颜色、空状态图片、通知权限与课程日期转移改为单击直达对应的原高级设置内容，不再要求用户先进入分类页。

本轮进一步将用户提供的图像设为应用全局图标，以图像中的暖象牙白、蓝灰和珊瑚色建立静态主题调色盘。主题色资源同时提供亮色与深色版本，课程表页新增主题感知的背景、表头、网格、课程块与文字处理，原课程颜色经主题表面色混合后继续保留区分度。Android 12 以上原有动态颜色开关仍然有效。

所有 Weeko 自有 Activity 均锁定为竖屏，原 `ClockActivity` 的 `sensorLandscape` 已移除。按用户要求，本轮以及后续不再进行横屏测试。

## 设置结构

| 分组 | 内容 |
| --- | --- |
| 外观 | 显示主题、动态颜色直达入口 |
| 课程表显示 | 当前课表、底部留白、空状态开关、错误提示、空状态图片直达入口 |
| 提醒与后台 | 通知与提醒直达入口、自启动、电池优化 |
| 桌面与语言 | 桌面小组件、语言 |
| 数据与更多 | 网页缓存、隐私政策与用户协议、按日期转移课程直达入口 |

设置页只重排既有对象，没有复制状态或引入新存储。主题对话框、语言对话框、精确提醒系统页、电池优化系统页以及四个高级设置直达入口均继续使用原实现。

## 视觉实现

图标原文件保存在 `assets/weeko-launcher.png`，SHA-256 为 `C80A35B21C459C412606D22CEFE1332D9F80117DE609BAA788535CFBFB347094`。构建脚本校验该哈希后，将同一图像写入传统与自适应图标资源；启动页和关于页也引用更新后的图标。没有重新绘制或改变用户提供的图像。

静态主题的三个基准采样色为：暖象牙白 `#FCFAF0`、蓝灰 `#678192`、珊瑚 `#E77459`。可访问控件使用同色相的较深或较浅层级以维持文字对比度。深色主题使用 `#10181D` 作为主背景，并提供对应的 Surface、Container、Outline、On Surface、Primary、Secondary 和 Tertiary 层级。浴室卡片和列表加载提示中遗留的固定黑字已改为主题文字色；桌面课程卡片通过 `drawable-night` 获得独立的深色层级，避免 RemoteViews 不继承 Activity 主题时仍显示白底。

课程表运行时从当前主题属性解析颜色：主背景和分页容器使用 Surface；顶部区域使用 Surface Container Low；日期、节次和时间文字使用 On Surface Variant；粗体日期使用珊瑚色系 Tertiary 作为强调；网格线使用半透明 Outline Variant。课程块保留原课程色，但分别与亮色或深色 Surface Container High 混合，文字和描边改用主题色，因此不会在深色模式中保留亮底黑字。

## 修改文件

| 文件 | 内容 |
| --- | --- |
| `.gitignore` | 允许纳入作为正式构建输入的图标 PNG |
| `assets/weeko-launcher.png` | 用户提供的原始图标副本 |
| `tools/replay-weeko-v08-settings-stage3-patches.ps1` | 设置扁平化、图标、主题色、课程表运行时调色和竖屏 Manifest 补丁 |
| `tools/build-weeko-v08-settings-stage3-debug.ps1` | 从干净 apktool 母体重建、注入原 DEX、对齐、签名与校验 |
| `docs/V08_STAGE3_REPORT.md` | 本阶段实现与验证记录 |

## 构建与静态验证

构建脚本从 `build/v0.6/repro-apktool` 复制干净母体，顺序重放既有补丁链、Stage 2 和 Stage 3，再执行 apktool 重建、原 DEX 注入、zipalign、debug 签名、签名校验和 badging 校验。

产物：`build/v0.8/Weeko-v0.8.0-settings-stage3-debug.apk`  
包名：`io.github.mxwf.weeko`  
版本：`versionCode 9`，`versionName 0.8.0-settings-stage3`  
大小：7,948,008 bytes  
SHA-256：`EFD6A633A483E4E15A0D981CB6639BB1D212AF06CF5FB008374889283E0950DE`

资源编译和 smali 汇编通过。Manifest XML 解析确认 19 个 Weeko 自有 Activity 全部为 `screenOrientation="portrait"`，且不存在 landscape 声明。构建后的 drawable 图像与源图 SHA-256 完全一致，传统 mipmap 通过 XML 直接引用同一图像，不产生第二份位图。zipalign 校验通过，apksigner 的 v1、v2、v3 校验均通过。连续两次从干净母体重建得到相同的 APK SHA-256。

## 实机验证

最终 APK 已通过 `adb install -r` 覆盖安装到设备 `3fde7e33`，未清除应用数据。冷启动正常进入 `ScheduleActivity`，亮色与深色课表均保留原课程数据；课程块在亮色下使用柔和主题混色，在深色下切换为深色容器并使用浅色文字，日期、节次、网格和页面背景均随主题变化。两次实测冷启动耗时分别为 865 ms 和 717 ms。

设置中心在系统深色下五组卡片层级、正文、说明文字、复选框与滚动区域显示正常。将设备临时调整为 360dp 小宽度并叠加 1.3 倍字体后，设置项正常换行、没有横向溢出或控件重叠。系统应用信息页显示了新的 Weeko 图标，版本为 `0.8.0-settings-stage3`。运行期间窗口配置始终为 `SCREEN_ORIENTATION_PORTRAIT`、`ROTATION_0`，没有进行横屏测试；logcat 未发现 Weeko 的 `FATAL EXCEPTION` 或 ANR 标记。

验收结束后，设备已恢复为 1220×2712 物理尺寸、1.0 字体比例和原浅色模式，应用停留在正常课表首页。

## 边界

本阶段没有改变课程、课表、作息或设置数据，没有申请权限，没有实际添加桌面小组件，也没有移除用户的课程颜色自定义能力。外部 SDK Activity 保留厂商声明；竖屏约束仅作用于 Weeko 自有界面。
