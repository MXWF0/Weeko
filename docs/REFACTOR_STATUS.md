# WakeUp 6.0.23 还原状态

## V0.6-F 验收结果（2026-09-05，本地完成）

本轮以 `build/v0.5/Weeko-v0.5.0-test1.apk`（SHA-256
`D3EBA2622CA23C6167D6F89D970D44DA54E9BF71E18E032C76597E77EAD7C7C2`）和
`.weeko-v0.5-apktool` 为只读行为基线。v0.6 候选包为
`build/v0.6/Weeko-v0.6.0-test1.apk`，大小 6,321,478 bytes，SHA-256
`3A4F0E8C11727B8A0A3DB0A31C752490F0CC5DFB2D6C58B8D248C27474B6D5B1`，包名
`io.github.mxwf.weeko`，versionCode `6`，versionName `0.6.0-test1`。签名为固定
Weeko v2 证书 `E114CA20A1DD4726E83FF511C290AD30278D37E09703AB1BC788405BBC759E21`，
v1/v2/v3、zipalign 和 APK 元数据检查均通过。

`tools/build-weeko-v06.ps1` 从只读 v0.5 apktool 副本复制工作目录，逐项校验并重放 9
个精确补丁，编译 `v06-source`、注入独立 dex、重建、对齐、签名和验证。ZIP 条目时间
固定为 1980-01-01；连续两次完整构建生成相同 SHA-256，脚本日志和补丁回放日志位于
`build/v0.6/logs/`。离线版本/更新测试通过 23 个用例。

设备 `3fde7e33`（型号 `22081212C`，Android 17/API 37）使用 `adb install -r` 覆盖安装，
未卸载 WakeUp、未清除 Weeko 数据、未改动真实课程。冷启动已进入
`SplashActivity → ScheduleActivity`；XML 验证四个底部入口、右上角与底部添加入口、
课表设置/作息页、全局设置、About、返回栈和更新检查无 Release 时的明确提示。测试课表
中完成课程新增、编辑、删除取消和删除成功；切换 `未命名`/`26-1` 后恢复，首节时间
`08:20` 保持不变。SAF 导出生成 `26-1.wakeup_schedule`，随后从“从备份”导入成功并
显示检查提示；导入产生的重复 `26-1` 和本轮临时 `V06Test` 课表已删除，原有两张课表
保留。About 邮箱复制弹窗可打开并关闭。

会话日志 `build/v0.6/device/v06f-session.log` 中 Weeko 进程无 `FATAL EXCEPTION`/`ANR in`，
crash buffer 中无 Weeko 条目；`v06f-exit-info.txt` 仅记录安装更新及正常用户停止。
屏幕自动旋转已恢复（`accelerometer_rotation=1`）。Widget 按约定不作为本轮重点。

保留的 WakeUp 引用仅用于兼容：旧组件类名、Room v11 数据库名 `wakeup`、Preferences 键、
`.wakeup_schedule` 文件格式、旧分享识别、迁移记录及许可证/第三方声明；教务 Parser、
Widget、提醒和课程逻辑未改动。APK 启发式扫描未命中私钥头或 GitHub Token，但第三方 SDK
的联网行为未作完整动态审计，不作超出证据范围的隐私承诺。

本机远程核验 `git ls-remote --symref` 已确认
`https://github.com/MXWF0/Weeko` 的默认分支为 `main`，HEAD 为
`3fa042a820b8102f705b783752017d13e76357e4`。本轮只在本地整理 Weeko 自有源码、规范文档和
无凭据构建脚本；APK、逆向工程、设备日志、构建缓存和签名凭据均由 `.gitignore` 排除并
保留在本地。按本阶段要求未提交、未推送、未创建 GitHub Release，也未上传二进制资产。

## V0.5 Weeko 过渡内测版（About 圆角修正，2026-09-03）

本阶段以 `build/v0.5/baseline/Weeko-v0.4.0-test1.apk` 为唯一行为基线。基线
SHA-256 为 `97D6296EA0BD85DEDD411EE42D2A357222AF993D62E83D150A254A53138498C4`，
大小为 6,305,094 bytes；原 APK、完整 v0.4 apktool 工程、About 源码和构建脚本均已
备份。Weeko 与 `com.suda.yzune.wakeupschedule` 均保留在设备上，升级测试使用
`adb install -r`，未卸载 WakeUp 或清除 Weeko 数据。

本轮集中修改 `.weeko-v0.5-apktool/` 和 `v05-about-source/`：

- 三个设置页的爱心菜单返回 `null`，因此不再显示专属捐赠菜单；捐赠类、资源和共享
  逻辑仍保留，避免误删共用代码。
- 导入、导出和分享的用户可见文案改为 Weeko/旧版兼容备份表述；另依据分享预览实机
  证据，仅替换 `utils/o00O0O.smali` 中写死的旧推广句，旧分享识别、`.wakeup_schedule`
  行格式、Room v11、Preferences 键、组件类名和核心课程逻辑未改动。
- About 入口仍由旧 AboutActivity 桥接，新增平台 Java 页面不访问数据库、Preferences、
  网络或 WakeUp Adapter。页面保留真实版本、数据与联网边界、内测限制、Weeko 邮箱、
  许可证与来源说明，并保留返回、滚动和邮箱复制行为。
- About 的信息容器和联系按钮改用平台 `GradientDrawable` 的母体同款圆角规格（约
  16dp/12dp），联系弹窗交由现有 Material 主题处理，不再使用独立的
  `G2ShapeDrawable` 曲线路径。这样与课表设置页的背景、填充色和圆角观感一致；旧课程
  卡片、设置页和其他母体控件没有全局改圆角。

本次重新构建的候选包 `build/v0.5/Weeko-v0.5.0-test1.apk` 已用既有
`weeko-v0.1-final-test` 密钥构建、对齐和签名：SHA-256
`D3EBA2622CA23C6167D6F89D970D44DA54E9BF71E18E032C76597E77EAD7C7C2`，大小
6,309,190 bytes，包名 `io.github.mxwf.weeko`，versionCode 5，versionName
`0.5.0-test1`，启动 Activity 仍为 `com.suda.yzune.wakeupschedule.SplashActivity`。
证书 SHA-256 为 `EF90365D9A36C36445518A3E9A29C1DC35FFB4CC916487E4BCA40398324F33E9`；
apksigner v1/v2/v3 和 zipalign 均通过。可重复流程见 `tools/build-weeko-v05.ps1`，
校验汇总见 `build/v0.5/logs/about-aligned-artifact-verification.txt` 和
`build/v0.5/logs/release-summary.txt`。

设备 `3fde7e33`（`22081212C`，Android 17/API 37）上已验证：升级后冷启动进入
ScheduleActivity；底部面板只有“添加课程、课表设置、全局设置、关于 Weeko”，右上角
加号与底部添加课程进入同一 AddCourseActivity；临时课程新增、编辑入口、删除确认/取消
及确认删除均可用；示例课表与 `26-1` 切换后可恢复，原有课程仍在；作息编辑保存后强制
停止并重启仍保留；兼容备份导出→SAF→导入成功，测试生成的重复课表随后用原有管理入口
删除。全局、功能和课表设置页的 XML 均不再出现爱心/捐赠入口。

About 的当前正常尺寸截图证据为 `build/v0.5/logs/about-typography-final.png`，
邮箱弹窗与入口面板分别见 `about-aligned-contact.png`、`about-native-rounded-panel.xml`；
对应布局 XML 中返回按钮位于左侧且联系人按钮保持约 48dp 触控高度。历史小屏截图仍保留
在日志目录，但不作为本次圆角修正的验收依据。

本次重新安装后的冷启动日志 `about-typography-cold-start.log` 未发现 Weeko
进程 FATAL 或 ANR（均为 0）。静态 WakeUp 残留审计见 `build/v0.5/logs/wakeup-remnants.txt`，
整理版清单见 `docs/WAKEUP_RESIDUALS.md`：旧 Activity/Provider、
Widget、通知/Alarm/WorkManager、HMS/网络/教务/在线分享、Donate 共用类和旧资源仍保留，
因为本轮只清理有明确证据的可见入口；静态命中不等于已确认联网或遥测行为。

本次字体对齐记录见 `build/v0.5/logs/about-typography-notes.txt`：工具栏标题为 22sp
sans-serif，版本与卡片标题为 16sp sans-serif-medium，正文为 16sp sans-serif，与母体
Material3 字阶保持一致。

未独立复测项：历史 WakeUp 分享口令样本（仓库没有真实脱敏样本）、Widget、深色模式在本
轮未扩展、教务/在线分享/更新服务的实际联网可用性。它们不影响本轮 About 与核心本地路径
证据，但不能据此宣称完整兼容或隐私安全。该 APK 仍是过渡性二进制内测版，不是完整源码
恢复工程，不公开发布；本阶段完成后停止，不开始 v0.6。

验收清单与逐项证据见 `build/v0.5/logs/v05-acceptance-checklist.txt`。

## V0.4 Weeko 过渡内测版（2026-09-03）

本阶段以 `build/v0.3/Weeko-v0.3.0-test1.apk` 为唯一发布行为基线。基线大小为
6,305,094 bytes，SHA-256 为
`79721166C649D5A28E372C4E060DCFCA388098333B7DECB132F398882BE0BB5C`；原 APK、实际
apktool 工程和待修改文件备份保存在 `build/v0.4/baseline/` 与
`build/v0.4/backups/pre-change-files/`。审查清单、基线运行记录和验收记录分别见
`build/v0.4/logs/v04-audit-plan.txt`、`baseline-*.txt/xml` 和
`v04-acceptance-checklist.txt`。
当前 `E:\codex\Weeko` 根目录不是 Git 工作树（`git status` 返回 not a git repository），
因此本阶段以显式备份目录和构建日志作为变更追踪依据。

交付候选为 `build/v0.4/Weeko-v0.4.0-test1.apk`，大小 6,305,094 bytes，SHA-256 为
`97D6296EA0BD85DEDD411EE42D2A357222AF993D62E83D150A254A53138498C4`。包名仍为
`io.github.mxwf.weeko`，版本为 `0.4.0-test1`（versionCode 4），启动入口仍为
`com.suda.yzune.wakeupschedule.SplashActivity`。使用既有
`weeko-v0.1-final-test` 密钥，证书 SHA-256 为
`EF90365D9A36C36445518A3E9A29C1DC35FFB4CC916487E4BCA40398324F33E9`，DN 为
`CN=Weeko V0.1 Internal Test, O=Weeko Test, C=CN`；zipalign 与 apksigner v1/v2/v3
均通过。可重复构建入口为 `tools/build-weeko-v04.ps1`，密钥无法打开时脚本直接失败，
不会生成替代密钥。

本阶段的实际改动严格集中在四处：

- `.weeko-v0.4-apktool/smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali`
  保留旧 Grid/点击包装器，将底部面板第一行四个格复用为添加课程、课表设置、全局
  设置、Weeko About；第二行旧视图只设为 `GONE`，不删除类、资源或共用逻辑。添加课程
  使用原右上角 `+` 的 listener，因此继续携带当前课表上下文；课表设置内部的上课时间
  与已添加课程入口保持原页面。
- `.weeko-v0.4-apktool/apktool.yml` 仅递增版本为 4/`0.4.0-test1`。
- `v04-about-source/` 仅更新关于页版本文案为 v0.4；它仍是独立编译、无数据库/网络
  访问的平台 Java 页面。
- `tools/build-weeko-v04.ps1` 固化 v0.3 基线校验、既有密钥、apktool 重建、About dex
  注入、zipalign、签名和校验流程。

底部面板实机 XML `build/v0.4/logs/v04-r2-more.xml`/`v04-final-panel2.xml` 确认只有
四项且顺序正确，单格点击区域约 94dp；截图 `v04-panel2.png` 显示原有低阴影 Tonal
Surface、大圆角卡片、统一图标尺寸与对齐。没有新增导航框架、毛玻璃库或 Compose；
现有卡片圆角与软件原视觉体系保留，深色模式、数据库、Preferences、导入格式和
Widget 均未改动。

设备 `3fde7e33`（`22081212C`，Android 17/API 37）验证：`adb install -r` 从 v0.3
升级成功，WakeUp 包 `com.suda.yzune.wakeupschedule` 仍安装，Weeko 数据未清除；冷启动
进入 `ScheduleActivity`，Room 数据库 `/data/user/0/io.github.mxwf.weeko/databases/wakeup`
打开。已回归四个底部入口、右上角 `+`、设置/作息/课程管理页面、About 返回与联系邮箱
复制、多课表切换与恢复、WakeUp 兼容备份导出→SAF→导入往返，以及导入临时课表的取消/删除
确认。课程增删改、删除取消、周次和作息保存/重启沿用未改动的核心母体，并以 v0.3
`v03-*.xml`、`time-*.xml`、`v03-week*.xml` 证据加上 v0.4 新入口回归覆盖；小组件按用户
要求不作为重点。最终干净日志 `build/v0.4/logs/v04-final-logcat.txt` 未发现 Weeko
进程 FATAL 或 ANR。

APK 大小没有变化。v0.3 基线三次 TotalTime 为 687/718/862 ms，v0.4 同设备记录为
647/583/629 ms（见 `baseline-cold-starts.txt`、`v04-cold-starts.txt`）；这是观察值，
没有实验室隔离，也没有承诺固定缩减比例。本版未删除资源，未关闭必要初始化，未移除
网络权限。

WakeUp 残留、联网/更新/教务/分享、HMS/AGConnect、Widget、通知/Alarm/WorkManager 及
旧类资源的已确认项、候选项和未知项见 `build/v0.4/logs/wakeup-remnants.txt`。这些内容
本版全部保留，下一版应先取得逐项调用和运行证据再清理；静态存在不等于已确认联网或遥测
行为。本 APK 是过渡性二进制内测版，不是完整源码恢复工程，不公开发布，也不以 WakeUp
私有服务身份运营；本阶段完成后停止，不开始 v0.5。

最后更新：2026-09-03（Asia/Shanghai）

## V0.3 Weeko 过渡内测版（2026-09-02）

本阶段以 `build/v0.2/Weeko-v0.2.0-test1.apk` 为唯一发布行为基线。基线
SHA-256 为 `1F8122971970F729274C4CDA9238EBF70EDA0B71CEE3BA17384F0AEFDA26574B`；
原 APK、apktool 工程和修改前文件快照保存在 `build/v0.3/baseline/`，重建工程为
`.weeko-v0.3-apktool/`。旧 `WakeUp` 包 `com.suda.yzune.wakeupschedule` 未卸载，
Weeko 用户数据未清除。可重复构建入口为 `tools/build-weeko-v03.ps1`，它会先校验
基线哈希和既有密钥，再执行独立源码编译、apktool 重建、dex 注入、zipalign、签名
和校验；密钥不可用时直接失败，不生成替代密钥。

交付 APK 为 `build/v0.3/Weeko-v0.3.0-test1.apk`，大小 6,305,094 bytes，
SHA-256 为
`79721166C649D5A28E372C4E060DCFCA388098333B7DECB132F398882BE0BB5C`。包名保持
`io.github.mxwf.weeko`，版本为 `0.3.0-test1`（versionCode 3），启动入口仍为
`com.suda.yzune.wakeupschedule.SplashActivity`。沿用 v0.1/v0.2 内测密钥
`weeko-v0.1-final-test`；证书 SHA-256 为
`EF90365D9A36C36445518A3E9A29C1DC35FFB4CC916487E4BCA40398324F33E9`，DN 为
`CN=Weeko V0.1 Internal Test, O=Weeko Test, C=CN`。zipalign 以及 apksigner
v1/v2/v3 校验通过；校验日志中的 META-INF/services 警告来自母体二进制，未被本阶段
改变。

本阶段集中处理确认的可见旧入口：设置页的“高级/解锁高级功能”推广改为中性“功能
设置”，高级设置直接显示原有选项；旧 Suda Life 可见开关和主面板入口不再展示，
但相关类、Preference 键、教务/在线/更新入口、网络权限和 SDK 初始化均保留，未据此
推断或承诺隐私行为。文件导入说明改为明确的 Weeko/WakeUp 兼容备份范围。课程表、
Room v11、数据库路径/表结构/Migration、Preferences 键、WakeUp 文件格式和核心
业务没有修改。

唯一新增的 Weeko 自有源码位于 `v03-about-source/`：平台 Java
`io.github.mxwf.weeko.about.WeekoAboutActivity` 独立编译并作为额外 dex 接入 About
入口。页面展示真实版本、过渡内测限制、数据与联网边界、许可证和本地可复制的
`mxwfwdw@outlook.com` 联系对话框；不访问课程数据库、Preferences、网络或 WakeUp
适配器，支持浅色/深色。核心课程和兼容母体仍是 apktool/smali 二进制，不能宣称完整
源码恢复或可维护源码工程。

设备回归在 `3fde7e33`（`22081212C`，Android 17/API 37）完成：从 v0.2 使用
`adb install -r` 升级成功，冷启动进入 `ScheduleActivity`，Room 数据库
`/data/user/0/io.github.mxwf.weeko/databases/wakeup` 可打开，`dumpsys dbinfo`
显示连接正常。已验证课程新增、编辑、删除确认与取消、多课表、当前周对话框、
自定义作息、全局/功能设置、About 打开/返回/联系邮箱复制，以及兼容备份导出后再从
SAF 文件选择器导入成功。往返导入产生的重复测试课表已通过原有管理入口删除；原有
课表保留。最终冷启动和导入日志均未发现 `FATAL EXCEPTION`、ANR 或 Weeko 进程崩溃。
小组件按用户要求不是本阶段验收重点，未主动修改或作完整回归承诺；旧更新、教务和
在线分享功能也未禁用。本轮未实际联网验证更新、在线分享、教务导入及相关服务，保留
入口不等于可用性或安全性保证。日志集中在 `build/v0.3/logs/`。

该 APK 是基于 WakeUp 行为母体的过渡性二进制内测版，仅供本地测试，不是公开发布物，
不得以 WakeUp 私有服务身份运营。本阶段完成后停止，不开始 v0.4。

## V0.2 Weeko 过渡内测版（2026-09-02）

本阶段以 `build/v0.1/Weeko-v0.1.0-test1.apk` 为唯一发布行为基线，先校验其
SHA-256 `AA03FDE825B000C4B292FFEA05664FE5C48D1AB7249624D58064C54578DCE761`，并将
原 APK、`.weeko-v0.1-apktool/` 和未修改文件快照保存在 `build/v0.2/baseline/`。
旧 `WakeUp` 包 `com.suda.yzune.wakeupschedule` 未卸载，主用户 Weeko 数据未清除。

交付 APK 为 `build/v0.2/Weeko-v0.2.0-test1.apk`，大小 6,305,094 bytes，SHA-256
为 `1F8122971970F729274C4CDA9238EBF70EDA0B71CEE3BA17384F0AEFDA26574B`。包名保持
`io.github.mxwf.weeko`，版本为 `0.2.0-test1`（versionCode 2），minSdk 21、targetSdk
35。它沿用 v0.1 最终内测密钥 `weeko-v0.1-final-test`；证书 SHA-256 为
`EF90365D9A36C36445518A3E9A29C1DC35FFB4CC916487E4BCA40398324F33E9`，DN 为
`CN=Weeko V0.1 Internal Test, O=Weeko Test, C=CN`。apktool 重建、zipalign 和
apksigner v1/v2/v3 校验均通过，重复构建入口为
`tools/build-weeko-v02.ps1`（口令必须由调用者显式传入；密钥不存在或无法打开时
脚本失败，不生成替代密钥）。

本阶段唯一源码化功能是 `v02-about-source/` 下的平台 Java
`io.github.mxwf.weeko.about.WeekoAboutActivity`。它用本地 Android 35 `android.jar`、
JDK 17 `javac` 和 Build Tools 36.0.0 `d8` 独立编译，作为额外 dex 接入同一 APK；
不依赖 Compose、AndroidX、Room、Preferences、网络 SDK 或 WakeUp 混淆类，不访问
课程数据库。原 About 入口和返回栈保持不变，旧 `AboutActivity` 只做最小 smali
桥接并先调用原 `BaseActivity.onCreate`，新页面返回 `ScheduleActivity`。页面显示真实
版本、过渡内测限制、数据/联网边界和许可证说明，并适配浅色/深色主题。

升级回归在设备 `3fde7e33`（`22081212C`，Android 17/API 37）完成：`adb install -r`
成功，Weeko 与 WakeUp 同时存在；冷启动进入旧 `ScheduleActivity`，Room
`/data/user/0/io.github.mxwf.weeko/databases/wakeup` 打开。已有两张课表保留。已验证
课程新增、编辑、删除确认与取消、多课表管理、当前周对话框、课表设置、全局设置、
WakeUp 备份导出→文件→再次导入往返，以及 About 打开/返回。导入往返产生的测试课表
已删除，主用户原有两张课表恢复。另创建并移除临时用户 10 做全新安装验证：该用户
从 Splash 进入 `ScheduleActivity`，`/data/user/10/io.github.mxwf.weeko/databases/wakeup`
可打开，未出现 FATAL/ANR。小组件按用户要求不作为本阶段验收重点，未主动修改。

本阶段没有改动 Room v11、数据库路径/表结构/Migration、Preferences 键、WakeUp
备份格式、周课程表业务、导入 Parser、Widget、Compose 或无关依赖。Manifest 中旧
更新、推广、联系、在线分享、教务导入及 SDK/网络入口仍由兼容母体保留；本阶段仅审计
并在新 About 中如实提示其可能连接原 WakeUp 服务，没有禁用或作隐私安全承诺。APK
仍是过渡性二进制内测版，不是完整可维护源码，不得公开发布或以 WakeUp 私有服务身份
运营。

构建/设备日志位于 `build/v0.2/logs/`；第一次桥接尝试产生的
`SuperNotCalledException` 已在随后修复，最终启动、About、升级和临时用户日志均无
`FATAL EXCEPTION`、ANR。根目录误建 Weeko-native 工程的 Gradle 单元测试仍因
`com.android.tools.build:gradle:9.3.0` 在当前离线环境不可解析而失败；它没有参与本次
发布 APK，亦未被扩展为替代应用。

## V0.1 Weeko 过渡测试版（2026-09-02）

本阶段以已验证可运行的 `build/wakeup-rebuilt-r50-debug.apk` 为唯一行为基线，
仅通过 apktool/smali 与资源修改建立独立 Weeko 身份；没有继续修补
`.wakeup-restoration` Java，没有迁移 Compose，没有修改 Room v11、数据库名
`wakeup`、表结构、Migration、Preferences 键、WakeUp 备份格式或课程表业务逻辑。

最终内测 APK 为 `build/v0.1/Weeko-v0.1.0-test1.apk`，大小 6,325,516 bytes，
SHA-256 为 `AA03FDE825B000C4B292FFEA05664FE5C48D1AB7249624D58064C54578DCE761`。
包名为 `io.github.mxwf.weeko`，版本为 `0.1.0-test1`（versionCode 1），
minSdk 21、targetSdk 35。APK 通过 zipalign，并通过 apksigner v1/v2/v3 校验；
内测证书 SHA-256 为
`EF90365D9A36C36445518A3E9A29C1DC35FFB4CC916487E4BCA40398324F33E9`，
DN 为 `CN=Weeko V0.1 Internal Test, O=Weeko Test, C=CN`。密钥仅供本次内测，
不得作为生产发布密钥。

身份修改包括：Manifest 包名、签名权限、ContentProvider/AndroidX 与厂商 Provider
authority、deep link、Widget/提醒 action、市场 URI；旧 DEX 类名继续保留为完整的
`com.suda.yzune.wakeupschedule.*`，未做全局类包替换。应用名称、Launcher/Adaptive/
Monochrome 图标、Splash Logo、通知图标和 About 可见身份已替换。首次启动隐私页已改为
诚实的过渡内测说明，不再声明原开发公司和联系方式；About 中原邮箱、群号和社交账号
显示为“暂未开放（过渡内测）”。

设备验证使用序列号 `3fde7e33`、型号 `22081212C`、Android 17（API 37）。旧
`com.suda.yzune.wakeupschedule` 与 Weeko 同时安装。清除 Weeko 数据后，隐私说明同意、
Splash → `ScheduleActivity`、Room `wakeup` 打开、课程新增/编辑/删除（含删除取消）、
全局设置、About、真实 `.wakeup_schedule` 文件选择与导入成功均已验证。最终候选的
Weeko Widget 已由 MIUI 桌面实际添加并绑定到新包（appWidgetId 76）；同阶段前一候选还
完成了刷新和重启恢复验证。用户确认小组件不是本轮重点，因此隐私/About 文字修正后的
最终候选不再重复第二轮 Widget 刷新与重启。各组验证均未观察到应用的
`FATAL EXCEPTION`。

该 APK 是过渡性二进制内测版，不是可维护源码。它仍包含原 WakeUp 的第三方 SDK、
网络、教务 Parser、在线分享、申请适配及历史帮助链接；这些旧联网边界没有迁移到
Weeko 身份，也没有在本阶段验证安全性或可用性。不得公开发布，不得提交教务密码、
Cookie、Token 或个人信息，也不得以 WakeUp 私有服务身份运营。后续工作必须另开阶段，
本阶段不开始 v0.2。

## R2 依赖替换闸门（2026-09-01）

本轮没有改动旧 `applicationId`、Room v11、资源、UI 或业务行为。已固定 APK
`wakeup6.0.23.apk`（SHA-256
`50EDBC7C7C3458DD0D97436F15A6AC1E69AFBE107054F53B63A0327E52DBB476`）的 75 个
`META-INF/*.version` 文件；APK 内没有 `.pom`/`.module`，AppCompat、Fragment 和
ViewPager2 三组实验的官方 POM/AAR 均从 Maven 取得。源码树实际为 6756 个 Java 文件，
其中 WakeUp 自有包 679 个、第三方/反编译包 6077 个；AndroidX 家族内部大量为
`Ooo*`/`o00*` 混淆类型。

三组实验分别排除了 `androidx/appcompat/**`、`androidx/fragment/**` 和
`androidx/viewpager2/**`，接入 APK 确认版本。三次官方 AAR 都在 Java 编译前触发
`mergeDebugResources` 的 Windows `InvalidPathException`，没有错误数量下降；
配置已撤回，恢复后的基线再次为 100 个 Javac 错误、43 个路径。因源码大量依赖
混淆后的 AndroidX/Room/WorkManager 内部类型，R2 最终闸门停止修补。完整版本、
POM、错误和备份证据见
[R2_DEPENDENCY_GATE.md](R2_DEPENDENCY_GATE.md)。

最终 Go/No-Go 判定为 **NO-GO**：三组正式依赖都在 Java 编译前的资源合并阶段失败，
没有生成 Gradle APK，也没有进行新的安装或运行冒烟；本阶段未改名、未改包、未发布
现有原型。若转向 Weeko-native，最小测试版边界和前置授权见上述闸门记录。

## 当前有效基线：Parser 补齐后的 r57/r58

本轮仍只维护 WakeUp 6.0.23 还原母体，没有开始 Weeko 身份、Compose、UI 或数据库改造。依据对应 smali、字段描述符、调用签名和 JADX simple 输出，恢复了 FSTVC fetcher、NPU/XLS、HTML 表格和 NWPU 四组 Parser 方法，并补回 NWPU smali 明确要求的 `(String, int)` 构造函数；对应参考/修改前副本均保留，详见 [RESTORATION_BUILD_ERRORS.md](RESTORATION_BUILD_ERRORS.md)。

当前源码检查结果：Parser 目录没有 `UnsupportedOperationException("Method not decompiled")`，全工程行首 `??` 为 0；Parser 中仍有 134 处 `throw null`，其语义尚未由独立 smali/运行证据确认，因此保持原样。

最新标准构建 `:app:assembleDebug --rerun-tasks`（r57，标准输出 `build/evidence-deps/wakeup-restoration-assemble-20260901-r57-clean.log`，错误流为同名 `.err.log`）在 `compileDebugJavaWithJavac` 失败；资源、Manifest 和资源处理任务通过。默认 Javac 错误上限下，首批 100 条错误去重涉及 43 个第三方/AndroidX/混淆源码文件，没有 Parser 或 WakeUp 应用包路径。随后 r58 临时将 `:app:compileDebugJavaWithJavac` 错误上限提高到 10,000，输出达到 10,000 条、去重 1,910 个源码路径；Parser 路径错误为 0，WakeUp 应用包仍有 96 个路径错误。r58 的临时参数已移除，不能再用全局替换或猜测性兼容类继续推进。

由 `.restoration-apktool/` 重组的 `build/wakeup-rebuilt-r50-debug.apk` 静态通过 zipalign、apksigner v1/v2/v3 和 aapt2，仍是原 DEX 的可签名二进制，不等于 Gradle 源母体已构建。本轮设备 `3fde7e33`（`22081212C`）已重新连接；执行 `adb install -r` 返回 `Success`，未卸载或清除旧包数据。强制停止后从 `SplashActivity` 冷启动返回 `Status: ok`，`Activity` 为 `.../.schedule.ScheduleActivity`，`TotalTime: 769`，crash buffer 没有该包的 `FATAL EXCEPTION`/`AndroidRuntime`。ScheduleActivity、设置和导入入口的最小黑盒冒烟均已完成；Room 数据库运行证据见下方构建与安装复核。

> r26–r56 记录保留为恢复轨迹；当前结论以 r57 标准构建、r58 扩展诊断和上面的静态检查为准。还原候选尚未达到可编译母体标准。

## 当前结论

路线已从“新建 Weeko 原生工程”纠正为“WakeUp 6.0.23 APK 还原母体优先”。审计确认：仓库没有 WakeUp 原始 Gradle 工程、源码或 Git 历史；当前能构建的 `app/` 是另建的 `io.github.mxwf.weeko` Compose/Room 实验工程，不是 WakeUp 还原工程。它和 `adapter/wakeup` 均保留，但已被标记为非权威、不得继续扩展为替代应用。

R1 已按证据推进：`LoginWebFragment.OoooOO0`、WebView 回调组和 Parser 文件已逐组恢复；当前 WakeUp 自有包和全工程行首 `??` 均为 0。r57 的首批错误及 r58 的扩展诊断均不再包含 Parser，剩余错误分布在第三方/混淆源码和 WakeUp 应用包（扩展诊断去重 1,910 个路径，其中 WakeUp 应用包 96 个），主要是 JADX 丢失的嵌套类型、循环继承、重复方法、外部 obfuscated package 解析冲突和缺少 `androidx.window` sidecar/extension 类。没有开始 UI、Compose、身份、数据库或业务流程改造。

## 阶段状态

| 工作项 | 状态 | 事实 |
| --- | --- | --- |
| APK 身份/Manifest 审计 | 已完成 | 包名 `com.suda.yzune.wakeupschedule`，6.0.23/263，min 21，target 35；组件、权限、Provider、Widget、WorkManager 已记录 |
| DEX/资源证据 | 已完成（静态） | JADX 1.5.6 输出 679 个 WakeUp 自有 Java 文件并报告 66 个错误；apktool 2.10.0 成功解码资源/Manifest/smali |
| WakeUp Gradle 候选 | 已建立但不可构建 | JADX `--export-gradle` 生成 `.wakeup-restoration/`；资源、Manifest 和签名配置处理已通过；r1 依据 smali 恢复登录方法、WebView 回调组及 Parser 组，r57 首个错误仍在第三方/混淆类，扩展诊断还显示 96 个 WakeUp 应用包路径错误，未生成 Gradle APK |
| apktool 重组二进制 | 已确认可重建、可安装并运行 | `build/wakeup-rebuilt-r50-debug.apk` 由 `.restoration-apktool/` 生成并通过 aapt2、zipalign、apksigner；2026-09-01 在设备 `3fde7e33` 上 `adb install -r` 成功并进入 `ScheduleActivity`；它不是可维护 Gradle 源工程 |
| Room/Preferences/文件格式证据 | 已完成（静态） | Room v11、路径分支、7→11 SQL、Preference 文件/键、五行 `.wakeup_schedule` 已索引 |
| 黑盒运行验证 | 重组包最小冒烟已完成，原始包差异待解释 | 原始签名 APK 的一次启动出现系统 locale 绑定阶段 NPE；本轮 apktool 重组并 debug 签名的 APK 已进入旧 `ScheduleActivity`，并验证设置、CSV 导入入口和 Room 数据库打开，两者不能直接视为等价 |
| WakeUp 可编译母体 | 阻塞 | 已有原包名 Gradle 候选，但缺少原始 Gradle/源码/mapping；r57 的 `mergeDebugResources`、`processDebugMainManifest`、`processDebugResources` 通过，`compileDebugJavaWithJavac` 仍失败，默认错误上限下首批去重涉及 43 个第三方/混淆文件，r58 扩展诊断去重 1,910 个路径（WakeUp 应用包 96 个）；当前 `app` 不计入 |
| Weeko-native 代码 | 保留并隔离 | 22 个 Kotlin 源文件、Weeko Room v1、Compose、课程详情/editor；不删除、不接入母体 |
| Git 状况 | 未建立 | `.git` 不存在，无分支、提交和 diff |

## 目录审计

| 路径 | 归属 | 风险/处理 |
| --- | --- | --- |
| `wakeup6.0.23.apk` | 原始 WakeUp 研究输入 | 高价值、只读、固定哈希 |
| `.stage4a-jadx/` | Java/资源反编译证据 | 不可直接编译；混淆/错误必须互证 |
| `.restoration-apktool/` | Manifest、资源、smali 证据 | 不作为 module；还原时逐项引用 |
| `.wakeup-public-source/` | YZune/WakeUpSchedule 公开历史对照，master `5d43928`（2018-04-07），2.10/GreenDAO | 只作版本和架构演变证据；未发现许可证文件；不复制源码 |
| `.wakeup-restoration/` | JADX 导出的原包名 Gradle 候选（6,756 个 Java 文件，其中 679 个为 `com.suda.yzune.wakeupschedule`，6,077 个为非应用包代码） | 当前唯一旧工程候选；第三方/混淆源码保留原路径并以归属清单逻辑隔离，未删除、未伪造兼容类；R2 的正式依赖替换实验未降低错误且已撤回，源码编译仍被反编译 Java 阻塞 |
| `app/` | 误建 Weeko-native 实验 | 暂不删除；后续决定隔离/回退/复用 |
| `adapter/wakeup/` | 手写 parser 候选 | 不代表 APK 兼容；暂不接入正式母体 |
| `docs/` | 项目证据与路线 | 本轮更新 |
| `build/`、`.gradle*`、`.kotlin/` | 生成物/缓存 | 非源码，不作为母体证据 |

## 旧架构关系（证据摘要）

- **Activity/Fragment**：launcher `SplashActivity`；主课表 `schedule.ScheduleActivity`；课程编辑 `course_add.AddCourseActivity`；设置、作息、课表管理、课表设置、关于和导入由旧包下的 Activity 承担。完整声明见 `EVIDENCE_MATRIX.md`。
- **Room**：schema version 11；`CourseBaseBean`、`CourseDetailBean`、`AppWidgetBean`、`TimeDetailBean`、`TimeTableBean`、`TableBean` 六张业务表；数据库名 `wakeup`，另有条件路径分支；迁移 7→8→9→10→11。
- **Preferences**：`multi_language`、`config`、`table{id}_config`、`time{id}_config`、`widget{id}_config`；动态键和默认值不能猜测。
- **Widget/通知/Alarm/WorkManager**：六个 provider、三个 RemoteViews service、MIUI `:widgetProvider` 进程；AlarmManager 课程提醒；WorkManager/AndroidX 初始化和厂商任务；旧 action、authority、channel、request code 属高风险边界。
- **导入导出/Parser/网络**：五行 JSON `.wakeup_schedule`；导入入口接受 `.wakeup_schedule`、HTML、CSV；Parser 输出旧 Course/TimeTable/TimeDetail/WeekBean；APK 同时存在 Ktor 和 Retrofit/OkHttp 迹象。

## 稳定性分级

- **稳定但老旧**：APK Manifest、Room v11/迁移 SQL、数据库路径、Preferences 文件名、五行文件结构、Provider/Widget 声明。
- **可以直接整理**：反编译证据目录、构建脚本/资源引用的逐项修复、错误日志、文档索引；前提是不改变外部行为。
- **高风险不可随便修改**：数据库结构和迁移、导入导出行序/字段、动态 Preference 键、Provider Cursor、Intent action、Widget service、Alarm/通知、Parser 网络/登录边界、混淆类语义。

## 本轮已做与未做

### r35–r40（2026-08-31）

按 smali 和字段描述符恢复 Parser 组及可确认的第三方局部类型。WakeUp Parser 自有包当前无行首 `??`，r54 javac 首批输出中没有 Parser 或 WakeUp 应用包文件；所有修改均保留修改前副本，未改变 Room、Manifest、Preferences、导入格式或应用身份。r54 资源、Manifest、重复类、签名配置和 `processDebugResources` 通过，但 Java 编译仍被第三方/混淆源码的缺失嵌套类型、包名冲突、缺失 window sidecar 类和重复方法阻塞。

已做：设置 JDK 21 后运行 aapt2、apkanalyzer、apktool、JADX；保留解码产物；依据 APK 依赖版本和 Android SDK 属性表逐项恢复候选资源；`mergeDebugResources`、`processDebugResources` 和 Manifest 处理已通过；依据 smali 对前一批类、RecyclerView、ksoup 四个 enum、Material/Huawei 类、文件校验/流类型、生成式 R 类、课程映射、日期监听器、AddCourse、DAO、分享协程和 `LoginWebFragment$refreshCode$1` 进行最小源码恢复。R1 继续完成 `LoginWebFragment.OoooOO0` 的局部类型与协程标签恢复、5 个 WebView 回调文件的确定类型恢复，以及 `schedule_parser/parser/o00000O0.java` 中 3 个方法的寄存器类型拆分；每组均先备份并重跑构建。

未做：未删除或移动 `app/`、未修改 WakeUp 业务源码和 Manifest、未更改 applicationId/namespace、未迁移 Room、未接入 Compose/UI、未伪造数据/Repository、未修改 WakeUp Adapter 行为；还原候选尚未产出可安装 Gradle APK。

## 构建与安装复核

根工程本次复核命令 `:adapter:wakeup:test :app:testDebugUnitTest :app:assembleDebug` 在配置阶段失败：插件 `com.android.tools.build:gradle:9.3.0` 无法从当前可用仓库/缓存解析，因此本次未运行测试或打包；此前缓存环境的成功记录不作为当前构建结论。该工程仍是误建的 Weeko-native 实验，不能作为 WakeUp 母体。

该 APK 安装到设备 `3fde7e33` 成功，`io.github.mxwf.weeko/.MainActivity` 进入 resumed；设备同时保留旧包名。此处只是当前误建 Weeko-native 工程的构建/安装证据，不是 WakeUp 母体构建结果。此前由 apktool 重组并使用本机 debug keystore 签名的 WakeUp APK（SHA-256 `D8B569980EA0945C9F243C01FC3F432BB221DB4F99A595F6BAF77D7155A651FE`）也曾安装成功，属于历史运行记录。当前复核使用 `build/wakeup-rebuilt-r50-debug.apk`（SHA-256 `A146E17D9FF4EE32676039640A836621033C1FC2755C310320807EF3C3C89CEA`）：`adb install -r` 返回 `Success`，随后进入旧 `ScheduleActivity`，UIAutomator 观察到日期、周次、节次和“本周没有课程哦”。

当前包的 `dumpsys dbinfo` 显示 `/data/user/0/com.suda.yzune.wakeupschedule/databases/wakeup` 为 `Open: true`，Room `room_master_table` identity 查询以及 `tablebean`、`timedetailbean`、`coursebasebean natural join coursedetailbean` 查询均成功；同一进程的 WorkManager 数据库也保持打开。点击功能面板的“全局设置”进入 `.settings.SettingsActivity` 并显示设置项。导入入口依次显示“从教务导入/从文件导入/从分享口令”和“从 CSV/从 HTML/从备份”；选择 CSV 后进入 `.schedule_import.LoginWebActivity`，勾选说明并打开系统文件选择器，取消后返回课表且未写入数据。`run-as` 因该 APK 未标记 debuggable 而拒绝，数据库证据来自系统 `dumpsys dbinfo`。原始签名 APK 的 locale 绑定 NPE 与重组包可运行之间的差异尚未解释，不能据此宣称原 APK 已修复。

还原候选的验证命令为 `:app:processDebugResources --rerun-tasks` 和 `:app:assembleDebug --rerun-tasks`。r57 再次确认资源、Manifest、重复类、签名配置和 `processDebugResources` 通过；`compileDebugJavaWithJavac` 首批 100 条错误去重涉及 43 个第三方/混淆源码文件，不包含 Parser 或 WakeUp 应用包。r58 扩展诊断达到 10,000 条错误、去重 1,910 个路径，其中 WakeUp 应用包 96 个、Parser 0 个。日志分别为 `build/evidence-deps/wakeup-restoration-assemble-20260901-r57-clean.log`、`build/evidence-deps/wakeup-restoration-compile-20260901-r58-maxerrors.log`；历史批次及文件/行号清单见 [RESTORATION_BUILD_ERRORS.md](RESTORATION_BUILD_ERRORS.md)。该结果与 apktool 重组 APK 分开记录，不能把重组 APK 当作 Gradle 母体构建结果。

## 下一步

`.wakeup-restoration/` 仍是唯一 WakeUp 旧包名候选，`app/` 与 `adapter/wakeup/` 继续保留但不作为母体。r57/r58 结论为“Parser 显式未反编译方法已按证据补齐且扩展编译无 Parser 错误，但 Gradle 母体仍不可构建”，阻塞分布在第三方/混淆源码和 WakeUp 应用包的结构缺失；缺少 mapping/对应依赖源码时不能安全批量补齐。apktool 重组并签名的当前静态复核包为 `build/wakeup-rebuilt-r50-debug.apk`（SHA-256 `A146E17D9FF4EE32676039640A836621033C1FC2755C310320807EF3C3C89CEA`），本轮已在设备 `3fde7e33` 上安装并运行；黑盒已覆盖课表主界面、全局设置和 CSV 文件导入入口（取消返回后未写入数据）。不能通过全局替换、假类或删除旧功能来掩盖缺口；诊断副本和资源备份位于 `build/evidence-deps/`、`build/`，不作为母体提交。

## R1 逐组恢复结果

- **源码归属与隔离**：`.wakeup-restoration/app/src/main/java` 共 6,754 个 Java 文件，其中 678 个属于 WakeUp 包，6,076 个来自第三方或混淆依赖。第三方源码没有删除或移动，以免改变包路径和编译关系；本阶段仅在状态和错误文档中逻辑隔离，未在版本证据不足时改用正式依赖。根目录 `app/`（Weeko-native）和 `adapter/wakeup/` 仍保留，未接入母体。
- **登录方法**：`LoginWebFragment.OoooOO0` 按对应 smali 的字段描述符、调用签名和协程状态标签恢复局部类型与 continuation 分支；修改前备份为 `build/evidence-deps/source-before-login-method-r1.java`，SHA-256 为 `D4FF15B049D2A1E6AA8D6AE6BF292C51B3E193089517E3D61F61E1EFC68143EB`。该方法当前无 `??` 占位符，未使用全局替换、空实现或异常吞掉。WebView 组备份在 `build/evidence-deps/r1-webview-backups/`，解析器备份在 `.wakeup-restoration/build/evidence-deps/r1-parser-backups/`。
- **后续可安全推进的组**：r31 通过 WebView 回调组，r32 通过 `o00000.java`，r33 通过 `o00000O0.java`；这些只做了 smali 可确认的局部类型/寄存器拆分，没有改变 Room、Manifest、导入格式或 UI。
- **静态风险指标**：全工程行首 `??` 当前为 0；当前源码仍可见 3,096 处 `throw null` 和 328 处 `UnsupportedOperationException` 文本，其中 22 处是可执行的 `UnsupportedOperationException("Method not decompiled")`（均在 Parser 之外），Parser 自身保留 134 处 `throw null`。这些需要逐项 smali/运行证据，不能当作已修复或直接批量替换。
- **停止依据**：r58 扩展编译确认 Parser 错误为 0，但 Javac 仍因第三方/混淆源码及 WakeUp 应用包的结构性问题失败；在缺少 mapping/原始依赖源码时继续猜测将跨入高风险恢复，故暂停批量源码编译修补。
