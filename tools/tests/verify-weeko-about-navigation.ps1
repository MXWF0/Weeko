$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding
$adb = 'E:\codex\tools\android-sdk\platform-tools\adb.exe'
$processId = (& $adb shell pidof io.github.mxwf.weeko).Trim()
for ($i = 0; $i -lt 3; $i++) {
    & $adb shell input -d 0 tap 1120 200
    Start-Sleep -Milliseconds 450
    & $adb shell input -d 0 tap 1000 620
    Start-Sleep -Milliseconds 450
    & $adb shell uiautomator dump /sdcard/weeko-about-test.xml | Out-Null
    [xml] $ui = (& $adb shell cat /sdcard/weeko-about-test.xml)
    if (!$ui.SelectSingleNode('//node[@text="版本 1.1.5"]')) { throw 'About page did not open.' }
    & $adb shell input -d 0 keyevent 4
    Start-Sleep -Milliseconds 450
}
for ($i = 0; $i -lt 2; $i++) {
    & $adb shell input -d 0 tap 1120 200
    Start-Sleep -Milliseconds 450
    & $adb shell input -d 0 tap 1000 620
    Start-Sleep -Milliseconds 50
    & $adb shell input -d 0 keyevent 4
    Start-Sleep -Milliseconds 450
}
if ((& $adb shell pidof io.github.mxwf.weeko).Trim() -ne $processId) { throw 'Weeko process changed.' }
& $adb shell uiautomator dump /sdcard/weeko-about-test.xml | Out-Null
[xml] $ui = (& $adb shell cat /sdcard/weeko-about-test.xml)
if (!$ui.SelectSingleNode('//node[@resource-id="io.github.mxwf.weeko:id/anko_ib_more"]')) {
    throw 'About return did not restore the timetable.'
}
Write-Output "About enter/return cycles=3 and early return cycles=2 passed; process=$processId unchanged."
