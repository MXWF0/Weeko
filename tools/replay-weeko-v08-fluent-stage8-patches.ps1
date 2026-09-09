param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage7Script = Join-Path $PSScriptRoot "replay-weeko-v08-fluent-stage7-patches.ps1"

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $stage7Script -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "Fluent Stage 7 patch replay failed; Fluent Stage 8 was not applied." }

function Replace-FluentStage8ExactText {
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

Replace-FluentStage8ExactText "apktool.yml" @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage7
'@ @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage8
'@

# Fit the two-line date/week cluster above the schedule weekday row. Commands
# remain 48dp touch targets but share the same compact visual baseline.
Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
.method private static styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    .locals 3

    const/16 v2, 0x30
    invoke-static {p0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v0
    invoke-virtual {p1, v0}, Landroid/view/View;->setMinimumHeight(I)V
    const/16 v2, 0x8
    invoke-static {p0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v0
'@ @'
.method private static styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    .locals 3

    const/16 v2, 0x1c
    invoke-static {p0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v0
    invoke-virtual {p1, v0}, Landroid/view/View;->setMinimumHeight(I)V
    const/16 v2, 0x4
    invoke-static {p0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v0
'@

Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
.method private static shiftCommand(Landroid/content/Context;Landroid/view/View;I)V
    .locals 2
    invoke-static {p0, p2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v0
    int-to-float v0, v0
    invoke-virtual {p1, v0}, Landroid/view/View;->setTranslationX(F)V
    return-void
.end method
'@ @'
.method private static shiftCommand(Landroid/content/Context;Landroid/view/View;I)V
    .locals 2
    invoke-static {p0, p2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v0
    int-to-float v0, v0
    invoke-virtual {p1, v0}, Landroid/view/View;->setTranslationX(F)V
    const/16 v1, -0x14
    invoke-static {p0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v0
    int-to-float v0, v0
    invoke-virtual {p1, v0}, Landroid/view/View;->setTranslationY(F)V
    return-void
.end method
'@

Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o0:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v7}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    const/high16 v4, 0x41800000
'@ @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o0:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v7}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    const/high16 v4, 0x41600000
'@

Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    const/high16 v4, 0x41a00000
'@ @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    const/high16 v4, 0x41b00000
'@

Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oO:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v7}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    const/high16 v4, 0x41800000
'@ @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oO:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v7}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    const/high16 v4, 0x41600000
'@

Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentTopBar.smali" @'
    const/16 v4, 0xe
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
'@ @'
    const/16 v4, 0xc
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
'@

# The rail is one 48dp row over the weekday header: a fixed week label plus a
# full-height SeekBar. It no longer hides the top information cluster.
Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    const/4 v4, -0x2
    const/16 v8, 0x20
'@ @'
    const/4 v4, -0x2
    const/16 v8, 0x10
'@

Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    iput v5, v6, Landroid/view/ViewGroup$MarginLayoutParams;->leftMargin:I
    const/4 v4, 0x0
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->topMargin:I
'@ @'
    iput v5, v6, Landroid/view/ViewGroup$MarginLayoutParams;->leftMargin:I
    const/16 v4, 0x8
    invoke-direct {p0, p1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v4
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->topMargin:I
'@

Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    const/16 v4, 0x20
    invoke-direct {p0, p1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v4
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->leftMargin:I
'@ @'
    const/16 v4, 0x58
    invoke-direct {p0, p1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v4
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->leftMargin:I
'@

Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    const/16 v4, 0x10
    invoke-direct {p0, p1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v4
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->topMargin:I
    invoke-virtual {p0, v7, v6}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V
'@ @'
    const/4 v4, 0x0
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->topMargin:I
    invoke-virtual {p0, v7, v6}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V
'@

Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    const/4 v5, -0x1
    const/16 v6, 0x50
'@ @'
    const/4 v5, -0x1
    const/16 v6, 0x34
'@

Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    new-instance v7, Landroid/view/ViewGroup$MarginLayoutParams;
    invoke-direct {v7, v5, v6}, Landroid/view/ViewGroup$MarginLayoutParams;-><init>(II)V
    const/16 v5, 0x30
'@ @'
    new-instance v7, Landroid/view/ViewGroup$MarginLayoutParams;
    invoke-direct {v7, v5, v6}, Landroid/view/ViewGroup$MarginLayoutParams;-><init>(II)V
    const/16 v5, 0x6c
'@

Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
    invoke-direct {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0oo()V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0OO:Landroidx/appcompat/widget/AppCompatTextView;
    const/16 v1, 0x8
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooOO0:Landroidx/appcompat/widget/AppCompatTextView;
    const/4 v1, 0x4
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    const/4 v1, 0x0
'@ @'
    invoke-direct {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0oo()V
    const/4 v1, 0x0
'@

# Capture the real current week on the first rail opening, after the initial
# schedule page has finished selecting its week. Later openings keep it.
Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
.method private OooOO0()V
    .locals 4
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;
    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;
    move-result-object v1
    iget v1, v1, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I
    iput v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->originalWeek:I
    invoke-direct {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0oo()V
'@ @'
.method private OooOO0()V
    .locals 4
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;
    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;
    move-result-object v1
    iget v2, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->originalWeek:I
    if-nez v2, :stage8_baseline_ready
    iget v1, v1, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I
    iput v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->originalWeek:I
    :stage8_baseline_ready
    invoke-direct {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0oo()V
'@

# Closing or timing out hides the rail but keeps the selected week.
Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
.method private OooOO0O()V
    .locals 3
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;
    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;
    move-result-object v1
    iget v2, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->originalWeek:I
    iput v2, v1, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I
    new-instance v1, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    const/16 v2, 0x9
    invoke-direct {v1, v0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
    const/4 v2, 0x0
    invoke-virtual {v1, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;->onMenuItemClick(Landroid/view/MenuItem;)Z
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0OO:Landroidx/appcompat/widget/AppCompatTextView;
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooOO0:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    const/16 v1, 0x8
    invoke-virtual {p0, v1}, Landroid/view/View;->setVisibility(I)V
    invoke-virtual {p0, p0}, Landroid/view/View;->removeCallbacks(Ljava/lang/Runnable;)Z
    return-void
.end method
'@ @'
.method private OooOO0O()V
    .locals 2
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0OO:Landroidx/appcompat/widget/AppCompatTextView;
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooOO0:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    const/16 v1, 0x8
    invoke-virtual {p0, v1}, Landroid/view/View;->setVisibility(I)V
    invoke-virtual {p0, p0}, Landroid/view/View;->removeCallbacks(Ljava/lang/Runnable;)Z
    return-void
.end method
'@

Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali" @'
.method public static toggle(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
'@ @'
.method public static returnToCurrent(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    .locals 4
    sget-object v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o:Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    invoke-virtual {p0}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;
    move-result-object v2
    iget v1, v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->originalWeek:I
    if-lez v1, :stage8_capture_current
    goto :stage8_restore_current
    :stage8_capture_current
    iget v1, v2, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I
    iput v1, v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->originalWeek:I
    :stage8_restore_current
    iput v1, v2, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I
    new-instance v0, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    const/16 v1, 0x9
    invoke-direct {v0, p0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;->onMenuItemClick(Landroid/view/MenuItem;)Z
    return-void
.end method

.method public static toggle(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
'@

Replace-FluentStage8ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    :fluent_current_week
    new-instance v0, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;

    const/16 v2, 0x9

    invoke-direct {v0, v13, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    const/4 v1, 0x0

    invoke-virtual {v0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;->onMenuItemClick(Landroid/view/MenuItem;)Z

    return-void
'@ @'
    :fluent_current_week
    invoke-static {v13}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->returnToCurrent(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    return-void
'@

Write-Output "Applied Fluent UI Stage 8 compact top bar and weekday-only week rail patch to $project"
