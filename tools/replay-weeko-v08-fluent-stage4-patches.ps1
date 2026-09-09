param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage3Script = Join-Path $PSScriptRoot "replay-weeko-v08-fluent-stage3-patches.ps1"

& $stage3Script -ProjectPath $project
if (!$?) { throw "Fluent Stage 3 patch replay failed; Fluent Stage 4 was not applied." }

function Replace-FluentStage4ExactText {
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

Replace-FluentStage4ExactText "apktool.yml" @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage3
'@ @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage4
'@

$topBarSource = Join-Path $PSScriptRoot "fluent-top-bar.smali"
$topBarTarget = Join-Path $project "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali"
if (!(Test-Path -LiteralPath $topBarSource)) { throw "Fluent top bar template is missing: $topBarSource" }
Copy-Item -LiteralPath $topBarSource -Destination $topBarTarget -Force

# Stage 3 owns the temporary rail. Stage 4 adds the shared themed treatment
# after both the existing header and the rail have been constructed.
Replace-FluentStage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
'@ @'
    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
'@

# When the rail is open it is the single week-status surface. Hide the date
# anchor during that short interaction so the 48 dp date hit target cannot
# visually collide with the rail card; the date is restored with the header.
Replace-FluentStage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
.field private final OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;
'@ @'
.field private final OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;

.field private final OooOO0:Landroidx/appcompat/widget/AppCompatTextView;
'@

Replace-FluentStage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    iget-object v0, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oO:Landroidx/appcompat/widget/AppCompatTextView;

    iput-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;

'@ @'
    iget-object v0, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oO:Landroidx/appcompat/widget/AppCompatTextView;

    iput-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;

    iget-object v0, p1, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;

    iget-object v0, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o0:Landroidx/appcompat/widget/AppCompatTextView;

    iput-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooOO0:Landroidx/appcompat/widget/AppCompatTextView;
'@

Replace-FluentStage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0OO:Landroidx/appcompat/widget/AppCompatTextView;
    const/16 v1, 0x8
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    const/4 v1, 0x0
    invoke-virtual {p0, v1}, Landroid/view/View;->setVisibility(I)V
'@ @'
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0OO:Landroidx/appcompat/widget/AppCompatTextView;
    const/16 v1, 0x8
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooOO0:Landroidx/appcompat/widget/AppCompatTextView;
    const/4 v1, 0x4
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    const/4 v1, 0x0
    invoke-virtual {p0, v1}, Landroid/view/View;->setVisibility(I)V
'@

Replace-FluentStage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0OO:Landroidx/appcompat/widget/AppCompatTextView;
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    const/16 v1, 0x8
    invoke-virtual {p0, v1}, Landroid/view/View;->setVisibility(I)V
'@ @'
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0OO:Landroidx/appcompat/widget/AppCompatTextView;
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooOO0:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    const/16 v1, 0x8
    invoke-virtual {p0, v1}, Landroid/view/View;->setVisibility(I)V
'@

Write-Output "Applied Fluent UI Stage 4 top-bar styling patch to $project"
