# Weeko v0.7 Stage 2 报告

## 结论

Stage 2 已完成并通过静态构建、安装和设备 UI 冒烟验证。分享入口已从顶层按钮迁移到右侧“更多”菜单；新增课程、导入课程和 Stage 1 导航入口保持可用。当前交付物是使用 Android debug keystore 签名的验证 APK，不是发布签名包。

## 变更范围

可复现补丁脚本：[`tools/replay-weeko-v07-stage2-patches.ps1`](../tools/replay-weeko-v07-stage2-patches.ps1)

- 将 `apktool.yml` 版本名更新为 `0.7.0-stage2`。
- 从动态顶栏移除旧的独立分享按钮及其直接点击监听。
- 将导入按钮的约束从已移除的分享按钮重定向到可见的“更多”按钮，保留“新增 → 导入 → 更多”布局链。
- 保留 Stage 1 左侧导航；分享菜单项继续调用原分享流程，并以右侧“更多”按钮作为级联菜单锚点。
- 移除首运行引导对旧分享图标的引用。

## 构建证据

- Stage 2 补丁从干净 v0.6 apktool 工程重放成功，退出码为 0：[`build/v0.7/stage2-replay-final.log`](../build/v0.7/stage2-replay-final.log)。
- Apktool 重建成功，随后注入独立编译的 `classes2.dex`，完成 zipalign 和 debug 签名。
- `zipalign -c` 通过；`apksigner verify` 的 v1/v2/v3 均通过。
- `aapt2 dump badging`：`io.github.mxwf.weeko`、`versionCode=7`、`versionName=0.7.0-stage2`。

验证 APK：[`build/v0.7/Weeko-v0.7.0-stage2-debug.apk`](../build/v0.7/Weeko-v0.7.0-stage2-debug.apk)  
SHA-256：`267A6F9B538D160DD1BEB6C4C7A13B803E131A1C07AF0008A0CDC74D4EE8D236`  
大小：`6,473,107` bytes

## 设备冒烟

设备 `3fde7e33` 上执行 `adb install -r` 返回 `Success`，冷启动进入 `ScheduleActivity`。

- 顶栏 UI：[`device-ui-stage2-final-main.xml`](../build/v0.7/device-ui-stage2-final-main.xml) 显示 `anko_ib_add`、`anko_ib_import`、`anko_ib_more` 和 `weeko_nav_left`，没有 `anko_ib_share`。
- “更多”菜单：[`device-ui-stage2-final-more.xml`](../build/v0.7/device-ui-stage2-final-more.xml) 显示“分享”菜单项。
- 点击“分享”：[`device-ui-stage2-final-share.xml`](../build/v0.7/device-ui-stage2-final-share.xml) 显示原分享子菜单（导出兼容备份、导出日历文件、分享 Weeko、在线分享课表）。
- 点击“新增”：[`device-ui-stage2-final-add2.xml`](../build/v0.7/device-ui-stage2-final-add2.xml) 进入 `AddCourseActivity`，显示“添加课程”和“保存”。

## 签名说明

发布签名仍受本机 DPAPI 凭据无法解密（`Import-Clixml: Key not valid for use in specified state`）阻塞；脚本保持 fail-closed，没有生成或冒充发布签名 APK。Stage 3 未开始。
