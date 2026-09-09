param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage1Script = Join-Path $PSScriptRoot "replay-weeko-v07-stage1-patches.ps1"

& $stage1Script -ProjectPath $project
if (!$?) { throw "Stage 1 patch replay failed; Stage 2 was not applied." }

function Replace-Stage2ExactText {
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

Replace-Stage2ExactText "apktool.yml" @'
  versionCode: 7
  versionName: 0.7.0-stage1
'@ @'
  versionCode: 7
  versionName: 0.7.0-stage2
'@

# Remove the old standalone share button from the dynamic top-row layout. The
# view object stays available as the original share callback's implementation
# anchor; the new menu invokes that callback from the visible overflow button.
Replace-Stage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali" @'
    .line 581
    invoke-virtual {v5, v7}, Landroid/view/ViewGroup$MarginLayoutParams;->setMarginEnd(I)V

    .line 582
    .line 583
    .line 584
    iget-object v15, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0:Landroidx/appcompat/widget/AppCompatImageButton;

    invoke-virtual {v3, v15, v5}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V
'@ @'
    .line 581
    invoke-virtual {v5, v7}, Landroid/view/ViewGroup$MarginLayoutParams;->setMarginEnd(I)V

    .line 582
    .line 583
    .line 584
'@

# Re-anchor the import button to the visible overflow button after the
# standalone share button is removed. The add button already anchors to
# import, so this preserves the complete add -> import -> more chain.
Replace-Stage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali" @'
    .line 502
    .line 503
    .line 504
    const v7, 0x7f090067

    .line 505
    .line 506
    .line 507
    iput v7, v5, Landroidx/constraintlayout/widget/ConstraintLayout$LayoutParams;->OooOo0:I
'@ @'
    .line 502
    .line 503
    .line 504
    const v7, 0x7f090065

    .line 505
    .line 506
    .line 507
    iput v7, v5, Landroidx/constraintlayout/widget/ConstraintLayout$LayoutParams;->OooOo0:I
'@

# Remove the direct click listener that exposed the share callback as a
# standalone top-level icon. Keep the existing fail-fast UI binding check and
# the following listener chain intact.
Replace-Stage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    .line 210
    .line 211
    if-eqz v12, :cond_1e

    .line 212
    .line 213
    iget-object v12, v12, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0:Landroidx/appcompat/widget/AppCompatImageButton;

    .line 214
    .line 215
    new-instance v15, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;

    .line 216
    .line 217
    invoke-direct {v15, v0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    .line 218
    .line 219
    .line 220
    invoke-virtual {v12, v15}, Landroid/view/View;->setOnClickListener(Landroid/view/View$OnClickListener;)V
'@ @'
    .line 210
    .line 211
    if-eqz v12, :cond_1e
'@

# The first-run guide no longer points at a removed share icon. Leave its
# remaining anchors and completion flow unchanged.
Replace-Stage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    .line 205
    .line 206
    .line 207
    iget-object v2, p0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;

    .line 208
    .line 209
    if-eqz v2, :cond_3

    .line 210
    .line 211
    iget-object v2, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0:Landroidx/appcompat/widget/AppCompatImageButton;

    .line 212
    .line 213
    invoke-static {v5, v6, v2}, Lcom/skydoves/balloon/OooOo00;->OooOO0O(Lcom/skydoves/balloon/OooOo00;Lcom/skydoves/balloon/OooOo00;Landroid/view/View;)V
'@ @'
    .line 205
    .line 206
    .line 207
    iget-object v2, p0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;
'@

# Invoke the original share flow from the visible overflow button so its
# cascade popup is positioned on the button that opened the right menu.
Replace-Stage2ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o0OOO0o.smali" @'
    iget-object v0, v6, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;

    iget-object v0, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0:Landroidx/appcompat/widget/AppCompatImageButton;
'@ @'
    iget-object v0, v6, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;

    iget-object v0, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0O:Landroidx/appcompat/widget/AppCompatImageButton;
'@

Write-Output "Applied v0.7 Stage 2 share migration patch to $project"
