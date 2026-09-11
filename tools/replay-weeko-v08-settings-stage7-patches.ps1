param(
    [Parameter(Mandatory = $true)] [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
$stage6 = Join-Path $root "tools\replay-weeko-v08-settings-stage6-patches.ps1"
& $pwsh -NoProfile -File $stage6 -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "Stage 6 replay failed; Stage 7 was not applied." }

function Replace-Stage7ExactText {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Old,
        [Parameter(Mandatory = $true)] [string] $New
    )
    $path = Join-Path $project $RelativePath
    $original = [IO.File]::ReadAllText($path)
    $lineEnding = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $content = $original.Replace("`r", "")
    $oldLf = $Old.Replace("`r", "").TrimEnd("`n")
    $newLf = $New.Replace("`r", "").TrimEnd("`n")
    if ([regex]::Matches($content, [regex]::Escape($oldLf)).Count -ne 1) {
        throw "Expected one Stage 7 match in $RelativePath"
    }
    $content = $content.Replace($oldLf, $newLf)
    if ($lineEnding -eq "`r`n") { $content = $content.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

# ViewPager2 dispatches page selections through its internal callback list.
# Keep the rail's selected week in sync with a manual left/right swipe.
$callback = @'
.class public final Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekPageCallback;
.super Landroidx/viewpager2/widget/OooOOOO;
.source "FluentWeekPageCallback.kt"

.field private final OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;

.method public constructor <init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    .locals 0
    invoke-direct {p0}, Landroidx/viewpager2/widget/OooOOOO;-><init>()V
    iput-object p1, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekPageCallback;->OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;
    return-void
.end method

.method public OooO0OO(I)V
    .locals 1
    add-int/lit8 p1, p1, 0x1
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekPageCallback;->OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;
    invoke-static {v0, p1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->updateFromPage(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
    return-void
.end method
'@
[IO.File]::WriteAllText(
    (Join-Path $project "smali\com\suda\yzune\wakeupschedule\schedule\FluentWeekPageCallback.smali"),
    $callback,
    [Text.UTF8Encoding]::new($false)
)

$rail = "smali\com\suda\yzune\wakeupschedule\schedule\FluentWeekRail.smali"
Replace-Stage7ExactText $rail @'
.method public static install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    .locals 1
    new-instance v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    invoke-direct {v0, p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    sput-object v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o:Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    return-void
.end method
'@ @'
.method public static install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    .locals 3
    new-instance v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    invoke-direct {v0, p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    sput-object v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o:Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    iget-object v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;
    iget-object v1, v1, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0OO:Landroidx/viewpager2/widget/ViewPager2;
    iget-object v1, v1, Landroidx/viewpager2/widget/ViewPager2;->OooOOoo:Landroidx/viewpager2/widget/OooO0O0;
    iget-object v1, v1, Landroidx/viewpager2/widget/OooO0O0;->OooO0O0:Ljava/lang/Object;
    check-cast v1, Ljava/util/ArrayList;
    new-instance v2, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekPageCallback;
    invoke-direct {v2, p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekPageCallback;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    invoke-virtual {v1, v2}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    return-void
.end method
'@

Replace-Stage7ExactText $rail @'
.method public static returnToCurrent(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
'@ @'
.method public static updateFromPage(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
    .locals 2
    invoke-virtual {p0}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;
    move-result-object v0
    iput p1, v0, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I
    sget-object v1, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o:Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    if-eqz v1, :week_page_sync_done
    invoke-direct {v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0oo()V
    :week_page_sync_done
    return-void
.end method

.method public static returnToCurrent(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
'@

# Use Surface Dim for the schedule's dark header/artwork region. The body
# remains on the themed Surface so the top bar reads as a deliberate layer.
$palette = "smali\com\suda\yzune\wakeupschedule\schedule\FluentSchedulePalette.smali"
Replace-Stage7ExactText $palette @'
    const v1, 0x7f040134
    invoke-static {p0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v1
    iget-object v2, p0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;
'@ @'
    const v1, 0x7f040134
    invoke-static {p0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v1
    invoke-static {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->isDark(Landroid/content/Context;)Z
    move-result v4
    if-eqz v4, :palette_top_surface_ready
    const v4, 0x7f040136
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v1
    :palette_top_surface_ready
    iget-object v2, p0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;
'@

# Keep the dark artwork scrim opaque enough that the top command region stays
# a quiet layer behind the high-contrast schedule labels.
Replace-Stage7ExactText $palette @'
    const/16 v0, 0x99
    invoke-static {v0, v5, v6, v1}, Landroid/graphics/Color;->argb(IIII)I
'@ @'
    const/16 v0, 0x99
    invoke-static {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->isDark(Landroid/content/Context;)Z
    move-result v4
    if-eqz v4, :palette_scrim_ready
    const/16 v0, 0xcc
    :palette_scrim_ready
    invoke-static {v0, v5, v6, v1}, Landroid/graphics/Color;->argb(IIII)I
'@

# The current-month and today labels are the bold date titles selected by
# styleTree. Use a fixed, high-purity blue instead of the device's dynamic
# green primary so the two anchors remain obvious in either theme.
Replace-Stage7ExactText $palette @'
    const v4, 0x7f040122
    invoke-static {v0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v4
    iget-object v5, p0, Lcom/suda/yzune/wakeupschedule/schedule/o000OO;->OooOOo0:Landroidx/constraintlayout/widget/ConstraintLayout;
'@ @'
    const v4, 0x7f040122
    invoke-static {v0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v4
    const v4, 0xff2f80ff
    iget-object v5, p0, Lcom/suda/yzune/wakeupschedule/schedule/o000OO;->OooOOo0:Landroidx/constraintlayout/widget/ConstraintLayout;
'@

Replace-Stage7ExactText "apktool.yml" @'
  versionCode: 10
  versionName: 0.8.0-settings-stage6
'@ @'
  versionCode: 11
  versionName: 0.8.0-settings-stage7
'@

Write-Output "Applied Weeko v0.8 Stage 7 About/theme, week-sync, and dark-header fixes to $project"
