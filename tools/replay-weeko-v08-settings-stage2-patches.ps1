param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage10Script = Join-Path $PSScriptRoot "replay-weeko-v08-fluent-stage10-patches.ps1"

& $stage10Script -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "Fluent Stage 10 patch replay failed; settings Stage 2 was not applied." }

function Replace-Stage2ExactText {
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
    $first = $content.IndexOf($oldLf, [StringComparison]::Ordinal)
    if ($first -lt 0) { throw "Expected original text was not found in $RelativePath" }
    $second = $content.IndexOf($oldLf, $first + $oldLf.Length, [StringComparison]::Ordinal)
    if ($second -ge 0) { throw "Expected original text occurs more than once in $RelativePath" }
    $updated = $content.Remove($first, $oldLf.Length).Insert($first, $newLf)
    if ($lineEnding -eq "`r`n") { $updated = $updated.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $updated, [Text.UTF8Encoding]::new($false))
}

function Replace-Stage2Range {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Start,
        [Parameter(Mandatory = $true)] [string] $End,
        [Parameter(Mandatory = $true)] [string] $Replacement
    )
    $path = Join-Path $project $RelativePath
    if (!(Test-Path -LiteralPath $path)) { throw "Patch input is missing: $RelativePath" }
    $original = [IO.File]::ReadAllText($path)
    $lineEnding = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $content = $original.Replace("`r", "")
    $startLf = $Start.Replace("`r", "").TrimEnd("`n")
    $endLf = $End.Replace("`r", "").TrimEnd("`n")
    $replacementLf = $Replacement.Replace("`r", "").TrimEnd("`n")
    $first = $content.IndexOf($startLf, [StringComparison]::Ordinal)
    if ($first -lt 0) { throw "Range start was not found in $RelativePath" }
    if ($content.IndexOf($startLf, $first + $startLf.Length, [StringComparison]::Ordinal) -ge 0) {
        throw "Range start occurs more than once in $RelativePath"
    }
    $last = $content.IndexOf($endLf, $first + $startLf.Length, [StringComparison]::Ordinal)
    if ($last -lt 0) { throw "Range end was not found after the start in $RelativePath" }
    $updated = $content.Remove($first, $last - $first).Insert($first, $replacementLf + "`n`n")
    if ($lineEnding -eq "`r`n") { $updated = $updated.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $updated, [Text.UTF8Encoding]::new($false))
}

Replace-Stage2ExactText "apktool.yml" @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage10
'@ @'
  versionCode: 8
  versionName: 0.8.0-settings-stage2
'@

# User-facing terminology. Internal classes, keys and storage are intentionally unchanged.
Replace-Stage2ExactText "res/values-zh-rCN/strings.xml" @'
    <string name="setting_class_time">上课时间</string>
'@ @'
    <string name="setting_class_time">作息时间</string>
'@
Replace-Stage2ExactText "res/values-zh-rCN/strings.xml" @'
    <string name="setting_manage_course">管理已添加课程</string>
'@ @'
    <string name="setting_manage_course">课程管理</string>
'@
Replace-Stage2ExactText "res/values-zh-rCN/strings.xml" @'
    <string name="setting_more_appearance">更多外观设置</string>
'@ @'
    <string name="setting_more_appearance">课表外观</string>
'@
Replace-Stage2ExactText "res/values-zh-rCN/strings.xml" @'
    <string name="setting_schedule_config">课表数据</string>
'@ @'
    <string name="setting_schedule_config">课表信息</string>
'@
Replace-Stage2ExactText "res/values/strings.xml" @'
    <string name="setting_class_time">Class Time</string>
'@ @'
    <string name="setting_class_time">Schedule Time</string>
'@
Replace-Stage2ExactText "res/values/strings.xml" @'
    <string name="setting_manage_course">管理已添加课程</string>
'@ @'
    <string name="setting_manage_course">Course Management</string>
'@
Replace-Stage2ExactText "res/values/strings.xml" @'
    <string name="setting_more_appearance">More appearance settings</string>
'@ @'
    <string name="setting_more_appearance">Schedule Appearance</string>
'@
Replace-Stage2ExactText "res/values/strings.xml" @'
    <string name="setting_schedule_config">Schedule Configuration</string>
'@ @'
    <string name="setting_schedule_config">Schedule Information</string>
'@

Replace-Stage2ExactText "res/navigation/nav_schedule_settings.xml" @'
    <fragment android:label="课表设置" android:name="com.suda.yzune.wakeupschedule.schedule_settings.ScheduleSettingsFragment" android:id="@id/scheduleSettingsFragment">
'@ @'
    <fragment android:label="课表管理" android:name="com.suda.yzune.wakeupschedule.schedule_settings.ScheduleSettingsFragment" android:id="@id/scheduleSettingsFragment">
'@
Replace-Stage2ExactText "res/navigation/nav_schedule_settings.xml" @'
    <fragment android:label="课表数据" android:name="com.suda.yzune.wakeupschedule.schedule_settings.TableConfigFragment" android:id="@id/tableConfigFragment" />
'@ @'
    <fragment android:label="课表信息" android:name="com.suda.yzune.wakeupschedule.schedule_settings.TableConfigFragment" android:id="@id/tableConfigFragment" />
'@
Replace-Stage2ExactText "res/navigation/nav_time_settings.xml" @'
    <fragment android:label="时间表" android:name="com.suda.yzune.wakeupschedule.settings.TimeTableFragment" android:id="@id/timeTableFragment">
'@ @'
    <fragment android:label="作息时间" android:name="com.suda.yzune.wakeupschedule.settings.TimeTableFragment" android:id="@id/timeTableFragment">
'@
Replace-Stage2ExactText "res/navigation/nav_time_settings.xml" @'
    <fragment android:label="编辑时间表" android:name="com.suda.yzune.wakeupschedule.settings.TimeSettingsFragment" android:id="@id/timeSettingsFragment" />
'@ @'
    <fragment android:label="编辑作息时间" android:name="com.suda.yzune.wakeupschedule.settings.TimeSettingsFragment" android:id="@id/timeSettingsFragment" />
'@

$fragmentPath = "smali/com/suda/yzune/wakeupschedule/schedule_settings/ScheduleSettingsFragment.smali"

# Keep all original activities and extras. This method only dispatches the three hub cards
# that previously had no common card-style navigation path.
Replace-Stage2ExactText $fragmentPath @'
.method public final onViewCreated(Landroid/view/View;Landroid/os/Bundle;)V
'@ @'
.method public final OoooOOO(I)V
    .locals 4

    const v0, 0x7f1201a6
    if-ne p1, v0, :stage2_course

    new-instance v0, Landroid/content/Intent;
    invoke-virtual {p0}, Landroidx/fragment/app/oo0o0Oo;->Oooo0O0()Landroidx/fragment/app/FragmentActivity;
    move-result-object v1
    const-class v2, Lcom/suda/yzune/wakeupschedule/settings/TimeSettingsActivity;
    invoke-direct {v0, v1, v2}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V
    invoke-virtual {p0}, Lcom/suda/yzune/wakeupschedule/schedule_settings/ScheduleSettingsFragment;->OoooO()Lcom/suda/yzune/wakeupschedule/schedule_settings/OooOo00;
    move-result-object v1
    invoke-virtual {v1}, Lcom/suda/yzune/wakeupschedule/schedule_settings/OooOo00;->OooO0o()Lcom/suda/yzune/wakeupschedule/bean/TableBean;
    move-result-object v1
    const-string v2, "tableData"
    invoke-virtual {v0, v2, v1}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Landroid/os/Parcelable;)Landroid/content/Intent;
    iget-object v1, p0, Lcom/suda/yzune/wakeupschedule/schedule_settings/ScheduleSettingsFragment;->OooooOo:Landroidx/fragment/app/o00O0O;
    invoke-virtual {v1, v0}, Landroidx/fragment/app/o00O0O;->OooO00o(Ljava/lang/Object;)V
    return-void

    :stage2_course
    const v0, 0x7f1201c4
    if-ne p1, v0, :stage2_schedules

    invoke-virtual {p0}, Landroidx/fragment/app/oo0o0Oo;->Oooo0O0()Landroidx/fragment/app/FragmentActivity;
    move-result-object v0
    new-instance v1, Landroid/content/Intent;
    const-class v2, Lcom/suda/yzune/wakeupschedule/schedule_manage/ScheduleManageActivity;
    invoke-direct {v1, v0, v2}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V
    invoke-virtual {p0}, Lcom/suda/yzune/wakeupschedule/schedule_settings/ScheduleSettingsFragment;->OoooO()Lcom/suda/yzune/wakeupschedule/schedule_settings/OooOo00;
    move-result-object v2
    invoke-virtual {v2}, Lcom/suda/yzune/wakeupschedule/schedule_settings/OooOo00;->OooO0o()Lcom/suda/yzune/wakeupschedule/bean/TableBean;
    move-result-object v2
    invoke-virtual {v2}, Lcom/suda/yzune/wakeupschedule/bean/TableBean;->getId()I
    move-result v2
    const-string v3, "selectedTableId"
    invoke-virtual {v1, v3, v2}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;
    invoke-virtual {v0, v1}, Landroid/content/Context;->startActivity(Landroid/content/Intent;)V
    return-void

    :stage2_schedules
    const v0, 0x7f120225
    if-ne p1, v0, :stage2_done

    invoke-virtual {p0}, Landroidx/fragment/app/oo0o0Oo;->Oooo0O0()Landroidx/fragment/app/FragmentActivity;
    move-result-object v0
    new-instance v1, Landroid/content/Intent;
    const-class v2, Lcom/suda/yzune/wakeupschedule/schedule_manage/ScheduleManageActivity;
    invoke-direct {v1, v0, v2}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V
    invoke-virtual {v0, v1}, Landroid/content/Context;->startActivity(Landroid/content/Intent;)V

    :stage2_done
    return-void
.end method

.method public final onViewCreated(Landroid/view/View;Landroid/os/Bundle;)V
'@

Replace-Stage2Range $fragmentPath @'
    new-instance v1, Ljava/util/ArrayList;

    .line 72
    .line 73
    invoke-direct {v1}, Ljava/util/ArrayList;-><init>()V

    .line 74
'@ @'
    iget-object v2, v0, Lcom/suda/yzune/wakeupschedule/schedule_settings/ScheduleSettingsFragment;->Ooooo0o:Lcom/suda/yzune/wakeupschedule/settings/OooOO0O;
'@ @'
    new-instance v1, Ljava/util/ArrayList;
    invoke-direct {v1}, Ljava/util/ArrayList;-><init>()V

    new-instance v2, Ljava/util/ArrayList;
    invoke-direct {v2}, Ljava/util/ArrayList;-><init>()V

    const/4 v5, 0x0
    const/4 v8, 0x4
    new-instance v3, Lo00O0o00/OooO;
    const v4, 0x7f1201a4
    invoke-direct {v3, v4, v5}, Lo00O0o00/OooO;-><init>(ILjava/lang/Boolean;)V
    invoke-virtual {v2, v3}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    new-instance v3, Lo00O0o00/OooOo00;
    const v6, 0x7f1201de
    const-string v7, "\u540d\u79f0\u3001\u5f00\u5b66\u65e5\u671f\u3001\u5f53\u524d\u5468\u3001\u603b\u5468\u6570\u548c\u6bcf\u65e5\u8282\u6570"
    invoke-direct {v3, v6, v7, v5, v8}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v3}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    new-instance v3, Lo00O0o00/OooOo00;
    const v6, 0x7f1201c4
    const-string v7, "\u65b0\u589e\u3001\u7f16\u8f91\u6216\u5220\u9664\u5f53\u524d\u8bfe\u8868\u4e2d\u7684\u8bfe\u7a0b"
    invoke-direct {v3, v6, v7, v5, v8}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v3}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    new-instance v3, Lo00O0o00/OooOo00;
    const v6, 0x7f1201a6
    const-string v7, "\u9009\u62e9\u5e76\u7f16\u8f91\u6bcf\u8282\u8bfe\u7684\u5f00\u59cb\u548c\u7ed3\u675f\u65f6\u95f4"
    invoke-direct {v3, v6, v7, v5, v8}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v3}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    new-instance v3, Lo00O0o00/OooOo00;
    const v6, 0x7f120225
    const-string v7, "\u5207\u6362\u3001\u65b0\u5efa\u3001\u590d\u5236\u3001\u91cd\u547d\u540d\u3001\u6392\u5e8f\u6216\u5220\u9664\u8bfe\u8868"
    invoke-direct {v3, v6, v7, v5, v8}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v3}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    new-instance v3, Lo00O0o00/OooOo00;
    const v6, 0x7f1201c7
    const-string v7, "\u8bbe\u7f6e\u5f53\u524d\u8bfe\u8868\u7684\u80cc\u666f\u3001\u7f51\u683c\u3001\u6587\u5b57\u548c\u8bfe\u7a0b\u5361\u7247"
    invoke-direct {v3, v6, v7, v5, v8}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v3}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    new-instance v3, Lo00O0o00/OooO0o;
    invoke-direct {v3, v2}, Lo00O0o00/OooO0o;-><init>(Ljava/util/ArrayList;)V
    invoke-virtual {v1, v3}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    new-instance v2, Ljava/util/ArrayList;
    invoke-direct {v2}, Ljava/util/ArrayList;-><init>()V
    new-instance v3, Lo00O0o00/OooO;
    invoke-direct {v3, v4, v5}, Lo00O0o00/OooO;-><init>(ILjava/lang/Boolean;)V
    invoke-virtual {v2, v3}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v3, Lo00O0o00/OooOo00;
    const v6, 0x7f1201df
    const-string v7, "\u4ec5\u5f71\u54cd\u4eca\u540e\u65b0\u5efa\u7684\u8bfe\u8868\uff0c\u4e0d\u4fee\u6539\u5df2\u6709\u8bfe\u8868"
    invoke-direct {v3, v6, v7, v5, v8}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v3}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v3, Lo00O0o00/OooO0o;
    invoke-direct {v3, v2}, Lo00O0o00/OooO0o;-><init>(Ljava/util/ArrayList;)V
    invoke-virtual {v1, v3}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    new-instance v2, Ljava/util/ArrayList;
    invoke-direct {v2}, Ljava/util/ArrayList;-><init>()V
    new-instance v3, Lo00O0o00/OooOo00;
    const-string v6, "\n\n\n"
    invoke-direct {v3, v4, v6, v5, v8}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v3}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v3, Lo00O0o00/OooO0o;
    invoke-direct {v3, v2}, Lo00O0o00/OooO0o;-><init>(Ljava/util/ArrayList;)V
    invoke-virtual {v1, v3}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
'@

$clickPath = "smali/com/suda/yzune/wakeupschedule/schedule_settings/OooOOO0.smali"
Replace-Stage2ExactText $clickPath @'
    iget p1, p1, Lo00O0o00/OooO0OO;->OooO0oO:I

    .line 49
    .line 50
    const p3, 0x7f0902b5
'@ @'
    iget p1, p1, Lo00O0o00/OooO0OO;->OooO0oO:I

    invoke-virtual {v1, p1}, Lcom/suda/yzune/wakeupschedule/schedule_settings/ScheduleSettingsFragment;->OoooOOO(I)V

    .line 49
    .line 50
    const p3, 0x7f0902b5
'@

Write-Output "Applied Weeko v0.8 settings Stage 2 schedule-management information architecture to $project"
