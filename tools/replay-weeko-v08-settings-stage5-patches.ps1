param(
    [Parameter(Mandatory = $true)] [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
$stage4 = Join-Path $root "tools\replay-weeko-v08-settings-stage4-patches.ps1"

if (!(Test-Path -LiteralPath $stage4)) { throw "Stage 4 replay script is missing: $stage4" }
& $pwsh -NoProfile -File $stage4 -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "Stage 4 replay failed; Stage 5 was not applied." }

function Replace-Stage5ExactText {
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
    if ($content.IndexOf($oldLf, $first + $oldLf.Length, [StringComparison]::Ordinal) -ge 0) {
        throw "Expected original text occurs more than once in $RelativePath"
    }
    $updated = $content.Remove($first, $oldLf.Length).Insert($first, $newLf)
    if ($lineEnding -eq "`r`n") { $updated = $updated.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $updated, [Text.UTF8Encoding]::new($false))
}

function Replace-Stage5MethodDefault {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Method,
        [Parameter(Mandatory = $true)] [string] $Key,
        [Parameter(Mandatory = $true)] [string] $NewConst
    )
    $path = Join-Path $project $RelativePath
    $original = [IO.File]::ReadAllText($path)
    $lineEnding = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $content = $original.Replace("`r", "")
    $pattern = '(?ms)(\.method public final ' + [regex]::Escape($Method) + '\(\)I.*?const-string v1, "' + [regex]::Escape($Key) + '".*?)(^\s*const[^\r\n]*)'
    $matches = [regex]::Matches($content, $pattern)
    if ($matches.Count -ne 1) { throw "Expected one default constant in $Method for $RelativePath" }
    $replacement = $matches[0].Groups[1].Value + "    " + $NewConst
    $updated = [regex]::Replace($content, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement })
    if ($lineEnding -eq "`r`n") { $updated = $updated.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $updated, [Text.UTF8Encoding]::new($false))
}

# Restore the v0.8 defaults at the actual ScheduleStyleConfig fallback sites.
# Existing table{id}_config SharedPreferences values remain untouched.
$styleConfig = "smali/com/suda/yzune/wakeupschedule/bean/ScheduleStyleConfig.smali"
Replace-Stage5MethodDefault $styleConfig "getCourseTextColor" "courseTextColor" "const v2, -0xdfdad5"
Replace-Stage5MethodDefault $styleConfig "getStrokeColor" "strokeColor" "const v2, -0x7f1d1814"
Replace-Stage5MethodDefault $styleConfig "getTextColor" "textColor" "const v2, -0xdfdad5"

$palettePath = Join-Path $project "smali\com\suda\yzune\wakeupschedule\schedule\FluentSchedulePalette.smali"
$palette = [IO.File]::ReadAllText($palettePath)
$lineEnding = if ($palette.Contains("`r`n")) { "`r`n" } else { "`n" }
$paletteLf = $palette.Replace("`r", "")

# Match semantic course colors by RGB, not by the current Paint alpha. This
# keeps the Weeko palette stable at every opacity setting while custom RGB
# values pass through unchanged.
$mapMethod = @'
.method private static mapCourseColor(IZ)I
    .locals 3
    move v2, p0
    const v0, 0xffffff
    and-int/2addr p0, v0
    const v1, 0xff1744
    if-eq p0, v1, :course_rose
    const v1, 0xfc718d
    if-eq p0, v1, :course_rose
    const v1, 0xecccd2
    if-eq p0, v1, :course_rose
    const v1, 0x653a45
    if-eq p0, v1, :course_rose
    const v1, 0xfa6278
    if-eq p0, v1, :course_rose_soft
    const v1, 0xe6cdd5
    if-eq p0, v1, :course_rose_soft
    const v1, 0x6b414d
    if-eq p0, v1, :course_rose_soft
    const v1, 0x2979ff
    if-eq p0, v1, :course_blue
    const v1, 0xcfe1f8
    if-eq p0, v1, :course_blue
    const v1, 0x294865
    if-eq p0, v1, :course_blue
    const v1, 0x1de9b6
    if-eq p0, v1, :course_teal
    const v1, 0x74efd1
    if-eq p0, v1, :course_teal
    const v1, 0xcbe8e2
    if-eq p0, v1, :course_teal
    const v1, 0x28564f
    if-eq p0, v1, :course_teal
    const v1, 0xa375ff
    if-eq p0, v1, :course_purple
    const v1, 0xddd5ee
    if-eq p0, v1, :course_purple
    const v1, 0x4c4264
    if-eq p0, v1, :course_purple
    const v1, 0xff9100
    if-eq p0, v1, :course_yellow
    const v1, 0xf2e5b8
    if-eq p0, v1, :course_yellow
    const v1, 0x62542b
    if-eq p0, v1, :course_yellow
    const v1, 0xff3d00
    if-eq p0, v1, :course_orange
    const v1, 0xf2d4c2
    if-eq p0, v1, :course_orange
    const v1, 0x654737
    if-eq p0, v1, :course_orange
    const v1, 0x2196f3
    if-eq p0, v1, :course_slate
    const v1, 0xd5e0e8
    if-eq p0, v1, :course_slate
    const v1, 0x3c4b57
    if-eq p0, v1, :course_slate
    const v1, 0x005caf
    if-eq p0, v1, :course_green
    const v1, 0xd9e8ce
    if-eq p0, v1, :course_green
    const v1, 0x3c5534
    if-eq p0, v1, :course_green
    return v2

    :course_rose
    if-eqz p1, :course_rose_light
    const v0, 0xff653a45
    return v0
    :course_rose_light
    const v0, 0xffecccd2
    return v0

    :course_rose_soft
    if-eqz p1, :course_rose_soft_light
    const v0, 0xff6b414d
    return v0
    :course_rose_soft_light
    const v0, 0xffe6cdd5
    return v0

    :course_blue
    if-eqz p1, :course_blue_light
    const v0, 0xff294865
    return v0
    :course_blue_light
    const v0, 0xffcfe1f8
    return v0

    :course_teal
    if-eqz p1, :course_teal_light
    const v0, 0xff28564f
    return v0
    :course_teal_light
    const v0, 0xffcbe8e2
    return v0

    :course_purple
    if-eqz p1, :course_purple_light
    const v0, 0xff4c4264
    return v0
    :course_purple_light
    const v0, 0xffddd5ee
    return v0

    :course_yellow
    if-eqz p1, :course_yellow_light
    const v0, 0xff62542b
    return v0
    :course_yellow_light
    const v0, 0xfff2e5b8
    return v0

    :course_orange
    if-eqz p1, :course_orange_light
    const v0, 0xff654737
    return v0
    :course_orange_light
    const v0, 0xfff2d4c2
    return v0

    :course_slate
    if-eqz p1, :course_slate_light
    const v0, 0xff3c4b57
    return v0
    :course_slate_light
    const v0, 0xffd5e0e8
    return v0

    :course_green
    if-eqz p1, :course_green_light
    const v0, 0xff3c5534
    return v0
    :course_green_light
    const v0, 0xffd9e8ce
    return v0
.end method
'@
$mapPattern = '(?s)\.method private static mapCourseColor\(IZ\)I.*?\.end method'
if ([regex]::Matches($paletteLf, $mapPattern).Count -ne 1) { throw "Expected one Stage 4 mapCourseColor method." }
$paletteLf = [regex]::Replace($paletteLf, $mapPattern, $mapMethod.TrimEnd("`r", "`n"))

# Apply only the card fill alpha. setColor() writes a new ARGB value and would
# otherwise reset Paint alpha to 255; each independent text/stroke alpha is
# captured and restored after its theme color is applied.
$styleCourse = @'
.method public static styleCourse(Lcom/suda/yzune/wakeupschedule/widget/TipTextView;)V
    .locals 7
    invoke-virtual {p0}, Landroid/view/View;->getContext()Landroid/content/Context;
    move-result-object v0
    const v1, 0x7f040132
    invoke-static {v0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v1
    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->isDark(Landroid/content/Context;)Z
    move-result v2
    iget-object v3, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;->OooOOOO:Landroid/graphics/Paint;
    invoke-virtual {v3}, Landroid/graphics/Paint;->getAlpha()I
    move-result v6
    invoke-virtual {v3}, Landroid/graphics/Paint;->getColor()I
    move-result v4
    invoke-static {v4, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->mapCourseColor(IZ)I
    move-result v4
    invoke-virtual {v3, v4}, Landroid/graphics/Paint;->setColor(I)V
    invoke-virtual {v3, v6}, Landroid/graphics/Paint;->setAlpha(I)V
    iget-object v3, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;->OooOOOo:Landroid/graphics/Paint;
    invoke-virtual {v3}, Landroid/graphics/Paint;->getAlpha()I
    move-result v6
    const/16 v5, 0x18
    invoke-static {v4, v1, v5}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->blend(III)I
    move-result v5
    invoke-virtual {v3, v5}, Landroid/graphics/Paint;->setColor(I)V
    invoke-virtual {v3, v6}, Landroid/graphics/Paint;->setAlpha(I)V
    const v5, 0x7f040119
    invoke-static {v0, v5}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v5
    iget-object v3, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;->OooOO0o:Landroid/text/TextPaint;
    invoke-virtual {v3}, Landroid/graphics/Paint;->getAlpha()I
    move-result v6
    invoke-virtual {v3, v5}, Landroid/graphics/Paint;->setColor(I)V
    invoke-virtual {v3, v6}, Landroid/graphics/Paint;->setAlpha(I)V
    iget-object v3, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;->OooOOO0:Landroid/text/TextPaint;
    invoke-virtual {v3}, Landroid/graphics/Paint;->getAlpha()I
    move-result v6
    invoke-virtual {v3, v5}, Landroid/graphics/Paint;->setColor(I)V
    invoke-virtual {v3, v6}, Landroid/graphics/Paint;->setAlpha(I)V
    iget-object v3, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;->OooOOO:Landroid/graphics/Paint;
    invoke-virtual {v3}, Landroid/graphics/Paint;->getAlpha()I
    move-result v6
    invoke-virtual {v3, v5}, Landroid/graphics/Paint;->setColor(I)V
    invoke-virtual {v3, v6}, Landroid/graphics/Paint;->setAlpha(I)V
    return-void
.end method
'@
$stylePattern = '(?s)\.method public static styleCourse\(Lcom/suda/yzune/wakeupschedule/widget/TipTextView;\)V.*?\.end method'
if ([regex]::Matches($paletteLf, $stylePattern).Count -ne 1) { throw "Expected one Stage 4 styleCourse method." }
$paletteLf = [regex]::Replace($paletteLf, $stylePattern, $styleCourse.TrimEnd("`r", "`n"))

# Resolve the same surface token used by the schedule body for an empty or
# invalid custom background instead of the old lavender fallback constant.
$defaultSurface = @'
.method public static defaultSurface(Landroid/content/Context;)I
    .locals 1
    const v0, 0x7f040134
    invoke-static {p0, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v0
    return v0
.end method
'@
$installNeedle = '.method public static install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V'
if ([regex]::Matches($paletteLf, [regex]::Escape($installNeedle)).Count -ne 1) { throw "Expected one FluentSchedulePalette.install method." }
$paletteLf = $paletteLf.Replace($installNeedle, $defaultSurface.TrimEnd("`r", "`n") + "`n`n" + $installNeedle)
if ($lineEnding -eq "`r`n") { $paletteLf = $paletteLf.Replace("`n", "`r`n") }
[IO.File]::WriteAllText($palettePath, $paletteLf, [Text.UTF8Encoding]::new($false))

$scheduleActivity = "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali"
Replace-Stage5ExactText $scheduleActivity @'
    const v9, -0x777778
'@ @'
    invoke-static {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->defaultSurface(Landroid/content/Context;)I
    move-result v9
'@

# Keep the schedule-management background preview on the same themed Surface
# when a stored custom color is malformed and the bitmap parser falls back.
$scheduleManageAdapter = "smali/com/suda/yzune/wakeupschedule/schedule/o0000OO0.smali"
Replace-Stage5ExactText $scheduleManageAdapter @'
    .locals 11
'@ @'
    .locals 12
'@
Replace-Stage5ExactText $scheduleManageAdapter @'
    const v6, -0x777778
'@ @'
    invoke-virtual {p0}, Lo0000oo0/OooOo00;->OooOo()Landroid/content/Context;
    move-result-object v11
    invoke-static {v11}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->defaultSurface(Landroid/content/Context;)I
    move-result v6
'@

# Apply the semantic colors before TipTextView draws its custom paints. The
# Stage 4 hook ran after super and needed an invalidate loop; moving the same
# call before super makes the first draw correct without scheduling redraws.
$tipPath = "smali/com/suda/yzune/wakeupschedule/widget/TipTextView.smali"
Replace-Stage5ExactText $tipPath @'
    invoke-super/range {p0 .. p1}, Landroid/view/View;->onDraw(Landroid/graphics/Canvas;)V

    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->styleCourse(Lcom/suda/yzune/wakeupschedule/widget/TipTextView;)V
'@ @'
    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->styleCourse(Lcom/suda/yzune/wakeupschedule/widget/TipTextView;)V

    invoke-super/range {p0 .. p1}, Landroid/view/View;->onDraw(Landroid/graphics/Canvas;)V
'@

# Derive launcher assets from the supplied artwork. Legacy density PNGs keep
# the exact full artwork; adaptive foreground/monochrome layers contain only
# the bar artwork, leaving the adaptive background to the system mask.
$launcherAsset = Join-Path $root "assets\weeko-launcher.png"
if (!(Test-Path -LiteralPath $launcherAsset)) { throw "Weeko launcher artwork is missing: $launcherAsset" }
$launcherHash = (Get-FileHash -LiteralPath $launcherAsset -Algorithm SHA256).Hash.ToUpperInvariant()
if ($launcherHash -ne "C80A35B21C459C412606D22CEFE1332D9F80117DE609BAA788535CFBFB347094") {
    throw "Weeko launcher artwork does not match the approved source image."
}

Add-Type -AssemblyName System.Drawing
$drawableNoDpi = Join-Path $project "res\drawable-nodpi"
$mipmapNoDpi = Join-Path $project "res\mipmap-nodpi"
New-Item -ItemType Directory -Force -Path $drawableNoDpi, $mipmapNoDpi | Out-Null
$sourceBitmap = [System.Drawing.Bitmap]::FromFile($launcherAsset)
try {
    $sizes = [ordered]@{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
    foreach ($entry in $sizes.GetEnumerator()) {
        $targetPath = Join-Path $project ("res\mipmap-{0}\ic_launcher.png" -f $entry.Key)
        $targetBitmap = [System.Drawing.Bitmap]::new($entry.Value, $entry.Value, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($targetBitmap)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.DrawImage($sourceBitmap, 0, 0, $entry.Value, $entry.Value)
        } finally { $graphics.Dispose() }
        if (Test-Path -LiteralPath $targetPath) { Remove-Item -LiteralPath $targetPath -Force }
        $targetBitmap.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $targetBitmap.Dispose()
    }

    $foreground = [System.Drawing.Bitmap]::new($sourceBitmap.Width, $sourceBitmap.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $monochrome = [System.Drawing.Bitmap]::new($sourceBitmap.Width, $sourceBitmap.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $foregroundPixels = 0
    try {
        for ($y = 0; $y -lt $sourceBitmap.Height; $y++) {
            for ($x = 0; $x -lt $sourceBitmap.Width; $x++) {
                $pixel = $sourceBitmap.GetPixel($x, $y)
                $r = $pixel.R; $g = $pixel.G; $b = $pixel.B
                $max = [Math]::Max($r, [Math]::Max($g, $b))
                $min = [Math]::Min($r, [Math]::Min($g, $b))
                $saturation = $max - $min
                $isBlue = (($b - $r) -ge 15 -and ($g - $r) -ge 5 -and ($b - $g) -le 35)
                $isCoral = (($r - $g) -ge 30 -and ($g - $b) -ge 8)
                if ($isBlue -or $isCoral) {
                    $alpha = [Math]::Min(255, [Math]::Max(0, [int](($saturation - 14) * 255 / 32)))
                } else {
                    $alpha = 0
                }
                if ($alpha -gt 0) { $foregroundPixels++ }
                $foreground.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $r, $g, $b))
                $monochrome.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, 255, 255, 255))
            }
        }
        if ($foreground.GetPixel(0, 0).A -ne 0 -or $foregroundPixels -lt 10000) {
            throw "Weeko adaptive foreground extraction did not produce a transparent bar layer."
        }
        $foregroundPath = Join-Path $drawableNoDpi "weeko_launcher_foreground_art.png"
        $monochromePath = Join-Path $drawableNoDpi "weeko_launcher_monochrome_art.png"
        foreach ($path in @($foregroundPath, $monochromePath)) { if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force } }
        $foreground.Save($foregroundPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $monochrome.Save($monochromePath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $foreground.Dispose(); $monochrome.Dispose()
    }
} finally { $sourceBitmap.Dispose() }
Copy-Item -LiteralPath $launcherAsset -Destination (Join-Path $drawableNoDpi "weeko_launcher_art.png") -Force

$legacyLayer = @'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <bitmap android:src="@drawable/weeko_launcher_art" android:gravity="fill" />
    </item>
</layer-list>
'@
$foregroundLayer = @'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <bitmap android:src="@drawable/weeko_launcher_foreground_art" android:gravity="fill" />
    </item>
</layer-list>
'@
$monochromeLayer = @'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <bitmap android:src="@drawable/weeko_launcher_monochrome_art" android:gravity="fill" />
    </item>
</layer-list>
'@
[IO.File]::WriteAllText((Join-Path $project "res\drawable\weeko_launcher_foreground_bitmap.xml"), $foregroundLayer, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $project "res\drawable\ic_launcher_foreground.xml"), $foregroundLayer, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $project "res\drawable\ic_weeko_monochrome.xml"), $monochromeLayer, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $project "res\mipmap-nodpi\ic_launcher.xml"), $legacyLayer, [Text.UTF8Encoding]::new($false))

$adaptiveV26 = @'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/weeko_launcher_foreground_bitmap" />
</adaptive-icon>
'@
$adaptiveV33 = @'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/weeko_launcher_foreground_bitmap" />
    <monochrome android:drawable="@drawable/ic_weeko_monochrome" />
</adaptive-icon>
'@
[IO.File]::WriteAllText((Join-Path $project "res\mipmap-anydpi-v26\ic_launcher.xml"), $adaptiveV26, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $project "res\mipmap-anydpi-v33\ic_launcher.xml"), $adaptiveV33, [Text.UTF8Encoding]::new($false))

$splash = @'
<?xml version="1.0" encoding="utf-8"?>
<layer-list android:opacity="opaque" xmlns:android="http://schemas.android.com/apk/res/android">
    <item><color android:color="?colorSurface" /></item>
    <item android:width="108.0dip" android:height="108.0dip" android:gravity="center" android:drawable="@drawable/weeko_launcher_art" />
</layer-list>
'@
[IO.File]::WriteAllText((Join-Path $project "res\drawable\splash.xml"), $splash, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $project "res\drawable\ic_weeko_splash.xml"), $legacyLayer, [Text.UTF8Encoding]::new($false))

Replace-Stage5ExactText "apktool.yml" @'
  versionCode: 9
  versionName: 0.8.0-settings-stage3
'@ @'
  versionCode: 9
  versionName: 0.8.0-settings-stage5
'@

Write-Output "Applied Weeko v0.8 Stage 5 alpha/default/background/icon fixes to $project"
