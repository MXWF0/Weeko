# Weeko v0.7 Stage 3 报告

日期：2026-09-06  
范围：把底栏上层的周数调整、课表切换/管理、回到当前周迁入左上角 `☰`；不删除底栏，不进入 Stage 4。

## 完成内容

可重复补丁入口为 [`tools/replay-weeko-v07-stage3-patches.ps1`](../tools/replay-weeko-v07-stage3-patches.ps1)。它从干净 v0.6 apktool 工程重放 Stage 1、Stage 2，再完成以下最小修改：

- 左侧菜单使用独立文案资源：中文为“调整周数”“切换/管理课表”，第三项复用“回到当前周”；默认语言提供对应英文文案。
- 左侧第一项继续调用原代码 8 的当前周设置 Dialog；第二项继续调用原代码 11 的 `ScheduleManageActivity`；第三项调用原代码 9 的 ViewPager 回到当前周逻辑。
- 移除左侧菜单中原先误混入的“新建课表”，并去掉只在非当前页显示的条件分支，使左侧入口稳定为三项。
- 修正上一阶段中文 Share 资源的 PowerShell 编码漂移，使用 XML 实体写入 `分享`；没有修改数据库、导入、提醒、Widget 或课程算法。

底栏仍保留，现场展开检查仍可见“周数、修改当前周、课表、新建课表、管理、添加课程、课表设置、全局设置、关于 Weeko”等原入口，Stage 4 前不宣称这些入口已删除或清理。

## 构建证据

- Stage 3 重放日志：[`build/v0.7/stage3-replay-final.log`](../build/v0.7/stage3-replay-final.log)，退出码 0。
- PowerShell parser errors：Stage 1、Stage 2、Stage 3 均为 0。
- Apktool 重建：[`build/v0.7/stage3-apktool-build.log`](../build/v0.7/stage3-apktool-build.log)，成功生成 helper APK。
- 调试验证包：[`build/v0.7/Weeko-v0.7.0-stage3-debug.apk`](../build/v0.7/Weeko-v0.7.0-stage3-debug.apk)。
- 包名 `io.github.mxwf.weeko`，`versionCode=7`，`versionName=0.7.0-stage3`；SHA-256 `057D0953F99CC0677BA0EF214D9B08CE2FFC98192A64F1B8A0A5F61582A61FC0`，大小 6,473,107 bytes。
- `zipalign -c` 通过；`apksigner verify` 的 v1/v2/v3 均通过。该包是 debug 签名，仅用于验证，不是发布签名包。

## 设备验证

设备 `3fde7e33` 上 `adb install -r` 成功，冷启动进入 `ScheduleActivity`。

- 主页面：[`device-ui-stage3-main.xml`](../build/v0.7/device-ui-stage3-main.xml) 保留 `weeko_nav_left`、新增、导入、更多；独立分享按钮仍不存在。
- 左侧菜单：[`device-ui-stage3-left-manage.xml`](../build/v0.7/device-ui-stage3-left-manage.xml) 的可见文案严格为“调整周数 / 切换/管理课表 / 回到当前周”，没有“新建课表”。
- “调整周数”：[`device-ui-stage3-adjust.xml`](../build/v0.7/device-ui-stage3-adjust.xml) 显示原“当前周” Dialog，范围为 1–18，含取消/确定。
- “切换/管理课表”：[`device-ui-stage3-manage3.xml`](../build/v0.7/device-ui-stage3-manage3.xml) 进入原“课程管理”页并显示课程列表。
- “回到当前周”：先翻到第 2 周（[`device-ui-stage3-weekaway.xml`](../build/v0.7/device-ui-stage3-weekaway.xml)），再点击入口后回到第 1 周（[`device-ui-stage3-weekback.xml`](../build/v0.7/device-ui-stage3-weekback.xml)）。
- 右侧菜单回归：[`device-ui-stage3-right.xml`](../build/v0.7/device-ui-stage3-right.xml) 仍为“多课表管理 / 分享 / 全局设置 / 关于 Weeko”四项。
- 底栏展开检查：[`device-ui-stage3-bottom3.xml`](../build/v0.7/device-ui-stage3-bottom3.xml) 证明 Stage 3 没有误删原底栏内容。

## 阶段结论

左侧三项已迁移并逐项通过设备验证，Stage 3 完成。底栏、布局占位和相关清理留到用户明确的 Stage 4；发布签名仍受既有 DPAPI 凭据作用域问题限制，本阶段不生成发布包。
