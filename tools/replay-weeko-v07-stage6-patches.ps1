param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage5Script = Join-Path $PSScriptRoot "replay-weeko-v07-stage5-patches.ps1"

& $stage5Script -ProjectPath $project
if (!$?) { throw "Stage 5 patch replay failed; Stage 6 was not applied." }

function Replace-Stage6ExactText {
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

Replace-Stage6ExactText "apktool.yml" @'
  versionCode: 7
  versionName: 0.7.0-stage5
'@ @'
  versionCode: 7
  versionName: 0.7.0-stage6
'@

Replace-Stage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali" @'
    const/16 v8, 0x40
'@ @'
    const/16 v8, 0x20
'@

# Keep the navigation affordance in a left rail and move the date/week labels
# together so the icon never sits on top of their glyphs. The top action row
# uses a 32dp trailing gap instead of the old 64dp gap. All offsets remain
# density-based: 32dp for labels and 16dp for the left icon.
Replace-Stage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali" @'
    invoke-virtual {v3, v15, v5}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    iput-object v3, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0o:Landroidx/constraintlayout/widget/ConstraintLayout;
'@ @'
    invoke-virtual {v3, v15, v5}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    add-int v4, v7, v7

    int-to-float v4, v4

    iget-object v2, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o0:Landroidx/appcompat/widget/AppCompatTextView;

    invoke-virtual {v2, v4}, Landroid/view/View;->setTranslationX(F)V

    iget-object v2, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o:Landroidx/appcompat/widget/AppCompatTextView;

    invoke-virtual {v2, v4}, Landroid/view/View;->setTranslationX(F)V

    iget-object v2, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oO:Landroidx/appcompat/widget/AppCompatTextView;

    invoke-virtual {v2, v4}, Landroid/view/View;->setTranslationX(F)V

    neg-int v7, v7

    int-to-float v7, v7

    invoke-virtual {v15, v7}, Landroid/view/View;->setTranslationX(F)V

    iput-object v3, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0o:Landroidx/constraintlayout/widget/ConstraintLayout;
'@

Write-Output "Applied v0.7 Stage 6 header spacing patch to $project"
