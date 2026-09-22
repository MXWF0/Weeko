param(
    [Parameter(Mandatory = $true)] [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
& $pwsh -NoProfile -File (Join-Path $root "tools\replay-weeko-v111-patches.ps1") -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "v1.1.1 patch replay failed; v1.1.2 week rail patches were not applied." }

function Replace-V112ExactText {
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
        throw "Expected one v1.1.2 match in $RelativePath"
    }
    $content = $content.Replace($oldLf, $newLf)
    if ($lineEnding -eq "`r`n") { $content = $content.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

Replace-V112ExactText "apktool.yml" "  versionCode: 15`n  versionName: 1.1.1" "  versionCode: 16`n  versionName: 1.1.2"

$railSource = Join-Path $root "tools\fluent-week-rail-v112.smali"
$railTarget = Join-Path $project "smali\com\suda\yzune\wakeupschedule\schedule\FluentWeekRail.smali"
if (!(Test-Path -LiteralPath $railSource)) { throw "v1.1.2 week rail template is missing: $railSource" }
Copy-Item -LiteralPath $railSource -Destination $railTarget -Force

# The legacy top-bar skin paints the rail with a translucent theme color.
# v1.1.2 owns the rail surface in WeekRailController, so keep the legacy
# thumb/track tinting but leave the controller's translucent light/dark
# surface intact.
Replace-V112ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    new-instance v3, Landroid/graphics/drawable/GradientDrawable;
    invoke-direct {v3}, Landroid/graphics/drawable/GradientDrawable;-><init>()V
    invoke-virtual {v3, p4}, Landroid/graphics/drawable/GradientDrawable;->setColor(I)V
    const/16 v5, 0xe6
    invoke-virtual {v3, v5}, Landroid/graphics/drawable/Drawable;->setAlpha(I)V
    const/16 v4, 0x10
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v4
    int-to-float v4, v4
    invoke-virtual {v3, v4}, Landroid/graphics/drawable/GradientDrawable;->setCornerRadius(F)V
    invoke-virtual {p1, v3}, Landroid/view/View;->setBackground(Landroid/graphics/drawable/Drawable;)V
    const/4 v4, 0x4
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v4
    int-to-float v4, v4
    invoke-virtual {p1, v4}, Landroid/view/View;->setElevation(F)V
'@ @'
# WeekRailController owns the translucent light/dark surface in v1.1.2.
'@

Write-Output "Applied Weeko v1.1.2 lightweight schedule week rail to $project"
