# Weeko v0.8 Stage 5：最终运行时修复报告

日期：2026-09-10  
范围：Stage 5 构建后的 `ScheduleActivity` 启动验证、运行时崩溃修复和最终包复核。

## 修复内容

Stage 5 首次安装验证时，`ScheduleActivity.OooOoO0()` 在 Android verifier 阶段失败：
`register v0 has type Reference: java.lang.String but expected Reference: android.content.Context`。
原因是 `FluentSchedulePalette.defaultSurface(Context)` 的调用误传了保存课表配置的字符串寄存器 `v0`，而不是 `ScheduleActivity` 的参数寄存器 `p0`。

`tools/replay-weeko-v08-settings-stage5-patches.ps1` 已将该调用改为 `invoke-static {p0}`。除此之外没有扩大 Stage 5 的业务范围，也没有改变数据库、SharedPreferences 或导入导出格式。

同一补丁还覆盖了课表管理列表中非法自定义背景颜色的 bitmap 解析回退：`o0000OO0` 现在调用 `FluentSchedulePalette.defaultSurface(Context)`，不再使用旧的固定 `#888888`。

## 最终构建

最终 APK：[`Weeko-v0.8.0-settings-stage5-debug.apk`](../build/v0.8/Weeko-v0.8.0-settings-stage5-debug.apk)  
构建摘要：[`settings-stage5-release-summary.txt`](../build/v0.8/settings-stage5-release-summary.txt)

| 项目 | 结果 |
| --- | --- |
| 包名 | `io.github.mxwf.weeko` |
| `versionCode` | `9` |
| `versionName` | `0.8.0-settings-stage5` |
| APK 大小 | `8,759,212` bytes |
| SHA-256 | `22ECB96CF8ADCFFDC917BC0D242BDE0FE2542306FFD9F6775ED3511EDBD9CF67` |
| zipalign | 通过 |
| apksigner | v1/v2/v3 通过；debug 签名 |

重放和构建日志分别见 [`settings-stage5-replay.log`](../build/v0.8/settings-stage5-replay.log)、[`settings-stage5-apktool-build.log`](../build/v0.8/settings-stage5-apktool-build.log)、[`settings-stage5-zipalign-verify.log`](../build/v0.8/settings-stage5-zipalign-verify.log) 和 [`settings-stage5-apksigner-verify.log`](../build/v0.8/settings-stage5-apksigner-verify.log)。

## 透明度回归

Stage 1 的 `itemAlpha` 仍从现有 `table{id}_config` 读取。最终 smali 中它只用于课程填充 Paint 的 `setAlpha`；课程文字与描边 Paint 的 Alpha 在调色前读取并在调色后恢复，图标和父容器没有复用该值。亮色和深色均在同一设备上验证了 100%、75%、50%、25% 四档：

- 亮色：[`evidence-alpha-light-100.png`](../build/v0.8/evidence-alpha-light-100.png)、[`evidence-alpha-light-75.png`](../build/v0.8/evidence-alpha-light-75.png)、[`evidence-alpha-light-50.png`](../build/v0.8/evidence-alpha-light-50.png)、[`evidence-alpha-light-25.png`](../build/v0.8/evidence-alpha-light-25.png)
- 深色：[`evidence-alpha-dark-100.png`](../build/v0.8/evidence-alpha-dark-100.png)、[`evidence-alpha-dark-75.png`](../build/v0.8/evidence-alpha-dark-75.png)、[`evidence-alpha-dark-50.png`](../build/v0.8/evidence-alpha-dark-50.png)、[`evidence-alpha-dark-25.png`](../build/v0.8/evidence-alpha-dark-25.png)

回归结束后恢复了设备原有的 `itemAlpha=60` 与 `day_night_theme=0`；设备上的课程数据只用于展示既有课程卡，不属于 APK 内置迁移逻辑。

## 最终包实机证据

最终包安装在设备 `3fde7e33` 上，以包名 `io.github.mxwf.weeko` 启动并操作。设置页、主题对话框和课表页的 UI dump 均包含该包名；运行截图如下：

- 深色设置页：[`evidence-settings-stage5-final-runtime.png`](../build/v0.8/evidence-settings-stage5-final-runtime.png)
- 浅色设置页：[`evidence-settings-stage5-final-light-runtime.png`](../build/v0.8/evidence-settings-stage5-final-light-runtime.png)
- 主题对话框：[`evidence-theme-dialog-stage5-final-runtime.png`](../build/v0.8/evidence-theme-dialog-stage5-final-runtime.png)
- 浅色空课表：[`evidence-schedule-stage5-final-light-runtime.png`](../build/v0.8/evidence-schedule-stage5-final-light-runtime.png)
- 深色填充课表：[`evidence-schedule-stage5-final-populated-runtime.png`](../build/v0.8/evidence-schedule-stage5-final-populated-runtime.png)
- 浅色填充课表：[`evidence-schedule-stage5-final-populated-light-runtime.png`](../build/v0.8/evidence-schedule-stage5-final-populated-light-runtime.png)

最终重建后又清空设备 logcat，并从 `SplashActivity` 冷启动同一哈希 APK：返回 `Status: ok`、`LaunchState: COLD`、`Activity: .../ScheduleActivity`，筛选后的日志没有 `FATAL EXCEPTION`、`VerifyError`、`NoSuchMethodError` 或 `ANR in`。对应记录为 [`evidence-final-cold-start.txt`](../build/v0.8/evidence-final-cold-start.txt)、[`evidence-final-cold-logcat.txt`](../build/v0.8/evidence-final-cold-logcat.txt) 和 [`evidence-final-clean-cold-start.png`](../build/v0.8/evidence-final-clean-cold-start.png)。

非法自定义背景回归也已在最终包上执行：将测试设备的课表背景临时写为非法值后进入课表管理页，页面正常显示并回退到主题 Surface；随后恢复原值。截图见 [`evidence-invalid-background-fallback.png`](../build/v0.8/evidence-invalid-background-fallback.png)。最终包已从同一干净母体连续重建，第二次 SHA-256 仍为 `22ECB96CF8ADCFFDC917BC0D242BDE0FE2542306FFD9F6775ED3511EDBD9CF67`。

填充课表截图展示了“商业展示设计”和“公共艺术设计”等课程卡，课程卡使用 Stage 4/5 的低饱和语义色和主题感知文字。为了验证渲染路径，测试设备上的最终包数据由原测试包的数据库、课表配置和作息配置复制到最终包；这只是设备测试准备，不是发布包的数据迁移机制。新安装且没有导入数据时，空课表是预期结果。

## 结论

错误寄存器已修复，最终 APK 已重新构建、签名、安装并完成设置页、主题切换和空/有数据课表的实机回归。该产物是 debug 验证包；正式发布仍需使用发布签名重新签名。
