# Weeko v0.7 Stage 1 报告

日期：2026-09-06  
范围：只实现并验证顶部左侧导航与右侧操作菜单；不包含 Stage 2 的底部栏移除或入口清理。

## 完成内容

`tools/replay-weeko-v07-stage1-patches.ps1` 是可重复的 Stage 1 修补入口，目标工程从 v0.6 `repro-test-apktool` 复制后执行。它完成以下最小改动：

- 版本元数据升级为 `versionCode 7`、`versionName 0.7.0-stage1`。
- 新增 `weeko_nav_left` ID、`weeko_nav_menu` vector 和 `weeko_nav_share` 字符串资源。
- 在 `ScheduleActivity` 绑定左侧导航按钮（代码 7）和右侧菜单按钮（代码 12）。
- 在 `o00000` 动态布局中加入左侧导航按钮，保留原有右侧“更多操作”按钮和底部/旧入口。
- 在 `o00oO0o` 增加右侧菜单构建器，菜单项分别使用代码 11–14。
- 在 `o0OOO0o` 增加代码 11–14 的点击分支：多课表管理、分享、全局设置、关于；原有 `packed-switch` 及旧底部逻辑保留。

## Stage 1 入口链

- 左侧按钮 → “修改当前周 / 多课表管理 / 新建课表”菜单。
- 右侧按钮 → “多课表管理 / 分享 / 全局设置 / 关于 Weeko”菜单。
- 右侧“多课表管理” → `ScheduleManageActivity`，设备上已看到课程列表及编辑提示。

## 验证记录

静态与构建验证：

- replay 脚本 PowerShell parser errors：`0`。
- release build 脚本 PowerShell parser errors：`0`。
- Apktool smali/resource rebuild 成功，产物为 `build/v0.7/helper-unsigned-fresh7.apk`。
- 调试签名 APK `build/v0.7/Weeko-v0.7.0-stage1-debug-fresh7.apk`：zipalign 校验通过，APK v1/v2/v3 签名校验通过。
- `aapt2 dump badging`：包名 `io.github.mxwf.weeko`，版本 `7 / 0.7.0-stage1`。

设备验证（不清除应用数据）：

- `adb install -r` 成功，冷启动进入 `ScheduleActivity`，进程保持运行。
- 主页面 UI XML 显示 `weeko_nav_left`，以及原有 `anko_ib_more`。
- 点击左侧按钮后 UI XML 显示三项 Stage 1 菜单。
- 点击右侧按钮后 UI XML 显示四项 Stage 1 菜单。
- 点击右侧“多课表管理”后进入 `ScheduleManageActivity`，课程列表可见。
- 本轮验证后的 UI XML 保存在 `build/v0.7/device-ui-stage1-fresh6.xml`、`device-ui-stage1-left3.xml`、`device-ui-stage1-right3.xml`、`device-ui-stage1-manage.xml`。

## 发布状态与阻塞

发布构建仍由 `tools/build-weeko-v07-stage1.ps1` 负责，并固定校验 v0.6 基线、Weeko v2 keystore 指纹、证书指纹及最终 APK 元数据。使用记录中的 `E:\codex\Weeko-signing\weeko-release-v2.p12` 和 DPAPI 凭据文件时，当前执行身份无法解密凭据，脚本在 `Import-Clixml` 处以退出码 1 失败：`Key not valid for use in specified state`。

这是签名凭据的用户/系统作用域问题，不应通过猜测密码、生成替代密钥或放宽校验绕过。获得同一 DPAPI 作用域下的凭据后，可直接重跑 release build；在此之前不声明已生成可发布签名 APK。

## Stage 1 结论

Stage 1 的左/右导航及其首个页面链已通过设备验证；旧底部入口仍保留。Stage 2（底部栏移除、重复入口清理、完整分享/设置返回栈验收）尚未开始。
