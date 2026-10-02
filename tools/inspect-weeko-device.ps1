param([switch] $Frames, [switch] $Memory)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding
$adb = 'E:\codex\tools\android-sdk\platform-tools\adb.exe'
if ($Frames) {
    & $adb shell dumpsys gfxinfo io.github.mxwf.weeko | Select-String 'Total frames|Janky frames:|percentile:'
} elseif ($Memory) {
    & $adb shell dumpsys meminfo io.github.mxwf.weeko | Select-String 'TOTAL PSS|Java Heap:|Native Heap:|Graphics:|Bitmap \(malloced\)'
} else {
    & $adb shell uiautomator dump /sdcard/weeko-review.xml | Out-Null
    [xml] $ui = (& $adb shell cat /sdcard/weeko-review.xml)
    if ($ui.hierarchy.node.package -ne 'io.github.mxwf.weeko') {
        throw 'Weeko is not foreground; no UI interaction was performed.'
    }
    $ui.SelectNodes('//node') | Where-Object { $_.text -or $_.'content-desc' } |
        ForEach-Object { '{0} {1} {2}' -f $_.text, $_.'content-desc', $_.bounds }
}
