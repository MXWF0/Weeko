param([string] $TemporaryCourse = 'WeekoInlineTest20261012')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'weeko-v120-ui.ps1')
# Run only against a deliberately created test course, never an existing real course.
if ($TemporaryCourse -ne 'WeekoInlineTest20261012') { throw 'This check is restricted to the temporary course' }
Read-WeekoUi
if (!(Find-WeekoNode 'text:显示主题')) { throw 'Start in Settings' }
$font = (& $weekoAdb shell settings get system font_scale).Trim()
$density = (& $weekoAdb shell wm density) -join "`n"
try {
    & $weekoAdb shell input keyevent 4
    Read-WeekoUi
    & $weekoAdb shell wm density 630
    & $weekoAdb shell settings put system font_scale 1.6
    Tap-Weeko 'desc:更多操作'
    Tap-Weeko 'text:课表管理'
    Tap-Weeko 'text:课程管理'
    Read-WeekoUi
    for ($i = 0; $i -lt 5 -and !(Find-WeekoNode "text:$TemporaryCourse"); $i++) { Scroll-Weeko; Read-WeekoUi }
    Tap-Weeko "text:$TemporaryCourse"
    Assert-WeekoText 'id:tv_credit' '3.5'
    Read-WeekoUi
    for ($i = 0; $i -lt 5 -and !(Find-WeekoNode 'id:tv_note'); $i++) { Scroll-Weeko; Read-WeekoUi }
    Fill-Weeko 'id:tv_note' ('a' * 301)
    & $weekoAdb shell input keyevent 4
    Tap-Weeko 'id:menu_save'
    Read-WeekoUi
    if (!(Find-WeekoNode 'id:tv_note')) { throw '301-character note should prevent saving' }
    if ($weekoUi.SelectSingleNode('//node[@resource-id="android:id/message"]')) { throw 'Inline note opened a dialog' }
    Fill-Weeko 'id:tv_note' 'inline-note-final'
    & $weekoAdb shell input keyevent 4
    Read-WeekoUi
    for ($i = 0; $i -lt 5 -and !(Find-WeekoNode 'id:et_teacher'); $i++) { Scroll-Weeko; Read-WeekoUi }
    Tap-Weeko 'id:et_teacher'
    Read-WeekoUi
    if ($weekoUi.SelectSingleNode('//node[@resource-id="android:id/message"]')) { throw 'Teacher opened a dialog' }
    if (@($weekoUi.SelectNodes('//node[@text="徐飞"]')).Count -lt 2) { throw 'Existing recommendation not visible below focused teacher' }
    Write-Output 'PASS 320dp / 1.6 font: inline fields, note limit, teacher recommendation and keyboard'
    & $weekoAdb shell input keyevent 4
    Tap-Weeko 'id:menu_save'
    Read-WeekoUi
    if (!(Find-WeekoNode 'text:轻触编辑，长按删除')) { throw 'Temporary edit did not save to course manager' }
    Tap-Weeko "text:$TemporaryCourse"
    Read-WeekoUi
    for ($i = 0; $i -lt 5 -and !(Find-WeekoNode 'id:tv_note'); $i++) { Scroll-Weeko; Read-WeekoUi }
    Assert-WeekoText 'id:tv_note' 'inline-note-final'
    & $weekoAdb shell input keyevent 4
    Read-WeekoUi
    & $weekoAdb shell input swipe 1258 2100 560 2100 400
    Read-WeekoUi
    if (!(Find-WeekoNode 'text:轻触编辑，长按删除')) { throw 'Second back did not return to real source' }
    Write-Output 'PASS temporary-course save/backfill and second gesture discard'
} finally {
    & $weekoAdb shell settings put system font_scale $font
    $override = [regex]::Match($density, 'Override density: (\d+)')
    if ($override.Success) { & $weekoAdb shell wm density $override.Groups[1].Value }
    else { & $weekoAdb shell wm density reset }
}
