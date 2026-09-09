param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path

function Replace-ExactText {
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

Replace-ExactText "apktool.yml" @'
  versionCode: 5
  versionName: 0.5.0-test1
'@ @'
  versionCode: 6
  versionName: 0.6.0-test1
'@

Replace-ExactText "smali/com/suda/yzune/wakeupschedule/OooOO0.smali" `
    '    const-string v0, "https://www.wakeup.fun"' `
    '    const-string v0, "https://github.com/MXWF0/Weeko/releases"'
Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule/oo0o0Oo.smali" `
    '    const-string v1, "WakeUp\u8bfe\u7a0b\u8868\u5206\u4eab\u7801"' `
    '    const-string v1, "Weeko\u8bfe\u7a0b\u8868\u5206\u4eab\u7801"'
Replace-ExactText 'smali/com/suda/yzune/wakeupschedule/schedule/ScheduleViewModel$exportICS$2.smali' `
    '    const-string v1, "-//YZune//WakeUpSchedule//EN"' `
    '    const-string v1, "-//MXWF0//Weeko//EN"'
Replace-ExactText "smali/com/suda/yzune/wakeupschedule/utils/OooOOOO.smali" `
    '    const-string v12, "WakeUpSchedule-"' `
    '    const-string v12, "WeekoSchedule-"'

$oldShare = @'
    const-string v2, "\u8fd9\u662f\u6765\u81ea\u300cWakeUp\u8bfe\u7a0b\u8868\u300d\u7684\u8bfe\u8868\u5206\u4eab"

    .line 53
    .line 54
    const/4 v3, 0x0

    .line 55
    invoke-static {v0, v2, v3}, Lkotlin/text/oo0o0Oo;->o00ooo(Ljava/lang/String;Ljava/lang/String;Z)Z

    .line 56
    .line 57
    .line 58
    move-result v2

    .line 59
    if-eqz v2, :cond_2
'@.Trim("`r", "`n")
$newShare = @'
    const-string v2, "\u8fd9\u662f\u6765\u81ea\u300cWakeUp\u8bfe\u7a0b\u8868\u300d\u7684\u8bfe\u8868\u5206\u4eab"

    .line 53
    .line 54
    const/4 v3, 0x0

    .line 55
    invoke-static {v0, v2, v3}, Lkotlin/text/oo0o0Oo;->o00ooo(Ljava/lang/String;Ljava/lang/String;Z)Z

    move-result v2

    if-nez v2, :cond_weeko_or_wakeup_share

    const-string v2, "\u8fd9\u662f\u6765\u81ea\u300cWeeko \u8bfe\u7a0b\u8868\u300d\u7684\u8bfe\u8868\u5206\u4eab"

    invoke-static {v0, v2, v3}, Lkotlin/text/oo0o0Oo;->o00ooo(Ljava/lang/String;Ljava/lang/String;Z)Z

    move-result v2

    if-eqz v2, :cond_2

    :cond_weeko_or_wakeup_share
'@.Trim("`r", "`n")
Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule_import/OooO00o.smali" $oldShare $newShare

$oldIntro = @'
    .line 151
    .line 152
    .line 153
    invoke-virtual {p2, v0}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    .line 154
    .line 155
    .line 156
    new-instance v0, Lo00O0o00/OooO0o;
'@.Trim("`r", "`n")
$newIntro = @'
    .line 151
    .line 152
    .line 153
    # v0.6: remove only the legacy external "more questions" item. Widget
    # setup, pinning, configuration, and refresh behavior stay unchanged.
    nop

    .line 154
    .line 155
    .line 156
    new-instance v0, Lo00O0o00/OooO0o;
'@.Trim("`r", "`n")
Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule_settings/IntroAppWidgetFragment.smali" $oldIntro $newIntro

$oldSettings = @'
    .line 255
    const v9, 0x7f1201a0

    .line 256
    .line 257
    .line 258
    invoke-direct {v4, v9, v5, v6, v8}, Lo00O0o00/OooOOO0;-><init>(IILjava/lang/String;Z)V

    .line 259
    .line 260
    .line 261
    invoke-virtual {v1, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
'@.Trim("`r", "`n")
$newSettings = @'
    .line 255
    const v9, 0x7f1201a0

    .line 256
    .line 257
    .line 258
    invoke-direct {v4, v9, v5, v6, v8}, Lo00O0o00/OooOOO0;-><init>(IILjava/lang/String;Z)V

    .line 259
    .line 260
    .line 261
    # v0.6: keep the s_update preference key for compatibility, but remove
    # the obsolete WakeUp automatic-update control. Weeko update checks are
    # explicit actions in the About page.
    nop
'@.Trim("`r", "`n")
Replace-ExactText "smali/com/suda/yzune/wakeupschedule/settings/SettingsActivity.smali" $oldSettings $newSettings

$oldScheduleShare = '    const-string v1, "\u8fd9\u662f\u6765\u81ea\u300cWakeUp\u8bfe\u7a0b\u8868\u300d\u7684\u8bfe\u8868\u5206\u4eab\uff0c30\u5206\u949f\u5185\u6709\u6548\u54e6\uff0c\u5982\u679c\u5931\u6548\u8bf7\u670b\u53cb\u518d\u5206\u4eab\u4e00\u904d\u53ed\u3002\u4e3a\u4e86\u4fdd\u62a4\u9690\u79c1\u6211\u4eec\u9009\u62e9\u4e0d\u76d1\u542c\u4f60\u7684\u526a\u8d34\u677f\uff0c\u8bf7\u590d\u5236\u8fd9\u6761\u6d88\u606f\u540e\uff0c\u6253\u5f00App\u7684\u4e3b\u754c\u9762\uff0c\u53f3\u4e0a\u89d2\u7b2c\u4e8c\u4e2a\u6309\u94ae -> \u4ece\u5206\u4eab\u53e3\u4ee4\u5bfc\u5165\uff0c\u6309\u64cd\u4f5c\u63d0\u793a\u5373\u53ef\u5b8c\u6210\u5bfc\u5165~\u5206\u4eab\u53e3\u4ee4\u4e3a\u300c"'
$newScheduleShare = '    const-string v1, "\u8fd9\u662f\u6765\u81ea\u300cWeeko \u8bfe\u7a0b\u8868\u300d\u7684\u8bfe\u8868\u5206\u4eab\uff0c30\u5206\u949f\u5185\u6709\u6548\u54e6\uff0c\u5982\u679c\u5931\u6548\u8bf7\u670b\u53cb\u518d\u5206\u4eab\u4e00\u904d\u53ed\u3002\u4e3a\u4e86\u4fdd\u62a4\u9690\u79c1\u6211\u4eec\u9009\u62e9\u4e0d\u76d1\u542c\u4f60\u7684\u526a\u8d34\u677f\uff0c\u8bf7\u590d\u5236\u8fd9\u6761\u6d88\u606f\u540e\uff0c\u6253\u5f00 App \u7684\u4e3b\u754c\u9762\uff0c\u4ece\u5206\u4eab\u53e3\u4ee4\u5bfc\u5165\uff0c\u6309\u64cd\u4f5c\u63d0\u793a\u5373\u53ef\u5b8c\u6210\u5bfc\u5165\u3002\u5206\u4eab\u53e3\u4ee4\u4e3a\u300c"'
Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" $oldScheduleShare $newScheduleShare

$oldPrivacy = '    const-string v0, "Weeko \u8bfe\u7a0b\u8868 0.2.0-test1 \u9690\u79c1\u4e0e\u5185\u6d4b\u8bf4\u660e\n\n\u672c\u7248\u672c\u662f\u4ee5 WakeUp 6.0.23 \u53ef\u8fd0\u884c APK \u4e3a\u884c\u4e3a\u57fa\u7ebf\u5236\u4f5c\u7684\u8fc7\u6e21\u6027\u4e8c\u8fdb\u5236\u5185\u6d4b\u7248\uff0c\u4e0d\u662f\u53ef\u7ef4\u62a4\u6e90\u7801\u53d1\u884c\u7248\uff0c\u4e0d\u5f97\u516c\u5f00\u53d1\u5e03\u3002\n\n\u8bfe\u7a0b\u8868\u3001\u8bbe\u7f6e\u548c\u5bfc\u5165\u6570\u636e\u4fdd\u5b58\u5728\u5f53\u524d\u8bbe\u5907\u3002\u5f53\u524d\u4e8c\u8fdb\u5236\u4ecd\u5305\u542b\u539f\u7248\u7b2c\u4e09\u65b9 SDK \u4e0e\u7f51\u7edc\u3001\u6559\u52a1\u5bfc\u5165\u3001\u5728\u7ebf\u5206\u4eab\u53ca\u7533\u8bf7\u9002\u914d\u5b9e\u73b0\u3002\u4f7f\u7528\u8fd9\u4e9b\u65e7\u8054\u7f51\u529f\u80fd\u53ef\u80fd\u8fde\u63a5\u539f WakeUp \u670d\u52a1\uff1b\u672c\u5185\u6d4b\u7248\u4e0d\u4fdd\u8bc1\u5176\u53ef\u7528\u6027\u6216\u6570\u636e\u5b89\u5168\uff0c\u8bf7\u52ff\u63d0\u4ea4\u6559\u52a1\u5bc6\u7801\u3001Cookie\u3001Token \u6216\u4e2a\u4eba\u4fe1\u606f\u3002\n\n\u672c\u7248\u672c\u4ec5\u7528\u4e8e\u672c\u5730\u517c\u5bb9\u6027\u548c\u529f\u80fd\u9a8c\u8bc1\u3002\u82e5\u4e0d\u540c\u610f\uff0c\u8bf7\u9009\u62e9\u62d2\u7edd\u5e76\u5378\u8f7d\u5e94\u7528\u3002"'
$newPrivacy = '    const-string v0, "Weeko \u8bfe\u7a0b\u8868 0.6.0-test1 \u9690\u79c1\u4e0e\u5185\u6d4b\u8bf4\u660e\n\n\u672c\u7248\u672c\u662f\u57fa\u4e8e\u5df2\u9a8c\u8bc1\u65e7\u7248\u8bfe\u7a0b\u8868\u884c\u4e3a\u6bcd\u4f53\u5236\u4f5c\u7684\u8fc7\u6e21\u6027\u4e8c\u8fdb\u5236\u5185\u6d4b\u7248\uff0c\u4e0d\u662f\u5b8c\u6574\u6e90\u7801\u53d1\u884c\u7248\uff0c\u4e0d\u5f97\u516c\u5f00\u53d1\u5e03\u3002\n\nv0.6 \u8d77\u4f7f\u7528\u65b0\u7684 Weeko \u957f\u671f\u7b7e\u540d\uff0c\u65e0\u6cd5\u76f4\u63a5\u8986\u76d6 v0.5\u3002\u8fc1\u79fb\u524d\u5fc5\u987b\u5148\u5bfc\u51fa\u517c\u5bb9\u5907\u4efd\uff0c\u518d\u5378\u8f7d\u65e7\u7b7e\u540d\u7248\u672c\u5e76\u5b89\u88c5 v0.6\u3002\n\n\u8bfe\u7a0b\u6570\u636e\u5e93\u548c\u5927\u591a\u6570\u8bbe\u7f6e\u4fdd\u5b58\u5728\u5f53\u524d\u8bbe\u5907\u3002\u5f53\u524d\u4e8c\u8fdb\u5236\u4ecd\u5305\u542b\u517c\u5bb9\u6bcd\u4f53\u7684\u7b2c\u4e09\u65b9 SDK\u3001\u6559\u52a1\u5bfc\u5165\u3001\u5728\u7ebf\u5206\u4eab\u53ca\u7533\u8bf7\u9002\u914d\u5b9e\u73b0\uff0c\u53ef\u80fd\u8fde\u63a5\u65e7\u7248\u6216\u5b66\u6821\u670d\u52a1\u3002\u5173\u4e8e\u9875\u7684\u66f4\u65b0\u68c0\u67e5\u4ec5\u8bbf\u95ee GitHub MXWF0/Weeko Releases API\uff0c\u4e0d\u5185\u7f6e Token\u3002\u8bf7\u52ff\u5411\u672a\u9a8c\u8bc1\u7684\u65e7\u8054\u7f51\u5165\u53e3\u63d0\u4ea4\u5bc6\u7801\u3001Cookie\u3001Token \u6216\u4e2a\u4eba\u4fe1\u606f\u3002\n\n\u672c\u7248\u672c\u4ec5\u7528\u4e8e\u672c\u5730\u517c\u5bb9\u6027\u548c\u529f\u80fd\u9a8c\u8bc1\u3002\u82e5\u4e0d\u540c\u610f\uff0c\u8bf7\u9009\u62d2\u7edd\u5e76\u5378\u8f7d\u5e94\u7528\u3002"'
Replace-ExactText "smali/com/suda/yzune/wakeupschedule/utils/o00O0O.smali" $oldPrivacy $newPrivacy

Write-Output "Applied 9 exact v0.6 smali patches and version metadata to $project"
