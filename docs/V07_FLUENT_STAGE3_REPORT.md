# Weeko v0.7 Fluent UI Stage 3 报告

日期：2026-09-07  
范围：把周数/星期状态迁移为可拖动的 Fluent week rail；不改课程、课表或系统组件业务。

## 完成内容

可重复补丁入口为 [`tools/replay-weeko-v08-fluent-stage3-patches.ps1`](../tools/replay-weeko-v08-fluent-stage3-patches.ps1)，构建入口为 [`tools/build-weeko-v08-fluent-stage3-debug.ps1`](../tools/build-weeko-v08-fluent-stage3-debug.ps1)。本阶段新增的 `FluentWeekRail`：

- 使用既有 `TableConfig.maxWeek` 和当前周索引设置 `SeekBar` 范围与初始值；
- 用户拖动只通过原有周切换回调刷新 `ViewPager`，不复制数据库、提醒或 Widget 状态；
- week rail 提供“选择周次”和“拖动选择周次”无障碍语义；
- 关闭或空闲超时恢复打开前的周次，并恢复日期、周数和星期显示。

## 构建证据

- 重放日志：[`build/v0.8/fluent-stage3-replay.log`](../build/v0.8/fluent-stage3-replay.log)，退出码为 0。
- 验证 APK：[`build/v0.8/Weeko-v0.7.0-fluent-stage3-debug.apk`](../build/v0.8/Weeko-v0.7.0-fluent-stage3-debug.apk)。
- 包名 `io.github.mxwf.weeko`，`versionCode=7`，`versionName=0.7.0-fluent-stage3`；SHA-256 `DA5BE99FFCA9B460E865C610F69E288E27A55A497E91B61D8B7C846DA97DB351`。
- `zipalign -c` 与 `apksigner verify` v1/v2/v3 均通过；该包为 debug 验证签名。

## 设备验证

设备 `3fde7e33`（`1220×2712`、density `480`）上安装成功并冷启动进入 `ScheduleActivity`：

- 主页面：[`build/v0.8/stage3-fixed-main.xml`](../build/v0.8/stage3-fixed-main.xml)；日期为 `2026/9/7`，周次为“第 2 周”，星期为“周一”。
- rail 打开：[`build/v0.8/stage3-fixed-rail.xml`](../build/v0.8/stage3-fixed-rail.xml)；文本“第 2 周”、`选择周次` 和 `拖动选择周次` 均可见。
- 3.5 秒空闲后：[`build/v0.8/stage3-fixed-after3s.xml`](../build/v0.8/stage3-fixed-after3s.xml) 恢复日期、周数和星期，周次仍为“第 2 周”。
- 对应截图为 [`stage3-fixed-main.png`](../build/v0.8/stage3-fixed-main.png) 和 [`stage3-fixed-rail.png`](../build/v0.8/stage3-fixed-rail.png)。

## 阶段结论

周 rail 已接入原有周切换链，拖动和空闲恢复均保持单一周状态源；本阶段没有触及数据库、导入导出、提醒、Widget 或课程计算。
