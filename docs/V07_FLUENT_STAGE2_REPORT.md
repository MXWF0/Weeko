# Weeko v0.7 Fluent UI Stage 2 报告

日期：2026-09-07  
范围：拆分日期、周状态和导航入口，校准 Fluent 迁移所需的最小回调边界。

## 完成内容

可重复补丁入口为 [`tools/replay-weeko-v08-fluent-stage2-patches.ps1`](../tools/replay-weeko-v08-fluent-stage2-patches.ps1)，构建入口为 [`tools/build-weeko-v08-fluent-stage2-debug.ps1`](../tools/build-weeko-v08-fluent-stage2-debug.ps1)。本阶段：

- 日期入口直接调用既有“回到当前周”回调，不再打开左侧导航菜单；
- 左侧导航保留三项迁移入口，右侧更多菜单保留四项入口；
- 顶部分享按钮继续由右侧“更多”菜单承载；
- 保留原有 Activity、Intent、数据库、导入导出、提醒、Widget 和周索引算法。

## 构建证据

- 重放日志：[`build/v0.8/fluent-stage2-replay.log`](../build/v0.8/fluent-stage2-replay.log)，退出码为 0。
- 验证 APK：[`build/v0.8/Weeko-v0.7.0-fluent-stage2-debug.apk`](../build/v0.8/Weeko-v0.7.0-fluent-stage2-debug.apk)。
- 包名 `io.github.mxwf.weeko`，`versionCode=7`，`versionName=0.7.0-fluent-stage2`；SHA-256 `77473E1B40B30AB27DA0326D757D1E0C549FE2D8F233819DE7322BB1FB70F291`。
- `zipalign -c` 与 `apksigner verify` v1/v2/v3 均通过；该包为 debug 验证签名。

## 阶段结论

日期直达与导航菜单已成为两个可独立验证的入口，后续周 rail 可以只接管周数/星期状态，不需要复制业务状态源。
