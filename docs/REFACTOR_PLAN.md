# WakeUp 6.0.23 还原与渐进重构计划

最后更新：2026-08-31（Asia/Shanghai）

> 当前计划快照为 r26 最终复核：仍处于 WakeUp 6.0.23 源码还原阶段，未进入 UI 或 Weeko 身份改造。

## 总路线

```text
WakeUp 6.0.23 APK
  → 证据型反编译与工程还原
  → 可编译/可安装/可运行的 WakeUp 母体
  → 保持行为的局部架构整理
  → 页面级 UI、资源、身份和逻辑渐进修改
  → Weeko
```

当前仓库中的 `app/` 和 `adapter/wakeup/` 不改变这条路线。它们是误建代码，暂不删除，不能继续发展成第二套功能应用。

## 进行中的阶段：还原基线

### 目标

先把 APK 还原为一个可持续修复的旧工程边界：原包名、Manifest、资源、Activity、依赖、Room v11、Preferences、导入导出、Widget、提醒和 Parser 都以证据为准。反编译 Java 不是可编译源码；JADX 只用于定位，smali、资源和运行证据用于确认。

### 步骤

1. 固定 APK SHA-256、aapt2/apkanalyzer Manifest、apktool 解包和 JADX 输出。
2. 已创建独立的 `.wakeup-restoration/` WakeUp Gradle 候选，不与当前 `app/` 共享 source set、namespace 或数据库。
3. 已导出原包名下的 Gradle、Manifest、Java 参考源码和资源目录；依据 APK 依赖版本和 Android SDK 属性表恢复了九宫格及 enum/flags 合法表达，`mergeDebugResources`、`processDebugResources` 和 Manifest 处理已通过。apktool 资源诊断副本仍暴露 41 个非法 `$` 文件名和 drawable/color 类型错写；r22–r25 已按 smali 越过 AddCourse、DAO、分享协程和 `LoginWebFragment$refreshCode$1`，r26 的完整构建下一步被 `LoginWebFragment.java` 中的 JADX 非法 Java 阻塞，依赖清单和混淆类型仍需从 APK 证据补齐。
4. 公开 `YZune/WakeUpSchedule` 仅作为历史对照：master `5d43928`（2018-04-07）为 2.10/GreenDAO，和 6.0.23 的 Room v11 不同；仓库未发现许可证文件，因此不复制其源码。
5. 依据 smali、原始 DEX、资源表和依赖版本逐组恢复非法 Java/混淆类型；每组改动都运行 Debug 构建，不先替换视觉资源，不用全局文本替换或假类掩盖不确定语义。
6. 构建通过后安装验证 launcher，再逐步验证旧课表、设置、导入、Widget、提醒和数据库迁移。

### 本阶段禁止

- 不迁移 Compose，不重做 UI，不建立 Weeko Design System。
- 不改变 applicationId、namespace、Provider authority、Intent action、Widget 名称、通知/Alarm 行为或 WorkManager 名称。
- 不建立新的领域模型、Room schema、Repository、假数据或替代页面。
- 不把当前 Weeko-native 实验代码拼接到 WakeUp 母体，也不为通过编译而删除旧功能。

## 还原完成后的阶段顺序

| 阶段 | 前置条件 | 范围 |
| --- | --- | --- |
| A. 构建与启动基线 | 旧母体可编译安装 | launcher、主进程、数据库打开、最小页面启动 |
| B. 行为回归基线 | 有可运行设备和脱敏样本 | 课表、设置、导入导出、Widget、提醒、迁移 |
| C. 低风险架构整理 | B 通过且有测试边界 | 一次只处理一个 Activity/Fragment/Manager 功能区，不改变行为 |
| D. 页面级 UI 现代化 | C 对应页面逻辑已分离 | 先课程详情，再编辑/设置/导入，最后核心周课表；保留旧入口可回退 |
| E. Weeko 身份改造 | 数据迁移和并装策略明确 | 应用名、图标、启动页、包名/authority 按兼容窗口逐项修改 |
| F. 新架构与数据演进 | 旧行为有回归保护 | 只在明确迁移方案后引入新模型、Compose、DataStore 或模块拆分 |

## 每个小批次的验收模板

1. 写明要修复的单一问题和 APK 证据来源。
2. 只修改该问题涉及的 Gradle、资源、Manifest 或必要源码。
3. 运行 `assembleDebug`；若涉及行为，再运行最小单元/设备验证。
4. 记录成功、准确错误和未确认行为；不把推断写成事实。
5. 更新 `REFACTOR_STATUS.md`、`EVIDENCE_MATRIX.md` 和相关风险记录，然后停止等待下一阶段指令。

## 当前阻塞与最小替代方案

缺少旧 Gradle/源码/mapping、真实数据库/导出样本，且研究设备启动 WakeUp 时出现系统 locale 绑定 NPE；当前候选仍被 `LoginWebFragment.java:1093–1169` 中的非法 Java 阻塞。已完成可由 smali 互证的局部类型恢复，RecyclerView 首批寄存器错误已清除，并按 smali 恢复 ksoup 四个 enum/状态机类、Material/Huawei 类、文件校验/流类型、生成式 R 类、课程映射、日期监听器、AddCourse、DAO、分享协程和 `LoginWebFragment$refreshCode$1`；最小下一步是只选择 `LoginWebFragment.java` 的一个方法取得完整 DEX/smali 或已确认依赖证据，或在证据不足时保留阻塞并报告，继续验证 `assembleDebug`，保持所有未知行为原样标记；不能用 Weeko-native 假实现、假类或删功能掩盖阻塞。
