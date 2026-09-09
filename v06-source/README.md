# Weeko v0.6 About 源码

`WeekoAboutActivity` 是本版本唯一接入 APK 的 Weeko 自有源码。它使用 Android SDK 平台 API 编译为独立 dex，再作为 `classes2.dex` 加入兼容母体 APK；旧课程表、Room、Preferences、导入导出和 Widget 实现保持原样。关于页的联系入口为本地可复制邮箱对话框，不访问课程数据库或网络。

本次将 About 页面对齐现有母体 Material 视觉：使用 `md_theme_background`、
`md_theme_surfaceContainerLow` 和 `md_theme_onSurfaceVariant`，信息容器使用母体同款
16dp 等效圆角，联系按钮使用 12dp 等效圆角，联系弹窗交由母体 Material 主题处理。
About 不再使用独立的自绘曲线路径，避免与其它页面出现不同的曲率观感；旧课程卡片、
设置页及其他兼容母体控件不作全局替换。

字体阶与母体保持一致：工具栏标题 22sp sans-serif，版本和卡片标题 16sp
sans-serif-medium，正文 16sp sans-serif；不引入额外字体文件。

在 Windows 开发环境中，发布脚本使用本地 Android SDK 的 `android-35/android.jar`、JDK 17 `javac` 和 Build Tools 36.0.0 `d8.bat` 编译。源码不依赖 AndroidX、Compose、Room、网络 SDK 或 WakeUp 混淆类，也不访问课程数据库。

旧 AboutActivity 仅作为兼容入口，通过一段最小 smali 桥接启动此 Activity 并结束自身；该桥接不伪造源码实现，旧入口仍保持可用，返回键回到原课程表页面。
