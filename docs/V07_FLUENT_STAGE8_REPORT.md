# Weeko v0.7 Fluent UI Stage 8

范围：继续重做主课表页顶栏、左上日期/周次信息区和周数 rail。课程数据、课表算法、设置存储、导入导出、提醒和 Widget 未修改。

## 设计与实现

顶栏沿用现有 Fluent 色彩语义，将日期与星期降为 14sp 次要信息，周次提升为 22sp 粗体主信息。三项文字使用 28dp 紧凑行高和 4dp 横向内边距；导航和右侧操作仍保留 48dp 点击热区，并整体上移到同一视觉基线。左侧信息继续从统一起点排列，不与导航按钮或星期栏重叠。

周数 rail 改为 52dp 高的单行浮层，范围为 `[0,324][1220,480]`，与星期栏 `[98,325][252,479]` 的纵向区间一致。周次标签位于左侧，SeekBar 保留 48dp 高拖动区域。浮层不再隐藏顶栏日期、周次和星期。

滑块调整后的周次会保留：真机从第 2 周拖到第 12 周，rail 自动收起后仍显示第 12 周。用户主动点击顶栏周次时才返回第 2 周，不打开旧周数弹窗。

## 修改文件

- `tools/replay-weeko-v08-fluent-stage8-patches.ps1`
- `tools/build-weeko-v08-fluent-stage8-debug.ps1`
- `docs/V07_FLUENT_STAGE8_REPORT.md`

## 构建与验收

- APK：`build/v0.8/Weeko-v0.7.0-fluent-stage8-debug.apk`
- 包名/版本：`io.github.mxwf.weeko` / `0.7.0-fluent-stage8`（versionCode 7）
- SHA-256：`1B055632E61E7BE9E128B109769AAB7E1B2F850405E14481E48ED4966FA88F01`
- 主界面截图：`build/v0.8/fluent-stage8-final-main.png`
- rail 拖动截图：`build/v0.8/fluent-stage8-final-drag.png`
- rail bounds：`build/v0.8/fluent-stage8-final-rail.xml`
- 周次保留：`build/v0.8/fluent-stage8-final-persist.xml`
- 手动返回本周：`build/v0.8/fluent-stage8-final-return.xml`
- 直接点击周次回归核验：`build/v0.8/weeko-rebuilt-week-tap.xml`
- 点击星期打开 rail 核验：`build/v0.8/weeko-rebuilt-weekday-tap.xml`

补丁与构建脚本 PowerShell 解析错误均为 0；修正了首次直接点击周次时未记录当前周数的问题，并重新构建 APK。APK 已通过 zipalign、v1/v2/v3 签名和元数据校验。真机安装后未出现 `FATAL EXCEPTION`。

## 清理结果

`build/v0.8` 已从约 3.6GB 的多阶段解包目录、重复 APK 和调试证据收敛到 6.7MB，只保留 Stage 8 最终产物和验收证据。被清理内容暂存于 `build/_cleanup_quarantine_20260907_stage8`，可恢复；永久删除需要单独确认。
