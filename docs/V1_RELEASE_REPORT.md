# Weeko v1.0.0 发布报告

状态：正式 APK 已构建，核心回归通过，准备发布  
日期：2026-09-11（Asia/Shanghai）

## 版本与迁移

- 包名：`io.github.mxwf.weeko`
- 应用名称：`Weeko 课程表`
- `versionCode=12`
- `versionName=1.0.0`
- 入口：`com.suda.yzune.wakeupschedule.SplashActivity`
- 数据库、Preference key、迁移、`.wakeup_schedule`、Widget 和旧 Activity/Provider/Receiver 名称未改写

用户已授权放弃旧签名。v1.0.0 起使用新的长期正式签名；旧版本不能直接覆盖升级。迁移时需先导出所有课表、确认备份可用，卸载旧安装后再安装 v1.0.0；v1.0.0 后续版本沿用新签名。

## 正式 APK

最终包：`build/v1.0/Weeko-v1.0.0-release.apk`  
SHA-256：`276005E3A8E6E3312A18DAA6BB018D18A01C69B82543848EE2E14F90605FA3CA`  
大小：`7,964,588` bytes

`aapt2 dump badging` 已确认包名、版本、应用名称和 launcher activity。`zipalign -c` 通过；`apksigner verify` 的 v1、v2、v3 均为 `true`。

新签名信息：

- keystore：`E:\codex\Weeko-signing\weeko-release-v3.p12`
- alias：`weeko-release-v3`
- keystore SHA-256：`2C3F4422CFA46D314C25B04984036BEC6DF3862E61CC68EBC5F83DD46B558C26`
- 证书 SHA-256：`E654E9A275921CB213CD0AE3EB5D8C35FD5DDE1C84E32F71D3B6D42EED328CD5`

keystore、加密凭据和密码均未写入 Git。

## 核心设备回归

设备：`3fde7e33`。已卸载旧安装后全新安装正式 APK，完成隐私确认和首次教程，冷启动进入 `ScheduleActivity`，无目标进程的 `FATAL EXCEPTION`、`ANR`、`VerifyError` 或 `NoSuchMethodError`。

已验证：

- 添加课程、保存、在课表中显示，并打开课程详情进入编辑表单；
- 修改课程名称并保存，课表卡片即时显示修改结果；
- 新建第二课表并切换，切换后显示空课表；
- 进入课表信息，确认当前周、学期周数和每日节数；
- 进入作息时间页，确认当前课表关联的时间表和编辑入口；
- 右侧菜单、课表管理、分享、设置和关于入口均可打开；About 页面显示 Weeko 图标、`1.0.0` 和新的签名迁移说明。

用户要求优先发布，因此未在本轮正式 APK 上继续执行备份清除恢复、通知/重启提醒、桌面 Widget、断网/错误文件矩阵等扩展回归；这些功能仍由已验证的 WakeUp 兼容母体提供，发布后可继续补测。

## 发布工具

正式构建入口为 [`tools/build-weeko-v10-release.ps1`](../tools/build-weeko-v10-release.ps1)。该脚本固定校验新 keystore、alias、证书摘要、zipalign、APK 签名和 v1.0.0 元数据。

最终提交：待提交后填写。  
GitHub Release：待发布后填写。
