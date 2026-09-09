# Weeko v0.7 Fluent UI Stage 9

范围：再次调整主课表页左上日期、周数和星期的排版，并压缩顶栏高度。课程数据、课表算法、设置、导入导出、提醒和 Widget 未修改。

## 设计与实现

本轮以原版课表顶栏为尺寸基准：日期恢复为 20sp 粗体主信息，周数与星期恢复为 14sp 常规字重并排显示。日期使用 `colorOnSurface`，周数与星期使用 `colorOnSurfaceVariant`，保留现有 Fluent 色彩语义。

左侧导航继续保留 48dp 点击区域。文字容器从导航区域结束处开始，依靠 4dp 内边距形成可见间隔；导航、文字块和右侧操作按钮重新居中于同一紧凑顶栏。周数 rail 同步上移，与压缩后的星期栏对齐。

## 尺寸对照

| 项目 | 原版 | Stage 8 | Stage 9 |
| --- | --- | --- | --- |
| 日期高度 | 80px | 84px | 80px |
| 周数行高度 | 56px | 88px | 60px |
| 课程表起点 | y=289 | y=325 | y=293 |

Stage 9 与原版课程表起点仅相差 4px，同时容纳新增的左侧导航按钮。

## 修改文件

- `tools/replay-weeko-v08-fluent-stage9-patches.ps1`
- `tools/build-weeko-v08-fluent-stage9-debug.ps1`
- `docs/V07_FLUENT_STAGE9_REPORT.md`

## 构建与验收

- APK：`build/v0.8/Weeko-v0.7.0-fluent-stage9-debug.apk`
- 包名/版本：`io.github.mxwf.weeko` / `0.7.0-fluent-stage9`（versionCode 7）
- SHA-256：`27B96669A8EA8C9EDAE80523483ABE26F25E7ECA0C4F6D915B7E9F00880CD0DE`
- 主界面截图：`build/v0.8/fluent-stage9-main.png`
- 周数 rail 截图：`build/v0.8/fluent-stage9-rail.png`
- 主界面 bounds：`build/v0.8/fluent-stage9-main.xml`
- 周数 rail bounds：`build/v0.8/fluent-stage9-rail.xml`

真机主界面 bounds：日期 `[192,141][479,221]`，周数 `[192,221][348,281]`，星期 `[372,221][480,281]`，导航 `[48,127][192,271]`，课程表 `[0,293][1220,2712]`。rail 的 SeekBar bounds 为 `[264,300][1172,444]`。

周数点击保持当前周且不打开旧弹窗；星期点击打开 rail。补丁与构建脚本 PowerShell 解析错误均为 0；APK 已通过 zipalign、v1/v2/v3 签名和元数据校验，真机安装包哈希与构建产物一致。
