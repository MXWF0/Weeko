param([ValidateSet('Settings','About')][string] $Page = 'About', [Parameter(Mandatory)][string] $Output)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding
$adb = 'E:\codex\tools\android-sdk\platform-tools\adb.exe'
& $adb shell uiautomator dump /sdcard/weeko-record.xml | Out-Null
[xml] $ui = & $adb shell cat /sdcard/weeko-record.xml
if (!$ui.SelectSingleNode('//node[@resource-id="io.github.mxwf.weeko:id/anko_ib_more"]')) { throw 'Start on the timetable.' }
& $adb shell input -d 0 tap 1120 200
Start-Sleep -Milliseconds 500
$record = Start-Process -FilePath $adb -ArgumentList @('shell','screenrecord','--time-limit','4','/sdcard/weeko-motion.mp4') -WindowStyle Hidden -PassThru
Start-Sleep -Milliseconds 700
& $adb shell input -d 0 tap 1000 $(if ($Page -eq 'About') { 620 } else { 480 })
$record.WaitForExit()
if ($record.ExitCode -ne 0) { throw 'Screen recording failed.' }
& $adb pull /sdcard/weeko-motion.mp4 $Output
if ($LASTEXITCODE -ne 0) { throw 'Recording download failed.' }
