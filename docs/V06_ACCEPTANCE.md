# Weeko v0.6-F 验收记录

日期：2026-09-05  
候选包：`build/v0.6/Weeko-v0.6.0-test1.apk`  
SHA-256：`3A4F0E8C11727B8A0A3DB0A31C752490F0CC5DFB2D6C58B8D248C27474B6D5B1`  
包名/版本：`io.github.mxwf.weeko` / versionCode `6` / versionName `0.6.0-test1`  
设备：`3fde7e33`，`22081212C`，Android 17/API 37

## 构建

- 只读基线：`build/v0.5/Weeko-v0.5.0-test1.apk`，SHA-256 为
  `D3EBA2622CA23C6167D6F89D970D44DA54E9BF71E18E032C76597E77EAD7C7C2`。
- `tools/build-weeko-v06.ps1` 从 v0.5 apktool 副本精确重放补丁，编译并注入 `v06-source`。
- 连续两次完整构建 SHA-256 一致；zipalign 和 apksigner v1/v2/v3 验证通过。
- 固定签名证书 SHA-256：`E114CA20A1DD4726E83FF511C290AD30278D37E09703AB1BC788405BBC759E21`。
- 离线更新/版本回归：23 个用例通过。

## 设备回归

以下项目在本候选包上通过，均未卸载 WakeUp、未清除 Weeko 数据，真实课表只读：

- 冷启动：Splash → ScheduleActivity。
- 底部四入口、右上角添加、底部添加入口和返回栈。
- 课程新增、编辑、删除取消、删除成功（临时课表）。
- 多课表切换、周次显示、课表设置、作息页、全局设置。
- About 页面、邮箱复制弹窗与返回。
- 稳定/测试更新检查在无 Release 时显示明确提示。
- SAF 导出 `26-1.wakeup_schedule`，再从“从备份”导入成功；导入产生的重复课表已删除。

本轮临时课表 `V06Test` 及临时课程已删除；原有 `未命名`、`26-1` 保留。设备自动旋转
已恢复为开启。Widget 按约定未纳入重点验收。

## 日志与未覆盖项

- 会话日志：`build/v0.6/device/v06f-session.log`。
- Activity exit-info：`build/v0.6/device/v06f-exit-info.txt`。
- Weeko 进程无新增 FATAL/ANR；crash buffer 无 Weeko 条目。
- 没有真实 GitHub Release，因此线上成功下载路径未宣称通过；仅离线测试错误分支已覆盖。
- 第三方 SDK 的完整联网/隐私行为未作动态审计。

本记录只描述过渡二进制候选包，不代表完整源码恢复或公开发布许可。
