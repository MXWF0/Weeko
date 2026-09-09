# Weeko v0.7 Stage 5 报告

日期：2026-09-06  
范围：修正首次使用 Balloon 引导在左侧导航迁移后的文案与指向。

## 完成内容

可重复补丁入口为 [`tools/replay-weeko-v07-stage5-patches.ps1`](../tools/replay-weeko-v07-stage5-patches.ps1)，构建入口为 [`tools/build-weeko-v07-stage5-debug.ps1`](../tools/build-weeko-v07-stage5-debug.ps1)。脚本从干净 v0.6 apktool 工程依次重放 Stage 1–4，再完成以下最小修改：

- `tooltip_current_week` 改为“打开导航菜单”，并将首个 Balloon 锚点从旧的新增按钮改为 `weeko_nav_left`（`Oooo00O`）。
- `tooltip_add_course` 保持原有文案，但锚点改为手动新增按钮 `anko_ib_add`（`OooO0oo`），不再指向导入按钮。
- `tooltip_share` 改为“打开更多功能”，对应现有 `anko_ib_more` 锚点；默认英文与五个中文地区资源同步更新。
- 未修改数据库、导入导出格式、提醒、Widget、课程计算或兼容资源名。

## 构建证据

- Stage 5 重放退出码为 0：[`build/v0.7/stage5-replay-final.log`](../build/v0.7/stage5-replay-final.log)。
- Apktool 重建成功：[`build/v0.7/stage5-apktool-build.log`](../build/v0.7/stage5-apktool-build.log)。
- 调试验证包：[`build/v0.7/Weeko-v0.7.0-stage5-debug.apk`](../build/v0.7/Weeko-v0.7.0-stage5-debug.apk)。
- 包名 `io.github.mxwf.weeko`，`versionCode=7`，`versionName=0.7.0-stage5`；SHA-256 `C42DAEF936AA74FB074577F9541639F0820CF23141D1F3EA3AA0EE152CECC24F`，大小 `6,317,459` bytes（[`stage5-release-summary.txt`](../build/v0.7/stage5-release-summary.txt)）。
- `zipalign -c` 通过；`apksigner verify` 的 v1/v2/v3 均通过（[`stage5-apksigner-verify.log`](../build/v0.7/stage5-apksigner-verify.log)）。该包为 debug 签名验证包，不是发布签名包。
- 资源静态检查确认旧的四条引导文案在 Stage5 工程中均为 0 个残留；两个迁移后的锚点位于 `ScheduleActivity.OooOo()` 的预期调用位置。

## 设备验证

设备 `3fde7e33` 上执行 `adb install -r` 返回 `Success`，随后以目标包名冷启动进入 `ScheduleActivity`（`Status: ok`、`LaunchState: COLD`）。

- 主页面 UI 树：[`device-ui-stage5-main.xml`](../build/v0.7/device-ui-stage5-main.xml)。`anko_bottom_sheet` 和 `bottom_sheet` 计数均为 0；`weeko_nav_left`、`anko_ib_add`、`anko_ib_import`、`anko_ib_more`、`anko_vp_schedule`、`anko_sv_schedule` 各出现 1 次。
- 课表区域仍延伸至屏幕底部；主页面菜单回归保持可用。
- 左侧菜单包含“调整周数 / 切换/管理课表 / 回到当前周”：[`device-ui-stage5-left-now.xml`](../build/v0.7/device-ui-stage5-left-now.xml)。
- 右侧菜单包含“多课表管理 / 分享 / 全局设置 / 关于 Weeko”：[`device-ui-stage5-more-now.xml`](../build/v0.7/device-ui-stage5-more-now.xml)。
- 最近设备 logcat 未发现目标包的 `FATAL EXCEPTION` 或 `AndroidRuntime` 错误；目标包当前 resumed Activity 为 `ScheduleActivity`。

设备已有持久化的首次引导状态，因此本轮不清除数据、不重复弹出 Balloon；引导文案和锚点以重放后的资源与 smali 静态证据核验，运行回归覆盖冷启动、主页面和左右菜单。

## 阶段结论

Stage 5 已完成首次引导语义与控件指向修正，迁移后的左导航、新增和更多操作入口均保持可用。发布签名仍不在本阶段范围内。
