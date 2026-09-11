param(
    [Parameter(Mandatory = $true)] [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
$basePatch = Join-Path $root "tools\replay-weeko-v10-patches.ps1"
& $pwsh -NoProfile -File $basePatch -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "v1.0.0 patch replay failed; v1.0.1 fixes were not applied." }

function Replace-V101ExactText {
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
        throw "Expected one v1.0.1 match in $RelativePath"
    }
    $content = $content.Replace($oldLf, $newLf)
    if ($lineEnding -eq "`r`n") { $content = $content.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

$metadataOld = "  versionCode: 12`n  versionName: 1.0.0"
$metadataNew = "  versionCode: 13`n  versionName: 1.0.1"
Replace-V101ExactText "apktool.yml" $metadataOld $metadataNew

# Stage 2 removed the standalone share button but left the tutorial relay in
# place. Route the import balloon directly to the existing more-actions balloon.
Replace-V101ExactText `
    "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" `
    '    invoke-static {v6, v0, v2}, Lcom/skydoves/balloon/OooOo00;->OooOO0O(Lcom/skydoves/balloon/OooOo00;Lcom/skydoves/balloon/OooOo00;Landroid/view/View;)V' `
    '    invoke-static {v5, v0, v2}, Lcom/skydoves/balloon/OooOo00;->OooOO0O(Lcom/skydoves/balloon/OooOo00;Lcom/skydoves/balloon/OooOo00;Landroid/view/View;)V'

# The completion callback must be durable before a process is reclaimed from
# recents; apply() only schedules the disk write.
$introOld = (@(
    '    const-string v1, "has_intro"',
    '',
    '    .line 285',
    '    .line 286',
    '    invoke-interface {v0, v1, v4}, Landroid/content/SharedPreferences$Editor;->putBoolean(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;',
    '',
    '    .line 287',
    '    .line 288',
    '    .line 289',
    '    invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->apply()V'
) -join "`n")
$introNew = $introOld.Replace('invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->apply()V', 'invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->commit()Z')
Replace-V101ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o000oOoO.smali" $introOld $introNew

$intro2Old = (@(
    '    const-string v0, "has_intro"',
    '',
    '    .line 77',
    '    .line 78',
    '    const/4 v1, 0x1',
    '',
    '    .line 79',
    '    invoke-interface {p2, v0, v1}, Landroid/content/SharedPreferences$Editor;->putBoolean(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;',
    '',
    '    .line 80',
    '    .line 81',
    '    .line 82',
    '    invoke-interface {p2}, Landroid/content/SharedPreferences$Editor;->apply()V'
) -join "`n")
$intro2New = $intro2Old.Replace('invoke-interface {p2}, Landroid/content/SharedPreferences$Editor;->apply()V', 'invoke-interface {p2}, Landroid/content/SharedPreferences$Editor;->commit()Z')
Replace-V101ExactText "smali/com/suda/yzune/wakeupschedule/schedule/Oooo0.smali" $intro2Old $intro2New

Write-Output "Applied Weeko v1.0.1 onboarding persistence and tutorial relay fixes to $project"
