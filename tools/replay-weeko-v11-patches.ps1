param(
    [Parameter(Mandatory = $true)] [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
& $pwsh -NoProfile -File (Join-Path $root "tools\replay-weeko-v101-patches.ps1") -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "v1.0.1 patch replay failed; v1.1 patches were not applied." }

function Replace-V11ExactText {
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
        throw "Expected one v1.1 match in $RelativePath"
    }
    $content = $content.Replace($oldLf, $newLf)
    if ($lineEnding -eq "`r`n") { $content = $content.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

Replace-V11ExactText "apktool.yml" "  versionCode: 13`n  versionName: 1.0.1" "  versionCode: 14`n  versionName: 1.1.0"

foreach ($layout in @("res/layout/fragment_web_view_login.xml", "res/layout-v22/fragment_web_view_login.xml")) {
    Replace-V11ExactText $layout 'android:text="密码一直错误？"' 'android:text="密码箱"'
}

Replace-V11ExactText "AndroidManifest.xml" `
    '<activity android:exported="false" android:label="Weeko 课程表" android:name="io.github.mxwf.weeko.about.WeekoAboutActivity" android:screenOrientation="portrait"/>' `
    @'
<activity android:exported="false" android:label="Weeko 课程表" android:name="io.github.mxwf.weeko.about.WeekoAboutActivity" android:screenOrientation="portrait"/>
        <activity android:exported="false" android:label="密码箱" android:name="io.github.mxwf.weeko.vault.PasswordVaultActivity" android:screenOrientation="portrait"/>
'@

Replace-V11ExactText "res/values/strings.xml" `
    '<string name="weeko_settings_section_data">Data &amp; More</string>' `
    '<string name="weeko_settings_section_data">Privacy &amp; Security</string>'
Replace-V11ExactText "res/values/strings.xml" `
    '    <string name="weeko_settings_action_transfer">Move Courses by Date</string>' `
    @'
    <string name="weeko_settings_action_transfer">Move Courses by Date</string>
    <string name="weeko_settings_action_vault">Password Vault</string>
'@
Replace-V11ExactText "res/values-zh-rCN/strings.xml" `
    '<string name="weeko_settings_section_data">&#x6570;&#x636E;&#x4E0E;&#x66F4;&#x591A;</string>' `
    '<string name="weeko_settings_section_data">隐私与安全</string>'
Replace-V11ExactText "res/values-zh-rCN/strings.xml" `
    '    <string name="weeko_settings_action_transfer">&#x6309;&#x65E5;&#x671F;&#x8F6C;&#x79FB;&#x8BFE;&#x7A0B;</string>' `
    @'
    <string name="weeko_settings_action_transfer">&#x6309;&#x65E5;&#x671F;&#x8F6C;&#x79FB;&#x8BFE;&#x7A0B;</string>
    <string name="weeko_settings_action_vault">密码箱</string>
'@
Replace-V11ExactText "res/values/public.xml" `
    '    <public type="string" name="weeko_settings_action_transfer" id="0x7f120248" />' `
    @'
    <public type="string" name="weeko_settings_action_transfer" id="0x7f120248" />
    <public type="string" name="weeko_settings_action_vault" id="0x7f120249" />
'@

$webFragment = "smali/com/suda/yzune/wakeupschedule/schedule_import/WebViewLoginFragment.smali"
Replace-V11ExactText $webFragment @'
    const-string v6, "\u6211\u77e5\u9053\u5566"

    .line 885
    .line 886
    invoke-virtual {v1, v6, v7}, Lo000Oo/OooO;->OooOOOO(Ljava/lang/String;Landroid/content/DialogInterface$OnClickListener;)V
'@ @'
    const-string v6, "\u6211\u77e5\u9053\u5566"

    .line 885
    .line 886
    invoke-virtual {v0}, Landroidx/fragment/app/oo0o0Oo;->Oooo0o0()Landroid/content/Context;
    move-result-object v10
    invoke-static {v10}, Lio/github/mxwf/weeko/vault/EduImportSupport;->noticeConfirmation(Landroid/content/Context;)Landroid/content/DialogInterface$OnClickListener;
    move-result-object v10
    invoke-virtual {v1, v6, v10}, Lo000Oo/OooO;->OooOOOO(Ljava/lang/String;Landroid/content/DialogInterface$OnClickListener;)V
'@

Replace-V11ExactText $webFragment @'
    invoke-virtual {v1}, LOooOoO0/o00000O;->OooO0oO()Landroidx/appcompat/app/OooOOO;

    .line 902
    .line 903
    .line 904
    move-result-object v1

    .line 905
    iput-object v1, v0, Lcom/suda/yzune/wakeupschedule/schedule_import/WebViewLoginFragment;->OooooO0:Landroidx/appcompat/app/OooOOO;
'@ @'
    invoke-virtual {v0}, Landroidx/fragment/app/oo0o0Oo;->Oooo0o0()Landroid/content/Context;
    move-result-object v6
    invoke-static {v6}, Lio/github/mxwf/weeko/vault/EduImportSupport;->isNoticeConfirmed(Landroid/content/Context;)Z
    move-result v6
    if-nez v6, :v11_create_notice_only
    invoke-virtual {v1}, LOooOoO0/o00000O;->OooO0oO()Landroidx/appcompat/app/OooOOO;
    move-result-object v1
    goto :v11_notice_ready

    :v11_create_notice_only
    invoke-virtual {v1}, LOooOoO0/o00000O;->OooO00o()Landroidx/appcompat/app/OooOOO;
    move-result-object v1

    :v11_notice_ready
    .line 905
    iput-object v1, v0, Lcom/suda/yzune/wakeupschedule/schedule_import/WebViewLoginFragment;->OooooO0:Landroidx/appcompat/app/OooOOO;
'@

Replace-V11ExactText $webFragment @'
    .line 604
    :goto_0
    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule_import/WebViewLoginFragment;->OoooOO0()Lcom/suda/yzune/wakeupschedule/schedule_import/OooOo00;
'@ @'
    .line 604
    :goto_0
    iget-object v1, v0, Lcom/suda/yzune/wakeupschedule/schedule_import/WebViewLoginFragment;->Ooooo0o:Lo00O0OO/OooO0o;
    iget-object v6, v1, Lo00O0OO/OooO0o;->OooOo00:Lcom/google/android/material/card/MaterialCardView;
    iget-object v10, v1, Lo00O0OO/OooO0o;->OooOO0:Lcom/google/android/material/button/MaterialButton;
    invoke-virtual {v0}, Landroidx/fragment/app/oo0o0Oo;->Oooo0o0()Landroid/content/Context;
    move-result-object v1
    invoke-static {v1, v6, v10}, Lio/github/mxwf/weeko/vault/EduImportSupport;->onEnter(Landroid/content/Context;Landroid/view/View;Landroid/view/View;)V

    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule_import/WebViewLoginFragment;->OoooOO0()Lcom/suda/yzune/wakeupschedule/schedule_import/OooOo00;
'@

$webClick = "smali/com/suda/yzune/wakeupschedule/schedule_import/o000OOo.smali"
Replace-V11ExactText $webClick @'
    packed-switch v0, :pswitch_data_0

    .line 4
'@ @'
    packed-switch v0, :pswitch_data_0

    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule_import/o000OOo;->OooO0oo:Lcom/suda/yzune/wakeupschedule/schedule_import/WebViewLoginFragment;
    invoke-virtual {v0}, Landroidx/fragment/app/oo0o0Oo;->Oooo0o0()Landroid/content/Context;
    move-result-object v0
    invoke-static {v0}, Lio/github/mxwf/weeko/vault/PasswordVaultActivity;->open(Landroid/content/Context;)V
    return-void

    .line 4
'@

$settings = "smali/com/suda/yzune/wakeupschedule/settings/SettingsActivity.smali"
Replace-V11ExactText $settings @'
.method public final Oooo0OO(I)Z
    .locals 4

    const v0, 0x7f120245
'@ @'
.method public final Oooo0OO(I)Z
    .locals 4

    const v0, 0x7f120249
    if-ne p1, v0, :v11_existing_settings_route
    invoke-static {p0}, Lio/github/mxwf/weeko/vault/PasswordVaultActivity;->open(Landroid/content/Context;)V
    const/4 v0, 0x1
    return v0

    :v11_existing_settings_route
    const v0, 0x7f120245
'@

Replace-V11ExactText $settings @'
    new-instance v4, Lo00O0o00/OooO;
    const v5, 0x7f120244
    invoke-direct {v4, v5, v3}, Lo00O0o00/OooO;-><init>(ILjava/lang/Boolean;)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    const v4, 0x7f1201a8
'@ @'
    new-instance v4, Lo00O0o00/OooO;
    const v5, 0x7f120244
    invoke-direct {v4, v5, v3}, Lo00O0o00/OooO;-><init>(ILjava/lang/Boolean;)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    new-instance v4, Lo00O0o00/OooOo00;
    const v5, 0x7f120249
    const-string v6, "Android Keystore 加密存储，仅手动复制"
    invoke-direct {v4, v5, v6, v3, v7}, Lo00O0o00/OooOo00;-><init>(ILjava/lang/String;Ljava/util/List;I)V
    invoke-virtual {v2, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    const v4, 0x7f1201a8
'@

Write-Output "Applied Weeko v1.1 education import and encrypted password vault patches to $project"
