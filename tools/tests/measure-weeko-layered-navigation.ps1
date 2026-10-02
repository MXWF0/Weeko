param([int] $Runs = 5)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding
$adb = 'E:\codex\tools\android-sdk\platform-tools\adb.exe'
& $adb shell uiautomator dump /sdcard/weeko-motion.xml | Out-Null
[xml] $ui = (& $adb shell cat /sdcard/weeko-motion.xml)
if (!$ui.SelectSingleNode('//node[@resource-id="io.github.mxwf.weeko:id/anko_ib_more"]')) {
    throw 'Start this measurement from the main timetable.'
}
& $adb shell dumpsys gfxinfo io.github.mxwf.weeko reset | Out-Null
for ($i = 0; $i -lt $Runs; $i++) {
    & $adb shell input -d 0 tap 1120 200
    Start-Sleep -Milliseconds 450
    & $adb shell input -d 0 tap 1000 480
    Start-Sleep -Milliseconds 600
    & $adb shell input -d 0 keyevent 4
    Start-Sleep -Milliseconds 600
}
Write-Output "Settings enter/return cycles=$Runs; menu frames included; not tap-to-display latency"
& $adb shell dumpsys gfxinfo io.github.mxwf.weeko | Select-String 'Total frames|Janky frames:|percentile:'
& $adb shell dumpsys meminfo io.github.mxwf.weeko | Select-String 'TOTAL PSS|Graphics:'
& $adb shell pidof io.github.mxwf.weeko
& $adb shell uiautomator dump /sdcard/weeko-motion.xml | Out-Null
[xml] $ui = (& $adb shell cat /sdcard/weeko-motion.xml)
if (!$ui.SelectSingleNode('//node[@resource-id="io.github.mxwf.weeko:id/anko_ib_more"]')) {
    throw 'Navigation did not return to the main timetable.'
}
