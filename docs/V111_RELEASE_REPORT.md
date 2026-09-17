# Weeko v1.1.1 发布报告

状态：已完成本地构建、正式签名和设备回归
日期：2026-09-17（Asia/Shanghai）

## 本轮调整

- 密码箱改为居中的小窗口，教务导入页面和设置页均可直接打开。新增和编辑只保留用户名、密码、备注三项；名称和学校不再出现在界面。v1.1.0 已保存记录的加密字段继续保留，用于原地升级读取；新记录以用户名作为显示标题。
- 密码箱仍使用 Android Keystore 的 AES-GCM 加密文件保存，不调用教务网页，不自动读取或自动填充。系统级密码管理器的提示属于系统行为，本版本不屏蔽。
- “关于 Weeko”移除“联网边界”和“签名重置”，并重写其余说明，使内容更直接、准确。
- 版本元数据升级为 `versionCode=15`、`versionName=1.1.1`；教务导入、数据库、课程解析、备份格式、Widget、提醒和周次算法未改动。

## 正式 APK

| 项目 | 结果 |
| --- | --- |
| APK | [`Weeko-v1.1.1-release.apk`](../build/v1.1.1/Weeko-v1.1.1-release.apk) |
| 包名 | `io.github.mxwf.weeko` |
| 版本 | `versionCode=15`，`versionName=1.1.1` |
| SHA-256 | `9D35AD126ABF823DEF0F743857CF36DF45FCA983913F05054D4D5F7D352BA8D7` |
| 大小 | `7,972,780` bytes |
| 签名证书 SHA-256 | `E654E9A275921CB213CD0AE3EB5D8C35FD5DDE1C84E32F71D3B6D42EED328CD5` |
| 对齐与签名 | `zipalign`、`apksigner verify` 通过 |

构建入口为 [`tools/build-weeko-v111-release.ps1`](../tools/build-weeko-v111-release.ps1)，补丁重放入口为 [`tools/replay-weeko-v111-patches.ps1`](../tools/replay-weeko-v111-patches.ps1)。完整摘要见 [`v1.1.1-release-summary.txt`](../build/v1.1.1/v1.1.1-release-summary.txt)。

## 设备回归

设备：`3fde7e33`（Android 17/API 37，1220×2712）。在已有 v1.1.0 数据上安装 v1.1.1 正式包，已确认旧加密记录仍可读取，版本元数据为 15/1.1.1。

- 密码箱窗口宽度为 960 像素，未占满屏幕；列表、复制用户名、复制密码、编辑和删除入口均可见。
- 新增账号编辑器只出现“用户名”“密码”“备注”三个输入框，密码输入和列表显示均为隐藏状态；保存后记录可重新读取。
- “关于 Weeko”显示重写后的内容，已删除两项旧卡片。
- 普通 Weeko 课程备份仍只走原有 `.wakeup_schedule` 路径，密码箱文件位于 no-backup 存储，不写入普通课程备份。
- v1.0.1 → v1.1.0 的原地升级回归已通过；v1.1.0 → v1.1.1 继续保留课程数据和密码箱记录。教务导入页面的首次提示状态和 WebView 导入流程未被本轮代码改动。

## 发布边界

本报告记录本轮 UI、加密存储和升级回归。系统级密码管理器可能在保存密码时显示自己的提示；密码箱不会响应其提示，也不会自动填充教务页面。
