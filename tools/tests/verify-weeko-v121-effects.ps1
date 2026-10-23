param([bool] $Predictive = $false, [bool] $Advanced = $true, [string] $Label = 'effects', [switch] $Restart, [switch] $SmokeOnly)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'weeko-v120-ui.ps1')
$output = Join-Path $PSScriptRoot "../../build/v1.2.1/device-verification/$Label"
New-Item -ItemType Directory -Path $output -Force | Out-Null
function Set-Effect([string] $title, [bool] $value) {
    Read-WeekoUi
    $node = Find-WeekoNode "text:$title"
    $control = $node.ParentNode.SelectSingleNode('.//node[@checkable="true"]')
    if (!$control) { throw "Switch missing: $title" }
    if ([bool]::Parse($control.checked) -ne $value) { Tap-Weeko "text:$title" }
    Read-WeekoUi
    $node = Find-WeekoNode "text:$title"
    if ([bool]::Parse($node.ParentNode.SelectSingleNode('.//node[@checkable="true"]').checked) -ne $value) {
        throw "Switch did not update: $title"
    }
}
Read-WeekoUi
if (!(Find-WeekoNode 'text:显示主题')) { throw 'Start on Settings' }
Set-Effect '预测性返回手势' $Predictive
Set-Effect '高级材质' $Advanced
if ($Restart) {
    & $weekoAdb shell am force-stop io.github.mxwf.weeko
    & $weekoAdb shell am start -n io.github.mxwf.weeko/com.suda.yzune.wakeupschedule.SplashActivity | Out-Null
    Read-WeekoUi
    if (!(Find-WeekoNode 'desc:更多操作')) { throw 'Restart did not reach timetable' }
    Tap-Weeko 'desc:更多操作'; Tap-Weeko 'text:设置'
    Read-WeekoUi
    foreach ($setting in @(@('预测性返回手势',$Predictive),@('高级材质',$Advanced))) {
        $node = Find-WeekoNode ('text:'+$setting[0])
        if ([bool]::Parse($node.ParentNode.SelectSingleNode('.//node[@checkable="true"]').checked) -ne $setting[1]) {
            throw ('Preference did not survive force-stop: '+$setting[0])
        }
    }
    Write-Output "PASS force-stop persistence: predictive=$Predictive materials=$Advanced"
}
$procId = (& $weekoAdb shell pidof io.github.mxwf.weeko).Trim()
$windows = @(& $weekoAdb shell dumpsys window windows)
$windows | Select-String 'OnBackInvokedCallback|isAnimationCallback' | Set-Content (Join-Path $output 'back-registration.txt')
$width = [int]([regex]::Match(((& $weekoAdb shell wm size) -join ' '),'(\d+)x\d+').Groups[1].Value)
& $weekoAdb shell atrace --async_start -b 8192 -a io.github.mxwf.weeko | Out-Null
try {
    & $weekoAdb shell "CLASSPATH=/data/local/tmp/weeko-back-probe.zip app_process /system/bin WeekoBackGestureProbe $width 2100 cancel"
    if ($LASTEXITCODE -ne 0) { throw 'Continuous gesture probe failed; compile/push WeekoBackGestureProbe before device tests' }
    Read-WeekoUi
    if (!(Find-WeekoNode 'text:显示主题')) { throw 'Short edge swipe left Settings' }
    & $weekoAdb shell input swipe ($width-2) 2100 ([int]($width*0.44)) 2100 400
    Read-WeekoUi
    if (!(Find-WeekoNode 'desc:更多操作')) { throw 'Completed gesture did not return to timetable' }
    foreach ($path in @('设置','关于 Weeko')) {
        $delays = if ($SmokeOnly) { @(120) } else { @(50,120,450) }
        foreach ($delay in $delays) {
            Tap-Weeko 'desc:更多操作'
            Read-WeekoUi
            $node = Find-WeekoNode "text:$path"
            $b = @([regex]::Matches($node.bounds,'\d+') | ForEach-Object {[int]$_.Value})
            & $weekoAdb shell input tap ([int](($b[0]+$b[2])/2)) ([int](($b[1]+$b[3])/2))
            Start-Sleep -Milliseconds $delay
            & $weekoAdb shell input keyevent 4
            Read-WeekoUi
            if (!(Find-WeekoNode 'desc:更多操作')) { throw "$path return failed (${delay}ms requested delay)" }
            if ((& $weekoAdb shell pidof io.github.mxwf.weeko).Trim() -ne $procId) { throw 'App process changed' }
            Write-Output "PASS predictive=$Predictive materials=$Advanced path=$path return requested-delay=${delay}ms"
        }
    }
} finally {
    & $weekoAdb shell atrace --async_stop | Select-String 'Weeko.page.|Weeko.capture|Weeko.enter' |
        Set-Content (Join-Path $output 'navigation-trace.txt')
}
Tap-Weeko 'desc:更多操作'
Tap-Weeko 'text:设置'
Write-Output "PASS short-edge cancel, completed edge return and stable process ($procId); predictive=$Predictive materials=$Advanced. Timing requests alone do not establish in-flight interruption or visual smoothness."
