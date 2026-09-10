# Weeko v0.8 Stage 4：课表色彩层级报告

日期：2026-09-10  
范围：主课表的亮色/深色色板、课程卡语义色与视觉层级；不改变几何、交互或顶栏布局。

## 结论

Stage 4 已完成。课表背景、表头/网格、日期选中状态、正文层级和课程卡现在使用冷中性色系统；课程卡从高饱和原色改为低饱和语义色，深色模式使用独立的深色容器与浅色文字。课程卡尺寸、课程位置、周轨布局、点击路径和顶栏结构保持原样。

## 色板

| 角色 | Light | Dark |
| --- | --- | --- |
| 主背景 | `#F7F8FA` | `#101419` |
| 顶部/低层 Surface | `#F1F3F6` | `#171C22` |
| 正文 | `#20252B` | `#F1F4F7` |
| 次要文字 | `#65717D` | `#A9B3BE` |
| Outline Variant | `#E2E7EC` | `#2B343D` |
| Brand / current / selected rail | `#4F6BFF` | `#7894FF` |

选中日期、当前日/周轨和关键强调统一使用蓝色；红色只保留给课程语义色，不再承担全局强调。课程卡描边使用课程色与主背景的 24% 混合色，保留轮廓但降低噪声。

## 课程语义映射

运行时同时识别原始资源色、带 `0x99` alpha 的绘制色和已映射色。Light/Dark 结果如下：

| 语义 | Light card | Dark card |
| --- | --- | --- |
| Rose `#FF1744`, `#FC718D` | `#ECCCD2` | `#653A45` |
| Soft rose `#FA6278` | `#E6CDD5` | `#6B414D` |
| Blue `#2979FF` | `#CFE1F8` | `#294865` |
| Teal `#1DE9B6`, `#74EFD1` | `#CBE8E2` | `#28564F` |
| Purple `#A375FF` | `#DDD5EE` | `#4C4264` |
| Yellow `#FF9100` | `#F2E5B8` | `#62542B` |
| Orange `#FF3D00` | `#F2D4C2` | `#654737` |
| Slate `#2196F3` | `#D5E0E8` | `#3C4B57` |
| Green `#005CAF` | `#D9E8CE` | `#3C5534` |

粗体日期改用主题主色，节次/时间和普通日期使用次要文字色；网格线使用半透明 Outline Variant。

## 修改文件

| 文件 | 内容 |
| --- | --- |
| `tools/replay-weeko-v08-settings-stage4-patches.ps1` | 重放 Stage 3 后写入 Light/Dark 色板、课程资源色和运行时课程映射；保持现有布局与资源 ID |
| `tools/build-weeko-v08-settings-stage4-debug.ps1` | 干净母体重建、原 DEX 注入、zipalign、debug 签名、badging/签名校验 |
| `docs/V08_STAGE4_REPORT.md` | 本阶段实现与验证记录 |

## 构建产物

产物：`build/v0.8/Weeko-v0.8.0-settings-stage4-debug.apk`  
包名：`io.github.mxwf.weeko`  
版本：`versionCode 9`，`versionName 0.8.0-settings-stage3`  
大小：`7,948,008` bytes  
SHA-256：`F6BD776E7D9F64F59BB949B768B056A9F16BF458E783332CE1BF4794DB92756`

重建脚本连续执行后哈希保持一致。`classes.dex` 之外的原始 DEX 以 `classes2.dex` 注入；zipalign 通过，apksigner v1/v2/v3 通过，APK badging 确认包名、版本和 target SDK 35。

## 实机验证

设备：`3fde7e33`，分辨率 `1220×2712`，`rotation=0`。最终 APK 通过 `adb install -r` 覆盖安装，未清除应用数据。冷启动进入原课表，原课程数据和原位置保留。

- 亮色课表截图：[schedule-stage4-light-device-final.png](../build/v0.8/evidence/schedule-stage4-light-device-final.png)
- 深色课表截图：[schedule-stage4-dark-device-final.png](../build/v0.8/evidence/schedule-stage4-dark-device-final.png)
- 深色主题设置验证：[settings-stage4-current.png](../build/v0.8/evidence/settings-stage4-current.png)（通过应用内“显示主题 → 深色模式”切换后确认设置页层级）
- UI dump 通过 `adb shell uiautomator dump` 检查，未作为产物提交。

亮色截图显示浅灰背景、蓝色当前日/周轨和粉/青低饱和课程卡；深色截图显示 `#101419` 主背景、深色语义卡、浅色课程文字和蓝色选中状态。菜单打开/关闭、设置页进入/返回、主题对话框选择和冷启动均通过；logcat 未出现 Weeko 的 `FATAL EXCEPTION` 或 `ANR`。

## 边界与剩余项

本阶段未改变课程数据、课表数据、尺寸、间距、触摸区域、周轨结构或顶栏布局，也没有进行横屏测试。顶栏仍保留应用原有背景图层；若后续需要把顶栏背景完全收敛到静态 Surface 色，应另开范围，不在本阶段追加结构性修改。
