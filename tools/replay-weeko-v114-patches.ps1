param(
    [Parameter(Mandatory = $true)] [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
& $pwsh -NoProfile -File (Join-Path $root "tools\replay-weeko-v113-patches.ps1") -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "v1.1.3 patch replay failed; v1.1.4 patches were not applied." }

function Replace-V114ExactText {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Old,
        [Parameter(Mandatory = $true)] [string] $New
    )
    $path = Join-Path $project $RelativePath
    if (!(Test-Path -LiteralPath $path)) { throw "Patch input is missing: $RelativePath" }
    $original = [IO.File]::ReadAllText($path)
    $lineEnding = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $content = $original.Replace("`r", "")
    $oldLf = $Old.Replace("`r", "").TrimEnd("`n")
    $newLf = $New.Replace("`r", "").TrimEnd("`n")
    if ([regex]::Matches($content, [regex]::Escape($oldLf)).Count -ne 1) {
        throw "Expected one v1.1.4 patch target in $RelativePath"
    }
    $content = $content.Replace($oldLf, $newLf)
    if ($lineEnding -eq "`r`n") { $content = $content.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

Replace-V114ExactText "AndroidManifest.xml" `
    '<activity android:exported="false" android:label="密码箱" android:name="io.github.mxwf.weeko.vault.PasswordVaultActivity" android:screenOrientation="portrait" android:theme="@style/Theme.MaterialComponents.DayNight.Dialog"/>' `
    '<activity android:exported="false" android:label="密码箱" android:name="io.github.mxwf.weeko.vault.PasswordVaultActivity" android:screenOrientation="portrait" android:theme="@style/WeekoVaultBottomSheetV114"/>'

$settingsPath = "smali\com\suda\yzune\wakeupschedule\settings\SettingsActivity.smali"
Replace-V114ExactText $settingsPath `
    '    const-string v6, "Android Keystore 加密存储，仅手动复制"' `
    '    const-string v6, ""'

Replace-V114ExactText $settingsPath @'
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f120245
    const-string v6, "\u8ddf\u968f\u684c\u9762\u58c1\u7eb8\u8c03\u6574\u5e94\u7528\u4e3b\u9898\u8272"
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
'@ @'
    invoke-static {}, Lo000Oo0o/o000oOoO;->OooO00o()Z
    move-result v4
    if-eqz v4, :weeko_v114_no_dynamic_color
    const-string v5, "config"
    invoke-static {p0, v5}, Lcom/suda/yzune/wakeupschedule/utils/OooO0o;->OooO(Landroid/content/Context;Ljava/lang/String;)Landroid/content/SharedPreferences;
    move-result-object v4
    const-string v5, "dynamic_colors"
    const/4 v6, 0x0
    invoke-interface {v4, v5, v6}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z
    move-result v6
    new-instance v4, Lo00O0o00/OooOOO0;
    const v5, 0x7f1201b1
    const/16 v7, 0xc
    const-string v0, "跟随壁纸调整主题色 · 重启后生效"
    invoke-direct {v4, v5, v7, v0, v6}, Lo00O0o00/OooOOO0;-><init>(IILjava/lang/String;Z)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    const/4 v7, 0x4
    :weeko_v114_no_dynamic_color
'@

Replace-V114ExactText "smali\com\suda\yzune\wakeupschedule\settings\OooOOO.smali" @'
    const/4 v3, -0x1

    .line 42
    sparse-switch v0, :sswitch_data_0
'@ @'
    const/4 v3, -0x1
    const v3, 0x7f1201b1
    if-ne v0, v3, :weeko_v114_other_switch
    invoke-static {p1, v1}, Lcom/suda/yzune/wakeupschedule/utils/OooO0o;->OooO(Landroid/content/Context;Ljava/lang/String;)Landroid/content/SharedPreferences;
    move-result-object v0
    invoke-interface {v0}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;
    move-result-object v0
    const-string v1, "dynamic_colors"
    invoke-interface {v0, v1, p2}, Landroid/content/SharedPreferences$Editor;->putBoolean(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;
    invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->apply()V
    invoke-virtual {p1}, Lcom/suda/yzune/wakeupschedule/base_view/BaseListActivity;->OooOo0()Landroidx/recyclerview/widget/RecyclerView;
    move-result-object v0
    const-string v1, "重启 App 后生效"
    const/4 v3, 0x0
    invoke-static {v0, v1, v3}, Lo000o0o0/o00oO0o;->OooO0o(Landroid/view/View;Ljava/lang/String;I)Lo000o0o0/o00oO0o;
    move-result-object v0
    invoke-virtual {v0}, Lo000o0o0/o00oO0o;->OooO0oo()V
    goto :goto_0

    :weeko_v114_other_switch
    const/4 v3, -0x1
    .line 42
    sparse-switch v0, :sswitch_data_0
'@

Replace-V114ExactText "smali\com\suda\yzune\wakeupschedule\schedule\o0OOO0o.smali" '    const v1, 0x7f090049' '    const v1, 0x7f09004c'
Replace-V114ExactText "smali\com\suda\yzune\wakeupschedule\schedule\o0OOO0o.smali" '    const v1, 0x7f1201ad' '    const/4 v1, 0x0'

Replace-V114ExactText "apktool.yml" "  versionCode: 17`n  versionName: 1.1.3" "  versionCode: 18`n  versionName: 1.1.4"

$resourceRoot = Join-Path $project "res"
New-Item -ItemType Directory -Path (Join-Path $resourceRoot "values-night"), (Join-Path $resourceRoot "anim") -Force | Out-Null
Copy-Item (Join-Path $PSScriptRoot "course-detail-sheet-v114.xml") (Join-Path $resourceRoot "layout\fragment_course_detail.xml") -Force
Copy-Item (Join-Path $PSScriptRoot "course-detail-sheet-v114.xml") (Join-Path $resourceRoot "layout-v22\fragment_course_detail.xml") -Force
Copy-Item (Join-Path $PSScriptRoot "course-detail-summary-v114.xml") (Join-Path $resourceRoot "layout\item_course_detail_summary_v114.xml") -Force
Copy-Item (Join-Path $PSScriptRoot "course-detail-menu-v114.xml") (Join-Path $resourceRoot "menu\course_detail_menu.xml") -Force
Copy-Item (Join-Path $PSScriptRoot "bg-course-detail-sheet-v114.xml") (Join-Path $resourceRoot "drawable\bg_course_detail_sheet_v114.xml") -Force
foreach ($popupName in @("m3_popupmenu_background_overlay", "mtrl_popupmenu_background_overlay", "mtrl_popupmenu_background")) {
    Copy-Item (Join-Path $PSScriptRoot "weeko-glass-popup-v114.xml") (Join-Path $resourceRoot "drawable\$popupName.xml") -Force
}
Copy-Item (Join-Path $PSScriptRoot "weeko-glass-popup-v114.xml") (Join-Path $resourceRoot "drawable-v23\mtrl_popupmenu_background_overlay.xml") -Force
Copy-Item (Join-Path $PSScriptRoot "weeko-popup-item-v114.xml") (Join-Path $resourceRoot "drawable\weeko_v114_popup_item.xml") -Force
Copy-Item (Join-Path $PSScriptRoot "bg-sheet-handle-v114.xml") (Join-Path $resourceRoot "drawable\bg_sheet_handle_v114.xml") -Force
Copy-Item (Join-Path $PSScriptRoot "weeko-detail-calendar-v114.xml") (Join-Path $resourceRoot "drawable\weeko_v114_calendar.xml") -Force
Copy-Item (Join-Path $PSScriptRoot "weeko-detail-clock-v114.xml") (Join-Path $resourceRoot "drawable\weeko_v114_clock.xml") -Force
Copy-Item (Join-Path $PSScriptRoot "weeko-detail-colors-v114.xml") (Join-Path $resourceRoot "values\weeko_detail_v114.xml") -Force
Copy-Item (Join-Path $PSScriptRoot "weeko-detail-colors-night-v114.xml") (Join-Path $resourceRoot "values-night\weeko_detail_v114.xml") -Force
Copy-Item (Join-Path $PSScriptRoot "weeko-vault-animations-v114.xml") (Join-Path $resourceRoot "values\weeko_vault_v114.xml") -Force
Copy-Item (Join-Path $PSScriptRoot "weeko-vault-sheet-enter-v114.xml") (Join-Path $resourceRoot "anim\weeko_vault_sheet_enter_v114.xml") -Force
Copy-Item (Join-Path $PSScriptRoot "weeko-vault-sheet-exit-v114.xml") (Join-Path $resourceRoot "anim\weeko_vault_sheet_exit_v114.xml") -Force
foreach ($pageMotion in @("open-enter", "open-exit", "close-enter", "close-exit")) {
    Copy-Item (Join-Path $PSScriptRoot "weeko-page-$pageMotion-v114.xml") (Join-Path $resourceRoot "anim\weeko_page_$($pageMotion.Replace('-', '_'))_v114.xml") -Force
}
foreach ($coverMotion in @("enter", "underlay-enter", "underlay-exit", "exit")) {
    Copy-Item (Join-Path $PSScriptRoot "weeko-settings-cover-$coverMotion-v114.xml") (Join-Path $resourceRoot "anim\weeko_settings_cover_$($coverMotion.Replace('-', '_'))_v114.xml") -Force
}
Copy-Item (Join-Path $PSScriptRoot "course-copy-dialog-listener-v114.smali") (Join-Path $project "smali\com\suda\yzune\wakeupschedule\schedule\CourseCopyDialogListenerV114.smali") -Force

Replace-V114ExactText "res\values\styles.xml" '<style name="AppTheme" parent="@style/BaseAppTheme" />' @'
<style name="AppTheme" parent="@style/BaseAppTheme">
        <item name="android:windowAnimationStyle">@style/WeekoPageMotionV114</item>
    </style>
'@
Replace-V114ExactText "res\values\public.xml" `
    '<public type="anim" name="nav_default_pop_exit_anim" id="0x7f010040" />' `
    @'
<public type="anim" name="nav_default_pop_exit_anim" id="0x7f010040" />
    <public type="anim" name="weeko_settings_cover_enter_v114" id="0x7f010041" />
    <public type="anim" name="weeko_settings_cover_underlay_exit_v114" id="0x7f010042" />
    <public type="anim" name="weeko_settings_cover_exit_v114" id="0x7f010043" />
    <public type="anim" name="weeko_settings_cover_underlay_enter_v114" id="0x7f010044" />
'@
Replace-V114ExactText "smali\com\suda\yzune\wakeupschedule\schedule_settings\OooOOO0.smali" `
    "    const p1, 0x7f09004c`n`n    .line 121`n    .line 122`n    .line 123`n    invoke-virtual {p2, p1, v0}, LOooooo/o00;->OooO0OO(ILandroid/os/Bundle;)V" `
    @'
    const p1, 0x7f09004c

    .line 121
    .line 122
    .line 123
    invoke-virtual {v1}, Landroidx/fragment/app/oo0o0Oo;->Oooo0o0()Landroid/content/Context;
    move-result-object p2
    new-instance v0, Landroid/content/Intent;
    const-class v2, Lcom/suda/yzune/wakeupschedule/schedule_settings/ScheduleSettingsActivity;
    invoke-direct {v0, p2, v2}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V
    const-string v2, "action"
    invoke-virtual {v0, v2, p1}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;
    check-cast p2, Landroid/app/Activity;
    invoke-virtual {p2}, Landroid/app/Activity;->getIntent()Landroid/content/Intent;
    move-result-object v2
    const-string p1, "tableData"
    invoke-virtual {v2, p1}, Landroid/content/Intent;->getParcelableExtra(Ljava/lang/String;)Landroid/os/Parcelable;
    move-result-object v2
    invoke-virtual {v0, p1, v2}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Landroid/os/Parcelable;)Landroid/content/Intent;
    const-string v2, "weekoCover"
    const/4 p1, 0x1
    invoke-virtual {v0, v2, p1}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Z)Landroid/content/Intent;
    invoke-virtual {p2, v0}, Landroid/content/Context;->startActivity(Landroid/content/Intent;)V
    const p1, 0x7f010041
    const v0, 0x7f010042
    invoke-virtual {p2, p1, v0}, Landroid/app/Activity;->overridePendingTransition(II)V
'@
Replace-V114ExactText "smali\com\suda\yzune\wakeupschedule\schedule_settings\OooOOO0.smali" `
    "    const p1, 0x7f09004b`n`n    .line 140`n    .line 141`n    .line 142`n    invoke-virtual {p2, p1, v0}, LOooooo/o00;->OooO0OO(ILandroid/os/Bundle;)V" `
    @'
    const p1, 0x7f09004b

    .line 140
    .line 141
    .line 142
    invoke-virtual {v1}, Landroidx/fragment/app/oo0o0Oo;->Oooo0o0()Landroid/content/Context;
    move-result-object p2
    new-instance v0, Landroid/content/Intent;
    const-class v2, Lcom/suda/yzune/wakeupschedule/schedule_settings/ScheduleSettingsActivity;
    invoke-direct {v0, p2, v2}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V
    const-string v2, "action"
    invoke-virtual {v0, v2, p1}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;
    check-cast p2, Landroid/app/Activity;
    invoke-virtual {p2}, Landroid/app/Activity;->getIntent()Landroid/content/Intent;
    move-result-object v2
    const-string p1, "tableData"
    invoke-virtual {v2, p1}, Landroid/content/Intent;->getParcelableExtra(Ljava/lang/String;)Landroid/os/Parcelable;
    move-result-object v2
    invoke-virtual {v0, p1, v2}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Landroid/os/Parcelable;)Landroid/content/Intent;
    const-string v2, "weekoCover"
    const/4 p1, 0x1
    invoke-virtual {v0, v2, p1}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Z)Landroid/content/Intent;
    invoke-virtual {p2, v0}, Landroid/content/Context;->startActivity(Landroid/content/Intent;)V
    const p1, 0x7f010041
    const v0, 0x7f010042
    invoke-virtual {p2, p1, v0}, Landroid/app/Activity;->overridePendingTransition(II)V
'@
Replace-V114ExactText "smali\com\suda\yzune\wakeupschedule\schedule_settings\ScheduleSettingsActivity.smali" @'
.method public final onBackPressed()V
    .locals 3

    .line 1
'@ @'
.method public final onBackPressed()V
    .locals 3

    invoke-virtual {p0}, Landroid/app/Activity;->getIntent()Landroid/content/Intent;
    move-result-object v0
    const-string v1, "weekoCover"
    const/4 v2, 0x0
    invoke-virtual {v0, v1, v2}, Landroid/content/Intent;->getBooleanExtra(Ljava/lang/String;Z)Z
    move-result v0
    if-eqz v0, :weeko_normal_back
    invoke-virtual {p0}, Landroid/app/Activity;->finish()V
    const v0, 0x7f010044
    const v1, 0x7f010043
    invoke-virtual {p0, v0, v1}, Landroid/app/Activity;->overridePendingTransition(II)V
    return-void
    :weeko_normal_back

    .line 1
'@

$cascadePopupHelper = "smali\com\suda\yzune\wakeupschedule\utils\OooO0o.smali"
Replace-V114ExactText $cascadePopupHelper `
    '    invoke-static {p1}, Landroid/content/res/ColorStateList;->valueOf(I)Landroid/content/res/ColorStateList;' `
    @'
    invoke-virtual {p0}, Landroid/view/View;->getContext()Landroid/content/Context;
    move-result-object p1
    invoke-virtual {p1}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;
    move-result-object v1
    const-string v2, "weeko_v114_popup_glass"
    const-string v3, "color"
    invoke-virtual {p1}, Landroid/content/Context;->getPackageName()Ljava/lang/String;
    move-result-object p1
    invoke-virtual {v1, v2, v3, p1}, Landroid/content/res/Resources;->getIdentifier(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result p1
    invoke-virtual {v1, p1}, Landroid/content/res/Resources;->getColor(I)I
    move-result p1
    invoke-static {p1}, Landroid/content/res/ColorStateList;->valueOf(I)Landroid/content/res/ColorStateList;
'@
Replace-V114ExactText $cascadePopupHelper `
    "    const/4 v1, 0x4`n`n    .line 104`n    int-to-float v1, v1" `
    "    const/16 v1, 0x14`n`n    .line 104`n    int-to-float v1, v1"

Replace-V114ExactText "smali\me\saket\cascade\OooOO0O.smali" `
    "    move-result v1`n`n    .line 73`n    new-instance v3, Lkotlinx/datetime/internal/format/parser/OooOO0;" `
    @'
    move-result v1
    invoke-virtual {p1}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;
    move-result-object v3
    const-string v4, "weeko_v114_popup_item"
    const-string v5, "drawable"
    invoke-virtual {p1}, Landroid/content/Context;->getPackageName()Ljava/lang/String;
    move-result-object v8
    invoke-virtual {v3, v4, v5, v8}, Landroid/content/res/Resources;->getIdentifier(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v1

    .line 73
    new-instance v3, Lkotlinx/datetime/internal/format/parser/OooOO0;
'@

Replace-V114ExactText "smali\me\saket\cascade\OooOO0O.smali" `
    "    .line 107`n    invoke-virtual {p0, v0}, Landroid/widget/PopupWindow;->setBackgroundDrawable(Landroid/graphics/drawable/Drawable;)V" `
    @'
    .line 107
    new-instance v0, Landroid/graphics/drawable/ColorDrawable;
    const/4 v3, 0x0
    invoke-direct {v0, v3}, Landroid/graphics/drawable/ColorDrawable;-><init>(I)V
    invoke-virtual {p0, v0}, Landroid/widget/PopupWindow;->setBackgroundDrawable(Landroid/graphics/drawable/Drawable;)V
'@

Replace-V114ExactText "smali\me\saket\cascade\OooOO0.smali" `
    "    invoke-virtual {v0, p0, v1, v4, v2}, Lme/saket/cascade/OooOO0O;->showAtLocation(Landroid/view/View;III)V`n`n    .line 81" `
    @'
    invoke-virtual {v0, p0, v1, v4, v2}, Lme/saket/cascade/OooOO0O;->showAtLocation(Landroid/view/View;III)V
    invoke-static {p0, v0}, Lio/github/mxwf/weeko/popup/GlassPopupBackground;->apply(Landroid/view/View;Landroid/widget/PopupWindow;)V

    .line 81
'@

$zhStrings = "res\values-zh-rCN\strings.xml"
Replace-V114ExactText $zhStrings '    <string name="weeko_nav_time_settings">&#x8C03;&#x6574;&#x4E0A;&#x8BFE;&#x65F6;&#x95F4;</string>' '    <string name="weeko_nav_time_settings">&#x4F5C;&#x606F;&#x65F6;&#x95F4;</string>'
Replace-V114ExactText $zhStrings '    <string name="setting_dynamic_colors">根据桌面壁纸更改主题色</string>' '    <string name="setting_dynamic_colors">动态颜色</string>'
$zhCopyString = @'
    <string name="course_detail_edit">编辑</string>
    <string name="weeko_course_copy">复制课程</string>
'@
Replace-V114ExactText $zhStrings '    <string name="course_detail_edit">编辑</string>' $zhCopyString
Replace-V114ExactText $zhStrings `
    '    <string name="detail_delete_confirm">确认删除</string>' `
    '    <string name="detail_delete_confirm">删除</string>'
Replace-V114ExactText $zhStrings `
    '    <string name="detail_delete_title">选择删除范围，请三思😯</string>' `
    '    <string name="detail_delete_title">删除后将从当前课表移除此课程。</string>'
$baseStrings = "res\values\strings.xml"
Replace-V114ExactText $baseStrings '    <string name="weeko_nav_time_settings">Adjust class times</string>' '    <string name="weeko_nav_time_settings">Class times</string>'
Replace-V114ExactText $baseStrings '    <string name="setting_dynamic_colors">Dynamic Colors based on Wallpaper</string>' '    <string name="setting_dynamic_colors">Dynamic colors</string>'
$baseCopyString = @'
    <string name="course_detail_edit">Edit</string>
    <string name="weeko_course_copy">Copy course</string>
'@
Replace-V114ExactText $baseStrings '    <string name="course_detail_edit">Edit</string>' $baseCopyString
Replace-V114ExactText $baseStrings `
    '    <string name="detail_delete_confirm">Confirm</string>' `
    '    <string name="detail_delete_confirm">Delete</string>'
Replace-V114ExactText $baseStrings `
    '    <string name="detail_delete_title">Choose the delete way. Please think twice. 😯</string>' `
    '    <string name="detail_delete_title">This course will be removed from the current timetable.</string>'
$sheetSmali = "smali\com\suda\yzune\wakeupschedule\schedule\CourseDetailBottomSheet.smali"
Replace-V114ExactText "smali\com\suda\yzune\wakeupschedule\schedule\o0000Ooo.smali" @'
    new-instance v6, Lcom/suda/yzune/wakeupschedule/schedule/OooOOO;

    .line 70
    .line 71
    const/4 v8, 0x2

    .line 72
    invoke-direct {v6, v8, v0}, Lcom/suda/yzune/wakeupschedule/schedule/OooOOO;-><init>(ILjava/lang/Object;)V
'@ @'
    new-instance v6, Lcom/suda/yzune/wakeupschedule/schedule/OooOOO;

    .line 70
    .line 71
    const/4 v8, -0x1

    .line 72
    invoke-direct {v6, v8, v0}, Lcom/suda/yzune/wakeupschedule/schedule/OooOOO;-><init>(ILjava/lang/Object;)V
'@
Replace-V114ExactText $sheetSmali `
    '    invoke-virtual {v10, v11}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V' `
    @'
    invoke-virtual {v10, v11}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    const/4 v11, 0x2
    const/high16 v12, 0x41700000
    invoke-virtual {v10, v11, v12}, Landroid/widget/TextView;->setTextSize(IF)V
'@
Replace-V114ExactText $sheetSmali `
    '    const/16 v11, 0x40' `
    '    const/16 v11, 0x38'
Replace-V114ExactText $sheetSmali @'
.field public oo000o:Lcom/suda/yzune/wakeupschedule/bean/CourseBean;
'@ @'
.field public oo000o:Lcom/suda/yzune/wakeupschedule/bean/CourseBean;
.field public weekoCopyAnchor:Landroid/view/View;
'@
Replace-V114ExactText $sheetSmali @'
    invoke-virtual {v6, v12}, Landroidx/appcompat/widget/Toolbar;->setTitle(Ljava/lang/CharSequence;)V
'@ @'
    invoke-virtual {v6, v12}, Landroidx/appcompat/widget/Toolbar;->setTitle(Ljava/lang/CharSequence;)V

    iget-object v14, v0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;->oo000o:Lcom/suda/yzune/wakeupschedule/bean/CourseBean;
    invoke-virtual {v14}, Lcom/suda/yzune/wakeupschedule/bean/CourseBean;->getColor()Ljava/lang/String;
    move-result-object v14
    invoke-virtual {v14}, Ljava/lang/String;->length()I
    move-result v15
    if-nez v15, :weeko_v114_course_dot_color
    const-string v14, "#4F6BFF"
    :weeko_v114_course_dot_color
    invoke-static {v14}, Landroid/graphics/Color;->parseColor(Ljava/lang/String;)I
    move-result v15
    new-instance v14, Landroid/graphics/drawable/GradientDrawable;
    invoke-direct {v14}, Landroid/graphics/drawable/GradientDrawable;-><init>()V
    const/4 v13, 0x1
    invoke-virtual {v14, v13}, Landroid/graphics/drawable/GradientDrawable;->setShape(I)V
    invoke-virtual {v14, v15}, Landroid/graphics/drawable/GradientDrawable;->setColor(I)V
    iget-object v6, v0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;->o0ooOOo:LOooOo0o/o00O000;
    iget-object v6, v6, LOooOo0o/o00O000;->OooOO0O:Ljava/lang/Object;
    check-cast v6, Lcom/google/android/material/appbar/MaterialToolbar;
    invoke-virtual {v6}, Landroid/view/View;->getResources()Landroid/content/res/Resources;
    move-result-object v15
    invoke-virtual {v15}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
    move-result-object v15
    iget v15, v15, Landroid/util/DisplayMetrics;->density:F
    const/high16 v13, 0x41800000
    mul-float v15, v15, v13
    float-to-int v15, v15
    invoke-virtual {v14, v15, v15}, Landroid/graphics/drawable/GradientDrawable;->setSize(II)V
    invoke-virtual {v6, v14}, Landroidx/appcompat/widget/Toolbar;->setNavigationIcon(Landroid/graphics/drawable/Drawable;)V
'@
Replace-V114ExactText $sheetSmali @'
    invoke-virtual {v1, v6}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
'@ @'
    invoke-virtual {v1, v6}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    iget-object v1, v0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;->o0ooOOo:LOooOo0o/o00O000;
    iget-object v1, v1, LOooOo0o/o00O000;->OooOO0O:Ljava/lang/Object;
    check-cast v1, Lcom/google/android/material/appbar/MaterialToolbar;
    invoke-virtual {v1}, Landroidx/appcompat/widget/Toolbar;->getSubtitle()Ljava/lang/CharSequence;
    move-result-object v14
    invoke-interface {v14}, Ljava/lang/CharSequence;->length()I
    move-result v15
    new-instance v12, Ljava/lang/StringBuilder;
    invoke-direct {v12}, Ljava/lang/StringBuilder;-><init>()V
    if-lez v15, :weeko_v114_subtitle_week_only
    invoke-virtual {v12, v14}, Ljava/lang/StringBuilder;->append(Ljava/lang/CharSequence;)Ljava/lang/StringBuilder;
    move-result-object v12
    const-string v14, " · "
    invoke-virtual {v12, v14}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    move-result-object v12
    :weeko_v114_subtitle_week_only
    invoke-virtual {v12, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    move-result-object v12
    invoke-virtual {v12}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v14
    invoke-virtual {v1, v14}, Landroidx/appcompat/widget/Toolbar;->setSubtitle(Ljava/lang/CharSequence;)V
'@
Replace-V114ExactText $sheetSmali @'
    invoke-virtual {v3, v5}, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->Oooo0OO(I)V
'@ @'
    invoke-virtual {v3, v5}, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->Oooo0OO(I)V

    invoke-virtual {v1}, Landroid/view/View;->getContext()Landroid/content/Context;
    move-result-object v15
    new-instance v14, Lio/github/mxwf/weeko/popup/CourseDetailG2SheetDrawableV114;
    invoke-direct {v14, v15}, Lio/github/mxwf/weeko/popup/CourseDetailG2SheetDrawableV114;-><init>(Landroid/content/Context;)V
    invoke-virtual {v1, v14}, Landroid/view/View;->setBackground(Landroid/graphics/drawable/Drawable;)V
    const/4 v15, 0x1
    invoke-virtual {v1, v15}, Landroid/view/View;->setClipToOutline(Z)V
    invoke-virtual {v1}, Landroid/view/View;->getParent()Landroid/view/ViewParent;
    move-result-object v14
    check-cast v14, Landroid/view/View;
    const/4 v15, 0x0
    invoke-virtual {v14, v15}, Landroid/view/View;->setBackgroundColor(I)V

    sget v8, Landroid/os/Build$VERSION;->SDK_INT:I
    const/16 v9, 0x1f
    if-lt v8, v9, :weeko_v114_skip_sheet_blur
    iget-object v10, v0, Landroidx/fragment/app/o0OoOo0;->o00O0O:Landroid/app/Dialog;
    invoke-virtual {v10}, Landroid/app/Dialog;->getWindow()Landroid/view/Window;
    move-result-object v10
    const/4 v11, 0x4
    invoke-virtual {v10, v11}, Landroid/view/Window;->addFlags(I)V
    move-object/from16 v11, p1
    invoke-virtual {v11}, Landroid/view/View;->getResources()Landroid/content/res/Resources;
    move-result-object v12
    invoke-virtual {v12}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
    move-result-object v12
    iget v13, v12, Landroid/util/DisplayMetrics;->density:F
    const/high16 v14, 0x40c00000
    mul-float v13, v13, v14
    float-to-int v13, v13
    new-instance v14, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV114;
    invoke-direct {v14, v10, v13}, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV114;-><init>(Landroid/view/Window;I)V
    iget-object v12, v3, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->OooooO0:Ljava/util/ArrayList;
    invoke-virtual {v12, v14}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    invoke-virtual {v10, v13}, Landroid/view/Window;->setBackgroundBlurRadius(I)V
    invoke-virtual {v10}, Landroid/view/Window;->getAttributes()Landroid/view/WindowManager$LayoutParams;
    move-result-object v11
    invoke-virtual {v11, v13}, Landroid/view/WindowManager$LayoutParams;->setBlurBehindRadius(I)V
    invoke-virtual {v10, v11}, Landroid/view/Window;->setAttributes(Landroid/view/WindowManager$LayoutParams;)V
    :weeko_v114_skip_sheet_blur

    iget-object v8, v0, Landroidx/fragment/app/o0OoOo0;->o00O0O:Landroid/app/Dialog;
    check-cast v8, Lo000OOO/OooO;
    const/4 v9, 0x1
    iput-boolean v9, v8, Lo000OOO/OooO;->OooOo00:Z
    invoke-virtual {v8}, Landroid/app/Dialog;->getWindow()Landroid/view/Window;
    move-result-object v8
    const/high16 v9, 0x8000000
    invoke-virtual {v8, v9}, Landroid/view/Window;->clearFlags(I)V
    const/high16 v9, -0x80000000
    invoke-virtual {v8, v9}, Landroid/view/Window;->addFlags(I)V
    invoke-virtual {v1}, Landroid/view/View;->getResources()Landroid/content/res/Resources;
    move-result-object v9
    invoke-virtual {v1}, Landroid/view/View;->getContext()Landroid/content/Context;
    move-result-object v10
    invoke-virtual {v10}, Landroid/content/Context;->getPackageName()Ljava/lang/String;
    move-result-object v12
    const-string v10, "weeko_v114_detail_navigation_bar"
    const-string v11, "color"
    invoke-virtual {v9, v10, v11, v12}, Landroid/content/res/Resources;->getIdentifier(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v10
    invoke-virtual {v9, v10}, Landroid/content/res/Resources;->getColor(I)I
    move-result v10
    const/4 v12, 0x0
    invoke-virtual {v8, v12}, Landroid/view/Window;->setNavigationBarColor(I)V
    sget v11, Landroid/os/Build$VERSION;->SDK_INT:I
    const/16 v12, 0x1d
    if-lt v11, v12, :weeko_v114_navigation_contrast_done
    const/4 v12, 0x0
    invoke-virtual {v8, v12}, Landroid/view/Window;->setNavigationBarContrastEnforced(Z)V
    :weeko_v114_navigation_contrast_done
    const/16 v12, 0x1a
    if-lt v11, v12, :weeko_v114_navigation_icons_done
    invoke-virtual {v8}, Landroid/view/Window;->getDecorView()Landroid/view/View;
    move-result-object v8
    invoke-virtual {v8}, Landroid/view/View;->getSystemUiVisibility()I
    move-result v9
    and-int/lit16 v10, v10, 0xff
    const/16 v11, 0x80
    if-lt v10, v11, :weeko_v114_navigation_icons_dark
    or-int/lit8 v9, v9, 0x10
    goto :weeko_v114_navigation_icons_apply
    :weeko_v114_navigation_icons_dark
    and-int/lit8 v9, v9, -0x11
    :weeko_v114_navigation_icons_apply
    invoke-virtual {v8, v9}, Landroid/view/View;->setSystemUiVisibility(I)V
    :weeko_v114_navigation_icons_done
    iget-object v8, v0, Landroidx/fragment/app/o0OoOo0;->o00O0O:Landroid/app/Dialog;
    invoke-virtual {v8}, Landroid/app/Dialog;->getWindow()Landroid/view/Window;
    move-result-object v8
    invoke-virtual {v8}, Landroid/view/Window;->getDecorView()Landroid/view/View;
    move-result-object v8
    invoke-virtual {v8}, Landroid/view/View;->getSystemUiVisibility()I
    move-result v9
    const/16 v10, 0x300
    or-int/2addr v9, v10
    invoke-virtual {v8, v9}, Landroid/view/View;->setSystemUiVisibility(I)V

    const v6, 0x7f0902bb
    invoke-virtual {v1, v6}, Landroid/view/View;->findViewById(I)Landroid/view/View;
    move-result-object v6
    invoke-virtual {v1}, Landroid/view/View;->getResources()Landroid/content/res/Resources;
    move-result-object v7
    invoke-virtual {v7}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
    move-result-object v7
    iget v7, v7, Landroid/util/DisplayMetrics;->heightPixels:I
    int-to-float v7, v7
    const v8, 0x3f333333
    mul-float v7, v7, v8
    float-to-int v7, v7
    new-instance v8, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailHeightLimiter;
    invoke-direct {v8, v1, v6, v7}, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailHeightLimiter;-><init>(Landroid/view/View;Landroid/view/View;I)V
    invoke-virtual {v1, v8}, Landroid/view/View;->addOnLayoutChangeListener(Landroid/view/View$OnLayoutChangeListener;)V
'@
Replace-V114ExactText $sheetSmali @'
    invoke-virtual {v1, v2}, Landroidx/appcompat/widget/Toolbar;->setOnMenuItemClickListener(Landroidx/appcompat/widget/o0O00OOO;)V
'@ @'
    invoke-virtual {v1, v2}, Landroidx/appcompat/widget/Toolbar;->setOnMenuItemClickListener(Landroidx/appcompat/widget/o0O00OOO;)V

    move-object/from16 v8, p1
    const v9, 0x7f090222
    invoke-virtual {v8, v9}, Landroid/view/View;->findViewById(I)Landroid/view/View;
    move-result-object v8
    new-instance v9, Lcom/suda/yzune/wakeupschedule/schedule/OooOOO;
    const/4 v10, 0x2
    invoke-direct {v9, v10, v0}, Lcom/suda/yzune/wakeupschedule/schedule/OooOOO;-><init>(ILjava/lang/Object;)V
    invoke-virtual {v8, v9}, Landroid/view/View;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    move-object/from16 v8, p1
    const v9, 0x7f090224
    invoke-virtual {v8, v9}, Landroid/view/View;->findViewById(I)Landroid/view/View;
    move-result-object v8
    new-instance v9, Lcom/suda/yzune/wakeupschedule/schedule/OooOOO;
    const/4 v10, 0x3
    invoke-direct {v9, v10, v0}, Lcom/suda/yzune/wakeupschedule/schedule/OooOOO;-><init>(ILjava/lang/Object;)V
    invoke-virtual {v8, v9}, Landroid/view/View;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    move-object/from16 v8, p1
    const/4 v9, 0x0
    invoke-virtual {v8, v9}, Landroid/view/View;->setAlpha(F)V
    invoke-virtual {v8}, Landroid/view/View;->getResources()Landroid/content/res/Resources;
    move-result-object v10
    invoke-virtual {v10}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
    move-result-object v10
    iget v10, v10, Landroid/util/DisplayMetrics;->density:F
    const/high16 v11, 0x41000000
    mul-float v10, v10, v11
    invoke-virtual {v8, v10}, Landroid/view/View;->setTranslationY(F)V
    invoke-virtual {v8}, Landroid/view/View;->animate()Landroid/view/ViewPropertyAnimator;
    move-result-object v9
    const/high16 v10, 0x3f800000
    invoke-virtual {v9, v10}, Landroid/view/ViewPropertyAnimator;->alpha(F)Landroid/view/ViewPropertyAnimator;
    const/4 v10, 0x0
    invoke-virtual {v9, v10}, Landroid/view/ViewPropertyAnimator;->translationY(F)Landroid/view/ViewPropertyAnimator;
    const-wide/16 v11, 0xc8
    invoke-virtual {v9, v11, v12}, Landroid/view/ViewPropertyAnimator;->setDuration(J)Landroid/view/ViewPropertyAnimator;
    invoke-virtual {v9}, Landroid/view/ViewPropertyAnimator;->start()V
'@

$heightLimiterPath = "smali\com\suda\yzune\wakeupschedule\schedule\CourseDetailHeightLimiter.smali"
Copy-Item (Join-Path $PSScriptRoot "course-detail-height-limiter-v114.smali") (Join-Path $project $heightLimiterPath) -Force

$menuCallback = "smali\com\suda\yzune\wakeupschedule\schedule\OooOOO.smali"
Replace-V114ExactText $menuCallback @'
.method public final onClick(Landroid/view/View;)V
    .locals 5

    .line 1
    const/4 p1, 0x0
'@ @'
.method public final onClick(Landroid/view/View;)V
    .locals 8

    .line 1
    move-object v2, p1
    const/4 p1, 0x0
'@
Replace-V114ExactText $menuCallback @'
    :cond_3
    invoke-static {v3}, Lkotlin/jvm/internal/OooOO0O;->OooOO0o(Ljava/lang/String;)V

    .line 129
    .line 130
    .line 131
    throw p1

    .line 132
    nop

    .line 133
    :pswitch_data_0
    .packed-switch 0x0
        :pswitch_1
        :pswitch_0
    .end packed-switch
'@ @'
    :cond_3
    invoke-static {v3}, Lkotlin/jvm/internal/OooOO0O;->OooOO0o(Ljava/lang/String;)V

    .line 129
    .line 130
    .line 131
    throw p1

    :pswitch_2
    check-cast v0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;
    iput-object v2, v0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;->weekoCopyAnchor:Landroid/view/View;
    iget-object v3, v0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;->o0ooOOo:LOooOo0o/o00O000;
    iget-object v3, v3, LOooOo0o/o00O000;->OooOO0O:Ljava/lang/Object;
    check-cast v3, Lcom/google/android/material/appbar/MaterialToolbar;
    invoke-virtual {v3}, Landroidx/appcompat/widget/Toolbar;->getMenu()Landroid/view/Menu;
    move-result-object v4
    const/4 v5, 0x0
    const v6, 0x7f090222
    const-string v7, ""
    invoke-interface {v4, v5, v6, v5, v7}, Landroid/view/Menu;->add(IIILjava/lang/CharSequence;)Landroid/view/MenuItem;
    move-result-object v7
    check-cast v7, LOooOO0/o00Ooo;
    new-instance v5, Lcom/suda/yzune/wakeupschedule/schedule/OooOOO0;
    invoke-direct {v5, v0}, Lcom/suda/yzune/wakeupschedule/schedule/OooOOO0;-><init>(Ljava/lang/Object;)V
    invoke-virtual {v5, v7}, Lcom/suda/yzune/wakeupschedule/schedule/OooOOO0;->OooO00o(LOooOO0/o00Ooo;)Z
    invoke-interface {v4, v6}, Landroid/view/Menu;->removeItem(I)V
    return-void

    :pswitch_3
    check-cast v0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;
    iget-object v3, v0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;->o0ooOOo:LOooOo0o/o00O000;
    iget-object v3, v3, LOooOo0o/o00O000;->OooOO0O:Ljava/lang/Object;
    check-cast v3, Lcom/google/android/material/appbar/MaterialToolbar;
    invoke-virtual {v3}, Landroidx/appcompat/widget/Toolbar;->getMenu()Landroid/view/Menu;
    move-result-object v4
    const/4 v5, 0x0
    const v6, 0x7f090224
    const-string v7, ""
    invoke-interface {v4, v5, v6, v5, v7}, Landroid/view/Menu;->add(IIILjava/lang/CharSequence;)Landroid/view/MenuItem;
    move-result-object v7
    check-cast v7, LOooOO0/o00Ooo;
    new-instance v5, Lcom/suda/yzune/wakeupschedule/schedule/OooOOO0;
    invoke-direct {v5, v0}, Lcom/suda/yzune/wakeupschedule/schedule/OooOOO0;-><init>(Ljava/lang/Object;)V
    invoke-virtual {v5, v7}, Lcom/suda/yzune/wakeupschedule/schedule/OooOOO0;->OooO00o(LOooOO0/o00Ooo;)Z
    invoke-interface {v4, v6}, Landroid/view/Menu;->removeItem(I)V
    return-void

    .line 132
    nop

    .line 133
    :pswitch_data_0
    .packed-switch 0x0
        :pswitch_1
        :pswitch_0
        :pswitch_2
        :pswitch_3
    .end packed-switch
'@

$menuListener = "smali\com\suda\yzune\wakeupschedule\schedule\OooOOO0.smali"
Replace-V114ExactText $menuListener @'
    iget-object p1, v4, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;->o0ooOOo:LOooOo0o/o00O000;

    .line 276
    .line 277
    if-eqz p1, :cond_e

    .line 278
    .line 279
    iget-object p1, p1, LOooOo0o/o00O000;->OooOO0O:Ljava/lang/Object;

    .line 280
    .line 281
    check-cast p1, Lcom/google/android/material/appbar/MaterialToolbar;

    .line 282
    .line 283
    invoke-virtual {p1, v5}, Landroid/view/View;->findViewById(I)Landroid/view/View;

    .line 284
    .line 285
    .line 286
    move-result-object p1

    .line 287
    invoke-static {p1}, Lkotlin/jvm/internal/OooOO0O;->OooO0O0(Ljava/lang/Object;)V
'@ @'
    iget-object p1, v4, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;->weekoCopyAnchor:Landroid/view/View;
    invoke-static {p1}, Lkotlin/jvm/internal/OooOO0O;->OooO0O0(Ljava/lang/Object;)V
'@
Replace-V114ExactText $menuListener @'
    const v6, 0x7f1200d9

    .line 213
    .line 214
    .line 215
    invoke-virtual {v4, v6}, Landroidx/fragment/app/oo0o0Oo;->OooOOO(I)Ljava/lang/String;

    .line 216
    .line 217
    .line 218
    move-result-object v6

    .line 219
    iget-object v7, v5, LOooOoO0/o00000O;->OooO:Ljava/lang/Object;

    .line 220
    .line 221
    check-cast v7, Landroidx/appcompat/app/OooO;

    .line 222
    .line 223
    iput-object v6, v7, Landroidx/appcompat/app/OooO;->OooO0Oo:Ljava/lang/CharSequence;
'@ @'
    iget-object v8, v4, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;->oo000o:Lcom/suda/yzune/wakeupschedule/bean/CourseBean;
    invoke-virtual {v8}, Lcom/suda/yzune/wakeupschedule/bean/CourseBean;->getCourseName()Ljava/lang/String;
    move-result-object v8
    new-instance v9, Ljava/lang/StringBuilder;
    const-string v10, "删除‘"
    invoke-direct {v9, v10}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V
    invoke-virtual {v9, v8}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    move-result-object v9
    const-string v10, "’？"
    invoke-virtual {v9, v10}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    move-result-object v9
    invoke-virtual {v9}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v6
    iget-object v7, v5, LOooOoO0/o00000O;->OooO:Ljava/lang/Object;
    check-cast v7, Landroidx/appcompat/app/OooO;
    iput-object v6, v7, Landroidx/appcompat/app/OooO;->OooO0Oo:Ljava/lang/CharSequence;
    const v6, 0x7f1200d9
    invoke-virtual {v4, v6}, Landroidx/fragment/app/oo0o0Oo;->OooOOO(I)Ljava/lang/String;
    move-result-object v6
    iput-object v6, v7, Landroidx/appcompat/app/OooO;->OooO0o:Ljava/lang/CharSequence;
'@

$menuListenerPath = Join-Path $project $menuListener
$menuListenerContent = [IO.File]::ReadAllText($menuListenerPath)
$menuListenerEnding = if ($menuListenerContent.Contains("`r`n")) { "`r`n" } else { "`n" }
$copyBranchPattern = '(?s)    :cond_c\r?\n.*?(?=    :cond_e\r?\n)'
if ([regex]::Matches($menuListenerContent, $copyBranchPattern).Count -ne 1) {
    throw "Expected one copy-menu branch in $menuListener"
}
$copyBranch = @'
    :cond_c
    const/4 v5, 0x2
    new-array v5, v5, [Ljava/lang/CharSequence;
    const v6, 0x7f1200c8
    invoke-virtual {v4, v6}, Landroidx/fragment/app/oo0o0Oo;->OooOOO(I)Ljava/lang/String;
    move-result-object v6
    const/4 v7, 0x0
    aput-object v6, v5, v7
    const v6, 0x7f1200c9
    invoke-virtual {v4, v6}, Landroidx/fragment/app/oo0o0Oo;->OooOOO(I)Ljava/lang/String;
    move-result-object v6
    const/4 v7, 0x1
    aput-object v6, v5, v7
    iget-object v10, v4, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;->o0ooOOo:LOooOo0o/o00O000;
    iget-object v10, v10, LOooOo0o/o00O000;->OooOO0O:Ljava/lang/Object;
    check-cast v10, Lcom/google/android/material/appbar/MaterialToolbar;
    invoke-virtual {v10}, Landroidx/appcompat/widget/Toolbar;->getMenu()Landroid/view/Menu;
    move-result-object v10
    const v11, 0x7f090222
    invoke-interface {v10, v11}, Landroid/view/Menu;->findItem(I)Landroid/view/MenuItem;
    move-result-object v10
    invoke-virtual {v4}, Landroidx/fragment/app/oo0o0Oo;->Oooo0o0()Landroid/content/Context;
    move-result-object v6
    new-instance v7, Lo000Oo/OooO;
    invoke-direct {v7, v6}, Lo000Oo/OooO;-><init>(Landroid/content/Context;)V
    iget-object v8, v7, LOooOoO0/o00000O;->OooO:Ljava/lang/Object;
    check-cast v8, Landroidx/appcompat/app/OooO;
    const-string v9, "复制课程"
    iput-object v9, v8, Landroidx/appcompat/app/OooO;->OooO0Oo:Ljava/lang/CharSequence;
    iput-object v5, v8, Landroidx/appcompat/app/OooO;->OooOOOO:[Ljava/lang/CharSequence;
    new-instance v9, Lcom/suda/yzune/wakeupschedule/schedule/CourseCopyDialogListenerV114;
    invoke-direct {v9, v4, v10}, Lcom/suda/yzune/wakeupschedule/schedule/CourseCopyDialogListenerV114;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;Landroid/view/MenuItem;)V
    iput-object v9, v8, Landroidx/appcompat/app/OooO;->OooOOo0:Landroid/content/DialogInterface$OnClickListener;
    invoke-virtual {v7}, Lo000Oo/OooO;->OooO00o()Landroidx/appcompat/app/OooOOO;
    move-result-object v7
    invoke-virtual {v7}, Landroid/app/Dialog;->show()V
    const/4 v0, 0x1
    return v0

'@
$copyBranch = $copyBranch.TrimEnd("`r", "`n").Replace("`n", $menuListenerEnding) + $menuListenerEnding
$menuListenerContent = [regex]::Replace($menuListenerContent, $copyBranchPattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $copyBranch }, 1)
[IO.File]::WriteAllText($menuListenerPath, $menuListenerContent, [Text.UTF8Encoding]::new($false))

$notificationPath = "smali\com\suda\yzune\wakeupschedule\today_appwidget\TodayCourseAppWidget.smali"
Replace-V114ExactText $notificationPath "    .locals 28" "    .locals 41"

Replace-V114ExactText $notificationPath @'
    :cond_34
    invoke-virtual {v1, v3, v2}, Landroid/app/NotificationManager;->notify(ILandroid/app/Notification;)V
'@ @'
    :cond_34
    sget-object v28, Landroid/os/Build;->MANUFACTURER:Ljava/lang/String;
    const-string v29, "vivo"
    invoke-virtual/range {v28 .. v29}, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z
    move-result v30
    if-eqz v30, :weeko_v114_notify_course

    new-instance v28, Landroid/os/Bundle;
    invoke-direct/range {v28 .. v28}, Landroid/os/Bundle;-><init>()V

    const-string v29, "notification.superx.operation"
    const/16 v30, 0x0
    invoke-virtual/range {v28 .. v30}, Landroid/os/Bundle;->putInt(Ljava/lang/String;I)V

    const-string v29, "notification.superx.showNotify"
    const/16 v30, 0x1
    invoke-virtual/range {v28 .. v30}, Landroid/os/Bundle;->putBoolean(Ljava/lang/String;Z)V

    const-string v29, "notification.superx.template"
    const/16 v30, 0x1
    invoke-virtual/range {v28 .. v30}, Landroid/os/Bundle;->putInt(Ljava/lang/String;I)V

    const-string v29, "notification.superx.scene"
    const-string v30, "METTING"
    invoke-virtual/range {v28 .. v30}, Landroid/os/Bundle;->putString(Ljava/lang/String;Ljava/lang/String;)V

    const-string v29, "notification.superx.clickResp"
    iget-object v11, v2, Landroid/app/Notification;->contentIntent:Landroid/app/PendingIntent;
    move-object/from16 v30, v11
    invoke-virtual/range {v28 .. v30}, Landroid/os/Bundle;->putParcelable(Ljava/lang/String;Landroid/os/Parcelable;)V

    new-instance v32, Landroid/os/Bundle;
    invoke-direct/range {v32 .. v32}, Landroid/os/Bundle;-><init>()V

    const-string v33, "notification.superx.baseInfos.icon"
    invoke-virtual/range {p1 .. p1}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;
    move-result-object v39
    iget v11, v2, Landroid/app/Notification;->icon:I
    move/from16 v40, v11
    invoke-static/range {v39 .. v40}, Landroid/graphics/BitmapFactory;->decodeResource(Landroid/content/res/Resources;I)Landroid/graphics/Bitmap;
    move-result-object v34
    invoke-virtual/range {v32 .. v34}, Landroid/os/Bundle;->putParcelable(Ljava/lang/String;Landroid/os/Parcelable;)V

    iget-object v11, v8, LOooOoOO/o000O000;->OooO0o0:Ljava/lang/CharSequence;
    move-object/from16 v37, v11
    const-string v33, "notification.superx.baseInfos.title"
    move-object/from16 v34, v37
    invoke-virtual/range {v32 .. v34}, Landroid/os/Bundle;->putCharSequence(Ljava/lang/String;Ljava/lang/CharSequence;)V

    iget-object v11, v8, LOooOoOO/o000O000;->OooO0o:Ljava/lang/CharSequence;
    move-object/from16 v37, v11
    const-string v33, "notification.superx.baseInfos.content"
    move-object/from16 v34, v37
    invoke-virtual/range {v32 .. v34}, Landroid/os/Bundle;->putCharSequence(Ljava/lang/String;Ljava/lang/CharSequence;)V

    const-string v29, "notification.superx.baseInfos"
    move-object/from16 v30, v32
    invoke-virtual/range {v28 .. v30}, Landroid/os/Bundle;->putBundle(Ljava/lang/String;Landroid/os/Bundle;)V

    iget-object v11, v2, Landroid/app/Notification;->extras:Landroid/os/Bundle;
    if-nez v11, :weeko_v114_merge_extras
    new-instance v11, Landroid/os/Bundle;
    invoke-direct {v11}, Landroid/os/Bundle;-><init>()V
    iput-object v11, v2, Landroid/app/Notification;->extras:Landroid/os/Bundle;

    :weeko_v114_merge_extras
    move-object/from16 v12, v28
    invoke-virtual/range {v11 .. v12}, Landroid/os/Bundle;->putAll(Landroid/os/Bundle;)V

    :weeko_v114_notify_course
    invoke-virtual {v1, v3, v2}, Landroid/app/NotificationManager;->notify(ILandroid/app/Notification;)V
'@

Copy-Item (Join-Path $PSScriptRoot "course-detail-blur-callback-v114.smali") (Join-Path $project "smali\com\suda\yzune\wakeupschedule\schedule\CourseDetailGlassBlurCallbackV114.smali") -Force
Write-Output "Applied Weeko v1.1.4 vivo local atomic course-reminder metadata to $project"
