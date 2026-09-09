# Weeko v0.7 Fluent UI Stage 5 报告

日期：2026-09-07  
范围：Fluent UI 全量回归，以及周 rail “只浏览、自动恢复”行为收口。

## 最终构建

构建入口为 [`tools/build-weeko-v08-fluent-stage5-debug.ps1`](../tools/build-weeko-v08-fluent-stage5-debug.ps1)，补丁入口为 [`tools/replay-weeko-v08-fluent-stage5-patches.ps1`](../tools/replay-weeko-v08-fluent-stage5-patches.ps1)。最终验证包：

- [`build/v0.8/Weeko-v0.7.0-fluent-stage5-debug.apk`](../build/v0.8/Weeko-v0.7.0-fluent-stage5-debug.apk)
- 包名 `io.github.mxwf.weeko`，`versionCode=7`，`versionName=0.7.0-fluent-stage5`
- SHA-256 `EA99466E03F57DBACCA1C50B2F23AAB8A7EFB1F8BDAB68B161410FC9F21F4B0C`，大小 `6,321,555` bytes
- apktool 重建、`zipalign -c`、`apksigner verify` v1/v2/v3 均通过；仅为 debug 验证签名

本阶段发现并修复了 rail 空闲收起后仍停留在最后浏览周的问题：打开 rail 时保存原周次，拖动期间仍调用原有周切换链，收起或 3 秒超时后恢复原周次并刷新课表。没有新增数据源或持久化格式。

## 菜单与入口回归

最终包安装到设备 `3fde7e33` 后，主页面冷启动树为 [`stage5-final-main-latest.xml`](../build/v0.8/stage5-final-main-latest.xml)，当前周为“第 2 周”、星期为“周一”。左/右菜单截图和树：[`stage5-fixed-left.xml`](../build/v0.8/stage5-fixed-left.xml)、[`stage5-fixed-right.xml`](../build/v0.8/stage5-fixed-right.xml)。

主页面树中 `anko_bottom_sheet` / `bottom_sheet` 均为 0，`anko_vp_schedule` 仍覆盖到屏幕底部；顶部四个命令入口各保留 48 dp bounds。

| 入口 | 实测结果 |
| --- | --- |
| 左侧“修改当前周” | `ScheduleSettingsActivity`，显示“当前周”对话框 |
| 左侧“切换/管理课表” | `ScheduleManageActivity` |
| 左侧“调整上课时间” | `TimeSettingsActivity` |
| 右侧“课表管理” | `ScheduleSettingsActivity` |
| 右侧“分享” | 原分享子菜单，含兼容备份、日历和 Weeko 分享 |
| 右侧“设置” | `SettingsActivity` |
| 右侧“关于 Weeko” | `WeekoAboutActivity` |

完整 Activity 栈和逐项 UI 树见 [`stage5-fixed-route-matrix.txt`](../build/v0.8/stage5-fixed-route-matrix.txt) 及 `stage5-fixed-route-*.xml`。逐项返回后均回到 `ScheduleActivity`。顶部“添加课程”进入 `AddCourseActivity`（[`stage5-add.xml`](../build/v0.8/stage5-add.xml)），“导入课程”保留“从教务导入 / 从文件导入 / 从分享口令 / 申请适配”（[`stage5-import.xml`](../build/v0.8/stage5-import.xml)）。

日期直达入口单独点击后仍停留在 `ScheduleActivity`，并保持当前周信息（[`stage5-date-direct.xml`](../build/v0.8/stage5-date-direct.xml)）。

## rail 边界与连续拖动

- 拖到第一周：[`stage5-fixed-rail-first.xml`](../build/v0.8/stage5-fixed-rail-first.xml)，显示“第 1 周”。
- 拖到最后一周：[`stage5-fixed-rail-last.xml`](../build/v0.8/stage5-fixed-rail-last.xml)，显示“第 18 周”。
- 连续 2400 ms 拖动到末端仍保持 rail 打开：同一 `stage5-fixed-rail-last.xml`，截图为 [`stage5-fixed-rail-last.png`](../build/v0.8/stage5-fixed-rail-last.png)。
- 等待 3.5 秒后自动收起并恢复原周次、日期和星期：[`stage5-fixed-rail-after3s.xml`](../build/v0.8/stage5-fixed-rail-after3s.xml)，恢复为“第 2 周 / 周一”。

## 明暗主题与稳定性

浅色主页面证据为 [`stage5-light-main.xml`](../build/v0.8/stage5-light-main.xml) / [`stage5-light-main.png`](../build/v0.8/stage5-light-main.png)；深色主页面与 rail 证据为 [`stage5-dark-main.png`](../build/v0.8/stage5-dark-main.png)、[`stage5-dark-rail.xml`](../build/v0.8/stage5-dark-rail.xml) 和 [`stage5-dark-rail.png`](../build/v0.8/stage5-dark-rail.png)。回归结束已将设备 night mode 恢复为 `no`。

冷启动、深色模式、菜单和 rail 回归 logcat 均未出现目标进程的 `FATAL EXCEPTION`、`VerifyError`、`NoSuchMethodError` 或 ANR；其中出现的 `AndroidRuntime` 行只是系统 uiautomator launcher 的正常启动记录：[`stage5-final-cold-logcat.txt`](../build/v0.8/stage5-final-cold-logcat.txt)、[`stage5-dark-logcat.txt`](../build/v0.8/stage5-dark-logcat.txt)、[`stage5-fixed-regression-logcat.txt`](../build/v0.8/stage5-fixed-regression-logcat.txt)。

## 阶段结论

Stage 5 的菜单全入口、添加/导入入口、rail 第一周/最后一周/连续拖动、3 秒恢复、明暗主题、返回栈和冷启动稳定性均已在最终 debug 包上复核。课程、课表、作息、导入导出、提醒、Widget 和周算法仍由 WakeUp 兼容母体提供，未在 Fluent 阶段复制或改写。
