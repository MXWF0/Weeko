# WakeUp 残留清单

## v0.6 复查（2026-09-05）

以下为当前 v0.6 工作副本复查；后文保留 v0.5 历史记录，不表示 v0.6 没有做品牌分离。
资源 `res/values/strings.xml` 中匹配 wakeup 的剩余项是资源键 `wakeup_club`，值已经是
“Weeko 过渡内测版”。实际导出菜单显示“导出 Weeko 兼容备份、分享 Weeko、在线分享
Weeko 课表”，About 标题和版本也已更换。没有因本轮复查删除任何共用类或资源。

| 分类 | 证据位置（相对 `.weeko-v0.6-apktool/smali/com/suda/yzune/wakeupschedule`） | 处理结论 |
| --- | --- | --- |
| 旧分享品牌前缀 | `schedule_import/OooO00o.smali` | 输入识别协议，保留 WakeUp 并兼容 Weeko，不能改成只认新品牌 |
| 教务请求标识 WakeUp | `schedule_import/login_school/jlu/UIMS.smali:5106` | 属于教务链路，未核实服务端约定，暂不改 |
| 厂商组件包及 WakeUpEntity | `ScheduleContentProvider.smali`、`utils/VivoIntentEntity.smali` | 第三方/Widget 协议，不作产品文案替换 |
| 原联系网址 | `schedule/Oooo0.smali:56` | 仍在历史回调代码，不能将静态存在当成当前入口可达；尚未删除 |
| FAQ、导出教程 | `schedule/o000oOoO.smali`、`schedule/Oooo0.smali`、`schedule_settings/Oooo000.smali` | 旧帮助内容未有等价 Weeko 教程，不盲目跳到仓库首页 |
| CSV/HTML/教务教程及模板 | `schedule_import/OooO.smali`、`OooOOO.smali`、`OooOO0.smali`、`o0Oo0oo.smali`、`o000000.smali`、`SchoolListActivity.smali` | 导入帮助依赖，不删除模板或改变格式 |
| `wakeup.fun/asset/version.json` 和学校列表 | `schedule_import/SchoolListActivity$initSchoolList$1$1.smali` | 是学校配置更新边界，不能误当应用更新地址替换 |
| `i.wakeup.fun` | `utils/Oooo0.smali` | 兼容在线服务边界，未经运行确认，不禁用 |
| `s_update` | `settings/SettingsActivity.smali`、`settings/OooOOO.smali` | 旧自动更新可见设置已移除，Preferences 键/历史读取保留 |

独立 About 更新检查仅由 `v06-source/.../GitHubUpdateChecker.java` 访问 MXWF0/Weeko
Releases API。这不表示整个 APK 已不含旧服务地址。旧组件类名、Room v11、数据库名、
Preferences 键、文件扩展名、迁移记录及许可证继续保留。当前没有完整资源可达性证明，
因此本轮未删除旧图片或公共资源 ID。设备运行时还能观察到 `ha_limit.db` 与
`userEvent.db`，只能证明存在数据库连接，不能据此断言发送了何种信息。

## v0.5 历史盘点

更新时间：2026-09-03  
范围：`build/v0.5/Weeko-v0.5.0-test1.apk`、`.weeko-v0.5-apktool/` 及其资源/Manifest。  
主要证据：`build/v0.5/logs/wakeup-remnants.txt`、`.weeko-v0.5-apktool/AndroidManifest.xml`、资源 XML、APK 内 DEX/SMALI 字符串，以及本机包安装检查。

本文是残留 inventory，不是清理授权。除 About 页面自己的视觉修正外，本轮没有删除或禁用下列内容；静态命中也不等于已经发生联网、遥测或用户可见行为。

## 已确认仍存在

| 区域 | 残留证据 | 当前状态与风险 |
| --- | --- | --- |
| 旧源码身份 | `com.suda.yzune.wakeupschedule.App`、`SplashActivity`、`ScheduleActivity`、`SettingsActivity`、`AddCourseActivity` 等类名仍在 Manifest/DEX 中 | 旧工程母体与行为边界，风险高；不可用全局替换清理 |
| Provider / authority | `io.github.mxwf.weeko.provider` 对应 `ScheduleContentProvider`；`io.github.mxwf.weeko.androidx-startup`；HMS `AnalyticsKitInitializeProvider`、`aaidinitprovider` | 组件发现和外部 URI 兼容边界，风险高；需逐项调用证据后处理 |
| Room / WorkManager | `androidx.room.MultiInstanceInvalidationService`；AndroidX Startup、`SystemAlarmService`、`SystemJobService`、`SystemForegroundService` 及 ForceStop/Reschedule receivers | 影响数据库并发、提醒与后台任务，风险高；本轮未改 |
| Widget | `ScheduleAppWidget`、`TodayCourseAppWidget`、MIUI/Vivo 变体、配置 Activity 和 RemoteViews service；多份 `*_app_widget_info.xml` | 行为和桌面兼容风险高；本轮不作为 About 验收范围，未删 |
| 闹钟/通知相关权限 | `VIBRATE`、`POST_NOTIFICATIONS`、`SCHEDULE_EXACT_ALARM`、`WAKE_LOCK`、`RECEIVE_BOOT_COMPLETED`、`FOREGROUND_SERVICE`、电池优化请求 | 可能支撑提醒和重启恢复，风险高；仅凭权限不能推断实际调度 |
| 教务/在线入口 | `LoginWebActivity`、`SchoolListActivity`、`fragment_web_view_login.xml`，以及在线分享、申请适配、更新/帮助相关字符串和入口类 | 可能依赖旧服务，行为风险高；未验证服务可用性，未禁用网络权限 |
| WakeUp 数据兼容 | `.wakeup_schedule` MIME/入口、旧分享识别、Room v11、Preferences 键和旧组件类名 | 迁移与导入兼容边界，风险最高；保持原样 |
| Donate / Suda Life / Clock | `DonateActivity`、`activity_donate.xml`、`fragment_donate.xml`、`donate_menu.xml`；`SudaLifeActivity`、`suda_life_menu.xml` 的“课程时钟”资源；`ClockActivity`、`activity_clock.xml` | 专属入口已从本轮可见设置面板移除，但共享类、布局、字符串仍在；后续需调用链确认后再清理 |
| WakeUp 资源标识 | `wakeup` drawable、`wakeup_club`、部分旧应用/分享/更新文案及 `public.xml` 公共资源 ID | 多数是历史资源或兼容文本，风险低到中；不能据名称判断是否可删除 |
| 第三方 SDK/厂商集成 | Huawei HMS/AGConnect/Hianalytics/AAID provider、Vivo/Honor 权限与 Widget 元数据、Google `AD_ID` 权限；APK 内还保留 Ktor/混淆服务声明 | 静态存在已确认；实际初始化、网络和遥测路径未知，风险中到高；不作隐私承诺 |
| 许可证与第三方声明 | APK `unknown/LICENSES`、`META-INF/services/*` 及第三方库 license 文件 | 发行合规所需，风险中；不可随意删除 |

## 实机已确认与尚未确认

已确认本机同时安装 `io.github.mxwf.weeko` 与 `com.suda.yzune.wakeupschedule`；Weeko 冷启动可进入旧母体的课程表入口，About 页面通过旧入口桥接打开并可返回。当前设备检查记录见 `build/v0.5/logs/about-native-rounded-cold-start.log`。

以下仍不能从当前证据写成确定结论：HMS/厂商 SDK 是否在本设备实际初始化或联网、更新/帮助/在线分享服务是否可用、教务登录是否把凭据写入持久存储、所有 Widget 在桌面上的刷新与重启恢复、旧分享口令的完整历史版本差异。`wakeup-remnants.txt` 中的静态字符串和权限命中只说明 APK 中有相关内容。

`wakeup-remnants.txt` 的 `smali/package family counts` 为目录扫描结果，不能当作 DEX 中不存在这些依赖的证明；真实类型仍需结合反编译 DEX、调用链和运行日志判断。

## 风险分层

- **高风险、暂不动**：Room v11/Provider、`.wakeup_schedule` 与旧分享识别、提醒/Alarm、Widget、WorkManager、教务登录和旧组件类名。
- **中风险、需调用证据**：HMS/厂商初始化、在线分享/更新/帮助、Donate/Suda Life/Clock 共享逻辑、旧导出/分享字符串。
- **低风险、可后续单独清点**：未被引用的历史文案、公共资源表条目和已确认只用于展示的旧品牌图片；仍须先做资源引用扫描和安装回归。

## 本轮明确未做的事

没有删除旧类、资源、权限、网络 SDK、Widget、Room/Preferences 键、导入格式或 Manifest 组件；没有修改 WakeUp Adapter，也没有修改 `.weeko-v0.5-apktool` 中上述残留。后续若要处理，应一次只选择一个有完整调用证据的区域，先备份、再构建和回归。
