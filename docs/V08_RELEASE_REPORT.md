# Weeko v0.8 Stage 5 最终发布验证报告

日期：2026-09-10  
范围：v0.8 Stage 2–5 设置中心、全局主题、课表色彩与最终运行时修复的汇总验收。

## 交付结论

Weeko v0.8 的设置中心扁平化、主题和图标统一、课表冷中性色层级、亮/暗课程语义色以及最终启动崩溃修复已完成。原有课程、课表、作息、导入、分享、提醒和 Widget 数据结构未被改写；本轮只在设置入口和课表绘制层增加了 UI 路由与主题映射。

## 最终产物

| 项目 | 结果 |
| --- | --- |
| APK | [`Weeko-v0.8.0-settings-stage5-debug.apk`](../build/v0.8/Weeko-v0.8.0-settings-stage5-debug.apk) |
| 包名 | `io.github.mxwf.weeko` |
| 版本 | `versionCode=9`，`versionName=0.8.0-settings-stage5` |
| SHA-256 | `22ECB96CF8ADCFFDC917BC0D242BDE0FE2542306FFD9F6775ED3511EDBD9CF67` |
| 大小 | `8,759,212` bytes |
| 签名 | Android debug；apksigner v1/v2/v3 通过 |

构建入口为 [`build-weeko-v08-settings-stage5-debug.ps1`](../tools/build-weeko-v08-settings-stage5-debug.ps1)，补丁重放入口为 [`replay-weeko-v08-settings-stage5-patches.ps1`](../tools/replay-weeko-v08-settings-stage5-patches.ps1)。完整摘要见 [`settings-stage5-release-summary.txt`](../build/v0.8/settings-stage5-release-summary.txt)。

## 验收矩阵

| 能力 | 实机结果 | 证据 |
| --- | --- | --- |
| 设置首页 | 进入成功，五组设置卡片和扁平入口可见 | [`evidence-settings-stage5-final-runtime.png`](../build/v0.8/evidence-settings-stage5-final-runtime.png) / [`evidence-settings-stage5-final-runtime.xml`](../build/v0.8/evidence-settings-stage5-final-runtime.xml) |
| 浅色/深色主题 | 主题对话框可打开并完成切换，设置页与课表页随主题变化 | [`evidence-theme-dialog-stage5-final-runtime.png`](../build/v0.8/evidence-theme-dialog-stage5-final-runtime.png) |
| 空课表 | 最终包冷启动后可显示空课表，不崩溃 | [`evidence-schedule-stage5-final-light-runtime.png`](../build/v0.8/evidence-schedule-stage5-final-light-runtime.png) |
| 有数据课表 | 课程卡可显示，课程标题和时间节点存在，浅色/深色语义色均生效 | [`evidence-schedule-stage5-final-populated-light-runtime.png`](../build/v0.8/evidence-schedule-stage5-final-populated-light-runtime.png)、[`evidence-schedule-stage5-final-populated-runtime.png`](../build/v0.8/evidence-schedule-stage5-final-populated-runtime.png) |
| 课程格子透明度 | 亮/暗色下 100%、75%、50%、25% 均只改变填充透明度，文字和描边保持可读 | [`V08_FINAL_FIX_REPORT.md`](V08_FINAL_FIX_REPORT.md#透明度回归) |
| 构建完整性 | apktool、zipalign、签名和 badging 均通过 | [`settings-stage5-apktool-build.log`](../build/v0.8/settings-stage5-apktool-build.log)、[`settings-stage5-zipalign-verify.log`](../build/v0.8/settings-stage5-zipalign-verify.log)、[`settings-stage5-apksigner-verify.log`](../build/v0.8/settings-stage5-apksigner-verify.log)、[`settings-stage5-apk-badging.txt`](../build/v0.8/settings-stage5-apk-badging.txt) |
| 最终冷启动 | 清空 logcat 后从 SplashActivity 冷启动返回 `Status: ok`，进入 ScheduleActivity；无目标包崩溃标记 | [`evidence-final-cold-start.txt`](../build/v0.8/evidence-final-cold-start.txt)、[`evidence-final-cold-logcat.txt`](../build/v0.8/evidence-final-cold-logcat.txt)、[`evidence-final-clean-cold-start.png`](../build/v0.8/evidence-final-clean-cold-start.png) |
| 非法背景回退 | 非法自定义背景回退到主题 Surface，页面保持可用 | [`evidence-invalid-background-fallback.png`](../build/v0.8/evidence-invalid-background-fallback.png) |

## 已知边界

设备回归使用原测试包数据复制到最终包，仅用于展示已有课程卡；最终包首次安装没有课程时显示空课表。没有进行横屏测试，Weeko 自有页面保持竖屏约束。产物为 debug 签名验证包，不应直接作为正式发布 APK。

## 结论

当前版本满足 v0.8 Stage 5 的 UI、构建和最终包运行时验收标准；最终包连续重建哈希一致，可作为后续发布签名和正式打包的输入。
