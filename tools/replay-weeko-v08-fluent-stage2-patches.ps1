param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage6Script = Join-Path $PSScriptRoot "replay-weeko-v07-stage6-patches.ps1"

& $stage6Script -ProjectPath $project
if (!$?) { throw "v0.7 Stage 6 patch replay failed; Fluent Stage 2 was not applied." }

function Replace-FluentStage2ExactText {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Old,
        [Parameter(Mandatory = $true)] [string] $New
    )
    $path = Join-Path $project $RelativePath
    if (!(Test-Path -LiteralPath $path)) { throw "Patch input is missing: $RelativePath" }
    $original = [IO.File]::ReadAllText($path)
    $lineEnding = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $content = $original.Replace("`r`n", "`n")
    $oldLf = $Old.Replace("`r`n", "`n")
    $newLf = $New.Replace("`r`n", "`n")
    $first = $content.IndexOf($oldLf, [StringComparison]::Ordinal)
    if ($first -lt 0) { throw "Expected original text was not found in $RelativePath" }
    $second = $content.IndexOf($oldLf, $first + $oldLf.Length, [StringComparison]::Ordinal)
    if ($second -ge 0) { throw "Expected original text occurs more than once in $RelativePath" }
    $updated = $content.Remove($first, $oldLf.Length).Insert($first, $newLf)
    if ($lineEnding -eq "`r`n") { $updated = $updated.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $updated, [Text.UTF8Encoding]::new($false))
}

Replace-FluentStage2ExactText "apktool.yml" @'
  versionCode: 7
  versionName: 0.7.0-stage6
'@ @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage2
'@

# Reserve stable resource IDs for the three new command labels. The existing
# IDs remain unchanged so previously decoded callbacks keep their meaning.
Replace-FluentStage2ExactText "res/values/public.xml" @'
    <public type="string" name="weeko_nav_switch_manage" id="0x7f12023c" />
'@ @'
    <public type="string" name="weeko_nav_switch_manage" id="0x7f12023c" />
    <public type="string" name="weeko_nav_schedule_manage" id="0x7f12023d" />
    <public type="string" name="weeko_nav_time_settings" id="0x7f12023e" />
    <public type="string" name="weeko_nav_settings" id="0x7f12023f" />
'@

Replace-FluentStage2ExactText "res/values/strings.xml" @'
    <string name="weeko_nav_switch_manage">Switch/manage schedules</string>
'@ @'
    <string name="weeko_nav_switch_manage">Switch/manage schedules</string>
    <string name="weeko_nav_schedule_manage">Schedule management</string>
    <string name="weeko_nav_time_settings">Adjust class times</string>
    <string name="weeko_nav_settings">Settings</string>
'@
Replace-FluentStage2ExactText "res/values/strings.xml" @'
    <string name="weeko_nav_adjust_week">Adjust week</string>
'@ @'
    <string name="weeko_nav_adjust_week">Change current week</string>
'@

Replace-FluentStage2ExactText "res/values-zh-rCN/strings.xml" @'
    <string name="weeko_nav_adjust_week">&#x8C03;&#x6574;&#x5468;&#x6570;</string>
'@ @'
    <string name="weeko_nav_adjust_week">&#x4FEE;&#x6539;&#x5F53;&#x524D;&#x5468;</string>
'@
Replace-FluentStage2ExactText "res/values-zh-rCN/strings.xml" @'
    <string name="weeko_nav_switch_manage">&#x5207;&#x6362;/&#x7BA1;&#x7406;&#x8BFE;&#x8868;</string>
'@ @'
    <string name="weeko_nav_switch_manage">&#x5207;&#x6362;/&#x7BA1;&#x7406;&#x8BFE;&#x8868;</string>
    <string name="weeko_nav_schedule_manage">&#x8BFE;&#x8868;&#x7BA1;&#x7406;</string>
    <string name="weeko_nav_time_settings">&#x8C03;&#x6574;&#x4E0A;&#x8BFE;&#x65F6;&#x95F4;</string>
    <string name="weeko_nav_settings">&#x8BBE;&#x7F6E;</string>
'@

# The right command surface's first item is schedule settings, while the
# global settings entry gets the shorter Fluent label “设置”.
Replace-FluentStage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    const v3, 0x7f120225
    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;
    move-result-object v3
    check-cast v3, LOooOO0/o00Ooo;
    const v4, 0x7f0800e2
    invoke-virtual {v3, v4}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;
    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    const/16 v5, 0xb
'@ @'
    const v3, 0x7f12023d
    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;
    move-result-object v3
    check-cast v3, LOooOO0/o00Ooo;
    const v4, 0x7f0800e2
    invoke-virtual {v3, v4}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;
    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    const/16 v5, 0x8
'@
Replace-FluentStage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    const v3, 0x7f120228
    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;
'@ @'
    const v3, 0x7f12023f
    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;
'@

# The left menu keeps callback 8 for the existing current-week dialog, uses a
# new no-extra callback for the multi-schedule card page, and adds the existing
# TimeSettingsActivity as its third command.
Replace-FluentStage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    const v3, 0x7f12023c

    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;

    move-result-object v3

    check-cast v3, LOooOO0/o00Ooo;

    const v4, 0x7f0800e2

    invoke-virtual {v3, v4}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;

    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;

    const/16 v5, 0xb
'@ @'
    const v3, 0x7f12023c
    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;
    move-result-object v3
    check-cast v3, LOooOO0/o00Ooo;
    const v4, 0x7f0800e2
    invoke-virtual {v3, v4}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;
    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    const/16 v5, 0xf
'@
Replace-FluentStage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    const v3, 0x7f12011f

    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;

    move-result-object v3

    check-cast v3, LOooOO0/o00Ooo;

    invoke-virtual {v3, v9}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;

    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;

    const/16 v5, 0x9
'@ @'
    const v3, 0x7f12023e
    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;
    move-result-object v3
    check-cast v3, LOooOO0/o00Ooo;
    const v6, 0x7f0800a7
    invoke-virtual {v3, v6}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;
    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    const/16 v5, 0x10
'@

# Date is a direct current-week action. The week number and weekday continue
# using callback 8 so Stage 3 can attach the visual rail to their existing UI.
Replace-FluentStage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    invoke-direct {v12, v0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
'@ @'
    const/16 v3, 0x9
    invoke-direct {v12, v0, v3}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    .line 240
    .line 241
    .line 242
    iget-object v15, v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;

    .line 243
    .line 244
    if-eqz v15, :cond_1c

    .line 245
    .line 246
    iget-object v15, v15, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o0:Landroidx/appcompat/widget/AppCompatTextView;
'@
Replace-FluentStage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    iget-object v15, v15, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o:Landroidx/appcompat/widget/AppCompatTextView;
'@ @'
    new-instance v12, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;

    invoke-direct {v12, v0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    iget-object v15, v15, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o:Landroidx/appcompat/widget/AppCompatTextView;
'@

# Reserve callback 15 for the multi-schedule card page without selectedTableId
# and callback 16 for the existing TimeSettingsActivity.
Replace-FluentStage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o0OOO0o.smali" @'
    const/16 v0, 0xb

    if-eq v8, v0, :stage1_schedule_manage

    const/16 v0, 0xc
'@ @'
    const/16 v0, 0xf

    if-eq v8, v0, :fluent_multi_schedule_manage

    const/16 v0, 0x10

    if-eq v8, v0, :fluent_time_settings

    const/16 v0, 0xb

    if-eq v8, v0, :stage1_schedule_manage

    const/16 v0, 0xc
'@
Replace-FluentStage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o0OOO0o.smali" @'
    const/16 v0, 0xe

    if-eq v8, v0, :stage1_about

    const-string v0, "tableId"
'@ @'
    const/16 v0, 0xe

    if-eq v8, v0, :stage1_about

    const-string v0, "tableId"
'@

# Reuse the existing callback-9 current-week algorithm for the date's direct
# action; it does not need a MenuItem instance when invoked from the TextView.
Replace-FluentStage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o0OOO0o.smali" @'
    :pswitch_0
    sget v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OoooOoO:I

    .line 29
    .line 30
    invoke-static {p1, v7}, Lkotlin/jvm/internal/OooOO0O;->OooO0o0(Ljava/lang/Object;Ljava/lang/String;)V
'@ @'
    :pswitch_0
    sget v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OoooOoO:I

    .line 29
    .line 30
'@

# Keep the new branches out of the original packed-switch fall-through path.
# A label placed immediately after the callback checks would make every old
# callback enter the new time-settings route.
Replace-FluentStage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o0OOO0o.smali" @'
    return v5

    :pswitch_data_0
    .packed-switch 0x0
'@ @'
    return v5

    :fluent_time_settings
    sget v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OoooOoO:I

    invoke-static {p1, v7}, Lkotlin/jvm/internal/OooOO0O;->OooO0o0(Ljava/lang/Object;Ljava/lang/String;)V

    new-instance p1, Landroid/content/Intent;

    const-class v0, Lcom/suda/yzune/wakeupschedule/settings/TimeSettingsActivity;

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

    :fluent_multi_schedule_manage
    sget v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OoooOoO:I

    invoke-static {p1, v7}, Lkotlin/jvm/internal/OooOO0O;->OooO0o0(Ljava/lang/Object;Ljava/lang/String;)V

    new-instance p1, Landroid/content/Intent;

    const-class v0, Lcom/suda/yzune/wakeupschedule/schedule_manage/ScheduleManageActivity;

    invoke-direct {p1, v6, v0}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V

    iget-object v0, v6, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->o000oOoO:LOooO0OO/OooO0o;

    invoke-virtual {v0, p1}, LOooO0OO/OooO0o;->OooO00o(Ljava/lang/Object;)V

    return v5

    :pswitch_data_0
    .packed-switch 0x0
'@

# Callback 9 is reserved for the date's direct “back to current week” action.
# Values 8 and 9 both used to fall through to the left command surface.
Replace-FluentStage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    const/16 v0, 0xc

    if-eq v11, v0, :stage1_right_menu

    .line 34
'@ @'
    const/16 v0, 0xc

    if-eq v11, v0, :stage1_right_menu

    const/16 v0, 0x9

    if-eq v11, v0, :fluent_current_week

    .line 34
'@
Replace-FluentStage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    :stage1_right_menu
    invoke-static {v13, v1}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;->stage1ShowRightMenu(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;Landroid/view/View;)V

    return-void

    :stage1_existing_default
'@ @'
    :stage1_right_menu
    invoke-static {v13, v1}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;->stage1ShowRightMenu(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;Landroid/view/View;)V

    return-void

    :fluent_current_week
    new-instance v0, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;

    const/16 v2, 0x9

    invoke-direct {v0, v13, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    const/4 v1, 0x0

    invoke-virtual {v0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;->onMenuItemClick(Landroid/view/MenuItem;)Z

    return-void

    :stage1_existing_default
'@

Write-Output "Applied Fluent UI Stage 2 entry and menu routing patch to $project"
