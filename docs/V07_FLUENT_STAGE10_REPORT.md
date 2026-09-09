# Weeko v0.7 Fluent UI Stage 10

范围：继续收紧主课表页顶栏的水平节奏，并微调周数 rail 的 Fluent 表面；课程数据、课表算法、设置、导入导出、提醒和 Widget 未修改。

## 设计与实现

左侧导航与日期/周次数据信息整体左移 16dp（设备 density=3 时为 48px），保留导航按钮的完整点击热区。右侧新增、导入、更多三个命令按钮固定右边界，按钮之间的视觉间距从 8dp 收紧为 6dp。日期、周次、星期仍按同一条紧凑水平节奏排列，课表起点保持在压缩后的 y=293。

周数 rail 增加 SeekBar 非活动轨道 tint，保留半透明 Fluent 表面，圆角为 16dp、elevation 为 4dp，并使用 secondary 色承载周数标签与非活动轨道。

## 修改文件

- `tools/replay-weeko-v08-fluent-stage10-patches.ps1`
- `tools/build-weeko-v08-fluent-stage10-debug.ps1`
- `docs/V07_FLUENT_STAGE10_REPORT.md`

## 构建与验收

- APK：`build/v0.8/Weeko-v0.7.0-fluent-stage10-debug.apk`
- 包名/版本：`io.github.mxwf.weeko` / `0.7.0-fluent-stage10`（versionCode 7）
- SHA-256：`99C3F94A38252E38F8903288103DCE049CDE08DF709F502B8932235C7F33EF0F`
- 主界面截图：`build/v0.8/fluent-stage10-main.png`
- 主界面 bounds：`build/v0.8/fluent-stage10-main.xml`

真机 `3fde7e33`（22081212C，1220×2712，density=3）安装返回 `Success`，显式冷启动进入 `io.github.mxwf.weeko/com.suda.yzune.wakeupschedule.schedule.ScheduleActivity`。主界面关键 bounds：导航 `[0,127][144,271]`，日期 `[144,141][430,221]`，周次 `[144,221][300,281]`，星期 `[324,221][432,281]`，新增 `[728,127][872,271]`，导入 `[890,127][1034,271]`，更多 `[1052,127][1196,271]`，课表 `[0,293][1220,2712]`。三个右侧命令热区之间均为 18px（6dp）间隔，右边界保持 x=1196。

补丁与构建脚本 PowerShell 解析错误均为 0；APK 已通过 apktool 重建、zipalign、v1/v2/v3 签名和 aapt2 元数据校验。周数 rail 的交互与自动收起逻辑沿用 Stage 9，Stage 10 仅改变其 tint、圆角和 elevation。
