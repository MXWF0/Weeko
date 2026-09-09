param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage2Script = Join-Path $PSScriptRoot "replay-weeko-v08-fluent-stage2-patches.ps1"

& $stage2Script -ProjectPath $project
if (!$?) { throw "Fluent Stage 2 patch replay failed; Fluent Stage 3 was not applied." }

function Replace-FluentStage3ExactText {
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

Replace-FluentStage3ExactText "apktool.yml" @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage2
'@ @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage3
'@

$railSource = Join-Path $PSScriptRoot "fluent-week-rail.smali"
$railTarget = Join-Path $project "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali"
if (!(Test-Path -LiteralPath $railSource)) { throw "Fluent week rail template is missing: $railSource" }
Copy-Item -LiteralPath $railSource -Destination $railTarget -Force

# The week and weekday header are the entry point for the temporary rail.
Replace-FluentStage3ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    .line 254
    .line 255
    new-instance v12, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;

    invoke-direct {v12, v0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
'@ @'
    .line 254
    .line 255
    const/16 v2, 0x11
    new-instance v12, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;

    invoke-direct {v12, v0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
'@

Replace-FluentStage3ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    :cond_6
    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOoO0()V
'@ @'
    :cond_6
    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOoO0()V

    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
'@

Replace-FluentStage3ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    const/16 v0, 0x9

    if-eq v11, v0, :fluent_current_week

    .line 34
'@ @'
    const/16 v0, 0x9

    if-eq v11, v0, :fluent_current_week

    const/16 v0, 0x11

    if-eq v11, v0, :fluent_week_rail

    .line 34
'@

Replace-FluentStage3ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    return-void

    :stage1_existing_default
'@ @'
    return-void

    :fluent_week_rail
    invoke-static {v13}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->toggle(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V

    return-void

    :stage1_existing_default
'@

Write-Output "Applied Fluent UI Stage 3 week rail patch to $project"
