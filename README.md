# Weeko

Weeko 是基于 WakeUp 6.0.23 行为母体维护的课程表项目。当前仓库同时保存可维护的
Weeko 原型源码和 v0.6 过渡二进制的可重复构建脚本；`build/`、APK、apktool/JADX
逆向目录和第三方反编译源码仅保留在本地，不纳入版本库。

## v0.6 过渡构建

`tools/build-weeko-v06.ps1` 从只读的 v0.5 apktool 副本重放精确补丁，编译并注入
`v06-source` 的 About 页面源码，再用项目外的 DPAPI 签名凭据构建 APK。密码只通过
进程内环境变量传递，构建结束后清理。脚本默认要求外部传入 keystore、Android SDK、
JDK、apktool 和 DPAPI 凭据路径；项目不包含任何密钥或凭据。

最新本地候选包及验收证据见 `docs/V06_ACCEPTANCE.md` 和 `docs/REFACTOR_STATUS.md`。
这是过渡性二进制内测版本，不代表完整源码恢复，也不构成公开发布许可。

## v0.7 顶部导航验证

v0.7 的 Stage 1–6 导航迁移、底栏清理和顶部间距调整已完成；构建、安装与设备
UI 证据见 [`docs/V07_RELEASE_REPORT.md`](docs/V07_RELEASE_REPORT.md)。验证用 debug
APK 只保存在本地 `build/v0.7/`，不代表正式发布签名。

Fluent UI 渐进迁移已完成 Stage 1–5：Stage 1 审计与视觉规范、Stage 2 入口拆分、
Stage 3 周 rail、Stage 4 顶部与浮层样式、Stage 5 全量回归。各阶段记录如下：

- [`docs/V07_FLUENT_STAGE1_REPORT.md`](docs/V07_FLUENT_STAGE1_REPORT.md)
- [`docs/V07_FLUENT_STAGE2_REPORT.md`](docs/V07_FLUENT_STAGE2_REPORT.md)
- [`docs/V07_FLUENT_STAGE3_REPORT.md`](docs/V07_FLUENT_STAGE3_REPORT.md)
- [`docs/V07_FLUENT_STAGE4_REPORT.md`](docs/V07_FLUENT_STAGE4_REPORT.md)
- [`docs/V07_FLUENT_STAGE5_REPORT.md`](docs/V07_FLUENT_STAGE5_REPORT.md)

当前本地回归候选包为 Stage 5 debug APK；构建、设备 UI 树、截图和 logcat 证据仅保存在
`build/v0.8/`，不代表正式发布签名。

## 开发源码

`app/` 与 `adapter/wakeup/` 是 Weeko 自有 Kotlin/Compose/Room 原型及兼容适配器，
`v06-source/` 是可独立编译的关于页源码。WakeUp 兼容数据格式、数据库和历史组件
引用仅在有证据的边界保留，详见 `docs/`。
