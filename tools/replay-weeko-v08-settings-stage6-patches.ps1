param(
    [Parameter(Mandatory = $true)] [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
$stage5 = Join-Path $root "tools\replay-weeko-v08-settings-stage5-patches.ps1"
& $pwsh -NoProfile -File $stage5 -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "Stage 5 replay failed; Stage 6 was not applied." }

function Replace-Stage6ExactText {
    param([string]$RelativePath, [string]$Old, [string]$New)
    $path = Join-Path $project $RelativePath
    $original = [IO.File]::ReadAllText($path)
    $lineEnding = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $content = $original.Replace("`r", "")
    $oldLf = $Old.Replace("`r", "").TrimEnd("`n")
    $newLf = $New.Replace("`r", "").TrimEnd("`n")
    if ([regex]::Matches($content, [regex]::Escape($oldLf)).Count -ne 1) { throw "Expected one Stage 6 match in $RelativePath" }
    $content = $content.Replace($oldLf, $newLf)
    if ($lineEnding -eq "`r`n") { $content = $content.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

# A deterministic two-column layout keeps the management screen useful on the
# narrow device as well as on larger windows.
Replace-Stage6ExactText "res\layout\item_table_list.xml" 'android:layout_marginLeft="24.0dip" android:layout_marginTop="24.0dip" android:layout_marginRight="24.0dip" android:layout_marginBottom="12.0dip"' 'android:layout_marginLeft="8.0dip" android:layout_marginTop="8.0dip" android:layout_marginRight="8.0dip" android:layout_marginBottom="8.0dip"'
Replace-Stage6ExactText "res\layout\item_table_list.xml" 'android:padding="16.0dip"' 'android:padding="12.0dip"'
Replace-Stage6ExactText "res\layout\item_table_list.xml" 'android:layout_height="96.0dip"' 'android:layout_height="72.0dip"'

$manageLambda = "smali/com/suda/yzune/wakeupschedule/schedule_manage/ScheduleManageFragment`$onCreateView`$1.smali"
$managePath = Join-Path $project $manageLambda
$manageText = [IO.File]::ReadAllText($managePath).Replace("`r", "")
$managePattern = '(?ms)    invoke-virtual \{v3\}, Landroidx/fragment/app/oo0o0Oo;->OooOO0\(\)Landroid/content/Context;.*?    :goto_1\r?\n'
$manageReplacement = @'
    new-instance v4, Landroidx/recyclerview/widget/GridLayoutManager;
    const/4 v6, 0x2
    invoke-direct {v4, v6}, Landroidx/recyclerview/widget/GridLayoutManager;-><init>(I)V
    invoke-virtual {v0, v4}, Landroidx/recyclerview/widget/RecyclerView;->setLayoutManager(Landroidx/recyclerview/widget/o000O00;)V
    :goto_1
'@
if ([regex]::Matches($manageText, $managePattern).Count -ne 1) { throw "Expected one schedule-management manager block." }
$manageText = [regex]::Replace($manageText, $managePattern, $manageReplacement.TrimEnd("`r", "`n"))
[IO.File]::WriteAllText($managePath, $manageText, [Text.UTF8Encoding]::new($false))
# The selected table is the user's active table. Persist it and close the
# manager so ScheduleActivity's existing result callback refreshes immediately.
$selectHandler = "smali/androidx/fragment/app/OooO0o.smali"
Replace-Stage6ExactText $selectHandler @'
    iget-object p2, p0, Landroidx/fragment/app/OooO0o;->OooO:Ljava/lang/Object;

    .line 70
    .line 71
    check-cast p2, Landroid/view/View;
'@ @'
    iget-object v0, p0, Landroidx/fragment/app/OooO0o;->OooO0oo:Ljava/lang/Object;
    check-cast v0, Lcom/suda/yzune/wakeupschedule/schedule_manage/ScheduleManageFragment;
    invoke-virtual {v0}, Landroidx/fragment/app/oo0o0Oo;->OooO0oo()Landroidx/fragment/app/FragmentActivity;
    move-result-object v0
    const/4 p3, -0x1
    invoke-virtual {v0, p3}, Landroid/app/Activity;->setResult(I)V
    invoke-virtual {v0}, Landroid/app/Activity;->finish()V
    const-string p3, "config"
    invoke-static {v0, p3}, Lcom/suda/yzune/wakeupschedule/utils/OooO0o;->OooO(Landroid/content/Context;Ljava/lang/String;)Landroid/content/SharedPreferences;
    move-result-object p1
    invoke-interface {p1}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;
    move-result-object p1
    const-string v0, "show_table_id"
    invoke-interface {p1, v0, p2}, Landroid/content/SharedPreferences$Editor;->putInt(Ljava/lang/String;I)Landroid/content/SharedPreferences$Editor;
    move-result-object p1
    invoke-interface {p1}, Landroid/content/SharedPreferences$Editor;->apply()V
    return-void
'@

# Recompute the current week from the active table every time the rail's
# current action is used; the previous snapshot could become stale overnight.
$rail = "smali/com/suda/yzune/wakeupschedule/schedule/FluentWeekRail.smali"
$railText = [IO.File]::ReadAllText((Join-Path $project $rail)).Replace("`r", "")
$returnPattern = '(?s)\.method public static returnToCurrent\(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;\)V.*?\.end method'
$returnMethod = @'
.method public static returnToCurrent(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    .locals 6
    sget-object v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o:Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    invoke-virtual {p0}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;
    move-result-object v1
    invoke-virtual {v1}, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o()Lcom/suda/yzune/wakeupschedule/bean/TableConfig;
    move-result-object v2
    invoke-virtual {v2}, Lcom/suda/yzune/wakeupschedule/bean/TableConfig;->getStartDate()Ljava/lang/String;
    move-result-object v3
    const/16 v4, 0x1e
    const/4 v5, 0x0
    invoke-static {v3, v4, v5}, Lcom/suda/yzune/wakeupschedule/utils/OooO0OO;->OooO0o0(Ljava/lang/String;IZ)I
    move-result v4
    invoke-virtual {v2}, Lcom/suda/yzune/wakeupschedule/bean/TableConfig;->getMaxWeek()I
    move-result v5
    if-lez v4, :week_one
    if-le v4, v5, :week_store
    move v4, v5
    goto :week_store
    :week_one
    const/4 v4, 0x1
    :week_store
    iput v4, v1, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I
    new-instance v1, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    const/16 v2, 0x9
    invoke-direct {v1, p0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
    const/4 v2, 0x0
    invoke-virtual {v1, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;->onMenuItemClick(Landroid/view/MenuItem;)Z
    return-void
.end method
'@
if ([regex]::Matches($railText, $returnPattern).Count -ne 1) { throw "Expected one current-week method." }
$railText = [regex]::Replace($railText, $returnPattern, $returnMethod.TrimEnd("`r", "`n"))
[IO.File]::WriteAllText((Join-Path $project $rail), $railText, [Text.UTF8Encoding]::new($false))

# Apply a 60% themed-surface SRC_OVER scrim to the schedule artwork in both
# light and dark themes, preserving the supplied image itself.
$palettePath = Join-Path $project "smali\com\suda\yzune\wakeupschedule\schedule\FluentSchedulePalette.smali"
$paletteText = [IO.File]::ReadAllText($palettePath).Replace("`r", "")
$paletteText = $paletteText.Replace(".method public static install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V`n    .locals 6", ".method public static install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V`n    .locals 7")
$oldFilter = @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0Oo:Landroidx/appcompat/widget/AppCompatImageView;
    invoke-static {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->isDark(Landroid/content/Context;)Z
    move-result v4
    if-eqz v4, :palette_clear_image_filter
    const/high16 v5, 0x66000000
    invoke-virtual {v3, v5}, Landroid/widget/ImageView;->setColorFilter(I)V
    goto :palette_install_done
    :palette_clear_image_filter
    invoke-virtual {v3}, Landroid/widget/ImageView;->clearColorFilter()V
    :palette_install_done
'@
$newFilter = @'
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0Oo:Landroidx/appcompat/widget/AppCompatImageView;
    invoke-static {v1}, Landroid/graphics/Color;->red(I)I
    move-result v5
    invoke-static {v1}, Landroid/graphics/Color;->green(I)I
    move-result v6
    invoke-static {v1}, Landroid/graphics/Color;->blue(I)I
    move-result v1
    const/16 v0, 0x99
    invoke-static {v0, v5, v6, v1}, Landroid/graphics/Color;->argb(IIII)I
    move-result v0
    sget-object v1, Landroid/graphics/PorterDuff$Mode;->SRC_OVER:Landroid/graphics/PorterDuff$Mode;
    invoke-static {v0, v1}, Landroidx/appcompat/widget/o0ooOOo;->OooO0OO(ILandroid/graphics/PorterDuff$Mode;)Landroid/graphics/PorterDuffColorFilter;
    move-result-object v0
    invoke-virtual {v3, v0}, Landroid/widget/ImageView;->setColorFilter(Landroid/graphics/ColorFilter;)V
'@
if ([regex]::Matches($paletteText, [regex]::Escape($oldFilter.Replace("`r", "").TrimEnd("`n"))).Count -ne 1) { throw "Expected one schedule artwork filter." }
$paletteText = $paletteText.Replace($oldFilter.Replace("`r", "").TrimEnd("`n"), $newFilter.Replace("`r", "").TrimEnd("`n"))
[IO.File]::WriteAllText($palettePath, $paletteText, [Text.UTF8Encoding]::new($false))

# Derive a safe-zone launcher from the approved source: 74% centered artwork
# on transparency, used for legacy, adaptive foreground and splash assets.
Add-Type -AssemblyName System.Drawing
$sourcePath = Join-Path $root "assets\weeko-launcher.png"
$source = [Drawing.Bitmap]::FromFile($sourcePath)
try {
    function New-PaddedBitmap([Drawing.Bitmap]$bitmap) {
        $null = $canvas = [Drawing.Bitmap]::new($bitmap.Width, $bitmap.Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $null = $g = [Drawing.Graphics]::FromImage($canvas)
        try {
            $null = $g.Clear([Drawing.Color]::Transparent)
            $null = $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $null = $inner = [int]($bitmap.Width * 0.74)
            $null = $offset = [int](($bitmap.Width - $inner) / 2)
            $null = $g.DrawImage($bitmap, $offset, $offset, $inner, $inner)
        } finally { $g.Dispose() }
        return $canvas
    }
    $padded = New-PaddedBitmap $source
    try {
        $drawable = Join-Path $project "res\drawable-nodpi"
        $padded.Save((Join-Path $drawable "weeko_launcher_art.png"), [Drawing.Imaging.ImageFormat]::Png)
        $sizes = [ordered]@{mdpi=48;hdpi=72;xhdpi=96;xxhdpi=144;xxxhdpi=192}
        foreach ($entry in $sizes.GetEnumerator()) {
            $small = [Drawing.Bitmap]::new($entry.Value,$entry.Value,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $g = [Drawing.Graphics]::FromImage($small)
            try { $g.Clear([Drawing.Color]::Transparent); $g.DrawImage($padded,0,0,$entry.Value,$entry.Value) } finally { $g.Dispose() }
            $small.Save((Join-Path $project ("res\mipmap-{0}\ic_launcher.png" -f $entry.Key)), [Drawing.Imaging.ImageFormat]::Png)
            $small.Dispose()
        }
        foreach ($name in @("weeko_launcher_foreground_art.png","weeko_launcher_monochrome_art.png")) {
            $path = Join-Path $drawable $name
            $old = [Drawing.Bitmap]::FromFile($path)
            $tmp = "$path.stage6.png"
            try { $safe = New-PaddedBitmap $old; try { $safe.Save($tmp,[Drawing.Imaging.ImageFormat]::Png) } finally { $safe.Dispose() } } finally { $old.Dispose() }
            Move-Item -LiteralPath $tmp -Destination $path -Force
        }
    } finally { $padded.Dispose() }
} finally { $source.Dispose() }

Replace-Stage6ExactText "apktool.yml" @'
  versionCode: 9
  versionName: 0.8.0-settings-stage5
'@ @'
  versionCode: 10
  versionName: 0.8.0-settings-stage6
'@
Write-Output "Applied Weeko v0.8 Stage 6 settings fixes to $project"
