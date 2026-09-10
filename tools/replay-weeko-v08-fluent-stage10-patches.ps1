param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage9Script = Join-Path $PSScriptRoot "replay-weeko-v08-fluent-stage9-patches.ps1"

$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
& $pwsh -NoProfile -File $stage9Script -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "Fluent Stage 9 patch replay failed; Fluent Stage 10 was not applied." }

function Replace-FluentStage10ExactText {
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

Replace-FluentStage10ExactText "apktool.yml" @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage9
'@ @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage10
'@

# Move the navigation target and date block left while keeping a 4dp visual gap.
Replace-FluentStage10ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali" @'
    add-int v4, v7, v7
    add-int v4, v4, v7

    int-to-float v4, v4
'@ @'
    add-int v4, v7, v7

    int-to-float v4, v4
'@

Replace-FluentStage10ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->Oooo00O:Landroidx/appcompat/widget/AppCompatImageButton;
    const/4 v6, 0x0
    invoke-static {p0, v3, v6}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->shiftCommand(Landroid/content/Context;Landroid/view/View;I)V
'@ @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->Oooo00O:Landroidx/appcompat/widget/AppCompatImageButton;
    const/16 v6, -0x10
    invoke-static {p0, v3, v6}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->shiftCommand(Landroid/content/Context;Landroid/view/View;I)V
'@

# Keep the right edge fixed and tighten the three command targets from 8dp to 6dp gaps.
Replace-FluentStage10ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    const/16 v6, 0x30
    invoke-static {p0, v3, v6}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->shiftCommand(Landroid/content/Context;Landroid/view/View;I)V
'@ @'
    const/16 v6, 0x34
    invoke-static {p0, v3, v6}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->shiftCommand(Landroid/content/Context;Landroid/view/View;I)V
'@

Replace-FluentStage10ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    const/16 v6, 0x18
    invoke-static {p0, v3, v6}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->shiftCommand(Landroid/content/Context;Landroid/view/View;I)V
'@ @'
    const/16 v6, 0x1a
    invoke-static {p0, v3, v6}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->shiftCommand(Landroid/content/Context;Landroid/view/View;I)V
'@

# Make the rail read as a small Fluent surface: opaque enough for the dates,
# softer corner rhythm, and a secondary-colored inactive track.
Replace-FluentStage10ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    invoke-virtual {v1, v2}, Landroid/widget/AbsSeekBar;->setThumbTintList(Landroid/content/res/ColorStateList;)V
    invoke-virtual {p1, v2}, Landroid/view/View;->setForegroundTintList(Landroid/content/res/ColorStateList;)V
'@ @'
    invoke-virtual {v1, v2}, Landroid/widget/AbsSeekBar;->setThumbTintList(Landroid/content/res/ColorStateList;)V
    invoke-virtual {v1, v2}, Landroid/widget/ProgressBar;->setProgressBackgroundTintList(Landroid/content/res/ColorStateList;)V
    invoke-virtual {p1, v2}, Landroid/view/View;->setForegroundTintList(Landroid/content/res/ColorStateList;)V
'@

Replace-FluentStage10ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    const/16 v4, 0xc
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
'@ @'
    const/16 v4, 0x10
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
'@

Replace-FluentStage10ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    const/4 v4, 0x2
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
'@ @'
    const/4 v4, 0x4
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
'@

# Pass the secondary color to the rail label and inactive track.
Replace-FluentStage10ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    invoke-static {p0, v4, v0, v1, v5}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleRail(Landroid/content/Context;Landroid/view/View;III)V
'@ @'
    invoke-static {p0, v4, v7, v1, v5}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleRail(Landroid/content/Context;Landroid/view/View;III)V
'@

Write-Output "Applied Fluent UI Stage 10 left alignment, right command tightening, and rail polish patch to $project"
