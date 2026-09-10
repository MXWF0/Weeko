param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage2Script = Join-Path $PSScriptRoot "replay-weeko-v08-settings-stage2-patches.ps1"

& $stage2Script -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "Settings Stage 2 patch replay failed; Stage 3 was not applied." }

function Replace-Stage3ExactText {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Old,
        [Parameter(Mandatory = $true)] [string] $New
    )
    $path = Join-Path $project $RelativePath
    Write-Output "Applying Stage 3 patch: $RelativePath"
    if (!(Test-Path -LiteralPath $path)) { throw "Patch input is missing: $RelativePath" }
    $original = [IO.File]::ReadAllText($path)
    $lineEnding = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $content = $original.Replace("`r", "")
    $oldLf = $Old.Replace("`r", "").TrimEnd("`n")
    $newLf = $New.Replace("`r", "").TrimEnd("`n")
    $first = $content.IndexOf($oldLf, [StringComparison]::Ordinal)
    if ($first -lt 0) { throw "Expected original text was not found in $RelativePath" }
    if ($content.IndexOf($oldLf, $first + $oldLf.Length, [StringComparison]::Ordinal) -ge 0) {
        throw "Expected original text occurs more than once in $RelativePath"
    }
    $updated = $content.Remove($first, $oldLf.Length).Insert($first, $newLf)
    if ($lineEnding -eq "`r`n") { $updated = $updated.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $updated, [Text.UTF8Encoding]::new($false))
}

Replace-Stage3ExactText "apktool.yml" @'
  versionCode: 8
  versionName: 0.8.0-settings-stage2
'@ @'
  versionCode: 9
  versionName: 0.8.0-settings-stage3
'@

Replace-Stage3ExactText "res/values-zh-rCN/strings.xml" @'
    <string name="title_settings">全局设置</string>
'@ @'
    <string name="title_settings">设置</string>
'@

$baseSettingsStrings = @'
    <string name="weeko_settings_section_appearance">Appearance</string>
    <string name="weeko_settings_section_schedule">Schedule Display</string>
    <string name="weeko_settings_section_reminders">Reminders &amp; Background</string>
    <string name="weeko_settings_section_desktop">Desktop &amp; Language</string>
    <string name="weeko_settings_section_data">Data &amp; More</string>
    <string name="weeko_settings_action_dynamic">Dynamic Colors</string>
    <string name="weeko_settings_action_empty_image">Empty-state Image</string>
    <string name="weeko_settings_action_reminders">Course Reminders &amp; Permissions</string>
    <string name="weeko_settings_action_transfer">Move Courses by Date</string>
'@
Replace-Stage3ExactText "res/values/strings.xml" @'
</resources>
'@ "$baseSettingsStrings`n</resources>"

$zhSettingsStrings = @'
    <string name="weeko_settings_section_appearance">&#x5916;&#x89C2;</string>
    <string name="weeko_settings_section_schedule">&#x8BFE;&#x7A0B;&#x8868;&#x663E;&#x793A;</string>
    <string name="weeko_settings_section_reminders">&#x63D0;&#x9192;&#x4E0E;&#x540E;&#x53F0;</string>
    <string name="weeko_settings_section_desktop">&#x684C;&#x9762;&#x4E0E;&#x8BED;&#x8A00;</string>
    <string name="weeko_settings_section_data">&#x6570;&#x636E;&#x4E0E;&#x66F4;&#x591A;</string>
    <string name="weeko_settings_action_dynamic">&#x52A8;&#x6001;&#x989C;&#x8272;</string>
    <string name="weeko_settings_action_empty_image">&#x7A7A;&#x72B6;&#x6001;&#x56FE;&#x7247;</string>
    <string name="weeko_settings_action_reminders">&#x8BFE;&#x7A0B;&#x63D0;&#x9192;&#x4E0E;&#x6743;&#x9650;</string>
    <string name="weeko_settings_action_transfer">&#x6309;&#x65E5;&#x671F;&#x8F6C;&#x79FB;&#x8BFE;&#x7A0B;</string>
'@
foreach ($locale in @("values-zh-rCN", "values-zh-rHK", "values-zh-rTW", "values-zh-rMO", "values-zh-rSG")) {
    Replace-Stage3ExactText "res/$locale/strings.xml" @'
</resources>
'@ "$zhSettingsStrings`n</resources>"
}

Replace-Stage3ExactText "res/values/public.xml" @'
    <public type="string" name="weeko_nav_settings" id="0x7f12023f" />
'@ @'
    <public type="string" name="weeko_nav_settings" id="0x7f12023f" />
    <public type="string" name="weeko_settings_section_appearance" id="0x7f120240" />
    <public type="string" name="weeko_settings_section_schedule" id="0x7f120241" />
    <public type="string" name="weeko_settings_section_reminders" id="0x7f120242" />
    <public type="string" name="weeko_settings_section_desktop" id="0x7f120243" />
    <public type="string" name="weeko_settings_section_data" id="0x7f120244" />
    <public type="string" name="weeko_settings_action_dynamic" id="0x7f120245" />
    <public type="string" name="weeko_settings_action_empty_image" id="0x7f120246" />
    <public type="string" name="weeko_settings_action_reminders" id="0x7f120247" />
    <public type="string" name="weeko_settings_action_transfer" id="0x7f120248" />
'@

$settingsActivity = "smali/com/suda/yzune/wakeupschedule/settings/SettingsActivity.smali"
Replace-Stage3ExactText $settingsActivity @'
    const-string v9, "\u5f53\u6ca1\u6709\u8bfe\u7a0b\u65f6\u663e\u793a\u7a7a\u89c6\u56fe\uff0c\u53ef\u4ee5\u5728\u300c\u529f\u80fd\u8bbe\u7f6e\u300d\u91cc\u81ea\u5b9a\u4e49\u4e3a\u559c\u6b22\u7684\u56fe\u7247\u54e6"
'@ @'
    const-string v9, "\u65e0\u8bfe\u7a0b\u65f6\u663e\u793a\u7a7a\u72b6\u6001\uff0c\u53ef\u5728\u4e0b\u65b9\u300c\u7a7a\u72b6\u6001\u56fe\u7247\u300d\u4e2d\u66f4\u6362\u56fe\u7247"
'@

Replace-Stage3ExactText $settingsActivity @'
.method public final onCreate(Landroid/os/Bundle;)V
'@ @'
.method public final Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    .locals 5

    invoke-virtual {p1}, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
    move-result-object v0

    :stage3_group_loop
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z
    move-result v1
    if-eqz v1, :stage3_find_done
    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;
    move-result-object v1
    check-cast v1, Lo00O0o00/OooO0o;
    iget-object v1, v1, Lo00O0o00/OooO0o;->OooOO0O:Ljava/util/ArrayList;
    invoke-virtual {v1}, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
    move-result-object v1

    :stage3_item_loop
    invoke-interface {v1}, Ljava/util/Iterator;->hasNext()Z
    move-result v2
    if-eqz v2, :stage3_group_loop
    invoke-interface {v1}, Ljava/util/Iterator;->next()Ljava/lang/Object;
    move-result-object v2
    move-object v3, v2
    check-cast v3, Lo00O0o00/OooO0OO;
    iget v4, v3, Lo00O0o00/OooO0OO;->OooO0oO:I
    if-ne v4, p3, :stage3_item_loop
    invoke-virtual {p2, v2}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    return-void

    :stage3_find_done
    return-void
.end method

.method public final Oooo0OO(I)Z
    .locals 4

    const v0, 0x7f120245
    if-ne p1, v0, :stage3_route_empty_image
    const-string v0, "appearance"
    goto :stage3_launch_advanced

    :stage3_route_empty_image
    const v0, 0x7f120246
    if-ne p1, v0, :stage3_route_reminders
    const-string v0, "schedule_display"
    goto :stage3_launch_advanced

    :stage3_route_reminders
    const v0, 0x7f120247
    if-ne p1, v0, :stage3_route_transfer
    const-string v0, "notifications"
    goto :stage3_launch_advanced

    :stage3_route_transfer
    const v0, 0x7f120248
    if-ne p1, v0, :stage3_not_category
    const-string v0, "advanced"

    :stage3_launch_advanced
    const-class v1, Lcom/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity;
    new-instance v3, Landroid/content/Intent;
    invoke-direct {v3, p0, v1}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V
    const-string v2, "weeko_advanced_section"
    invoke-virtual {v3, v2, v0}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;
    invoke-virtual {p0, v3}, Landroid/content/Context;->startActivity(Landroid/content/Intent;)V
    const/4 v0, 0x1
    return v0

    :stage3_not_category
    const/4 v0, 0x0
    return v0
.end method

.method public final Oooo00o(Ljava/util/ArrayList;)Ljava/util/ArrayList;
    .locals 8

    goto :stage3_flat_root

    invoke-virtual {p0}, Landroid/app/Activity;->getIntent()Landroid/content/Intent;
    move-result-object v0
    const-string v1, "weeko_settings_section"
    invoke-virtual {v0, v1}, Landroid/content/Intent;->getStringExtra(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    if-nez v0, :stage3_section_page

    const v1, 0x7f12023f
    invoke-virtual {p0, v1}, Landroid/app/Activity;->setTitle(I)V
    new-instance v1, Ljava/util/ArrayList;
    invoke-direct {v1}, Ljava/util/ArrayList;-><init>()V
    new-instance v2, Ljava/util/ArrayList;
    invoke-direct {v2}, Ljava/util/ArrayList;-><init>()V
    const/4 v3, 0x0
    new-instance v4, Lo00O0o00/OooO;
    const v5, 0x7f1201a4
    invoke-direct {v4, v5, v3}, Lo00O0o00/OooO;-><init>(ILjava/lang/Boolean;)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    const/4 v7, 0x4

    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f120240
    const-string v6, "\u663e\u793a\u6a21\u5f0f\u3001\u52a8\u6001\u989c\u8272\u4e0e\u7cfb\u7edf\u5916\u89c2"
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f120241
    const-string v6, "\u7a7a\u767d\u533a\u57df\u3001\u7a7a\u72b6\u6001\u548c\u9519\u8bef\u63d0\u793a"
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f120242
    const-string v6, "\u8bfe\u7a0b\u63d0\u9192\u3001\u63d0\u524d\u65f6\u95f4\u4e0e\u7cfb\u7edf\u6743\u9650"
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f120243
    const-string v6, "\u6dfb\u52a0\u65e5\u89c6\u56fe\u6216\u5468\u89c6\u56fe\u5c0f\u7ec4\u4ef6"
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f120244
    const-string v6, "\u81ea\u542f\u52a8\u3001\u7535\u6c60\u4f18\u5316\u4e0e\u5382\u5546\u8bbe\u7f6e"
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f120245
    const-string v6, "\u8ddf\u968f\u7cfb\u7edf\u3001\u4e2d\u6587\u6216 English"
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f120246
    const-string v6, "\u7f51\u9875\u7f13\u5b58\u3001\u9690\u79c1\u653f\u7b56\u4e0e\u7528\u6237\u534f\u8bae"
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f120247
    const-string v6, "\u6309\u65e5\u671f\u8f6c\u79fb\u8bfe\u7a0b\u7b49\u4f4e\u9891\u529f\u80fd"
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v4, Lo00O0o00/OooO0o;
    invoke-direct {v4, v2}, Lo00O0o00/OooO0o;-><init>(Ljava/util/ArrayList;)V
    invoke-virtual {v1, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    return-object v1

    :stage3_section_page
    new-instance v1, Ljava/util/ArrayList;
    invoke-direct {v1}, Ljava/util/ArrayList;-><init>()V
    new-instance v2, Ljava/util/ArrayList;
    invoke-direct {v2}, Ljava/util/ArrayList;-><init>()V
    const/4 v3, 0x0
    new-instance v4, Lo00O0o00/OooO;
    const v5, 0x7f1201a4
    invoke-direct {v4, v5, v3}, Lo00O0o00/OooO;-><init>(ILjava/lang/Boolean;)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    const-string v4, "appearance"
    invoke-virtual {v4, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v4
    if-eqz v4, :stage3_check_schedule
    const v4, 0x7f120240
    invoke-virtual {p0, v4}, Landroid/app/Activity;->setTitle(I)V
    const v4, 0x7f1201b0
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f12019d
    const-string v6, "\u52a8\u6001\u989c\u8272\u7b49\u4e3b\u9898\u9009\u9879"
    const/4 v7, 0x4
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    goto :stage3_wrap_section

    :stage3_check_schedule
    const-string v4, "schedule_display"
    invoke-virtual {v4, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v4
    if-eqz v4, :stage3_check_widgets
    const v4, 0x7f120241
    invoke-virtual {p0, v4}, Landroid/app/Activity;->setTitle(I)V
    const v4, 0x7f1201ac
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v4, 0x7f1201a5
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v4, 0x7f1201e5
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v4, 0x7f1201ed
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f1201b3
    const-string v6, "\u9009\u62e9\u65e0\u8bfe\u7a0b\u65f6\u7684\u663e\u793a\u56fe\u7247"
    const/4 v7, 0x4
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    goto :stage3_wrap_section

    :stage3_check_widgets
    const-string v4, "widgets"
    invoke-virtual {v4, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v4
    if-eqz v4, :stage3_check_background
    const v4, 0x7f120243
    invoke-virtual {p0, v4}, Landroid/app/Activity;->setTitle(I)V
    const v4, 0x7f1201d8
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    goto :stage3_wrap_section

    :stage3_check_background
    const-string v4, "background"
    invoke-virtual {v4, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v4
    if-eqz v4, :stage3_check_language
    const v4, 0x7f120244
    invoke-virtual {p0, v4}, Landroid/app/Activity;->setTitle(I)V
    const v4, 0x7f1201a1
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v4, 0x7f1201b9
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    goto :stage3_wrap_section

    :stage3_check_language
    const-string v4, "language"
    invoke-virtual {v4, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v4
    if-eqz v4, :stage3_check_data
    const v4, 0x7f120245
    invoke-virtual {p0, v4}, Landroid/app/Activity;->setTitle(I)V
    const v4, 0x7f1201c3
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    goto :stage3_wrap_section

    :stage3_check_data
    const-string v4, "data"
    invoke-virtual {v4, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v4
    if-eqz v4, :stage3_unknown_section
    const v4, 0x7f120246
    invoke-virtual {p0, v4}, Landroid/app/Activity;->setTitle(I)V
    const v4, 0x7f1201a8
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v4, 0x7f120221
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    goto :stage3_wrap_section

    :stage3_unknown_section
    return-object p1

    :stage3_wrap_section
    new-instance v4, Lo00O0o00/OooO0o;
    invoke-direct {v4, v2}, Lo00O0o00/OooO0o;-><init>(Ljava/util/ArrayList;)V
    invoke-virtual {v1, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    return-object v1

    :stage3_flat_root
    const v0, 0x7f12023f
    invoke-virtual {p0, v0}, Landroid/app/Activity;->setTitle(I)V
    new-instance v1, Ljava/util/ArrayList;
    invoke-direct {v1}, Ljava/util/ArrayList;-><init>()V
    const/4 v3, 0x0
    const/4 v7, 0x4

    new-instance v2, Ljava/util/ArrayList;
    invoke-direct {v2}, Ljava/util/ArrayList;-><init>()V
    new-instance v4, Lo00O0o00/OooO;
    const v5, 0x7f120240
    invoke-direct {v4, v5, v3}, Lo00O0o00/OooO;-><init>(ILjava/lang/Boolean;)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    const v4, 0x7f1201b0
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f120245
    const-string v6, "\u8ddf\u968f\u684c\u9762\u58c1\u7eb8\u8c03\u6574\u5e94\u7528\u4e3b\u9898\u8272"
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v4, Lo00O0o00/OooO0o;
    invoke-direct {v4, v2}, Lo00O0o00/OooO0o;-><init>(Ljava/util/ArrayList;)V
    invoke-virtual {v1, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    new-instance v2, Ljava/util/ArrayList;
    invoke-direct {v2}, Ljava/util/ArrayList;-><init>()V
    new-instance v4, Lo00O0o00/OooO;
    const v5, 0x7f120241
    invoke-direct {v4, v5, v3}, Lo00O0o00/OooO;-><init>(ILjava/lang/Boolean;)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    const v4, 0x7f1201ac
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v4, 0x7f1201a5
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v4, 0x7f1201e5
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v4, 0x7f1201ed
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f120246
    const-string v6, "\u9009\u62e9\u65e0\u8bfe\u7a0b\u65f6\u663e\u793a\u7684\u56fe\u7247"
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v4, Lo00O0o00/OooO0o;
    invoke-direct {v4, v2}, Lo00O0o00/OooO0o;-><init>(Ljava/util/ArrayList;)V
    invoke-virtual {v1, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    new-instance v2, Ljava/util/ArrayList;
    invoke-direct {v2}, Ljava/util/ArrayList;-><init>()V
    new-instance v4, Lo00O0o00/OooO;
    const v5, 0x7f120242
    invoke-direct {v4, v5, v3}, Lo00O0o00/OooO;-><init>(ILjava/lang/Boolean;)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f120247
    const-string v6, "\u8bbe\u7f6e\u63d0\u9192\u65f6\u95f4\u3001\u9759\u97f3\u65b9\u5f0f\u548c\u7cfb\u7edf\u6743\u9650"
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    const v4, 0x7f1201a1
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v4, 0x7f1201b9
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    new-instance v4, Lo00O0o00/OooO0o;
    invoke-direct {v4, v2}, Lo00O0o00/OooO0o;-><init>(Ljava/util/ArrayList;)V
    invoke-virtual {v1, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    new-instance v2, Ljava/util/ArrayList;
    invoke-direct {v2}, Ljava/util/ArrayList;-><init>()V
    new-instance v4, Lo00O0o00/OooO;
    const v5, 0x7f120243
    invoke-direct {v4, v5, v3}, Lo00O0o00/OooO;-><init>(ILjava/lang/Boolean;)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    const v4, 0x7f1201d8
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v4, 0x7f1201c3
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    new-instance v4, Lo00O0o00/OooO0o;
    invoke-direct {v4, v2}, Lo00O0o00/OooO0o;-><init>(Ljava/util/ArrayList;)V
    invoke-virtual {v1, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    new-instance v2, Ljava/util/ArrayList;
    invoke-direct {v2}, Ljava/util/ArrayList;-><init>()V
    new-instance v4, Lo00O0o00/OooO;
    const v5, 0x7f120244
    invoke-direct {v4, v5, v3}, Lo00O0o00/OooO;-><init>(ILjava/lang/Boolean;)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    const v4, 0x7f1201a8
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v4, 0x7f120221
    invoke-virtual {p0, p1, v2, v4}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f120248
    const-string v6, "\u5c06\u6307\u5b9a\u65e5\u671f\u540e\u7684\u8bfe\u7a0b\u6574\u4f53\u524d\u79fb\u6216\u540e\u79fb"
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v4, Lo00O0o00/OooO0o;
    invoke-direct {v4, v2}, Lo00O0o00/OooO0o;-><init>(Ljava/util/ArrayList;)V
    invoke-virtual {v1, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    return-object v1
.end method

.method public final onCreate(Landroid/os/Bundle;)V
'@

Replace-Stage3ExactText $settingsActivity @'
    iget-object p1, p0, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->OoooO00:Lcom/suda/yzune/wakeupschedule/settings/OooOO0O;
'@ @'
    invoke-virtual {p0, v0}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo00o(Ljava/util/ArrayList;)Ljava/util/ArrayList;
    move-result-object v0

    iget-object p1, p0, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->OoooO00:Lcom/suda/yzune/wakeupschedule/settings/OooOO0O;
'@

$settingsClick = "smali/com/suda/yzune/wakeupschedule/settings/OooOOO.smali"
Replace-Stage3ExactText $settingsClick @'
    invoke-virtual {v8, v0}, Lcom/suda/yzune/wakeupschedule/settings/OooOO0O;->Oooo0OO(I)Lo00O0o00/OooO0OO;

    .line 29
    .line 30
    .line 31
    move-result-object v8

    .line 32
    instance-of v9, v8, Lo00O0o00/OooOO0;
'@ @'
    invoke-virtual {v8, v0}, Lcom/suda/yzune/wakeupschedule/settings/OooOO0O;->Oooo0OO(I)Lo00O0o00/OooO0OO;

    .line 29
    .line 30
    .line 31
    move-result-object v8

    iget v9, v8, Lo00O0o00/OooO0OO;->OooO0oO:I
    invoke-virtual {v7, v9}, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;->Oooo0OO(I)Z
    move-result v9
    if-eqz v9, :stage3_original_click
    return-void

    :stage3_original_click
    .line 32
    instance-of v9, v8, Lo00O0o00/OooOO0;
'@

$advancedActivity = "smali/com/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity.smali"
Replace-Stage3ExactText $advancedActivity @'
    const-string v12, "\u8fd9\u4e2a\u662f\u7a7a\u89c6\u56fe\u56fe\u7247\uff01\u5c31\u662f\u6ca1\u6709\u8bfe\u7684\u65f6\u5019\u663e\u793a\u7684\u56fe\u7247\uff01\u76ee\u524d\u4ec5\u5728 App \u4e3b\u754c\u9762\u3001\u65e5\u89c6\u56fe\u5c0f\u7ec4\u4ef6\u548c\u5468\u89c6\u56fe\u5c0f\u7ec4\u4ef6\u4e0a\u751f\u6548\u3002\u957f\u6309\u53ef\u4ee5\u6062\u590d\u9ed8\u8ba4~"
'@ @'
    const-string v12, "\u9009\u62e9\u65e0\u8bfe\u7a0b\u65f6\u663e\u793a\u7684\u56fe\u7247\u3002\u5f53\u524d\u7528\u4e8e App \u4e3b\u754c\u9762\u3001\u65e5\u89c6\u56fe\u548c\u5468\u89c6\u56fe\u5c0f\u7ec4\u4ef6\uff1b\u957f\u6309\u53ef\u6062\u590d\u9ed8\u8ba4\u56fe\u7247\u3002"
'@

Replace-Stage3ExactText $advancedActivity @'
.method public final onCreate(Landroid/os/Bundle;)V
'@ @'
.method public final Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    .locals 5

    invoke-virtual {p1}, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
    move-result-object v0
    :stage3_adv_group_loop
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z
    move-result v1
    if-eqz v1, :stage3_adv_find_done
    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;
    move-result-object v1
    check-cast v1, Lo00O0o00/OooO0o;
    iget-object v1, v1, Lo00O0o00/OooO0o;->OooOO0O:Ljava/util/ArrayList;
    invoke-virtual {v1}, Ljava/util/ArrayList;->iterator()Ljava/util/Iterator;
    move-result-object v1
    :stage3_adv_item_loop
    invoke-interface {v1}, Ljava/util/Iterator;->hasNext()Z
    move-result v2
    if-eqz v2, :stage3_adv_group_loop
    invoke-interface {v1}, Ljava/util/Iterator;->next()Ljava/lang/Object;
    move-result-object v2
    move-object v3, v2
    check-cast v3, Lo00O0o00/OooO0OO;
    iget v4, v3, Lo00O0o00/OooO0OO;->OooO0oO:I
    if-ne v4, p3, :stage3_adv_item_loop
    invoke-virtual {p2, v2}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    return-void
    :stage3_adv_find_done
    return-void
.end method

.method public final Oooo00o(Ljava/util/ArrayList;)Ljava/util/ArrayList;
    .locals 6

    invoke-virtual {p0}, Landroid/app/Activity;->getIntent()Landroid/content/Intent;
    move-result-object v0
    const-string v1, "weeko_advanced_section"
    invoke-virtual {v0, v1}, Landroid/content/Intent;->getStringExtra(Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    if-nez v0, :stage3_adv_section
    return-object p1

    :stage3_adv_section
    new-instance v1, Ljava/util/ArrayList;
    invoke-direct {v1}, Ljava/util/ArrayList;-><init>()V
    new-instance v2, Ljava/util/ArrayList;
    invoke-direct {v2}, Ljava/util/ArrayList;-><init>()V
    const/4 v3, 0x0
    new-instance v4, Lo00O0o00/OooO;
    const v5, 0x7f1201a4
    invoke-direct {v4, v5, v3}, Lo00O0o00/OooO;-><init>(ILjava/lang/Boolean;)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    const-string v3, "appearance"
    invoke-virtual {v3, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :stage3_adv_check_schedule
    const v3, 0x7f120245
    invoke-virtual {p0, v3}, Landroid/app/Activity;->setTitle(I)V
    const v3, 0x7f1201b1
    invoke-virtual {p0, p1, v2, v3}, Lcom/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    goto :stage3_adv_wrap

    :stage3_adv_check_schedule
    const-string v3, "schedule_display"
    invoke-virtual {v3, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :stage3_adv_check_notifications
    const v3, 0x7f120246
    invoke-virtual {p0, v3}, Landroid/app/Activity;->setTitle(I)V
    const v3, 0x7f1201b3
    invoke-virtual {p0, p1, v2, v3}, Lcom/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    goto :stage3_adv_wrap

    :stage3_adv_check_notifications
    const-string v3, "notifications"
    invoke-virtual {v3, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :stage3_adv_check_advanced
    const v3, 0x7f120247
    invoke-virtual {p0, v3}, Landroid/app/Activity;->setTitle(I)V
    const v3, 0x7f1201cf
    invoke-virtual {p0, p1, v2, v3}, Lcom/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v3, 0x7f12019f
    invoke-virtual {p0, p1, v2, v3}, Lcom/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v3, 0x7f1201ca
    invoke-virtual {p0, p1, v2, v3}, Lcom/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v3, 0x7f1201d3
    invoke-virtual {p0, p1, v2, v3}, Lcom/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v3, 0x7f1201d0
    invoke-virtual {p0, p1, v2, v3}, Lcom/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v3, 0x7f1201d1
    invoke-virtual {p0, p1, v2, v3}, Lcom/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    const v3, 0x7f1201d2
    invoke-virtual {p0, p1, v2, v3}, Lcom/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    goto :stage3_adv_wrap

    :stage3_adv_check_advanced
    const-string v3, "advanced"
    invoke-virtual {v3, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v3
    if-eqz v3, :stage3_adv_unknown
    const v3, 0x7f120248
    invoke-virtual {p0, v3}, Landroid/app/Activity;->setTitle(I)V
    const v3, 0x7f1201c6
    invoke-virtual {p0, p1, v2, v3}, Lcom/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity;->Oooo0o0(Ljava/util/ArrayList;Ljava/util/ArrayList;I)V
    goto :stage3_adv_wrap

    :stage3_adv_unknown
    return-object p1

    :stage3_adv_wrap
    new-instance v3, Lo00O0o00/OooO0o;
    invoke-direct {v3, v2}, Lo00O0o00/OooO0o;-><init>(Ljava/util/ArrayList;)V
    invoke-virtual {v1, v3}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    return-object v1
.end method

.method public final onCreate(Landroid/os/Bundle;)V
'@

Replace-Stage3ExactText $advancedActivity @'
    iget-object v3, v0, Lcom/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity;->OoooO00:Lcom/suda/yzune/wakeupschedule/settings/OooOO0O;
'@ @'
    invoke-virtual {v0, v2}, Lcom/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity;->Oooo00o(Ljava/util/ArrayList;)Ljava/util/ArrayList;
    move-result-object v2

    iget-object v3, v0, Lcom/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity;->OoooO00:Lcom/suda/yzune/wakeupschedule/settings/OooOO0O;
'@

# Apply the supplied Weeko artwork everywhere the application icon is shown.
$launcherAsset = Join-Path (Split-Path $PSScriptRoot -Parent) "assets\weeko-launcher.png"
if (!(Test-Path -LiteralPath $launcherAsset)) { throw "Weeko launcher artwork is missing: $launcherAsset" }
$launcherHash = (Get-FileHash -LiteralPath $launcherAsset -Algorithm SHA256).Hash.ToUpperInvariant()
if ($launcherHash -ne "C80A35B21C459C412606D22CEFE1332D9F80117DE609BAA788535CFBFB347094") {
    throw "Weeko launcher artwork does not match the approved source image."
}
$drawableNoDpi = Join-Path $project "res\drawable-nodpi"
$mipmapNoDpi = Join-Path $project "res\mipmap-nodpi"
New-Item -ItemType Directory -Force -Path $drawableNoDpi, $mipmapNoDpi | Out-Null
Copy-Item -LiteralPath $launcherAsset -Destination (Join-Path $drawableNoDpi "weeko_launcher_art.png") -Force

$launcherBitmap = @'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <bitmap android:src="@drawable/weeko_launcher_art" android:gravity="fill" />
    </item>
</layer-list>
'@
[IO.File]::WriteAllText(
    (Join-Path $project "res\drawable\weeko_launcher_foreground_bitmap.xml"),
    $launcherBitmap,
    [Text.UTF8Encoding]::new($false)
)
[IO.File]::WriteAllText(
    (Join-Path $mipmapNoDpi "ic_launcher.xml"),
    $launcherBitmap,
    [Text.UTF8Encoding]::new($false)
)
foreach ($adaptiveIcon in @("res/mipmap-anydpi-v26/ic_launcher.xml", "res/mipmap-anydpi-v33/ic_launcher.xml")) {
    Replace-Stage3ExactText $adaptiveIcon '@drawable/ic_launcher_foreground' '@drawable/weeko_launcher_foreground_bitmap'
}
Replace-Stage3ExactText "res/drawable/ic_launcher_background.xml" '#FF335C81' '#FFFCFAF0'
Replace-Stage3ExactText "res/drawable/splash.xml" '@drawable/ic_weeko_splash' '@drawable/weeko_launcher_foreground_bitmap'

# Lock every Weeko-owned activity to portrait. External SDK activities keep
# their vendor-declared configuration.
$manifestPath = Join-Path $project "AndroidManifest.xml"
$manifest = [IO.File]::ReadAllText($manifestPath)
$activityPattern = '<activity\b[^>]*android:name="(?:com\.suda\.yzune\.wakeupschedule|io\.github\.mxwf\.weeko)[^"]*"[^>]*>'
$weekoActivities = [regex]::Matches($manifest, $activityPattern)
if ($weekoActivities.Count -lt 10) { throw "Expected Weeko activities were not found in AndroidManifest.xml" }
$manifest = [regex]::Replace($manifest, $activityPattern, {
    param($match)
    $tag = $match.Value
    if ($tag -match 'android:screenOrientation="[^"]+"') {
        return [regex]::Replace($tag, 'android:screenOrientation="[^"]+"', 'android:screenOrientation="portrait"')
    }
    $insertAt = if ($tag.EndsWith('/>')) { $tag.Length - 2 } else { $tag.Length - 1 }
    return $tag.Insert($insertAt, ' android:screenOrientation="portrait"')
})
if ($manifest -match '<activity\b[^>]*android:name="(?:com\.suda\.yzune\.wakeupschedule|io\.github\.mxwf\.weeko)[^"]*"(?![^>]*android:screenOrientation="portrait")[^>]*>') {
    throw "At least one Weeko activity was not locked to portrait."
}
[IO.File]::WriteAllText($manifestPath, $manifest, [Text.UTF8Encoding]::new($false))

# Use the supplied artwork's ivory, blue-grey, and coral as the static Fluent
# palette. Android 12+ dynamic colors remain available when the user enables
# the existing dynamic-color setting.
function Set-Stage3PaletteColor {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $true)] [string] $Value
    )
    $path = Join-Path $project $RelativePath
    $content = [IO.File]::ReadAllText($path)
    $pattern = '(<color name="' + [regex]::Escape($Name) + '">)[^<]+(</color>)'
    $matches = [regex]::Matches($content, $pattern)
    if ($matches.Count -ne 1) { throw "Expected one color named $Name in $RelativePath" }
    $updated = [regex]::Replace($content, $pattern, ('$1' + $Value + '$2'))
    [IO.File]::WriteAllText($path, $updated, [Text.UTF8Encoding]::new($false))
}

$lightPalette = [ordered]@{
    md_theme_background = '#fffcfaf0'
    md_theme_inverseOnSurface = '#fff0f2f3'
    md_theme_inversePrimary = '#ffa9c6d5'
    md_theme_inverseSurface = '#ff2d373d'
    md_theme_onBackground = '#ff25343d'
    md_theme_onPrimary = '#ffffffff'
    md_theme_onPrimaryContainer = '#ff163543'
    md_theme_onSecondary = '#ffffffff'
    md_theme_onSecondaryContainer = '#ff203b49'
    md_theme_onSurface = '#ff25343d'
    md_theme_onSurfaceVariant = '#ff536a78'
    md_theme_onTertiary = '#ffffffff'
    md_theme_onTertiaryContainer = '#ff4b1208'
    md_theme_outline = '#ff71838d'
    md_theme_outlineVariant = '#ffc4d0d5'
    md_theme_primary = '#ff526f82'
    md_theme_primaryContainer = '#ffdce8ee'
    md_theme_secondary = '#ff678192'
    md_theme_secondaryContainer = '#ffe4edf1'
    md_theme_surface = '#fffcfaf0'
    md_theme_surfaceBright = '#fffffdf6'
    md_theme_surfaceContainer = '#fff1ede2'
    md_theme_surfaceContainerHigh = '#ffebe6d9'
    md_theme_surfaceContainerHighest = '#ffe4ded0'
    md_theme_surfaceContainerLow = '#fff7f4e9'
    md_theme_surfaceContainerLowest = '#ffffffff'
    md_theme_surfaceDim = '#ffddd8cb'
    md_theme_surfaceVariant = '#ffe3e8e9'
    md_theme_tertiary = '#ffb94d35'
    md_theme_tertiaryContainer = '#ffffdbd2'
}
foreach ($entry in $lightPalette.GetEnumerator()) {
    Set-Stage3PaletteColor "res/values/colors.xml" $entry.Key $entry.Value
}

$darkPalette = [ordered]@{
    md_theme_background = '#ff10181d'
    md_theme_inverseOnSurface = '#ff2d373d'
    md_theme_inversePrimary = '#ff526f82'
    md_theme_inverseSurface = '#ffe1e7ea'
    md_theme_onBackground = '#ffeaf0f3'
    md_theme_onPrimary = '#ff163543'
    md_theme_onPrimaryContainer = '#ffd5e7ef'
    md_theme_onSecondary = '#ff203b49'
    md_theme_onSecondaryContainer = '#ffdbe7ed'
    md_theme_onSurface = '#ffeaf0f3'
    md_theme_onSurfaceVariant = '#ffc1cdd3'
    md_theme_onTertiary = '#ff551607'
    md_theme_onTertiaryContainer = '#ffffdbd2'
    md_theme_outline = '#ff899aa3'
    md_theme_outlineVariant = '#ff3d4a50'
    md_theme_primary = '#ffa9c6d5'
    md_theme_primaryContainer = '#ff334f5d'
    md_theme_secondary = '#ffb3c7d2'
    md_theme_secondaryContainer = '#ff3b515d'
    md_theme_surface = '#ff10181d'
    md_theme_surfaceBright = '#ff344047'
    md_theme_surfaceContainer = '#ff1b252b'
    md_theme_surfaceContainerHigh = '#ff253037'
    md_theme_surfaceContainerHighest = '#ff303b42'
    md_theme_surfaceContainerLow = '#ff172126'
    md_theme_surfaceContainerLowest = '#ff0b1115'
    md_theme_surfaceDim = '#ff10181d'
    md_theme_surfaceVariant = '#ff3d4a50'
    md_theme_tertiary = '#ffffb4a2'
    md_theme_tertiaryContainer = '#ff7a2d1c'
}
foreach ($entry in $darkPalette.GetEnumerator()) {
    Set-Stage3PaletteColor "res/values-night/colors.xml" $entry.Key $entry.Value
}

# Remove the last two feature-specific light surfaces so the bath page also
# follows the active app theme.
$bathPath = Join-Path $project "res\layout\fragment_bath.xml"
$bath = [IO.File]::ReadAllText($bathPath)
$bathReplacements = [ordered]@{
    '#fffce4ec' = '?colorTertiaryContainer'
    '#ff880e4f' = '?colorOnTertiaryContainer'
    '#ff560027' = '?colorOnTertiaryContainer'
    '#ffe3f2fd' = '?colorPrimaryContainer'
    '#ff0d47a1' = '?colorOnPrimaryContainer'
    '#ff002171' = '?colorOnPrimaryContainer'
    '@android:color/black' = '?colorOnSurface'
}
foreach ($entry in $bathReplacements.GetEnumerator()) {
    if (!$bath.Contains($entry.Key)) { throw "Expected bath color $($entry.Key) was not found" }
    $bath = $bath.Replace($entry.Key, $entry.Value)
}
[IO.File]::WriteAllText($bathPath, $bath, [Text.UTF8Encoding]::new($false))

# Keep list loading text readable in both theme modes.
$loadMorePath = Join-Path $project "res\layout\brvah_quick_view_load_more.xml"
$loadMore = [IO.File]::ReadAllText($loadMorePath)
if (!$loadMore.Contains('android:textColor="@android:color/black"')) {
    throw "Expected load-more text color was not found"
}
$loadMore = $loadMore.Replace('android:textColor="@android:color/black"', 'android:textColor="?colorOnSurface"')
[IO.File]::WriteAllText($loadMorePath, $loadMore, [Text.UTF8Encoding]::new($false))

# RemoteViews do not inherit the Activity theme. Give the course widget an
# explicit companion drawable for system night mode while keeping its layers.
$widgetCardPath = Join-Path $project "res\drawable\muticards_bg.xml"
$widgetCard = [IO.File]::ReadAllText($widgetCardPath)
$widgetCardReplacements = [ordered]@{
    '#ffa9a9a9' = '#ffb3c7d2'
    '#ffc3c3c3' = '#ffdce8ee'
    '@android:color/white' = '#fffcfaf0'
}
foreach ($entry in $widgetCardReplacements.GetEnumerator()) {
    if (!$widgetCard.Contains($entry.Key)) { throw "Expected widget card color $($entry.Key) was not found" }
    $widgetCard = $widgetCard.Replace($entry.Key, $entry.Value)
}
[IO.File]::WriteAllText($widgetCardPath, $widgetCard, [Text.UTF8Encoding]::new($false))

$widgetCardNightDirectory = Join-Path $project "res\drawable-night"
[IO.Directory]::CreateDirectory($widgetCardNightDirectory) | Out-Null
$widgetCardNight = $widgetCard.Replace('#ffb3c7d2', '#ff3b515d').Replace('#ffdce8ee', '#ff253037').Replace('#fffcfaf0', '#ff10181d')
[IO.File]::WriteAllText((Join-Path $widgetCardNightDirectory "muticards_bg.xml"), $widgetCardNight, [Text.UTF8Encoding]::new($false))

$paletteSmali = @'
.class public final Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;
.super Ljava/lang/Object;
.source "FluentSchedulePalette.kt"

.method private constructor <init>()V
    .locals 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

.method private static resolveColor(Landroid/content/Context;I)I
    .locals 4
    const/4 v0, 0x1
    new-array v0, v0, [I
    const/4 v1, 0x0
    aput p1, v0, v1
    invoke-virtual {p0, v0}, Landroid/content/Context;->obtainStyledAttributes([I)Landroid/content/res/TypedArray;
    move-result-object v2
    invoke-virtual {v2, v1, v1}, Landroid/content/res/TypedArray;->getColor(II)I
    move-result v3
    invoke-virtual {v2}, Landroid/content/res/TypedArray;->recycle()V
    return v3
.end method

.method private static isDark(Landroid/content/Context;)Z
    .locals 2
    invoke-virtual {p0}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;
    move-result-object v0
    invoke-virtual {v0}, Landroid/content/res/Resources;->getConfiguration()Landroid/content/res/Configuration;
    move-result-object v0
    iget v0, v0, Landroid/content/res/Configuration;->uiMode:I
    and-int/lit8 v0, v0, 0x30
    const/16 v1, 0x20
    if-ne v0, v1, :palette_light
    const/4 v0, 0x1
    return v0
    :palette_light
    const/4 v0, 0x0
    return v0
.end method

.method private static blend(III)I
    .locals 7
    const/16 v6, 0x64
    sub-int v6, v6, p2
    invoke-static {p0}, Landroid/graphics/Color;->red(I)I
    move-result v0
    mul-int/2addr v0, p2
    invoke-static {p1}, Landroid/graphics/Color;->red(I)I
    move-result v1
    mul-int/2addr v1, v6
    add-int/2addr v0, v1
    div-int/lit8 v0, v0, 0x64
    invoke-static {p0}, Landroid/graphics/Color;->green(I)I
    move-result v2
    mul-int/2addr v2, p2
    invoke-static {p1}, Landroid/graphics/Color;->green(I)I
    move-result v3
    mul-int/2addr v3, v6
    add-int/2addr v2, v3
    div-int/lit8 v2, v2, 0x64
    invoke-static {p0}, Landroid/graphics/Color;->blue(I)I
    move-result v4
    mul-int/2addr v4, p2
    invoke-static {p1}, Landroid/graphics/Color;->blue(I)I
    move-result v5
    mul-int/2addr v5, v6
    add-int/2addr v4, v5
    div-int/lit8 v4, v4, 0x64
    invoke-static {v0, v2, v4}, Landroid/graphics/Color;->rgb(III)I
    move-result v0
    return v0
.end method

.method public static install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    .locals 6
    const v0, 0x7f04012f
    invoke-static {p0, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v0
    const v1, 0x7f040134
    invoke-static {p0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v1
    iget-object v2, p0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOo00:Landroidx/coordinatorlayout/widget/CoordinatorLayout;
    invoke-virtual {v3, v0}, Landroid/view/View;->setBackgroundColor(I)V
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0OO:Landroidx/viewpager2/widget/ViewPager2;
    invoke-virtual {v3, v0}, Landroid/view/View;->setBackgroundColor(I)V
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0o:Landroidx/constraintlayout/widget/ConstraintLayout;
    invoke-virtual {v3, v1}, Landroid/view/View;->setBackgroundColor(I)V
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0Oo:Landroidx/appcompat/widget/AppCompatImageView;
    invoke-static {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->isDark(Landroid/content/Context;)Z
    move-result v4
    if-eqz v4, :palette_clear_image_filter
    const/high16 v5, 0x66000000
    invoke-virtual {v3, v5}, Landroid/widget/ImageView;->setColorFilter(I)V
    goto :palette_install_done
    :palette_clear_image_filter
    invoke-virtual {v3}, Landroid/widget/ImageView;->clearColorFilter()V
    :palette_install_done
    return-void
.end method

.method private static styleCourse(Lcom/suda/yzune/wakeupschedule/widget/TipTextView;)V
    .locals 7
    invoke-virtual {p0}, Landroid/view/View;->getContext()Landroid/content/Context;
    move-result-object v0
    const v1, 0x7f040132
    invoke-static {v0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v1
    const v2, 0x7f040119
    invoke-static {v0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v2
    const v3, 0x7f040121
    invoke-static {v0, v3}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v3
    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->isDark(Landroid/content/Context;)Z
    move-result v4
    if-eqz v4, :palette_course_light
    const/16 v4, 0x2d
    goto :palette_course_weight_ready
    :palette_course_light
    const/16 v4, 0x37
    :palette_course_weight_ready
    iget-object v5, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;->OooOOOO:Landroid/graphics/Paint;
    invoke-virtual {v5}, Landroid/graphics/Paint;->getColor()I
    move-result v6
    invoke-static {v6, v1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->blend(III)I
    move-result v6
    invoke-virtual {v5, v6}, Landroid/graphics/Paint;->setColor(I)V
    iget-object v5, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;->OooOO0o:Landroid/text/TextPaint;
    invoke-virtual {v5, v2}, Landroid/graphics/Paint;->setColor(I)V
    iget-object v5, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;->OooOOO0:Landroid/text/TextPaint;
    invoke-virtual {v5, v2}, Landroid/graphics/Paint;->setColor(I)V
    iget-object v5, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;->OooOOOo:Landroid/graphics/Paint;
    invoke-virtual {v5, v3}, Landroid/graphics/Paint;->setColor(I)V
    invoke-virtual {p0}, Landroid/view/View;->invalidate()V
    return-void
.end method

.method private static styleTree(Landroid/view/View;III)V
    .locals 6
    instance-of v0, p0, Landroid/widget/TextView;
    if-eqz v0, :palette_check_grid
    move-object v0, p0
    check-cast v0, Landroid/widget/TextView;
    invoke-virtual {v0, p1}, Landroid/widget/TextView;->setTextColor(I)V
    invoke-virtual {v0}, Landroid/widget/TextView;->getTypeface()Landroid/graphics/Typeface;
    move-result-object v1
    if-eqz v1, :palette_check_grid
    invoke-virtual {v1}, Landroid/graphics/Typeface;->isBold()Z
    move-result v1
    if-eqz v1, :palette_check_grid
    invoke-virtual {v0, p3}, Landroid/widget/TextView;->setTextColor(I)V
    :palette_check_grid
    instance-of v0, p0, Lcom/suda/yzune/wakeupschedule/widget/GridBackgroundView;
    if-eqz v0, :palette_check_course
    move-object v0, p0
    check-cast v0, Lcom/suda/yzune/wakeupschedule/widget/GridBackgroundView;
    invoke-virtual {v0, p2}, Lcom/suda/yzune/wakeupschedule/widget/GridBackgroundView;->setColor(I)V
    const v1, 0x3ed70a3d    # 0.42f
    invoke-virtual {v0, v1}, Landroid/view/View;->setAlpha(F)V
    :palette_check_course
    instance-of v0, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;
    if-eqz v0, :palette_check_group
    move-object v0, p0
    check-cast v0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;
    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->styleCourse(Lcom/suda/yzune/wakeupschedule/widget/TipTextView;)V
    :palette_check_group
    instance-of v0, p0, Landroid/view/ViewGroup;
    if-eqz v0, :palette_tree_done
    check-cast p0, Landroid/view/ViewGroup;
    invoke-virtual {p0}, Landroid/view/ViewGroup;->getChildCount()I
    move-result v0
    const/4 v1, 0x0
    :palette_child_loop
    if-ge v1, v0, :palette_tree_done
    invoke-virtual {p0, v1}, Landroid/view/ViewGroup;->getChildAt(I)Landroid/view/View;
    move-result-object v2
    invoke-static {v2, p1, p2, p3}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->styleTree(Landroid/view/View;III)V
    add-int/lit8 v1, v1, 0x1
    goto :palette_child_loop
    :palette_tree_done
    return-void
.end method

.method public static styleSchedule(Lcom/suda/yzune/wakeupschedule/schedule/o000OO;)V
    .locals 6
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/o000OO;->OooO00o:Landroid/content/Context;
    const v1, 0x7f04012f
    invoke-static {v0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v1
    const v2, 0x7f04011b
    invoke-static {v0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v2
    const v3, 0x7f040121
    invoke-static {v0, v3}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v3
    const v4, 0x7f04013a
    invoke-static {v0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v4
    iget-object v5, p0, Lcom/suda/yzune/wakeupschedule/schedule/o000OO;->OooOOo0:Landroidx/constraintlayout/widget/ConstraintLayout;
    invoke-virtual {v5, v1}, Landroid/view/View;->setBackgroundColor(I)V
    iget-object v5, p0, Lcom/suda/yzune/wakeupschedule/schedule/o000OO;->OooOOOO:Landroidx/constraintlayout/widget/ConstraintLayout;
    invoke-virtual {v5, v1}, Landroid/view/View;->setBackgroundColor(I)V
    iget-object v5, p0, Lcom/suda/yzune/wakeupschedule/schedule/o000OO;->OooOOo0:Landroidx/constraintlayout/widget/ConstraintLayout;
    invoke-static {v5, v2, v3, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->styleTree(Landroid/view/View;III)V
    return-void
.end method
'@
[IO.File]::WriteAllText(
    (Join-Path $project "smali\com\suda\yzune\wakeupschedule\schedule\FluentSchedulePalette.smali"),
    $paletteSmali,
    [Text.UTF8Encoding]::new($false)
)

Replace-Stage3ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
'@ @'
    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
'@

Replace-Stage3ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o0000Ooo.smali" @'
    iput-object v1, v4, Lcom/suda/yzune/wakeupschedule/schedule/o000OO;->OooOOO:Lo00Oo0O0/o000O000;

    .line 669
'@ @'
    iput-object v1, v4, Lcom/suda/yzune/wakeupschedule/schedule/o000OO;->OooOOO:Lo00Oo0O0/o000O000;

    invoke-static {v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->styleSchedule(Lcom/suda/yzune/wakeupschedule/schedule/o000OO;)V

    .line 669
'@

Write-Output "Applied Weeko v0.8 settings Stage 3 flattened settings, global theme, icon, portrait, and Fluent schedule palette to $project"
