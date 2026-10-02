param(
    [Parameter(Mandatory = $true)] [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source

function Replace-V115RegexText {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Pattern,
        [Parameter(Mandatory = $true)] [AllowEmptyString()] [string] $Replacement
    )
    $path = Join-Path $project $RelativePath
    if (!(Test-Path -LiteralPath $path)) { throw "Patch input is missing: $RelativePath" }
    $original = [IO.File]::ReadAllText($path)
    $lineEnding = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $content = $original.Replace("`r", "")
    $matches = [regex]::Matches($content, $Pattern)
    if ($matches.Count -ne 1) { throw "Expected one v1.1.5 regex patch target in $RelativePath; found $($matches.Count)" }
    $match = $matches[0]
    $replacementLf = $Replacement.Replace("`r", "")
    $content = $content.Substring(0, $match.Index) + $replacementLf + $content.Substring($match.Index + $match.Length)
    if ($lineEnding -eq "`r`n") { $content = $content.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

& $pwsh -NoProfile -File (Join-Path $root "tools\replay-weeko-v114-patches.ps1") -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "v1.1.4 patch replay failed; v1.1.5 patches were not applied." }

function Replace-V115ExactText {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Old,
        [Parameter(Mandatory = $true)] [AllowEmptyString()] [string] $New
    )
    $path = Join-Path $project $RelativePath
    if (!(Test-Path -LiteralPath $path)) { throw "Patch input is missing: $RelativePath" }
    $original = [IO.File]::ReadAllText($path)
    $lineEnding = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $content = $original.Replace("`r", "")
    $oldLf = $Old.Replace("`r", "").TrimEnd("`n")
    $newLf = $New.Replace("`r", "").TrimEnd("`n")
    if ([regex]::Matches($content, [regex]::Escape($oldLf)).Count -ne 1) {
        throw "Expected one v1.1.5 patch target in $RelativePath"
    }
    $content = $content.Replace($oldLf, $newLf)
    if ($lineEnding -eq "`r`n") { $content = $content.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

Replace-V115ExactText "apktool.yml" "  versionCode: 18`n  versionName: 1.1.4" "  versionCode: 19`n  versionName: 1.1.5"

Replace-V115ExactText "AndroidManifest.xml" `
    '<activity android:label="@string/title_select_school" android:name="com.suda.yzune.wakeupschedule.schedule_import.SchoolListActivity" android:windowSoftInputMode="adjustResize" android:screenOrientation="portrait"/>' `
    '<activity android:label="@string/title_select_school" android:name="com.suda.yzune.wakeupschedule.schedule_import.SchoolListActivity" android:theme="@style/WeekoEduImportBackThemeV115" android:windowSoftInputMode="adjustResize" android:screenOrientation="portrait"/>'
Copy-Item (Join-Path $PSScriptRoot "edu-import-back-v115\weeko_edu_import_back_theme.xml") (Join-Path $project "res\values\weeko_edu_import_back_theme.xml") -Force

Replace-V115ExactText "smali\com\suda\yzune\wakeupschedule\base_view\BaseListActivity.smali" @'
    invoke-virtual {v2, v3}, Landroidx/appcompat/widget/Toolbar;->setNavigationIcon(I)V

    .line 69
'@ @'
    invoke-virtual {v2, v3}, Landroidx/appcompat/widget/Toolbar;->setNavigationIcon(I)V

    iget-object v3, v2, Landroidx/appcompat/widget/Toolbar;->OooO0oo:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v3}, Landroid/widget/TextView;->getCurrentTextColor()I
    move-result v3
    iget-object v4, v2, Landroidx/appcompat/widget/Toolbar;->OooOO0:Landroidx/appcompat/widget/AppCompatImageButton;
    invoke-virtual {v4, v3}, Landroid/widget/ImageView;->setColorFilter(I)V
    .line 69
'@

Replace-V115ExactText "smali\com\suda\yzune\wakeupschedule\base_view\BaseTitleActivity.smali" @'
    invoke-virtual {v1, v3}, Landroidx/appcompat/widget/Toolbar;->setNavigationIcon(I)V

    .line 76
'@ @'
    invoke-virtual {v1, v3}, Landroidx/appcompat/widget/Toolbar;->setNavigationIcon(I)V

    iget-object v3, v1, Landroidx/appcompat/widget/Toolbar;->OooO0oo:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v3}, Landroid/widget/TextView;->getCurrentTextColor()I
    move-result v3
    iget-object v4, v1, Landroidx/appcompat/widget/Toolbar;->OooOO0:Landroidx/appcompat/widget/AppCompatImageButton;
    invoke-virtual {v4, v3}, Landroid/widget/ImageView;->setColorFilter(I)V

    .line 76
'@

Replace-V115ExactText "smali\com\suda\yzune\wakeupschedule\base_view\BaseBlurTitleActivity.smali" @'
    invoke-virtual {v0, v2}, Landroidx/appcompat/widget/Toolbar;->setNavigationIcon(I)V

    .line 97
'@ @'
    invoke-virtual {v0, v2}, Landroidx/appcompat/widget/Toolbar;->setNavigationIcon(I)V

    iget-object v2, v0, Landroidx/appcompat/widget/Toolbar;->OooO0oo:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v2}, Landroid/widget/TextView;->getCurrentTextColor()I
    move-result v2
    iget-object v3, v0, Landroidx/appcompat/widget/Toolbar;->OooOO0:Landroidx/appcompat/widget/AppCompatImageButton;
    invoke-virtual {v3, v2}, Landroid/widget/ImageView;->setColorFilter(I)V

    .line 97
'@

Replace-V115ExactText "smali\com\suda\yzune\wakeupschedule\schedule\o00oO0o.smali" @'
    .line 630
    const-string v2, "action"

    .line 631
    .line 632
    const v3, 0x7f090049

    .line 633
    .line 634
    .line 635
'@ @'
    .line 630
    const-string v2, "action"

    .line 631
    .line 632
    const v3, 0x7f09004c

    .line 633
    .line 634
    .line 635
'@

Replace-V115ExactText "smali\com\suda\yzune\wakeupschedule\schedule\o0OOO0o.smali" @'
    .line 124
    const v1, 0x7f090049
'@ @'
    .line 124
    const v1, 0x7f09004c
'@

Replace-V115ExactText "smali\com\suda\yzune\wakeupschedule\schedule\o00oO0o.smali" @'
    const v3, 0x7f12023d
    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;
    move-result-object v3
    check-cast v3, LOooOO0/o00Ooo;
    const v4, 0x7f0800e2
    invoke-virtual {v3, v4}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;
    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    const/16 v5, 0x8
'@ @'
    const v3, 0x7f12023d
    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;
    move-result-object v3
    check-cast v3, LOooOO0/o00Ooo;
    const v4, 0x7f0800e2
    invoke-virtual {v3, v4}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;
    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    const/16 v5, 0x11
'@

Replace-V115ExactText "smali\com\suda\yzune\wakeupschedule\schedule\o0OOO0o.smali" @'
    const/16 v0, 0xf

    if-eq v8, v0, :fluent_multi_schedule_manage
'@ @'
    const/16 v0, 0x11
    if-eq v8, v0, :weeko_schedule_settings

    const/16 v0, 0xf

    if-eq v8, v0, :fluent_multi_schedule_manage
'@

Replace-V115ExactText "smali\com\suda\yzune\wakeupschedule\schedule\o0OOO0o.smali" @'
    :stage1_schedule_manage
    sget v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OoooOoO:I
'@ @'
    :weeko_schedule_settings
    new-instance p1, Landroid/content/Intent;
    const-class v0, Lcom/suda/yzune/wakeupschedule/schedule_settings/ScheduleSettingsActivity;
    invoke-direct {p1, v6, v0}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V
    invoke-virtual {v6}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;
    move-result-object v0
    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0()Lcom/suda/yzune/wakeupschedule/bean/TableBean;
    move-result-object v0
    const-string v1, "tableData"
    invoke-virtual {p1, v1, v0}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Landroid/os/Parcelable;)Landroid/content/Intent;
    iget-object v0, v6, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->o000oOoO:LOooO0OO/OooO0o;
    invoke-virtual {v0, p1}, LOooO0OO/OooO0o;->OooO00o(Ljava/lang/Object;)V
    return v5

    :stage1_schedule_manage
    sget v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OoooOoO:I
'@

Replace-V115ExactText "smali\com\suda\yzune\wakeupschedule\schedule\o0OOO0o.smali" @'
    .line 130
    const-string v0, "settingItem"

    .line 131
    .line 132
    const/4 v1, 0x0

    .line 133
    .line 134
    .line 135
    invoke-virtual {p1, v0, v1}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;
'@ @'
    const-string v0, "settingItem"

    .line 131
    .line 132
    const/4 v1, -0x1

    .line 133
    .line 134
    invoke-virtual {p1, v0, v1}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;
'@

$modifyWeekPath = "smali\com\suda\yzune\wakeupschedule\schedule\o0OOO0o.smali"
Replace-V115ExactText $modifyWeekPath @'
    invoke-virtual {p1, v0, v1}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;

    .line 136
'@ @'
    invoke-virtual {p1, v0, v1}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;

    const-string v0, "weekoCover"
    const/4 v1, 0x1
    invoke-virtual {p1, v0, v1}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Z)Landroid/content/Intent;

    .line 136
'@

$scheduleActivityPath = "smali\com\suda\yzune\wakeupschedule\schedule\ScheduleActivity.smali"
Replace-V115ExactText $scheduleActivityPath @'
    .line 347
    .line 348
    .line 349
    move-result v1

    .line 350
    const/4 v6, 0x0
'@ @'
    .line 347
    .line 348
    .line 349
    move-result v1

    invoke-virtual {p0}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;
    move-result-object v9
    invoke-virtual {v9}, Landroid/content/res/Resources;->getConfiguration()Landroid/content/res/Configuration;
    move-result-object v9
    iget v9, v9, Landroid/content/res/Configuration;->uiMode:I
    and-int/lit8 v9, v9, 0x30
    const/16 v10, 0x20
    if-ne v9, v10, :weekoV115LightMode
    const/4 v9, 0x1
    goto :weekoV115ModeReady
    :weekoV115LightMode
    const/4 v9, 0x0
    :weekoV115ModeReady

    .line 350
    const/4 v6, 0x0
'@

Replace-V115ExactText $scheduleActivityPath @'
    .line 380
    move-result v8

    .line 381
    invoke-virtual {v7, v8}, Landroid/widget/TextView;->setTextColor(I)V
'@ @'
    .line 380
    move-result v8
    if-eqz v9, :weekoV115KeepHeaderTextColor
    const/4 v8, -0x1
    :weekoV115KeepHeaderTextColor

    .line 381
    invoke-virtual {v7, v8}, Landroid/widget/TextView;->setTextColor(I)V
'@

Replace-V115ExactText $scheduleActivityPath @'
    .line 402
    move-result v8

    .line 403
    invoke-static {v8}, Landroid/content/res/ColorStateList;->valueOf(I)Landroid/content/res/ColorStateList;
'@ @'
    .line 402
    move-result v8
    if-eqz v9, :weekoV115KeepHeaderIconColor
    const/4 v8, -0x1
    :weekoV115KeepHeaderIconColor

    .line 403
    invoke-static {v8}, Landroid/content/res/ColorStateList;->valueOf(I)Landroid/content/res/ColorStateList;
'@

Replace-V115ExactText $scheduleActivityPath @'
    .line 497
    xor-int/2addr v1, v3

    .line 498
    invoke-virtual {v6, v1}, Lo00O00Oo/OooOO0;->o00o0O(Z)V
'@ @'
    .line 497
    xor-int/2addr v1, v3
    if-eqz v9, :weekoV115KeepStatusBarMode
    const/4 v1, 0x0
    :weekoV115KeepStatusBarMode

    .line 498
    invoke-virtual {v6, v1}, Lo00O00Oo/OooOO0;->o00o0O(Z)V
'@

$stylePath = "res\values-v31\styles.xml"
Replace-V115RegexText $stylePath '(?s)<style name="ThemeOverlay\.Material3\.DynamicColors\.Dark" parent="">.*?</style>' @'
    <style name="ThemeOverlay.Material3.DynamicColors.Dark" parent="">
        <item name="android:colorAccent">@color/weeko_soft_dark_primary_v115</item>
        <item name="colorPrimary">@color/weeko_soft_dark_primary_v115</item>
        <item name="colorPrimaryContainer">@color/weeko_soft_dark_primary_container_v115</item>
        <item name="colorOnPrimary">@color/m3_sys_color_dynamic_dark_on_primary</item>
        <item name="colorOnPrimaryContainer">@color/m3_sys_color_dynamic_dark_on_primary_container</item>
        <item name="colorSecondary">@color/weeko_soft_dark_secondary_v115</item>
        <item name="colorSecondaryContainer">@color/weeko_soft_dark_secondary_container_v115</item>
        <item name="colorOnSecondary">@color/m3_sys_color_dynamic_dark_on_secondary</item>
        <item name="colorOnSecondaryContainer">@color/m3_sys_color_dynamic_dark_on_secondary_container</item>
        <item name="colorTertiary">@color/weeko_soft_dark_tertiary_v115</item>
        <item name="colorTertiaryContainer">@color/weeko_soft_dark_tertiary_container_v115</item>
        <item name="colorOnTertiary">@color/m3_sys_color_dynamic_dark_on_tertiary</item>
        <item name="colorOnTertiaryContainer">@color/m3_sys_color_dynamic_dark_on_tertiary_container</item>
        <item name="isMaterial3DynamicColorApplied">true</item>
    </style>
'@
Replace-V115RegexText $stylePath '(?s)<style name="ThemeOverlay\.Material3\.DynamicColors\.Light" parent="">.*?</style>' @'
    <style name="ThemeOverlay.Material3.DynamicColors.Light" parent="">
        <item name="android:colorAccent">@color/weeko_soft_light_primary_v115</item>
        <item name="colorPrimary">@color/weeko_soft_light_primary_v115</item>
        <item name="colorPrimaryContainer">@color/weeko_soft_light_primary_container_v115</item>
        <item name="colorOnPrimary">@color/m3_sys_color_dynamic_light_on_primary</item>
        <item name="colorOnPrimaryContainer">@color/m3_sys_color_dynamic_light_on_primary_container</item>
        <item name="colorSecondary">@color/weeko_soft_light_secondary_v115</item>
        <item name="colorSecondaryContainer">@color/weeko_soft_light_secondary_container_v115</item>
        <item name="colorOnSecondary">@color/m3_sys_color_dynamic_light_on_secondary</item>
        <item name="colorOnSecondaryContainer">@color/m3_sys_color_dynamic_light_on_secondary_container</item>
        <item name="colorTertiary">@color/weeko_soft_light_tertiary_v115</item>
        <item name="colorTertiaryContainer">@color/weeko_soft_light_tertiary_container_v115</item>
        <item name="colorOnTertiary">@color/m3_sys_color_dynamic_light_on_tertiary</item>
        <item name="colorOnTertiaryContainer">@color/m3_sys_color_dynamic_light_on_tertiary_container</item>
        <item name="isMaterial3DynamicColorApplied">true</item>
    </style>
'@

$resourceRoot = Join-Path $project "res"
New-Item -ItemType Directory -Path (Join-Path $resourceRoot "color-v31") -Force | Out-Null
Get-ChildItem (Join-Path $PSScriptRoot "soft-dynamic-colors-v115") -Filter "*.xml" | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $resourceRoot "color-v31\$($_.Name)") -Force
}

Replace-V115ExactText "smali\com\suda\yzune\wakeupschedule\schedule\FluentSchedulePalette.smali" @'
    const v4, 0xff2f80ff
'@ @'
    const v4, 0xff2f80ff
    invoke-static {v0, v4}, Lio/github/mxwf/weeko/theme/SoftDynamicColors;->resolveAccent(Landroid/content/Context;I)I
    move-result v4
'@

Replace-V115ExactText "smali\com\suda\yzune\wakeupschedule\schedule\o0000Ooo.smali" @'
    invoke-virtual {v8}, Lcom/suda/yzune/wakeupschedule/bean/ScheduleStyleConfig;->getTextColor()I

    .line 165
    .line 166
    .line 167
    move-result v7

    .line 168
    invoke-virtual {v11, v7}, Landroid/widget/TextView;->setTextColor(I)V
'@ @'
    invoke-virtual {v8}, Lcom/suda/yzune/wakeupschedule/bean/ScheduleStyleConfig;->getTextColor()I

    .line 165
    .line 166
    .line 167
    move-result v7
    invoke-static {v13, v7}, Lio/github/mxwf/weeko/theme/SoftDynamicColors;->resolveAccent(Landroid/content/Context;I)I
    move-result v7

    .line 168
    invoke-virtual {v11, v7}, Landroid/widget/TextView;->setTextColor(I)V
'@

Replace-V115ExactText "smali\o000Oo0o.3\Oooo0.smali" @'
.method public final onActivityResumed(Landroid/app/Activity;)V
    .locals 0

    .line 1
    return-void
.end method
'@ @'
.method public final onActivityResumed(Landroid/app/Activity;)V
    .locals 0

    invoke-static {p1}, Lio/github/mxwf/weeko/theme/SoftDynamicColors;->apply(Landroid/app/Activity;)V
    return-void
.end method
'@

$sheetPath = "smali\com\suda\yzune\wakeupschedule\schedule\CourseDetailBottomSheet.smali"
Replace-V115ExactText $sheetPath @'
    invoke-virtual {v8, v12}, Landroid/view/Window;->setNavigationBarColor(I)V
'@ @'
    invoke-virtual {v8, v12}, Landroid/view/Window;->setStatusBarColor(I)V
    invoke-virtual {v8, v12}, Landroid/view/Window;->setNavigationBarColor(I)V
'@
Replace-V115ExactText $sheetPath @'
    invoke-virtual {v8, v12}, Landroid/view/Window;->setNavigationBarContrastEnforced(Z)V
'@ @'
    invoke-virtual {v8, v12}, Landroid/view/Window;->setStatusBarContrastEnforced(Z)V
    invoke-virtual {v8, v12}, Landroid/view/Window;->setNavigationBarContrastEnforced(Z)V
'@
Replace-V115ExactText $sheetPath @'
    const/16 v10, 0x300
    or-int/2addr v9, v10
'@ @'
    const/16 v10, 0x700
    or-int/2addr v9, v10
'@
Replace-V115ExactText $sheetPath @'
# instance fields
.field public o00oO0O:Ljava/util/ArrayList;
'@ @'
# instance fields
.field private weekoV115BlurCallback:Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;
.field public o00oO0O:Ljava/util/ArrayList;
'@
Replace-V115ExactText $sheetPath @'
    new-instance v14, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV114;
    invoke-direct {v14, v10, v13}, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV114;-><init>(Landroid/view/Window;I)V
'@ @'
    move-object/from16 v12, p0
    invoke-virtual {v12}, Landroidx/fragment/app/oo0o0Oo;->OooO0oo()Landroidx/fragment/app/FragmentActivity;
    move-result-object v11
    const v9, 0x01020002
    invoke-virtual {v11, v9}, Landroid/app/Activity;->findViewById(I)Landroid/view/View;
    move-result-object v11
    new-instance v14, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;
    invoke-direct {v14, v10, v11, v13}, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;-><init>(Landroid/view/Window;Landroid/view/View;I)V
    iput-object v14, v12, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;->weekoV115BlurCallback:Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;
'@
Replace-V115ExactText $sheetPath @'
    invoke-virtual {v1, v2}, Landroid/view/View;->setOnLongClickListener(Landroid/view/View$OnLongClickListener;)V

    .line 787
    .line 788
    .line 789
    if-eqz p2, :cond_c
'@ @'
    invoke-virtual {v1, v2}, Landroid/view/View;->setOnLongClickListener(Landroid/view/View$OnLongClickListener;)V

    .line 787
    .line 788
    .line 789
    move-object/from16 v1, p1
    invoke-static {v1}, Lio/github/mxwf/weeko/theme/SoftDynamicColors;->apply(Landroid/view/View;)V
    if-eqz p2, :cond_c
'@

$sheetFullPath = Join-Path $project $sheetPath
$sheetContent = [IO.File]::ReadAllText($sheetFullPath)
if ([regex]::Matches($sheetContent, [regex]::Escape(".method public onDismiss(Landroid/content/DialogInterface;)V")).Count -ne 0) {
    throw "Course detail already defines onDismiss in $sheetPath"
}
$sheetContent += @'

.method public onDismiss(Landroid/content/DialogInterface;)V
    .locals 2

    invoke-super {p0, p1}, Landroidx/fragment/app/o0OoOo0;->onDismiss(Landroid/content/DialogInterface;)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;->weekoV115BlurCallback:Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;
    if-eqz v0, :weeko_v115_blur_clear_done
    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->close()V
    const/4 v1, 0x0
    iput-object v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;->weekoV115BlurCallback:Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;
    :weeko_v115_blur_clear_done
    return-void
.end method
'@
[IO.File]::WriteAllText($sheetFullPath, $sheetContent, [Text.UTF8Encoding]::new($false))

Copy-Item (Join-Path $PSScriptRoot "course-detail-blur-callback-v115.smali") (Join-Path $project "smali\com\suda\yzune\wakeupschedule\schedule\CourseDetailGlassBlurCallbackV115.smali") -Force
$obsoleteBlur = Join-Path $project "smali\com\suda\yzune\wakeupschedule\schedule\CourseDetailGlassBlurCallbackV114.smali"
$obsoleteBlurCallers = @(Get-ChildItem (Join-Path $project "smali") -Recurse -Filter "*.smali" |
    Where-Object { $_.FullName -ne $obsoleteBlur } | Select-String -SimpleMatch "CourseDetailGlassBlurCallbackV114")
if ($obsoleteBlurCallers.Count -ne 0) { throw "Old blur callback still has callers" }
Remove-Item -LiteralPath $obsoleteBlur -Force
Write-Output "Applied Weeko v1.1.5 progressive blur fallback and softened dynamic colors to $project"

# All in-process AppCompat alert dialogs share this lifecycle. System dialogs do not.
Replace-V115ExactText "smali\androidx\fragment\app\o0OoOo0.smali" @'
    invoke-virtual {v0}, Landroid/app/Dialog;->show()V
'@ @'
    invoke-virtual {v0}, Landroid/app/Dialog;->show()V
    invoke-static {v0}, Lio/github/mxwf/weeko/popup/GlassDialogSurface;->applyFragment(Landroid/app/Dialog;)V
'@
Replace-V115ExactText "smali\o000OOO\OooO.smali" @'
.method public final onStart()V
    .locals 3
'@ @'
.method public final onStart()V
    .locals 3
    invoke-static {p0}, Lio/github/mxwf/weeko/popup/GlassDialogSurface;->applySheet(Landroid/app/Dialog;)V
'@
$alertPath = "smali\androidx\appcompat\app\OooOOO.smali"
Replace-V115ExactText $alertPath @'
# virtual methods
'@ @'
# virtual methods
.method protected onStart()V
    .locals 0
    invoke-super {p0}, Landroidx/appcompat/app/o00000OO;->onStart()V
    invoke-static {p0}, Lio/github/mxwf/weeko/popup/GlassDialogSurface;->apply(Landroid/app/Dialog;)V
    return-void
.end method

'@
Replace-V115ExactText "smali\androidx\appcompat\widget\ListPopupWindow.smali" @'
    invoke-virtual {v4, v0, v2, v3, v5}, Landroid/widget/PopupWindow;->showAsDropDown(Landroid/view/View;III)V
'@ @'
    invoke-virtual {v4, v0, v2, v3, v5}, Landroid/widget/PopupWindow;->showAsDropDown(Landroid/view/View;III)V
    invoke-static {v0, v4}, Lio/github/mxwf/weeko/popup/GlassPopupBackground;->apply(Landroid/view/View;Landroid/widget/PopupWindow;)V
'@

$manifestPath = "AndroidManifest.xml"
Replace-V115RegexText $manifestPath '(?m)^[\t ]*<activity\b(?=[^\r\n]*android:name="com\.suda\.yzune\.wakeupschedule\.clock\.ClockActivity")[^\r\n]*/>[\t ]*\r?\n?' ""
Replace-V115RegexText $manifestPath '(?m)^[\t ]*<activity\b(?=[^\r\n]*android:name="com\.suda\.yzune\.wakeupschedule\.suda_life\.SudaLifeActivity")[^\r\n]*/>[\t ]*\r?\n?' ""

$menuListenerPath = "smali\com\suda\yzune\wakeupschedule\schedule\Oooo000.smali"
Replace-V115RegexText $menuListenerPath '(?s)\.method public OooO00o\(LOooOO0/o00Ooo;\)Z.*?\.end method' @'
.method public OooO00o(LOooOO0/o00Ooo;)Z
    .locals 1

    const/4 v0, 0x1
    return v0
.end method
'@

$scheduleActivityPath = "smali\com\suda\yzune\wakeupschedule\schedule\ScheduleActivity.smali"
Replace-V115RegexText $scheduleActivityPath '(?ms)^    :pswitch_2\r?\n(?:(?!^    :pswitch_[0-9a-f]+).)*?new-instance v12, Lcom/suda/yzune/wakeupschedule/schedule/oo000o;(?:(?!^    :pswitch_[0-9a-f]+).)*?^    goto :goto_5' @'
    :pswitch_2
    const/4 v12, 0x0
    goto :goto_5
'@
$legacyMenuClickPath = Join-Path $project "smali\com\suda\yzune\wakeupschedule\schedule\oo000o.smali"
$legacyMenuCallers = @(Get-ChildItem -LiteralPath (Join-Path $project "smali") -Recurse -File -Filter "*.smali" | Where-Object { $_.FullName -ne $legacyMenuClickPath } | Select-String -SimpleMatch "Lcom/suda/yzune/wakeupschedule/schedule/oo000o;")
if ($legacyMenuCallers.Count -ne 0) { throw "The obsolete menu click callback still has callers" }
Remove-Item -LiteralPath $legacyMenuClickPath -Force
Replace-V115RegexText $scheduleActivityPath '(?s)    const-string v1, "suda_life".*?    :cond_16' @'
    return-void

    :cond_16
'@

$navPath = Join-Path $project "smali\com\suda\yzune\wakeupschedule\schedule\o00000.smali"
$navOriginal = [IO.File]::ReadAllText($navPath)
$navLineEnding = if ($navOriginal.Contains("`r`n")) { "`r`n" } else { "`n" }
$navContent = $navOriginal.Replace("`r", "")
$sudaKey = '    const-string v4, "suda_life"'
$sudaKeyIndex = $navContent.IndexOf($sudaKey, [StringComparison]::Ordinal)
if ($sudaKeyIndex -lt 0 -or $navContent.IndexOf($sudaKey, $sudaKeyIndex + $sudaKey.Length, [StringComparison]::Ordinal) -ge 0) {
    throw "Expected one suda_life nav toggle in schedule/o00000.smali"
}
$navConfig = '    const-string v2, "config"'
$navConfigIndex = $navContent.LastIndexOf($navConfig, $sudaKeyIndex, [StringComparison]::Ordinal)
$navNextTile = "    :cond_1`n"
$navNextTileIndex = $navContent.IndexOf($navNextTile, $sudaKeyIndex, [StringComparison]::Ordinal)
if ($navConfigIndex -lt 0 -or $navNextTileIndex -lt 0) { throw "Could not bound the obsolete nav feature branch" }
$navBranch = $navContent.Substring($navConfigIndex, $navNextTileIndex - $navConfigIndex)
if (!$navBranch.Contains("goto :cond_1")) { throw "The obsolete nav branch no longer matches the v1.1.5 layout" }
$navContent = $navContent.Substring(0, $navConfigIndex) + "    goto :cond_1`n`n" + $navContent.Substring($navNextTileIndex)
foreach ($oldNavValue in @("const v2, 0x7f120223", "const v4, 0x7f0800cc")) {
    if ([regex]::Matches($navContent, [regex]::Escape($oldNavValue)).Count -ne 1) { throw "Expected one obsolete nav resource value: $oldNavValue" }
}
$navContent = $navContent.Replace("const v2, 0x7f120223", "const v2, 0x7f120228").Replace("const v4, 0x7f0800cc", "const v4, 0x7f0800c0")
$navTileStart = $navContent.IndexOf($navNextTile, $navConfigIndex, [StringComparison]::Ordinal)
$navLayoutParams = $navContent.IndexOf('    new-instance v4, Landroidx/constraintlayout/widget/ConstraintLayout$LayoutParams;', $navTileStart, [StringComparison]::Ordinal)
if ($navTileStart -lt 0 -or $navLayoutParams -lt 0) { throw "Could not locate the obsolete nav tile view" }
$navResult = $navContent.LastIndexOf("    move-result-object v2`n", $navLayoutParams, [StringComparison]::Ordinal)
if ($navResult -lt $navTileStart) { throw "Could not locate the obsolete nav tile view result" }
$navResultEnd = $navResult + "    move-result-object v2`n".Length
$navContent = $navContent.Substring(0, $navResultEnd) + "    const/16 v4, 0x8`n    invoke-virtual {v2, v4}, Landroid/view/View;->setVisibility(I)V`n" + $navContent.Substring($navResultEnd)
if ($navLineEnding -eq "`r`n") { $navContent = $navContent.Replace("`n", "`r`n") }
[IO.File]::WriteAllText($navPath, $navContent, [Text.UTF8Encoding]::new($false))

$settingsListenerPath = "smali\com\suda\yzune\wakeupschedule\settings\OooOOO.smali"
Replace-V115RegexText $settingsListenerPath '(?ms)^    :sswitch_1\b(?:(?!^    :sswitch_2\b).)*?const-string v0, "suda_life"(?:(?!^    :sswitch_2\b).)*?(?=^    :sswitch_2\b)' ""
Replace-V115ExactText $settingsListenerPath "        0x7f1201ea -> :sswitch_1" ""
$settingsActivityPath = "smali\com\suda\yzune\wakeupschedule\settings\SettingsActivity.smali"
Replace-V115ExactText $settingsActivityPath "goto :after_suda_life_setting" "goto :after_removed_feature_setting"
Replace-V115ExactText $settingsActivityPath ":after_suda_life_setting" ":after_removed_feature_setting"

$materialClickPath = "smali\com\google\android\material\datepicker\o00O0O.smali"
Replace-V115RegexText $materialClickPath '(?ms)^    :pswitch_3\r?\n(?:(?!^    :pswitch_[0-9a-f]+).)*?(?=^    :pswitch_4)' "    :pswitch_3`n    return-void`n`n"
Replace-V115RegexText $materialClickPath '(?ms)^    :pswitch_4\r?\n(?:(?!^    :pswitch_[0-9a-f]+).)*?(?=^    :pswitch_5)' "    :pswitch_4`n    return-void`n`n"
Replace-V115RegexText "smali\Oooooo.4\o0000O00.smali" '(?ms)^    :pswitch_f\r?\n(?:(?!^    :pswitch_[0-9a-f]+).)*?(?=^    :pswitch_10)' "    :pswitch_f`n    const/4 v0, 0x0`n    return-object v0`n`n"
Replace-V115ExactText "smali\Ooooooo.13\o0OO0o00.smali" "    sget v2, Lcom/suda/yzune/wakeupschedule/clock/ClockActivity;->Oooo0oo:I" ""
Replace-V115ExactText "smali\OoooooO.12\oo0oO0.smali" "    sget v3, Lcom/suda/yzune/wakeupschedule/clock/ClockActivity;->Oooo0oo:I" ""

$courseAdapterPath = "smali\com\suda\yzune\wakeupschedule\course_add\OooOo.smali"
Replace-V115RegexText $courseAdapterPath '(?s)check-cast p2, Lcom/suda/yzune/wakeupschedule/bean/SudaRoomData;.*?return-void' "return-void"

$clockPath = Join-Path $project "smali\com\suda\yzune\wakeupschedule\clock"
$sudaPath = Join-Path $project "smali\com\suda\yzune\wakeupschedule\suda_life"
$packageRoot = (Resolve-Path -LiteralPath (Join-Path $project "smali\com\suda\yzune\wakeupschedule")).Path
foreach ($featurePath in @($clockPath, $sudaPath)) {
    $resolvedFeaturePath = (Resolve-Path -LiteralPath $featurePath).Path
    if ([IO.Path]::GetDirectoryName($resolvedFeaturePath) -ne $packageRoot) { throw "Feature package escaped its expected root: $featurePath" }
    $featureFiles = @(Get-ChildItem -LiteralPath $resolvedFeaturePath -Force)
    if ($featureFiles.Count -eq 0 -or @($featureFiles | Where-Object { $_.PSIsContainer -or $_.Extension -ne ".smali" }).Count -ne 0) {
        throw "Feature package is not a flat smali-only directory: $featurePath"
    }
    foreach ($featureFile in $featureFiles) { Remove-Item -LiteralPath $featureFile.FullName -Force }
    Remove-Item -LiteralPath $resolvedFeaturePath -Force
}

foreach ($featureBean in @("BathData.smali", "BathResponse.smali", "BathResult.smali", "SudaRoomData.smali")) {
    Remove-Item -LiteralPath (Join-Path $project "smali\com\suda\yzune\wakeupschedule\bean\$featureBean") -Force
}
Remove-Item -LiteralPath (Join-Path $project "smali\com\suda\yzune\wakeupschedule\widget\RoomView.smali") -Force

foreach ($resourcePath in @(
    "res\menu\suda_life_menu.xml",
    "res\layout\activity_clock.xml",
    "res\layout-land\activity_clock.xml",
    "res\layout\fragment_clock_settings.xml",
    "res\layout-land\fragment_clock_settings.xml",
    "res\layout\fragment_bath.xml",
    "res\layout\fragment_empty_room.xml",
    "res\layout\item_suda_room.xml",
    "res\drawable\ic_twotone_alarm_on_24.xml",
    "res\drawable\ic_twotone_bathtub_24.xml"
)) {
    Remove-Item -LiteralPath (Join-Path $project $resourcePath) -Force
}

$stringsFiles = @(Get-ChildItem -LiteralPath (Join-Path $project "res") -Recurse -File -Filter "strings.xml")
foreach ($featureString in @("setting_show_suda_life", "title_schedule_clock", "title_suda_life")) {
    $removedFrom = 0
    foreach ($stringsFile in $stringsFiles) {
        $relativePath = [IO.Path]::GetRelativePath($project, $stringsFile.FullName)
        $stringsText = [IO.File]::ReadAllText($stringsFile.FullName).Replace("`r", "")
        $stringPattern = '(?m)^[\t ]*<string name="' + [regex]::Escape($featureString) + '"[^>]*>.*?</string>[\t ]*\r?\n?'
        $stringMatches = [regex]::Matches($stringsText, $stringPattern)
        if ($stringMatches.Count -gt 1) { throw "Duplicate $featureString entries in $relativePath" }
        if ($stringMatches.Count -eq 1) {
            Replace-V115RegexText $relativePath $stringPattern ""
            $removedFrom++
        }
    }
    if ($removedFrom -eq 0) { throw "No resource definition was found for $featureString" }
}

Replace-V115RegexText "res\values\styles.xml" '(?ms)^[\t ]*<style name="BaseClockTheme"[^>]*>.*?</style>[\t ]*\r?\n?' ""
Replace-V115RegexText "res\values\styles.xml" '(?m)^[\t ]*<style name="ClockTheme"[^>]*/>[\t ]*\r?\n?' ""
Replace-V115RegexText "res\values-v28\styles.xml" '(?ms)^[\t ]*<style name="ClockTheme"[^>]*>.*?</style>[\t ]*\r?\n?' ""

$idsPath = "res\values\ids.xml"
foreach ($idName in @("menu_bathroom", "menu_clock", "menu_empty_room", "menu_hide_suda", "room_view", "tv_room_name")) {
    Replace-V115RegexText $idsPath ('(?m)^[\t ]*<item type="id" name="' + [regex]::Escape($idName) + '"\s*/>[\t ]*\r?\n?') ""
}

$publicPath = "res\values\public.xml"
$resourceGroups = @(
    @{ Type = "drawable"; Names = @("ic_twotone_alarm_on_24", "ic_twotone_bathtub_24") },
    @{ Type = "layout"; Names = @("activity_clock", "fragment_bath", "fragment_clock_settings", "fragment_empty_room", "item_suda_room") },
    @{ Type = "menu"; Names = @("suda_life_menu") },
    @{ Type = "id"; Names = @("menu_bathroom", "menu_clock", "menu_empty_room", "menu_hide_suda", "room_view", "tv_room_name") },
    @{ Type = "string"; Names = @("setting_show_suda_life", "title_schedule_clock", "title_suda_life") },
    @{ Type = "style"; Names = @("BaseClockTheme", "ClockTheme") }
)
foreach ($resourceGroup in $resourceGroups) {
    $rClassPath = 'smali\com\suda\yzune\wakeupschedule\R${0}.smali' -f $resourceGroup.Type
    foreach ($resourceName in $resourceGroup.Names) {
        $publicPattern = '(?m)^[\t ]*<public type="' + [regex]::Escape($resourceGroup.Type) + '" name="' + [regex]::Escape($resourceName) + '" id="[^"]+"\s*/>[\t ]*\r?\n?'
        Replace-V115RegexText $publicPath $publicPattern ""
        $fieldPattern = '(?m)^[\t ]*\.field public static final ' + [regex]::Escape($resourceName) + ':[^=\r\n]+=[^\r\n]*\r?\n?'
        Replace-V115RegexText $rClassPath $fieldPattern ""
    }
}

Copy-Item (Join-Path $PSScriptRoot "weeko-vault-animations-v115.xml") `
    (Join-Path $project "res\values\weeko_vault_v114.xml") -Force
foreach ($vaultAnimation in @("weeko_vault_sheet_enter_v114.xml", "weeko_vault_sheet_exit_v114.xml")) {
    Remove-Item -LiteralPath (Join-Path $project "res\anim\$vaultAnimation") -Force
}

Write-Output "Removed campus-life and course-clock features from the v1.1.5 replay while retaining shared course and Material time-picker code."

Replace-V115ExactText "smali\com\skydoves\balloon\OooOOOO.smali" `
    '    invoke-virtual {v1, v3, v4, v0}, Landroid/widget/PopupWindow;->showAsDropDown(Landroid/view/View;II)V' `
    @'
    invoke-virtual {v1, v3, v4, v0}, Landroid/widget/PopupWindow;->showAsDropDown(Landroid/view/View;II)V
    invoke-static {v3, v1}, Lio/github/mxwf/weeko/popup/GlassPopupBackground;->applyHint(Landroid/view/View;Landroid/widget/PopupWindow;)V
'@

# Lossless, pixel-identical artwork; keep resource names and every icon/splash reference.
# One page-motion policy for Activity windows, covering Settings activities and NavHost pages.
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "weeko-detail-edit-v115.xml") -Destination (Join-Path $project "res\drawable\weeko_detail_edit_v115.xml") -Force
Replace-V115ExactText "res\menu\course_detail_menu.xml" '@drawable/ic_twotone_edit_24' '@drawable/weeko_detail_edit_v115'
Replace-V115ExactText "res\menu\course_detail_menu.xml" ' app:iconTint="?attr/colorOnSurface"' ''

foreach ($motion in @(
    @("enter", "open_enter", "enter"),
    @("underlay-exit", "open_exit", "exit"),
    @("underlay-enter", "close_enter", "pop_enter"),
    @("exit", "close_exit", "pop_exit")
)) {
    $sourceMotion = Join-Path $PSScriptRoot "weeko-layered-page-$($motion[0])-v115.xml"
    Copy-Item -LiteralPath $sourceMotion -Destination (Join-Path $project "res\anim\nav_default_$($motion[2])_anim.xml") -Force
    foreach ($alias in @("weeko_page_$($motion[1])_v114", "weeko_settings_cover_$($motion[0].Replace('-', '_'))_v114")) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot "weeko-layered-window-none-v115.xml") -Destination (Join-Path $project "res\anim\$alias.xml") -Force
    }
}

Replace-V115ExactText "smali\com\suda\yzune\wakeupschedule\App.smali" `
    '    invoke-super {p0}, Landroid/app/Application;->onCreate()V' `
    @'
    invoke-super {p0}, Landroid/app/Application;->onCreate()V
    invoke-static {p0}, Lio/github/mxwf/weeko/navigation/LayeredPageTransition;->install(Landroid/app/Application;)V
'@

$pageLaunchFiles = Get-ChildItem -LiteralPath (Join-Path $project "smali\com\suda\yzune\wakeupschedule") -Recurse -File -Filter "*.smali"
foreach ($launchFile in $pageLaunchFiles) {
    $launchText = [IO.File]::ReadAllText($launchFile.FullName)
    $launchText = [regex]::Replace($launchText,
        'invoke-virtual \{([vp]\d+), ([vp]\d+)\}, Landroid/content/Context;->startActivity\(Landroid/content/Intent;\)V',
        'invoke-static {$1, $2}, Lio/github/mxwf/weeko/navigation/LayeredPageTransition;->start(Landroid/content/Context;Landroid/content/Intent;)V')
    [IO.File]::WriteAllText($launchFile.FullName, $launchText, [Text.UTF8Encoding]::new($false))
}
Replace-V115ExactText "smali\androidx\activity\OooO.smali" `
    '    invoke-virtual {v0, p2, v2, v7}, Landroid/app/Activity;->startActivityForResult(Landroid/content/Intent;ILandroid/os/Bundle;)V' `
    '    invoke-static {v0, p2, v2, v7}, Lio/github/mxwf/weeko/navigation/LayeredPageTransition;->startForResult(Landroid/app/Activity;Landroid/content/Intent;ILandroid/os/Bundle;)V'

# Finish the shared in-window return before closing its Activity. No per-page override.
$componentActivityPath = Join-Path $project "smali\androidx\activity\ComponentActivity.smali"
$componentActivity = [IO.File]::ReadAllText($componentActivityPath)
if ($componentActivity.Contains('.method public finish()V')) { throw "ComponentActivity already defines finish; review its implementation" }
$componentActivity += @'

.method public finish()V
    .locals 1
    invoke-static {p0}, Lio/github/mxwf/weeko/navigation/LayeredPageTransition;->finish(Landroid/app/Activity;)Z
    move-result v0
    if-eqz v0, :weeko_finish_now
    return-void
    :weeko_finish_now
    invoke-super {p0}, Landroidx/core/app/ComponentActivity;->finish()V
    return-void
.end method
'@
[IO.File]::WriteAllText($componentActivityPath, $componentActivity, [Text.UTF8Encoding]::new($false))

# The shared Fragment animation loader already knows the operation's owning view.
$fragmentLoaderPath = Join-Path $project "smali\androidx\fragment\app\OooOO0.smali"
$fragmentLoader = [IO.File]::ReadAllText($fragmentLoaderPath)
$oldLoad = '    invoke-static {p1, v2}, Landroid/view/animation/AnimationUtils;->loadAnimation(Landroid/content/Context;I)Landroid/view/animation/Animation;'
if ([regex]::Matches($fragmentLoader, [regex]::Escape($oldLoad)).Count -ne 2) { throw "Expected both Fragment animation-loading paths" }
$newLoad = @'
    iget-object v1, p0, LOooOO0/OooO;->OooO0oo:Ljava/lang/Object;
    check-cast v1, Landroidx/fragment/app/o000OO00;
    iget-object v1, v1, Landroidx/fragment/app/o000OO00;->OooO0OO:Landroidx/fragment/app/oo0o0Oo;
    iget-object v1, v1, Landroidx/fragment/app/oo0o0Oo;->Oooo0o0:Landroid/view/View;
    invoke-static {p1, v2, v1}, Lio/github/mxwf/weeko/navigation/LayeredPageTransition;->load(Landroid/content/Context;ILandroid/view/View;)Landroid/view/animation/Animation;
'@
$fragmentLoader = $fragmentLoader.Replace($oldLoad, $newLoad)
[IO.File]::WriteAllText($fragmentLoaderPath, $fragmentLoader, [Text.UTF8Encoding]::new($false))

foreach ($artName in @("weeko_launcher_art", "weeko_launcher_foreground_art", "weeko_launcher_monochrome_art")) {
    $artDirectory = Join-Path $project "res\drawable-nodpi"
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "assets\weeko-v115\$artName.webp") -Destination (Join-Path $artDirectory "$artName.webp") -Force
    Remove-Item -LiteralPath (Join-Path $artDirectory "$artName.png") -Force
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "assets\weeko-v115\weeko_about_foreground.png") -Destination (Join-Path $project "res\drawable-nodpi\weeko_about_foreground.png") -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "weeko-popup-window-animations-v115.xml") -Destination (Join-Path $project "res\values\weeko_popup_window_animations_v115.xml") -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "weeko-popup-window-exit-v115.xml") -Destination (Join-Path $project "res\anim\weeko_popup_window_exit_v115.xml") -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "weeko-layered-window-hold-v115.xml") -Destination (Join-Path $project "res\anim\weeko_layered_window_hold_v115.xml") -Force
