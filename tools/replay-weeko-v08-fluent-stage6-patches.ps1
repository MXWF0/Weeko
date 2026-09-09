param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage5Script = Join-Path $PSScriptRoot "replay-weeko-v08-fluent-stage5-patches.ps1"

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $stage5Script -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "Fluent Stage 5 patch replay failed; Fluent Stage 6 was not applied." }

function Replace-FluentStage6ExactText {
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

Replace-FluentStage6ExactText "apktool.yml" @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage5
'@ @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage6
'@

# The week label keeps the existing current-week action (callback 9). The
# weekday label alone opens the temporary Fluent week rail (callback 17).
Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    .line 254
    .line 255
    const/16 v2, 0x11
    new-instance v12, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;
'@ @'
    .line 254
    .line 255
    const/16 v2, 0x9
    new-instance v12, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    if-eqz v15, :cond_1a

    .line 263
    .line 264
    iget-object v15, v15, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oO:Landroidx/appcompat/widget/AppCompatTextView;
'@ @'
    if-eqz v15, :cond_1a

    const/16 v2, 0x11
    new-instance v12, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;

    invoke-direct {v12, v0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    .line 263
    .line 264
    iget-object v15, v15, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oO:Landroidx/appcompat/widget/AppCompatTextView;
'@

# Reuse the existing four-argument command styler and translate only the
# visual command views; their 48dp layout and hit targets remain unchanged.
Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
.method public static install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
'@ @'
.method private static shiftCommand(Landroid/content/Context;Landroid/view/View;I)V
    .locals 2
    invoke-static {p0, p2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v0
    int-to-float v0, v0
    invoke-virtual {p1, v0}, Landroid/view/View;->setTranslationX(F)V
    return-void
.end method

.method public static install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->Oooo00O:Landroidx/appcompat/widget/AppCompatImageButton;
'@ @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->Oooo00O:Landroidx/appcompat/widget/AppCompatImageButton;
    const/4 v6, 0x0
    invoke-static {p0, v3, v6}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->shiftCommand(Landroid/content/Context;Landroid/view/View;I)V
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oo:Landroidx/appcompat/widget/AppCompatImageButton;
'@ @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oo:Landroidx/appcompat/widget/AppCompatImageButton;
    const/16 v6, 0x30
    invoke-static {p0, v3, v6}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->shiftCommand(Landroid/content/Context;Landroid/view/View;I)V
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO:Landroidx/appcompat/widget/AppCompatImageButton;
'@ @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO:Landroidx/appcompat/widget/AppCompatImageButton;
    const/16 v6, 0x18
    invoke-static {p0, v3, v6}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->shiftCommand(Landroid/content/Context;Landroid/view/View;I)V
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0O:Landroidx/appcompat/widget/AppCompatImageButton;
'@ @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0O:Landroidx/appcompat/widget/AppCompatImageButton;
    const/4 v6, 0x0
    invoke-static {p0, v3, v6}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->shiftCommand(Landroid/content/Context;Landroid/view/View;I)V
'@

# Resolve the supporting text color once before the command registers are reused.
Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    const v2, 0x7f040132
    invoke-static {p0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->resolveColor(Landroid/content/Context;I)I
    move-result v2
    move v5, v2
'@ @'
    const v2, 0x7f040132
    invoke-static {p0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->resolveColor(Landroid/content/Context;I)I
    move-result v2
    move v5, v2
    const v7, 0x7f04011b
    invoke-static {p0, v7}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->resolveColor(Landroid/content/Context;I)I
    move-result v7
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o0:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
'@ @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o0:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v7}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    const/high16 v4, 0x41800000
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setTextSize(F)V
    sget-object v4, Landroid/graphics/Typeface;->DEFAULT:Landroid/graphics/Typeface;
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setTypeface(Landroid/graphics/Typeface;)V
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
'@ @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    const/high16 v4, 0x41a00000
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setTextSize(F)V
    sget-object v4, Landroid/graphics/Typeface;->DEFAULT_BOLD:Landroid/graphics/Typeface;
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setTypeface(Landroid/graphics/Typeface;)V
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oO:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
'@ @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oO:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v7}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    const/high16 v4, 0x41800000
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setTextSize(F)V
    sget-object v4, Landroid/graphics/Typeface;->DEFAULT:Landroid/graphics/Typeface;
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setTypeface(Landroid/graphics/Typeface;)V
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    const/16 v4, 0x10
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
'@ @'
    const/16 v4, 0xe
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    const/4 v4, 0x4
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
'@ @'
    const/4 v4, 0x2
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
'@

# Compact the rail without reducing the 48dp drag target.
Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    const/16 v8, 0x30
    invoke-direct {p0, p1, v8}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v5
'@ @'
    const/16 v8, 0x20
    invoke-direct {p0, p1, v8}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v5
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    const/16 v4, 0x30
    invoke-direct {p0, p1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v4
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->leftMargin:I
'@ @'
    const/16 v4, 0x20
    invoke-direct {p0, p1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v4
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->leftMargin:I
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    const/16 v4, 0x18
    invoke-direct {p0, p1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v4
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->rightMargin:I
'@ @'
    const/16 v4, 0x10
    invoke-direct {p0, p1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v4
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->rightMargin:I
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    const/16 v4, 0x1c
    invoke-direct {p0, p1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v4
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->topMargin:I
'@ @'
    const/16 v4, 0x10
    invoke-direct {p0, p1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v4
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->topMargin:I
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    const/16 v6, 0x60
    invoke-direct {p0, p1, v6}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
'@ @'
    const/16 v6, 0x50
    invoke-direct {p0, p1, v6}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
'@

Replace-FluentStage6ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    const/16 v5, 0x40
    invoke-direct {p0, p1, v5}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
'@ @'
    const/16 v5, 0x30
    invoke-direct {p0, p1, v5}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
'@

Write-Output "Applied Fluent UI Stage 6 hierarchy, spacing, and compact rail patch to $project"
