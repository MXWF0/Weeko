# Weeko v0.7 Fluent UI Stage 4 报告

日期：2026-09-07  
范围：统一顶部命令、周 rail 和浮层的 Fluent 视觉处理；不改变入口回调和业务数据。

## 完成内容

可重复补丁入口为 [`tools/replay-weeko-v08-fluent-stage4-patches.ps1`](../tools/replay-weeko-v08-fluent-stage4-patches.ps1)，构建入口为 [`tools/build-weeko-v08-fluent-stage4-debug.ps1`](../tools/build-weeko-v08-fluent-stage4-debug.ps1)。本阶段新增 `FluentTopBar`，在运行时沿用当前主题角色：

- 顶部导航、添加、导入和更多命令统一为 `48 dp` 最小触控区，并补齐中文 content description；
- 日期、周数和星期使用统一的 48 dp 文本节奏；
- rail 使用主题色进度/滑块、`surfaceContainerHigh` 浮层、16 dp 圆角和 4 dp elevation；
- rail 打开时隐藏日期锚点，避免与周状态卡片重叠，关闭时恢复日期。

## 构建证据

- 重放日志：[`build/v0.8/fluent-stage4-replay.log`](../build/v0.8/fluent-stage4-replay.log)，退出码为 0。
- 验证 APK：[`build/v0.8/Weeko-v0.7.0-fluent-stage4-debug.apk`](../build/v0.8/Weeko-v0.7.0-fluent-stage4-debug.apk)。
- 包名 `io.github.mxwf.weeko`，`versionCode=7`，`versionName=0.7.0-fluent-stage4`；SHA-256 `9F744185A3F7AF2A1E633A82E865B5BB7D9ECA36A7C4C1995132AB0A0197CEBE`。
- `zipalign -c` 与 `apksigner verify` v1/v2/v3 均通过；该包为 debug 验证签名。

## 设备验证

设备 `3fde7e33` 上安装成功并冷启动进入 `ScheduleActivity`：

- 主页面：[`build/v0.8/stage4-fixed-main.xml`](../build/v0.8/stage4-fixed-main.xml)，四个顶部命令均为 48 dp bounds。
- rail 卡片：[`build/v0.8/stage4-fixed-rail.xml`](../build/v0.8/stage4-fixed-rail.xml)；`选择周次`、`拖动选择周次` 和主题化 rail 可见，截图见 [`stage4-fixed-rail.png`](../build/v0.8/stage4-fixed-rail.png)。
- 3.5 秒空闲后：[`build/v0.8/stage4-fixed-after3s.xml`](../build/v0.8/stage4-fixed-after3s.xml) 恢复日期、周数和星期。

## 阶段结论

顶部命令和周 rail 已完成主题化边界处理，原有 Activity、菜单分发、数据库、导入导出、提醒、Widget 和周算法保持不变。
