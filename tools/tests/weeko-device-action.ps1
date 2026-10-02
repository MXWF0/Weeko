param([ValidateSet('Back','Tap','Swipe','Inspect')][string]$Action = 'Inspect', [int]$X = 0, [int]$Y = 0, [int]$EndX = 0, [int]$EndY = 0, [int]$Duration = 400)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding
$adb = 'E:\codex\tools\android-sdk\platform-tools\adb.exe'
if ($Action -eq 'Back') { & $adb shell input -d 0 keyevent 4 }
if ($Action -eq 'Tap') { & $adb shell input -d 0 tap $X $Y }
if ($Action -eq 'Swipe') { & $adb shell input -d 0 swipe $X $Y $EndX $EndY $Duration }
if ($Action -ne 'Inspect' -and $LASTEXITCODE -ne 0) { throw "ADB action failed: $LASTEXITCODE" }
Start-Sleep -Milliseconds 700
& (Join-Path $PSScriptRoot '..\inspect-weeko-device.ps1')
