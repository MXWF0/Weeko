# Weeko v0.7 Fluent UI Stage 7

范围：重新整理主课表页左上角布局，只改变顶部导航与日期/周次/星期的视觉位置；课程、周次算法、设置存储、导入导出、提醒和 Widget 均不改动。

## 布局调整

左上角现在是一个明确的两层信息块：导航按钮保留 48dp 点击热区并固定在 16dp 起始边距；日期、周次和星期统一向右 16dp，形成 64dp 的共同信息起点。周次仍使用主要信息层级，日期与星期保持次要字号和颜色。右侧操作组、星期栏和周数 rail 沿用 Stage 6 的紧凑 Fluent 规则。

## 可重复构建

- 补丁：[`tools/replay-weeko-v08-fluent-stage7-patches.ps1`](../tools/replay-weeko-v08-fluent-stage7-patches.ps1)
- 构建：[`tools/build-weeko-v08-fluent-stage7-debug.ps1`](../tools/build-weeko-v08-fluent-stage7-debug.ps1)
- 产物：`build/v0.8/Weeko-v0.7.0-fluent-stage7-debug.apk`
- 包名/版本：`io.github.mxwf.weeko` / `0.7.0-fluent-stage7`（versionCode 7）
- SHA-256：`1874F54275B0E7D8EB0F69EAC3C4BD27B161ED0C0E844A4B61FBF84A8192070C`

Stage 7 只在 Stage 6 生成工程的顶部动态布局构造段加入两个偏移修正：导航从屏幕边缘移入 16dp，日期/周次/星期共同右移到 64dp 信息起点。所有偏移仍按设备 density 计算。

## 真机验收证据

- 主课表截图：`build/v0.8/fluent-stage7-main.png`
- 星期栏打开周数 rail 的截图：`build/v0.8/fluent-stage7-weekday-open.png`
- 对应 UI dump：`build/v0.8/fluent-stage7-weekday-final.xml`，包含 `选择周次` 与 `拖动选择周次`。
- 在新位置点击 `第 2 周` 后的 dump：`build/v0.8/fluent-stage7-week-after.xml`，未出现 `修改当前周` 弹窗；点击 `周一` 后出现周数 rail。
- 关键 bounds（1220×2712、density 3）：导航 `[48,213][192,357]`；日期 `[240,141][487,285]`；周次 `[240,285][477,429]`；星期 `[501,285][645,429]`。
