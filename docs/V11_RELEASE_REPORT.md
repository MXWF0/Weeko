# Weeko v1.1.0 发布报告

## 交付内容

本版本在 v1.0.1 上原地升级，版本号为 `1.1.0`、`versionCode 14`。教务导入底部入口已改为“密码箱”；密码箱支持账号的新增、查看、复制、编辑和删除，密码默认隐藏。设置页在“隐私与安全”分组增加密码箱入口，只显示加密方式与手动复制说明。

密码箱数据使用 Android Keystore 中的 AES 密钥和 AES-GCM 加密，密文文件写入 `noBackupFilesDir/password-vault.bin`。账号内容不进入 SharedPreferences、Room、日志或普通 Weeko 课表备份。教务页不会读取或自动填充密码，用户只能主动复制。

“注意事项”和网址提示分别由 `edu_notice_confirmed`、`edu_url_notice_confirmed` 控制，确认时使用同步 `commit()` 落盘。注意事项确认后仍可从页面帮助按钮主动打开。

## 回归结果

在设备 `3fde7e33`（Xiaomi 22081212C）完成覆盖安装和真机回归：

- v1.0.1 覆盖升级至 v1.1.0 成功，应用数据未清除，原课程数据在升级后仍可读取。
- 两项提示首次进入均出现；分别确认后，强制停止并冷启动教务页均未再次出现。
- 密码箱新增、隐藏显示、复制用户名、复制密码、粘贴、编辑、删除均通过；记录在强制停止后可解密恢复。
- 从教务页面进入密码箱再返回，原 `LoginWebActivity`、网址和 WebView 页面状态保持不变。
- 设置页“隐私与安全”分组、密码箱摘要和入口跳转通过。
- 最终发布包教务入口冷启动通过，未出现 `VerifyError`、`FATAL EXCEPTION` 或目标应用 `AndroidRuntime` 崩溃。
- 密码箱使用独立的 no-backup 加密文件，原数据库、课程解析、备份导出、Widget、提醒和周次算法未修改。

## 发布产物

`build/v1.1.0/Weeko-v1.1.0-release.apk`

- 包名：`io.github.mxwf.weeko`
- 版本：`1.1.0`（14）
- 大小：7,972,780 bytes
- APK SHA-256：`A62B3DB1FE0EFDF28CB919BEFAF787DEA89E92B437B9DE796FDC5FD467A3E902`
- 签名证书 SHA-256：`E654E9A275921CB213CD0AE3EB5D8C35FD5DDE1C84E32F71D3B6D42EED328CD5`
