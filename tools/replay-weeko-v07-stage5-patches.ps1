param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage4Script = Join-Path $PSScriptRoot "replay-weeko-v07-stage4-patches.ps1"

& $stage4Script -ProjectPath $project
if (!$?) { throw "Stage 4 patch replay failed; Stage 5 was not applied." }

function Replace-Stage5ExactText {
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

Replace-Stage5ExactText "apktool.yml" @'
  versionCode: 7
  versionName: 0.7.0-stage4
'@ @'
  versionCode: 7
  versionName: 0.7.0-stage5
'@

Replace-Stage5ExactText "res/values/strings.xml" @'
    <string name="tooltip_current_week">Tap here to back to the current week.</string>
'@ @'
    <string name="tooltip_current_week">Tap here to open the navigation menu.</string>
'@
Replace-Stage5ExactText "res/values/strings.xml" @'
    <string name="tooltip_share">Tap here to share or export the schedule.</string>
'@ @'
    <string name="tooltip_share">Tap here to open more actions.</string>
'@

$utf8 = [Text.Encoding]::UTF8
$zhCurrentOld = $utf8.GetString([Convert]::FromBase64String("ICAgIDxzdHJpbmcgbmFtZT0idG9vbHRpcF9jdXJyZW50X3dlZWsiPueCuei/memHjOW/q+mAn+WbnuWIsOW9k+WJjeWRqDwvc3RyaW5nPg=="))
$zhCurrentNew = $utf8.GetString([Convert]::FromBase64String("ICAgIDxzdHJpbmcgbmFtZT0idG9vbHRpcF9jdXJyZW50X3dlZWsiPueCuei/memHjOaJk+W8gOWvvOiIquiPnOWNlTwvc3RyaW5nPg=="))
$zhShareOld = $utf8.GetString([Convert]::FromBase64String("ICAgIDxzdHJpbmcgbmFtZT0idG9vbHRpcF9zaGFyZSI+54K56L+Z6YeM5a+85Ye644CB5YiG5Lqr6K++6KGoPC9zdHJpbmc+"))
$zhShareNew = $utf8.GetString([Convert]::FromBase64String("ICAgIDxzdHJpbmcgbmFtZT0idG9vbHRpcF9zaGFyZSI+54K56L+Z6YeM5omT5byA5pu05aSa5Yqf6IO9PC9zdHJpbmc+"))
foreach ($locale in @("zh-rCN", "zh-rHK", "zh-rMO", "zh-rSG", "zh-rTW")) {
    Replace-Stage5ExactText "res/values-$locale/strings.xml" $zhCurrentOld $zhCurrentNew
    Replace-Stage5ExactText "res/values-$locale/strings.xml" $zhShareOld $zhShareNew
}

# The left navigation button replaced the old current-week action. The add
# tooltip now targets the manual-add button rather than the import button.
Replace-Stage5ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    iget-object v2, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oo:Landroidx/appcompat/widget/AppCompatImageButton;

    .line 194
    .line 195
    invoke-static {v1, v4, v2}, Lcom/skydoves/balloon/OooOo00;->OooOO0O(Lcom/skydoves/balloon/OooOo00;Lcom/skydoves/balloon/OooOo00;Landroid/view/View;)V
'@ @'
    iget-object v2, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->Oooo00O:Landroidx/appcompat/widget/AppCompatImageButton;

    .line 194
    .line 195
    invoke-static {v1, v4, v2}, Lcom/skydoves/balloon/OooOo00;->OooOO0O(Lcom/skydoves/balloon/OooOo00;Lcom/skydoves/balloon/OooOo00;Landroid/view/View;)V
'@
Replace-Stage5ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    iget-object v2, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO:Landroidx/appcompat/widget/AppCompatImageButton;

    .line 203
    .line 204
    invoke-static {v4, v5, v2}, Lcom/skydoves/balloon/OooOo00;->OooOO0O(Lcom/skydoves/balloon/OooOo00;Lcom/skydoves/balloon/OooOo00;Landroid/view/View;)V
'@ @'
    iget-object v2, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oo:Landroidx/appcompat/widget/AppCompatImageButton;

    .line 203
    .line 204
    invoke-static {v4, v5, v2}, Lcom/skydoves/balloon/OooOo00;->OooOO0O(Lcom/skydoves/balloon/OooOo00;Lcom/skydoves/balloon/OooOo00;Landroid/view/View;)V
'@

Write-Output "Applied v0.7 Stage 5 first-run tooltip and anchor patch to $project"
