# Weeko v0.7 Stage 4 报告

日期：2026-09-06  
范围：移除课表主页面底部操作栏及其专属状态/动画；保留顶部导航、课程网格和课程详情 BottomSheet。

## 完成内容

可重复补丁入口为 [`tools/replay-weeko-v07-stage4-patches.ps1`](../tools/replay-weeko-v07-stage4-patches.ps1)，构建入口为 [`tools/build-weeko-v07-stage4-debug.ps1`](../tools/build-weeko-v07-stage4-debug.ps1)。脚本从干净 v0.6 apktool 工程依次重放 Stage 1–3，再完成以下最小修改：

- CoordinatorLayout 只保留课表内容作为可见子项；底部 LinearLayout 不再 `addView`，因此课表区域填满可用高度。
- 清除主页面 BottomSheetBehavior 的获取、底栏点击监听、返回键折叠逻辑、首运行/导入完成/菜单中的主页面底栏状态转换。
- 保留兼容字段和未挂载的底部对象，避免改动无关的 inset 管线；课程详情页面自己的 `CourseDetailBottomSheet` 不受影响。
- 未修改数据库、导入数据、提醒、Widget、课程计算和顶部入口。

## 构建证据

- Stage 4 重放退出码为 0：[`build/v0.7/stage4-replay-final.log`](../build/v0.7/stage4-replay-final.log)。
- Apktool 重建成功：[`build/v0.7/stage4-apktool-build.log`](../build/v0.7/stage4-apktool-build.log)。
- 调试验证包：[`build/v0.7/Weeko-v0.7.0-stage4-debug.apk`](../build/v0.7/Weeko-v0.7.0-stage4-debug.apk)。
- 包名 `io.github.mxwf.weeko`，`versionCode=7`，`versionName=0.7.0-stage4`；SHA-256 `E986B21B116A73A1E879A22BE55A43BADCE3FB8F27BF6729E0D73D485BD14D15`，大小 `6,317,459` bytes（[`stage4-release-summary.txt`](../build/v0.7/stage4-release-summary.txt)）。
- `zipalign -c` 通过；`apksigner verify` 的 v1/v2/v3 均通过（[`stage4-apksigner-verify.log`](../build/v0.7/stage4-apksigner-verify.log)）。该包为 debug 签名验证包，不是发布签名包。

## 设备验证

设备 `3fde7e33` 上 `adb install -r` 成功，并以目标包名冷启动 `ScheduleActivity`。

- 主页面 UI 树：[`device-ui-stage4-main.xml`](../build/v0.7/device-ui-stage4-main.xml)。`anko_bottom_sheet` 和 `bottom_sheet` 计数均为 0；`weeko_nav_left`、`anko_ib_add`、`anko_ib_import`、`anko_ib_more`、`anko_vp_schedule` 各出现 1 次。
- 课表布局已延伸到底部：`anko_vp_schedule` bounds 为 `[0,289][2712,1220]`，`anko_sv_schedule` bounds 为 `[0,443][2712,1220]`，底部课程节点同样到达 `y=1220`。
- 左侧菜单仍可打开，菜单文案为“调整周数 / 切换/管理课表 / 回到当前周”：[`device-ui-stage4-left2.xml`](../build/v0.7/device-ui-stage4-left2.xml)。
- 右侧菜单仍可打开，保留“多课表管理 / 分享 / 全局设置 / 关于 Weeko”：[`device-ui-stage4-more.xml`](../build/v0.7/device-ui-stage4-more.xml)。
- 新增和导入顶栏按钮仍存在于目标包主页面；新增入口的既有设备验证见 Stage 3 之前报告。

## 阶段结论

Stage 4 的主页面底部栏、布局占位和专属主页面 BottomSheet 状态已移除，课表内容占满底部空间，顶部导航和右/左菜单保持可用。发布签名仍不在本阶段范围内。
