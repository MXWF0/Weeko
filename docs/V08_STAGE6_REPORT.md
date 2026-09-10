# Weeko v0.8 Stage 6 验收报告

日期：2026-09-10  
范围：设置中心链路之后的多课表管理、主题背景遮罩、当前周重算与启动图安全区收尾。

## 交付结论

Stage 6 已完成。多课表管理页在窄屏设备上固定为两列卡片；卡片点击会写入 `config/show_table_id`、返回成功结果并关闭管理页；“回到当前周”每次按当前课表开始日期重算并限制在有效周次范围。课表背景保留原图，并使用当前主题 Surface 的 60% `SRC_OVER` 遮罩；启动图保留原画并居中缩放到约 74% 的透明安全区。

## 最终产物

| 项目 | 结果 |
| --- | --- |
| APK | [`Weeko-v0.8.0-settings-stage6-debug.apk`](../build/v0.8/Weeko-v0.8.0-settings-stage6-debug.apk) |
| 包名 | `io.github.mxwf.weeko` |
| 版本 | `versionCode=10`，`versionName=0.8.0-settings-stage6` |
| SHA-256 | `0B10A46DC9B18A09F0B0264F497B11D31FA8EE8A50C62A9F2F318A916E2FD169` |
| 大小 | `7,960,492` bytes |
| 签名 | Android debug；apksigner v1/v2/v3 通过 |

可重复构建入口为 [`build-weeko-v08-settings-stage6-debug.ps1`](../tools/build-weeko-v08-settings-stage6-debug.ps1)，补丁入口为 [`replay-weeko-v08-settings-stage6-patches.ps1`](../tools/replay-weeko-v08-settings-stage6-patches.ps1)。apktool、zipalign、badging 和签名证据保存在 `build/v0.8/settings-stage6-*`。

## 实机验证

设备 `3fde7e33`（1220×2712，竖屏）执行 `adb install -r` 成功。清空 logcat 后从 `SplashActivity` 冷启动返回 `Status: ok`，进入 `ScheduleActivity`，`TotalTime: 698 ms`；本轮未出现目标包 `FATAL EXCEPTION` 或 `AndroidRuntime` 崩溃。

- 主课表日期、周次、星期和课程网格：[device-ui-settings-stage6-main.xml](../build/v0.8/device-ui-settings-stage6-main.xml)
- 多课表管理页：[device-ui-settings-stage6-manage.xml](../build/v0.8/device-ui-settings-stage6-manage.xml)
- 管理页卡片边界显示两列（首行 `[24,521][586,865]` 与 `[634,521][1196,865]`），图片区域为 72dp 高，卡片点击返回主课表且无崩溃：[device-ui-settings-stage6-after-select.xml](../build/v0.8/device-ui-settings-stage6-after-select.xml)

## 边界

本阶段仍使用 debug 签名验证包；未清除设备应用数据，横屏和桌面 Widget Host 绑定不在本阶段范围内。
