param([string] $ProjectPath = 'build/v1.2.0/repro-apktool-v1')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$source = [IO.File]::ReadAllText((Join-Path $root 'v06-source/src/main/java/io/github/mxwf/weeko/navigation/LayeredPageTransition.java'))
if ($source -notmatch 'if \(target.getBackground\(\) == null\) opaquePage\(target\)' -or
        $source -notmatch 'opaquePage\(this\)' -or $source -notmatch 'opaquePage\(content\)') {
    throw 'Activity, transparent Fragment roots and source snapshots must share an opaque page canvas'
}
if ($source -notmatch 'DURATION = 320' -or $source -notmatch 'new DecelerateInterpolator\(\)' -or
        $source -notmatch 'layer.update\(progress\)' -or $source -notmatch 'layer.clear\(\); layer = null') {
    throw 'Shared duration, easing, backdrop progress or cleanup changed'
}
[xml]$nav = [IO.File]::ReadAllText((Join-Path $root "$ProjectPath/res/navigation/nav_time_settings.xml"))
$action = $nav.SelectSingleNode('//*[@*[local-name()="id"]="@id/timeTableFragment_to_timeSettingsFragment"]')
foreach ($entry in @(@('enterAnim','enter'),@('exitAnim','exit'),@('popEnterAnim','pop_enter'),@('popExitAnim','pop_exit'))) {
    if ($action.GetAttribute($entry[0], 'http://schemas.android.com/apk/res-auto') -ne "@anim/nav_default_$($entry[1])_anim") {
        throw 'Timetable edit bypasses the shared transition'
    }
}
foreach ($name in @('TimeSettingsFragment','TimeTableFragment','o00Ooo')) {
    $relative = "smali/com/suda/yzune/wakeupschedule/settings/$name.smali"
    if ([IO.File]::ReadAllText((Join-Path $root "$ProjectPath/$relative")) -ne
            [IO.File]::ReadAllText((Join-Path $root "build/v1.1.5/repro-apktool-v1/$relative"))) {
        throw "Timetable editing/data code changed: $name"
    }
}
Write-Output 'PASS shared opaque page/snapshot canvas, 320ms easing/progress/cleanup and unchanged timetable edit/data classes'
