# Weeko v0.7 最终验证报告

日期：2026-09-06  
范围：Stage 1–6 导航迁移、底栏清理、首次引导锚点修正，以及顶部布局收口。

## 最终 UI 调整

Stage 6 通过 [`tools/replay-weeko-v07-stage6-patches.ps1`](../tools/replay-weeko-v07-stage6-patches.ps1) 在 Stage 5 链之后只改动 `ScheduleActivity` 顶部布局：

- 左侧 `weeko_nav_left` 移入左侧预留栏，bounds 为 `[0,161][96,257]`。
- 日期、周次、星期整体右移 32dp，分别为 `[144,141][402,221]`、`[144,221][269,277]`、`[293,221][377,277]`，不再被汉堡图标覆盖。
- 加号、导入、更多保持 32dp 点击区域，bounds 分别为 `[716,161][812,257]`、`[908,161][1004,257]`、`[1100,161][1196,257]`；按钮之间均为 96px 空隙，间距均匀且比上一版紧凑。
- 偏移使用运行时 density 计算；未修改数据库、导入导出格式、提醒、Widget 或课程计算。

复核截图：[`build/v0.7/stage6-layout-final.png`](../build/v0.7/stage6-layout-final.png)。

## 构建证据

- 重放日志：[`build/v0.7/stage6-replay-final.log`](../build/v0.7/stage6-replay-final.log)，Stage 1–6 均返回成功。
- 构建入口：[`tools/build-weeko-v07-stage6-debug.ps1`](../tools/build-weeko-v07-stage6-debug.ps1)。
- 验证 APK：[`build/v0.7/Weeko-v0.7.0-stage6-debug.apk`](../build/v0.7/Weeko-v0.7.0-stage6-debug.apk)。
- 包名 `io.github.mxwf.weeko`，`versionCode=7`，`versionName=0.7.0-stage6`。
- SHA-256：`BFE5FD7FD65D5CE383D4A26304A70D457FD63E8E4BAE8DE648B76B016DC1BD0A`；大小 `6,317,459` bytes（[`stage6-release-summary.txt`](../build/v0.7/stage6-release-summary.txt)）。
- `zipalign -c`、`apksigner verify` v1/v2/v3 均通过（[`stage6-apksigner-verify.log`](../build/v0.7/stage6-apksigner-verify.log)）。包为 debug 签名验证包，不是发布签名包。

## 主要修改文件

- `tools/replay-weeko-v07-stage1-patches.ps1` 至 `tools/replay-weeko-v07-stage6-patches.ps1`：按阶段重放入口、分享迁移、左侧菜单、底栏移除、引导锚点和顶部间距补丁。
- `tools/build-weeko-v07-stage1.ps1`、`tools/build-weeko-v07-stage4-debug.ps1`、`tools/build-weeko-v07-stage5-debug.ps1`、`tools/build-weeko-v07-stage6-debug.ps1`：对应阶段的可重复构建、注入、对齐、签名和元数据校验入口。
- Stage 6 生成工程中的主要受影响代码/资源为 `ScheduleActivity.smali`、`o00000.smali`、`o00oO0o.smali`、`o0OOO0o.smali`、`o000oOoO.smali`、`Oooo000.smali`，以及导航 vector、ID 和引导文案资源；这些位于本地 `build/v0.7/` 生成目录，不改变数据库、Entity、DAO、Migration、序列化字段或 SharedPreferences key。
- `docs/V07_STAGE1_REPORT.md` 至 `docs/V07_STAGE5_REPORT.md`、`docs/V07_NAVIGATION_AUDIT.md`：保存各阶段的入口决策和验收证据；本文件汇总最终包。
- `README.md`：增加 v0.7 验证入口和 debug 包说明。

## 设备回归

设备 `3fde7e33` 上执行 `adb install -r` 返回 `Success`，未清除已有数据；随后以目标包名显式冷启动 `ScheduleActivity`。以下 XML 和截图均来自 Stage 6 验证包或本轮对该包的直接操作：

| 能力 | 实机结果与证据 |
| --- | --- |
| 主页面与底栏 | 主页面进入成功；最终 UI 树中 `anko_bottom_sheet`、`bottom_sheet` 均为 0，顶部 `☰`、加号、导入、`⋮` 均存在：[`device-ui-stage6-final-main-final.xml`](../build/v0.7/device-ui-stage6-final-main-final.xml)、[`stage6-final-main-final.png`](../build/v0.7/stage6-final-main-final.png)。 |
| 左侧导航 | 菜单显示“调整周数 / 切换/管理课表 / 回到当前周”，调整周数对话框可打开：[`device-ui-stage6-final-left-live.xml`](../build/v0.7/device-ui-stage6-final-left-live.xml)、[`device-ui-stage6-final-adjust2.xml`](../build/v0.7/device-ui-stage6-final-adjust2.xml)。多课表卡片页可由 `ScheduleManageActivity` 无参数入口打开，显示“多课表管理 / 未命名 / 26-1”：[`device-ui-stage6-final-multi-direct-final.xml`](../build/v0.7/device-ui-stage6-final-multi-direct-final.xml)。 |
| 右侧导航与分享 | `⋮` 显示“多课表管理 / 分享 / 全局设置 / 关于 Weeko”；分享子菜单保留兼容备份、日历、应用分享、在线分享四项：[`device-ui-stage6-final-right-live2.xml`](../build/v0.7/device-ui-stage6-final-right-live2.xml)、[`device-ui-stage6-final-share2.xml`](../build/v0.7/device-ui-stage6-final-share2.xml)。 |
| 课程操作 | 顶部加号进入 `AddCourseActivity`；课程查看、编辑和删除范围确认均可达，删除验证只点击“取消”未写入数据：[`device-ui-stage6-final-add.xml`](../build/v0.7/device-ui-stage6-final-add.xml)、[`device-ui-stage6-final-course-view-live.xml`](../build/v0.7/device-ui-stage6-final-course-view-live.xml)、[`device-ui-stage6-final-course-edit-live.xml`](../build/v0.7/device-ui-stage6-final-course-edit-live.xml)、[`device-ui-stage6-final-delete-live2.xml`](../build/v0.7/device-ui-stage6-final-delete-live2.xml)。 |
| 课表设置与作息 | “全局设置 → 设置当前课表”进入“课表设置”；“上课时间”进入“时间表”，其“默认”项可打开原有“编辑时间表”页面：[`device-ui-stage6-final-current-table-settings.xml`](../build/v0.7/device-ui-stage6-final-current-table-settings.xml)、[`device-ui-stage6-final-time-from-route.xml`](../build/v0.7/device-ui-stage6-final-time-from-route.xml)、[`device-ui-stage6-final-time-edit.xml`](../build/v0.7/device-ui-stage6-final-time-edit.xml)。 |
| 导入 | 顶部导入入口打开原有“从教务导入 / 从文件导入 / 从分享口令 / 申请适配”菜单，未改动导入业务：[`device-ui-stage6-final-import-live.xml`](../build/v0.7/device-ui-stage6-final-import-live.xml)。 |
| 设置、提醒、深色模式 | “全局设置”与“功能设置”可达；提醒开关触发系统通知权限对话框，拒绝后显示原有“无法提醒，请去系统设置允许 App 发送通知”提示：[`device-ui-stage6-final-settings2.xml`](../build/v0.7/device-ui-stage6-final-settings2.xml)、[`device-ui-stage6-final-function-settings-dark-scroll.xml`](../build/v0.7/device-ui-stage6-final-function-settings-dark-scroll.xml)、[`device-ui-stage6-final-reminder-toggle.xml`](../build/v0.7/device-ui-stage6-final-reminder-toggle.xml)、[`device-ui-stage6-final-reminder-afterdeny.xml`](../build/v0.7/device-ui-stage6-final-reminder-afterdeny.xml)。显示主题对话框含浅色、深色、跟随系统，深色设置页截图通过；回归结束已恢复“跟随系统”：[`device-ui-stage6-final-theme-dialog.xml`](../build/v0.7/device-ui-stage6-final-theme-dialog.xml)、[`stage6-final-settings-dark.png`](../build/v0.7/stage6-final-settings-dark.png)、[`device-ui-stage6-final-settings-restored.xml`](../build/v0.7/device-ui-stage6-final-settings-restored.xml)。课表颜色主题继续由原有课表主题覆盖逻辑控制，本阶段未改变。 |
| Widget | Manifest 保留日视图、周视图和课程 Widget receiver/service；配置页可打开并显示课表选择项“未命名 / 26-1”：[`device-ui-stage6-final-widget-config.xml`](../build/v0.7/device-ui-stage6-final-widget-config.xml)。本轮验证了配置页和 `APPWIDGET_UPDATE` 广播无崩溃，但未伪造桌面 Host 的绑定结果。 |
| 稳定性 | 本轮及最近设备 logcat 未出现目标包的 `FATAL EXCEPTION`、`AndroidRuntime` 或 ANR 记录。 |

入口语义边界：左侧“切换/管理课表”和右侧“多课表管理”复用了母体已有的
`ScheduleManageActivity` 调用链。带当前 `selectedTableId` 的原调用会进入该课表的
“课程管理”列表；无参数启动则进入“多课表管理”卡片页。两条路径均未新增业务逻辑，
本轮分别保留了课程列表和多课表卡片的实机证据。

## 结论

Weeko v0.7 的 Stage 1–6 导航迁移、底栏移除、引导锚点和顶部间距调整已完成，并通过构建、签名、安装和设备 UI 回归；既有课程、课表、作息、导入、分享、设置、提醒和 Widget 路径均保持可达。当前产物适合作为 debug 验证包；正式发布仍需单独使用发布签名凭据重新签名。桌面 Widget 的最终显示仍取决于系统 Host，未在本报告中虚构 Host 绑定结果。
