param([string] $Label = 'all-page-back')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'weeko-v120-ui.ps1')
$output = Join-Path $PSScriptRoot "../../build/v1.2.1/device-verification/$Label"
New-Item -ItemType Directory -Path $output -Force | Out-Null
function Back-Gesture([string] $kind = 'commit') {
    & $weekoAdb shell "CLASSPATH=/data/local/tmp/weeko-back-probe.zip app_process /system/bin WeekoBackGestureProbe 1220 2100 $kind"
    if ($LASTEXITCODE -ne 0) { throw 'Continuous gesture injection failed' }
    Read-WeekoUi
}
function Require-Page([string] $selector) {
    if (!(Find-WeekoNode $selector)) { throw "Expected source/page missing: $selector" }
}
Read-WeekoUi
Require-Page 'desc:更多操作'
$procId = (& $weekoAdb shell pidof io.github.mxwf.weeko).Trim()
& $weekoAdb shell atrace --async_start -b 8192 -a io.github.mxwf.weeko | Out-Null
try {
    Tap-Weeko 'desc:更多操作'; Tap-Weeko 'text:课表管理'
    foreach ($route in @(@('课表信息','text:课表名称'), @('课表外观','text:课程表背景'),
            @('课程管理','text:商业展示设计'), @('多课表管理','id:tv_table_name'))) {
        Tap-Weeko ('text:'+$route[0]); Read-WeekoUi
        Require-Page $route[1]
        Back-Gesture cancel; Require-Page $route[1]
        Back-Gesture; Require-Page 'text:将此课表配置用作默认配置'
        Write-Output ('PASS continuous cancel and return: '+$route[0])
    }
    Tap-Weeko 'text:作息时间'; Tap-Weeko 'text:默认'; Read-WeekoUi
    Back-Gesture cancel; Require-Page 'text:编辑作息时间'
    Back-Gesture; Require-Page 'text:需要保存以使设置生效吗？'
    Back-Gesture; Require-Page 'text:点击即可编辑'
    Write-Output 'PASS internal timetable preview cancel, original prompt and second-back discard. No timetable values changed/saved.'
    Back-Gesture; Require-Page 'text:将此课表配置用作默认配置'
    Back-Gesture; Require-Page 'desc:更多操作'
    Tap-Weeko 'desc:添加课程'
    Fill-Weeko 'id:et_name' 'WeekoPredictBack121'
    & $weekoAdb shell input keyevent 4
    Read-WeekoUi; Require-Page 'id:et_name'
    Back-Gesture cancel; Require-Page 'id:et_name'
    Back-Gesture; Require-Page 'text:离开'
    Back-Gesture; Require-Page 'desc:更多操作'
    Write-Output 'PASS add-course IME close, predictive cancel and second-back discard. Draft not saved.'
    Tap-Weeko 'desc:导入课程'; Tap-Weeko 'text:从教务导入'; Read-WeekoUi
    Back-Gesture cancel; Require-Page 'text:选择学校'
    Back-Gesture; Require-Page 'desc:更多操作'
    Write-Output 'PASS school-list continuous cancel and return. No school selected.'
    if ((& $weekoAdb shell pidof io.github.mxwf.weeko).Trim() -ne $procId) { throw 'App process changed' }
} finally {
    & $weekoAdb shell atrace --async_stop | Select-String 'Weeko.page.|Weeko.fragment.|Weeko.vault.|Weeko.capture' |
        Set-Content (Join-Path $output 'trace.txt')
}
Write-Output 'Device paths passed on this device only; not a visual smoothness/performance or all-device claim.'
