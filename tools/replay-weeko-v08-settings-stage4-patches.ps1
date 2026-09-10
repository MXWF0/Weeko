param(
    [Parameter(Mandatory = $true)] [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
$stage3 = Join-Path $root "tools\replay-weeko-v08-settings-stage3-patches.ps1"

if (!(Test-Path -LiteralPath $stage3)) { throw "Stage 3 replay script is missing: $stage3" }
& $pwsh -NoProfile -File $stage3 -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "Stage 3 replay failed; Stage 4 palette was not applied." }

function Set-Stage4Color {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $true)] [string] $Value
    )
    $path = Join-Path $project $RelativePath
    $content = [IO.File]::ReadAllText($path)
    $pattern = '(<color name="' + [regex]::Escape($Name) + '">)[^<]+(</color>)'
    $matches = [regex]::Matches($content, $pattern)
    if ($matches.Count -ne 1) { throw "Expected one color named $Name in $RelativePath" }
    $updated = [regex]::Replace($content, $pattern, ('$1' + $Value + '$2'))
    [IO.File]::WriteAllText($path, $updated, [Text.UTF8Encoding]::new($false))
}

function Set-Stage4NightColor {
    param(
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $true)] [string] $Value
    )
    $path = Join-Path $project "res\values-night\colors.xml"
    $content = [IO.File]::ReadAllText($path)
    $pattern = '(<color name="' + [regex]::Escape($Name) + '">)[^<]+(</color>)'
    $matches = [regex]::Matches($content, $pattern)
    if ($matches.Count -eq 1) {
        $content = [regex]::Replace($content, $pattern, ('$1' + $Value + '$2'))
    } elseif ($matches.Count -eq 0) {
        $needle = '</resources>'
        if (!$content.Contains($needle)) { throw "Night colors resource has no resources terminator." }
        $replacement = '    <color name="' + $Name + '">' + $Value + '</color>' + "`r`n" + $needle
        $content = $content.Replace($needle, $replacement)
    } else {
        throw "Expected at most one color named $Name in res/values-night/colors.xml"
    }
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

# Weeko's schedule uses a deliberately cool neutral surface system. The
# existing dynamic-color switch remains available; these are the static
# light/night resources used when it is off.
$lightPalette = [ordered]@{
    md_theme_background = '#fff7f8fa'
    md_theme_inverseOnSurface = '#fff1f4f7'
    md_theme_inversePrimary = '#ffb6c2ff'
    md_theme_inverseSurface = '#ff20252b'
    md_theme_onBackground = '#ff20252b'
    md_theme_onPrimary = '#ffffffff'
    md_theme_onPrimaryContainer = '#ff1f2f78'
    md_theme_onSecondary = '#ffffffff'
    md_theme_onSecondaryContainer = '#ff20252b'
    md_theme_onSurface = '#ff20252b'
    md_theme_onSurfaceVariant = '#ff65717d'
    md_theme_onTertiary = '#ffffffff'
    md_theme_onTertiaryContainer = '#ff1f2f78'
    md_theme_outline = '#ffb9c3cc'
    md_theme_outlineVariant = '#ffe2e7ec'
    md_theme_primary = '#ff4f6bff'
    md_theme_primaryContainer = '#ffe0e6ff'
    md_theme_secondary = '#ff65717d'
    md_theme_secondaryContainer = '#ffe7ebef'
    md_theme_surface = '#fff7f8fa'
    md_theme_surfaceBright = '#ffffffff'
    md_theme_surfaceContainer = '#ffedf0f3'
    md_theme_surfaceContainerHigh = '#ffe7ebef'
    md_theme_surfaceContainerHighest = '#ffe2e7ec'
    md_theme_surfaceContainerLow = '#fff1f3f6'
    md_theme_surfaceContainerLowest = '#ffffffff'
    md_theme_surfaceDim = '#ffe8ebef'
    md_theme_surfaceVariant = '#ffe7ebef'
    md_theme_tertiary = '#ff4f6bff'
    md_theme_tertiaryContainer = '#ffe0e6ff'
}
foreach ($entry in $lightPalette.GetEnumerator()) {
    Set-Stage4Color "res/values/colors.xml" $entry.Key $entry.Value
}

$darkPalette = [ordered]@{
    md_theme_background = '#ff101419'
    md_theme_inverseOnSurface = '#ff20252b'
    md_theme_inversePrimary = '#ff4f6bff'
    md_theme_inverseSurface = '#ffe7ebef'
    md_theme_onBackground = '#fff1f4f7'
    md_theme_onPrimary = '#ff111a41'
    md_theme_onPrimaryContainer = '#ffdce4ff'
    md_theme_onSecondary = '#ff20252b'
    md_theme_onSecondaryContainer = '#ffe9edf2'
    md_theme_onSurface = '#fff1f4f7'
    md_theme_onSurfaceVariant = '#ffa9b3be'
    md_theme_onTertiary = '#ff111a41'
    md_theme_onTertiaryContainer = '#ffdce4ff'
    md_theme_outline = '#ff64717c'
    md_theme_outlineVariant = '#ff2b343d'
    md_theme_primary = '#ff7894ff'
    md_theme_primaryContainer = '#ff263664'
    md_theme_secondary = '#ffa9b3be'
    md_theme_secondaryContainer = '#ff2b343d'
    md_theme_surface = '#ff101419'
    md_theme_surfaceBright = '#ff232a33'
    md_theme_surfaceContainer = '#ff1b2128'
    md_theme_surfaceContainerHigh = '#ff202730'
    md_theme_surfaceContainerHighest = '#ff2b343d'
    md_theme_surfaceContainerLow = '#ff171c22'
    md_theme_surfaceContainerLowest = '#ff0b0e12'
    md_theme_surfaceDim = '#ff0c0f13'
    md_theme_surfaceVariant = '#ff2b343d'
    md_theme_tertiary = '#ff7894ff'
    md_theme_tertiaryContainer = '#ff263664'
}
foreach ($entry in $darkPalette.GetEnumerator()) {
    Set-Stage4Color "res/values-night/colors.xml" $entry.Key $entry.Value
}

# Keep the existing color resource IDs and array order, but make the course
# picker use the same low-saturation semantic palette as the rendered cards.
$courseLight = [ordered]@{
    red = '#ffecccd2'
    pink = '#ffe6cdd5'
    blue = '#ffcfe1f8'
    green = '#ffcbe8e2'
    purple = '#ffddd5ee'
    orange = '#fff2e5b8'
    deepOrange = '#fff2d4c2'
    lightBlue = '#ffd5e0e8'
    ruri = '#ffd9e8ce'
}
$courseDark = [ordered]@{
    red = '#ff653a45'
    pink = '#ff6b414d'
    blue = '#ff294865'
    green = '#ff28564f'
    purple = '#ff4c4264'
    orange = '#ff62542b'
    deepOrange = '#ff654737'
    lightBlue = '#ff3c4b57'
    ruri = '#ff3c5534'
}
foreach ($entry in $courseLight.GetEnumerator()) {
    Set-Stage4Color "res/values/colors.xml" $entry.Key $entry.Value
}
foreach ($entry in $courseDark.GetEnumerator()) {
    Set-Stage4NightColor $entry.Key $entry.Value
}

$palettePath = Join-Path $project "smali\com\suda\yzune\wakeupschedule\schedule\FluentSchedulePalette.smali"
$smali = [IO.File]::ReadAllText($palettePath)
$courseMethod = @'
.method private static mapCourseColor(IZ)I
    .locals 2
    move v0, p0
    const v1, 0xffff1744
    if-eq v0, v1, :course_rose
    const v1, 0x99ff1744
    if-eq v0, v1, :course_rose
    const v1, 0xffecccd2
    if-eq v0, v1, :course_rose
    const v1, 0xff653a45
    if-eq v0, v1, :course_rose
    const v1, 0xfffc718d
    if-eq v0, v1, :course_rose
    const v1, 0xfffa6278
    if-eq v0, v1, :course_rose_soft
    const v1, 0x99fa6278
    if-eq v0, v1, :course_rose_soft
    const v1, 0xffe6cdd5
    if-eq v0, v1, :course_rose_soft
    const v1, 0xff6b414d
    if-eq v0, v1, :course_rose_soft
    const v1, 0xff2979ff
    if-eq v0, v1, :course_blue
    const v1, 0x992979ff
    if-eq v0, v1, :course_blue
    const v1, 0xffcfe1f8
    if-eq v0, v1, :course_blue
    const v1, 0xff294865
    if-eq v0, v1, :course_blue
    const v1, 0xff1de9b6
    if-eq v0, v1, :course_teal
    const v1, 0x991de9b6
    if-eq v0, v1, :course_teal
    const v1, 0xffcbe8e2
    if-eq v0, v1, :course_teal
    const v1, 0xff28564f
    if-eq v0, v1, :course_teal
    const v1, 0xff74efd1
    if-eq v0, v1, :course_teal
    const v1, 0xffa375ff
    if-eq v0, v1, :course_purple
    const v1, 0x99a375ff
    if-eq v0, v1, :course_purple
    const v1, 0xffddd5ee
    if-eq v0, v1, :course_purple
    const v1, 0xff4c4264
    if-eq v0, v1, :course_purple
    const v1, 0xffff9100
    if-eq v0, v1, :course_yellow
    const v1, 0x99ff9100
    if-eq v0, v1, :course_yellow
    const v1, 0xfff2e5b8
    if-eq v0, v1, :course_yellow
    const v1, 0xff62542b
    if-eq v0, v1, :course_yellow
    const v1, 0xffff3d00
    if-eq v0, v1, :course_orange
    const v1, 0x99ff3d00
    if-eq v0, v1, :course_orange
    const v1, 0xfff2d4c2
    if-eq v0, v1, :course_orange
    const v1, 0xff654737
    if-eq v0, v1, :course_orange
    const v1, 0xff2196f3
    if-eq v0, v1, :course_slate
    const v1, 0x992196f3
    if-eq v0, v1, :course_slate
    const v1, 0xffd5e0e8
    if-eq v0, v1, :course_slate
    const v1, 0xff3c4b57
    if-eq v0, v1, :course_slate
    const v1, 0xff005caf
    if-eq v0, v1, :course_green
    const v1, 0x99005caf
    if-eq v0, v1, :course_green
    const v1, 0xffd9e8ce
    if-eq v0, v1, :course_green
    const v1, 0xff3c5534
    if-eq v0, v1, :course_green
    return p0

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

.method public static styleCourse(Lcom/suda/yzune/wakeupschedule/widget/TipTextView;)V
    .locals 7
    invoke-virtual {p0}, Landroid/view/View;->getContext()Landroid/content/Context;
    move-result-object v0
    const v1, 0x7f04012f
    invoke-static {v0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v1
    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->isDark(Landroid/content/Context;)Z
    move-result v2
    iget-object v3, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;->OooOOOO:Landroid/graphics/Paint;
    invoke-virtual {v3}, Landroid/graphics/Paint;->getColor()I
    move-result v4
    invoke-static {v4, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->mapCourseColor(IZ)I
    move-result v4
    invoke-virtual {v3, v4}, Landroid/graphics/Paint;->setColor(I)V
    iget-object v3, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;->OooOOOo:Landroid/graphics/Paint;
    const/16 v6, 0x18
    invoke-static {v4, v1, v6}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->blend(III)I
    move-result v5
    invoke-virtual {v3, v5}, Landroid/graphics/Paint;->setColor(I)V
    const v5, 0x7f040119
    invoke-static {v0, v5}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->resolveColor(Landroid/content/Context;I)I
    move-result v5
    iget-object v3, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;->OooOO0o:Landroid/text/TextPaint;
    invoke-virtual {v3, v5}, Landroid/graphics/Paint;->setColor(I)V
    iget-object v3, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;->OooOOO0:Landroid/text/TextPaint;
    invoke-virtual {v3, v5}, Landroid/graphics/Paint;->setColor(I)V
    iget-object v3, p0, Lcom/suda/yzune/wakeupschedule/widget/TipTextView;->OooOOO:Landroid/graphics/Paint;
    invoke-virtual {v3, v5}, Landroid/graphics/Paint;->setColor(I)V
    invoke-virtual {p0}, Landroid/view/View;->invalidate()V
    return-void
.end method
'@
$coursePattern = '(?s)\.method private static styleCourse\(Lcom/suda/yzune/wakeupschedule/widget/TipTextView;\)V.*?\.end method'
if ([regex]::Matches($smali, $coursePattern).Count -ne 1) { throw "Expected one Stage 3 styleCourse method." }
$smali = [regex]::Replace($smali, $coursePattern, $courseMethod)
$oldSelectedColor = '    const v4, 0x7f04013a'
if ([regex]::Matches($smali, [regex]::Escape($oldSelectedColor)).Count -ne 1) { throw "Expected one tertiary selected-date color." }
$smali = $smali.Replace($oldSelectedColor, '    const v4, 0x7f040122')
[IO.File]::WriteAllText($palettePath, $smali, [Text.UTF8Encoding]::new($false))

# The schedule page creates course views after the initial page container is
# styled. Re-apply the course palette at draw time so dynamically bound cards
# receive the same Light/Dark mapping without changing layout or interaction.
$tipPath = Join-Path $project "smali\com\suda\yzune\wakeupschedule\widget\TipTextView.smali"
$tip = [IO.File]::ReadAllText($tipPath)
$onDrawNeedle = "    invoke-super/range {p0 .. p1}, Landroid/view/View;->onDraw(Landroid/graphics/Canvas;)V"
if ([regex]::Matches($tip, [regex]::Escape($onDrawNeedle)).Count -ne 1) { throw "Expected one TipTextView onDraw super call." }
$tip = $tip.Replace($onDrawNeedle, $onDrawNeedle + "`r`n`r`n    invoke-static {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentSchedulePalette;->styleCourse(Lcom/suda/yzune/wakeupschedule/widget/TipTextView;)V")
[IO.File]::WriteAllText($tipPath, $tip, [Text.UTF8Encoding]::new($false))

Write-Output "Applied Weeko v0.8 Stage 4 cool-neutral schedule palette and fixed Light/Dark course mappings to $project"
