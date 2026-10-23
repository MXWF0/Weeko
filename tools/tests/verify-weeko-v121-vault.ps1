$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'weeko-v120-ui.ps1')
Read-WeekoUi
if (!(Find-WeekoNode 'text:显示主题')) { throw 'Start at top of Settings' }
for ($i=0; $i -lt 5; $i++) {
    if (Find-WeekoNode 'text:密码箱') { break }
    Scroll-Weeko down
    Read-WeekoUi
}
Tap-Weeko 'text:密码箱'
Read-WeekoUi
$handle=Find-WeekoNode 'desc:下滑关闭密码箱'
$b=@([regex]::Matches($handle.bounds,'\d+')|ForEach-Object{[int]$_.Value})
$x=[int](($b[0]+$b[2])/2); $y=[int](($b[1]+$b[3])/2)
& $weekoAdb shell input swipe $x $y $x ($y+70) 550
Read-WeekoUi
if (!(Find-WeekoNode 'text:完成')) { throw 'Small sheet drag did not rebound' }
Tap-Weeko 'text:＋ 新增'
Read-WeekoUi
if ($weekoUi.SelectNodes('//node[@class="android.widget.EditText"]').Count -ne 3) { throw 'Vault editor fields missing' }
& $weekoAdb shell input keyevent 4
Read-WeekoUi
if (!(Find-WeekoNode 'text:完成')) { throw 'Input dialog cancel lost vault' }
Tap-Weeko 'text:完成'
Read-WeekoUi
if (!(Find-WeekoNode 'text:隐私与安全')) { throw 'Done did not restore settings source' }
Tap-Weeko 'text:密码箱'
Read-WeekoUi
$handle=Find-WeekoNode 'desc:下滑关闭密码箱'
$b=@([regex]::Matches($handle.bounds,'\d+')|ForEach-Object{[int]$_.Value})
$y=[int](($b[1]+$b[3])/2)
& $weekoAdb shell input swipe $x $y $x 2670 500
Read-WeekoUi
if (!(Find-WeekoNode 'text:隐私与安全')) { throw 'Downward drag did not close vault' }
Tap-Weeko 'text:密码箱'
Read-WeekoUi
$handle=Find-WeekoNode 'desc:下滑关闭密码箱'
$top=[int]([regex]::Matches($handle.bounds,'\d+')[1].Value)
& $weekoAdb shell input tap 610 ([int]($top/2))
Read-WeekoUi
if (!(Find-WeekoNode 'text:隐私与安全')) { throw 'Scrim tap did not restore settings' }
& $weekoAdb shell input keyevent 4
Read-WeekoUi
if (!(Find-WeekoNode 'desc:更多操作')) { throw 'Settings return lost timetable' }
Tap-Weeko 'desc:更多操作'; Tap-Weeko 'text:设置'
Write-Output 'PASS vault partial rebound, input-dialog cancel, Done, full downward close, scrim close and reopen. No account fields were saved or copied. Does not by itself establish visual blur cleanup.'
