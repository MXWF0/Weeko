param([Parameter(Mandatory = $true)] [string] $ProjectPath)
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
& (Get-Command pwsh.exe).Source -NoProfile -File (Join-Path $PSScriptRoot 'replay-weeko-v120-patches.ps1') -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw 'v1.2.0 baseline replay failed' }
function Replace-V121Text($relative, $old, $replacement) {
    $path = Join-Path $project $relative
    $text = [IO.File]::ReadAllText($path).Replace("`r", '')
    $old = $old.Replace("`r", '')
    if ([regex]::Matches($text, [regex]::Escape($old)).Count -ne 1) { throw "Expected one v1.2.1 patch target: $relative" }
    [IO.File]::WriteAllText($path, $text.Replace($old, $replacement.Replace("`r", '')), [Text.UTF8Encoding]::new($false))
}
Replace-V121Text 'apktool.yml' 'versionCode: 20' 'versionCode: 21'
Replace-V121Text 'apktool.yml' 'versionName: 1.2.0' 'versionName: 1.2.1'
Replace-V121Text 'smali/com/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette.smali' @'
    invoke-virtual {v0, p3}, Landroid/widget/TextView;->setTextColor(I)V
'@ @'
    invoke-virtual {v0, p3}, Landroid/widget/TextView;->setTextColor(I)V
    invoke-static {v0, p3}, Lio/github/mxwf/weeko/theme/SoftDynamicColors;->styleDateHighlight(Landroid/widget/TextView;I)V
'@
# Permit the shared callback to opt in at runtime. No change to the legacy back dispatcher.
Replace-V121Text 'AndroidManifest.xml' '<activity android:label="@string/title_add_course"' '<activity android:enableOnBackInvokedCallback="true" android:label="@string/title_add_course"'
Replace-V121Text 'AndroidManifest.xml' '<activity android:exported="false" android:label="密码箱"' '<activity android:enableOnBackInvokedCallback="true" android:exported="false" android:label="密码箱"'
# The native dispatcher is runtime-gated in the shared component. Opt in every
# in-app BaseActivity, not just BaseListActivity; keep Widget/external hosts out.
$manifestPath = Join-Path $project 'AndroidManifest.xml'
$manifestText = [IO.File]::ReadAllText($manifestPath)
[xml]$manifest = $manifestText
$androidNamespace = 'http://schemas.android.com/apk/res/android'
foreach ($entry in $manifest.manifest.application.activity) {
    $name = $entry.GetAttribute('name', $androidNamespace)
    if ($name -match '\.schedule_appwidget\.' -or $entry.GetAttribute('enableOnBackInvokedCallback', $androidNamespace) -eq 'true') { continue }
    $type = $name
    while ($type.StartsWith('com.suda.yzune.wakeupschedule.')) {
        if ($type -eq 'com.suda.yzune.wakeupschedule.base_view.BaseActivity') {
            $pattern = '<activity\b[^>]*android:name="' + [regex]::Escape($name) + '"[^>]*>'
            $manifestText = [regex]::Replace($manifestText, $pattern, {
                param($match)
                $match.Value.Replace('<activity ', '<activity android:enableOnBackInvokedCallback="true" ')
            })
            break
        }
        $classPath = Join-Path $project ('smali/' + $type.Replace('.', '/') + '.smali')
        $super = [regex]::Match([IO.File]::ReadAllText($classPath), '(?m)^\.super L([^;]+);')
        if (!$super.Success) { throw "Missing Activity superclass: $type" }
        $type = $super.Groups[1].Value.Replace('/', '.')
    }
}
[IO.File]::WriteAllText($manifestPath, $manifestText, [Text.UTF8Encoding]::new($false))
Replace-V121Text 'smali/androidx/activity/Oooo000.smali' `
    '    invoke-interface {p1, p2, p3}, Landroid/window/OnBackInvokedDispatcher;->registerOnBackInvokedCallback(ILandroid/window/OnBackInvokedCallback;)V' `
    @'
    invoke-interface {p1, p2, p3}, Landroid/window/OnBackInvokedDispatcher;->registerOnBackInvokedCallback(ILandroid/window/OnBackInvokedCallback;)V
    invoke-static {p1}, Lio/github/mxwf/weeko/navigation/LayeredPageTransition;->frameworkBackRegistered(Ljava/lang/Object;)V
'@
# Material sheets have their own native back dispatcher. Gate its callback
# factory too; otherwise they keep following the gesture when the setting is off.
$materialBack = 'smali/o000o00.1/oo0o0Oo.smali'
Replace-V121Text $materialBack @'
.method public OooO0O0(Lo000o00/o0OO00O;Landroid/view/View;Z)V
    .locals 1
'@ @'
.method public OooO0O0(Lo000o00/o0OO00O;Landroid/view/View;Z)V
    .locals 2
'@
Replace-V121Text $materialBack @'
    :cond_0
    invoke-static {p2}, LOooo/o00oO0o;->OooO0Oo(Landroid/view/View;)Landroid/window/OnBackInvokedDispatcher;
'@ @'
    :cond_0
    invoke-virtual {p2}, Landroid/view/View;->getContext()Landroid/content/Context;
    move-result-object v0
    invoke-static {v0}, Lio/github/mxwf/weeko/theme/UiEffects;->predictiveBack(Landroid/content/Context;)Z
    move-result v1
    invoke-static {p2}, LOooo/o00oO0o;->OooO0Oo(Landroid/view/View;)Landroid/window/OnBackInvokedDispatcher;
'@
Replace-V121Text $materialBack @'
    :cond_1
    invoke-virtual {p0, p1}, Lo000o00/oo0o0Oo;->OooO00o(Lo000o00/o0OO00O;)Landroid/window/OnBackInvokedCallback;
'@ @'
    :cond_1
    if-eqz v1, :weeko_v121_material_plain_back
    invoke-virtual {p0, p1}, Lo000o00/oo0o0Oo;->OooO00o(Lo000o00/o0OO00O;)Landroid/window/OnBackInvokedCallback;
'@
Replace-V121Text $materialBack @'
    move-result-object p1

    .line 17
    iput-object p1, p0, Lo000o00/oo0o0Oo;->OooO00o:Landroid/window/OnBackInvokedCallback;
'@ @'
    move-result-object p1
    goto :weeko_v121_material_back_ready
    :weeko_v121_material_plain_back
    new-instance v0, Landroidx/activity/OooOo;
    const/4 v1, 0x3
    invoke-direct {v0, v1, p1}, Landroidx/activity/OooOo;-><init>(ILjava/lang/Object;)V
    move-object p1, v0
    :weeko_v121_material_back_ready
    .line 17
    iput-object p1, p0, Lo000o00/oo0o0Oo;->OooO00o:Landroid/window/OnBackInvokedCallback;
'@
Replace-V121Text 'res/values/public.xml' '</resources>' @'
    <public type="string" name="weeko_predictive_back" id="0x7f12024a" />
    <public type="string" name="weeko_advanced_materials" id="0x7f12024b" />
</resources>
'@
foreach ($locale in @('values', 'values-zh-rCN')) {
    Replace-V121Text "res/$locale/strings.xml" '</resources>' @'
    <string name="weeko_predictive_back">预测性返回手势</string>
    <string name="weeko_advanced_materials">高级材质</string>
</resources>
'@
}
$settings = 'smali/com/suda/yzune/wakeupschedule/settings/SettingsActivity.smali'
Replace-V121Text $settings '    :weeko_v114_no_dynamic_color' @'
    :weeko_v114_no_dynamic_color
    const v5, 0x7f12024a
    const/16 v7, 0x8
    const-string v6, "config"
    invoke-virtual {p0, v6, v3}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v6
    const-string v0, "predictive_back"
    const/4 v4, 0x0
    invoke-interface {v6, v0, v4}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z
    move-result v6
    new-instance v4, Lo00O0o00/OooOOO0;
    const-string v0, "跟随返回手势预览上一页 · 需要 Android 14 或更高版本"
    invoke-direct {v4, v5, v7, v0, v6}, Lo00O0o00/OooOOO0;-><init>(IILjava/lang/String;Z)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v4, Lo00O0o00/OooOOO0;
    const v5, 0x7f12024b
    const-string v0, "半透明磨砂玻璃与渐进模糊；关闭后使用纯色材质"
    invoke-static {p0}, Lio/github/mxwf/weeko/theme/UiEffects;->advancedMaterials(Landroid/content/Context;)Z
    move-result v6
    invoke-direct {v4, v5, v7, v0, v6}, Lo00O0o00/OooOOO0;-><init>(IILjava/lang/String;Z)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    const/4 v7, 0x4
'@
# Oooo0o builds the entire list and has enough locals; no new UI adapter or click path.
Replace-V121Text 'smali/com/suda/yzune/wakeupschedule/settings/OooOOO.smali' @'
    :weeko_v114_other_switch
    const/4 v3, -0x1
'@ @'
    :weeko_v114_other_switch
    invoke-static {p1, v0, p2}, Lio/github/mxwf/weeko/theme/UiEffects;->change(Landroid/content/Context;IZ)Z
    move-result v3
    if-eqz v3, :weeko_v121_original_switch
    goto/16 :goto_0
    :weeko_v121_original_switch
    const/4 v3, -0x1
'@
# Do not enable native window blur or install the blur callback in solid mode.
Replace-V121Text 'smali/com/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet.smali' @'
    sget v8, Landroid/os/Build$VERSION;->SDK_INT:I
    const/16 v9, 0x1f
    if-lt v8, v9, :weeko_v114_skip_sheet_blur
'@ @'
    invoke-virtual {v1}, Landroid/view/View;->getContext()Landroid/content/Context;
    move-result-object v8
    invoke-static {v8}, Lio/github/mxwf/weeko/theme/UiEffects;->advancedMaterials(Landroid/content/Context;)Z
    move-result v8
    if-eqz v8, :weeko_v114_skip_sheet_blur
    sget v8, Landroid/os/Build$VERSION;->SDK_INT:I
    const/16 v9, 0x1f
    if-lt v8, v9, :weeko_v114_skip_sheet_blur
'@
# Reuse the original index 0/1 delete paths. A message hides AlertController's
# single-choice list; the course title plus explicit choices are the confirmation.
$deleteMenu = 'smali/com/suda/yzune/wakeupschedule/schedule/OooOOO0.smali'
Replace-V121Text $deleteMenu '    filled-new-array {v6, v3, v5}, [Ljava/lang/String;' '    filled-new-array {v6, v3}, [Ljava/lang/String;'
Replace-V121Text $deleteMenu @'
    const v6, 0x7f1200d9
    invoke-virtual {v4, v6}, Landroidx/fragment/app/oo0o0Oo;->OooOOO(I)Ljava/lang/String;
    move-result-object v6
    iput-object v6, v7, Landroidx/appcompat/app/OooO;->OooO0o:Ljava/lang/CharSequence;
'@ ''
foreach ($locale in @('values-zh-rCN','values-zh-rHK','values-zh-rTW','values-zh-rSG','values-zh-rMO')) {
    Replace-V121Text "res/$locale/strings.xml" `
        '<string name="detail_delete_choice_0">仅第%1$d周%2$s的这节课</string>' `
        '<string name="detail_delete_choice_0">仅第 %1$d 周（%2$s）的这一次</string>'
    Replace-V121Text "res/$locale/strings.xml" `
        '<string name="detail_delete_choice_1">全部%1$s同老师同地点的这节课</string>' `
        '<string name="detail_delete_choice_1">这个时间段的全部周次（%1$s，同教师、地点）</string>'
}
Replace-V121Text 'res/values/strings.xml' `
    '<string name="detail_delete_choice_0">Only the lesson on %2$s, Week %1$d</string>' `
    '<string name="detail_delete_choice_0">Only this occurrence (%2$s, week %1$d)</string>'
Replace-V121Text 'res/values/strings.xml' `
    '<string name="detail_delete_choice_1">All the lessons on %1$s with the same teacher and same place</string>' `
    '<string name="detail_delete_choice_1">All weeks of this time slot (%1$s, same teacher and location)</string>'
Write-Output 'Applied v1.2.1 effect preferences and two explicit existing course-delete scopes.'
