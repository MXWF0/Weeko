param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage8Script = Join-Path $PSScriptRoot "replay-weeko-v08-fluent-stage8-patches.ps1"

$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
& $pwsh -NoProfile -File $stage8Script -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "Fluent Stage 8 patch replay failed; Fluent Stage 9 was not applied." }

function Replace-FluentStage9ExactText {
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

Replace-FluentStage9ExactText "apktool.yml" @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage8
'@ @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage9
'@

# Restore the original information hierarchy while retaining Fluent colors:
# 20sp strong date, then 14sp week and weekday on one compact secondary row.
Replace-FluentStage9ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    const/16 v2, 0x1c
    invoke-static {p0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
'@ @'
    const/16 v2, 0x14
    invoke-static {p0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
'@

Replace-FluentStage9ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    const/16 v1, -0x14
    invoke-static {p0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
'@ @'
    const/16 v1, -0x4
    invoke-static {p0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
'@

Replace-FluentStage9ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o0:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v7}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    const/high16 v4, 0x41600000
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setTextSize(F)V
    sget-object v4, Landroid/graphics/Typeface;->DEFAULT:Landroid/graphics/Typeface;
'@ @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o0:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    const/high16 v4, 0x41a00000
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setTextSize(F)V
    sget-object v4, Landroid/graphics/Typeface;->DEFAULT_BOLD:Landroid/graphics/Typeface;
'@

Replace-FluentStage9ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    const/high16 v4, 0x41b00000
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setTextSize(F)V
    sget-object v4, Landroid/graphics/Typeface;->DEFAULT_BOLD:Landroid/graphics/Typeface;
'@ @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v7}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    const/high16 v4, 0x41600000
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setTextSize(F)V
    sget-object v4, Landroid/graphics/Typeface;->DEFAULT:Landroid/graphics/Typeface;
'@

# The 48dp navigation target ends at x=64dp. The text view begins there and
# its existing 4dp inner padding creates the visible gap, matching the compact
# rhythm of the original header.
Replace-FluentStage9ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali" @'
    add-int v4, v7, v7
    add-int v4, v4, v4

    int-to-float v4, v4
'@ @'
    add-int v4, v7, v7
    add-int v4, v4, v7

    int-to-float v4, v4
'@

# Keep the week rail aligned with the compressed weekday header.
Replace-FluentStage9ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    const/16 v5, 0x6c
    invoke-direct {p0, p1, v5}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
'@ @'
    const/16 v5, 0x64
    invoke-direct {p0, p1, v5}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
'@

Write-Output "Applied Fluent UI Stage 9 original-scale compact header patch to $project"
