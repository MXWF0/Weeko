$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$adb = 'E:\codex\tools\android-sdk\platform-tools\adb.exe'
$processId = (& $adb shell pidof io.github.mxwf.weeko).Trim()
$activities = & $adb shell dumpsys activity activities
$resumed = $activities | Select-String 'topResumedActivity=.*io.github.mxwf.weeko/.*ScheduleActivity t(\d+)'
if (!$resumed) { throw 'Start this test on the foreground timetable.' }
$taskId = $resumed.Matches[0].Groups[1].Value
foreach ($scenario in @('early-back', 'home-enter', 'home-return')) {
    & $adb shell input -d 0 tap 1120 200
    Start-Sleep -Milliseconds 500
    & $adb shell uiautomator dump /sdcard/weeko-settings-test.xml | Out-Null
    [xml] $menu = (& $adb shell cat /sdcard/weeko-settings-test.xml)
    if (!$menu.SelectSingleNode('//node[@text="关于 Weeko"]')) { throw 'Main menu did not open.' }
    & $adb shell input -d 0 tap 1000 480
    if ($scenario -eq 'early-back') {
        Start-Sleep -Milliseconds 50
        & $adb shell input -d 0 keyevent 4
    } elseif ($scenario -eq 'home-enter') {
        Start-Sleep -Milliseconds 50
        & $adb shell input -d 0 keyevent 3
        Start-Sleep -Milliseconds 500
        & $adb shell am task focus $taskId | Out-Null
        Start-Sleep -Milliseconds 700
        & $adb shell uiautomator dump /sdcard/weeko-settings-test.xml | Out-Null
        [xml] $settings = (& $adb shell cat /sdcard/weeko-settings-test.xml)
        if (!$settings.SelectSingleNode('//node[@text="设置"]')) { throw 'Settings did not resume.' }
        & $adb shell input -d 0 keyevent 4
    } else {
        Start-Sleep -Milliseconds 700
        & $adb shell input -d 0 keyevent 4
        & $adb shell input -d 0 keyevent 3
        Start-Sleep -Milliseconds 500
        & $adb shell am task focus $taskId | Out-Null
    }
    Start-Sleep -Milliseconds 700
    & $adb shell uiautomator dump /sdcard/weeko-settings-test.xml | Out-Null
    [xml] $ui = (& $adb shell cat /sdcard/weeko-settings-test.xml)
    if (!$ui.SelectSingleNode('//node[@resource-id="io.github.mxwf.weeko:id/anko_ib_more"]')) {
        throw "Timetable did not return after $scenario."
    }
    if ((& $adb shell pidof io.github.mxwf.weeko).Trim() -ne $processId) { throw 'Weeko process changed.' }
    Write-Output "$scenario passed; process=$processId unchanged."
}
