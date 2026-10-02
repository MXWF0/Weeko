param([Parameter(Mandatory)][string] $Label, [int] $Runs = 3, [switch] $StartAtManagement, [switch] $MainMenu, [int] $ObservationMs = 500, [switch] $NoTrace, [switch] $MotionTrace, [switch] $SchedulingTrace, [ValidateSet('Settings','About','Information','Appearance')][string[]] $Paths = @())
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding
$adb = 'E:\codex\tools\android-sdk\platform-tools\adb.exe'
$directory = Join-Path $PSScriptRoot "..\..\build\v1.1.5\motion-$Label"
New-Item -ItemType Directory -Force -Path $directory | Out-Null
function Adb([string[]] $Arguments) {
    $result = & $adb @Arguments
    if ($LASTEXITCODE -ne 0) { throw "ADB failed: $($Arguments -join ' ')" }
    return $result
}
function Check([string] $Text) {
    Adb @('shell','uiautomator','dump','/sdcard/weeko-paths.xml') | Out-Null
    [xml] $ui = Adb @('shell','cat','/sdcard/weeko-paths.xml')
    if (!$ui.SelectSingleNode("//node[@text='$Text' or @content-desc='$Text']")) { throw "Wrong page; expected $Text" }
}
function Tap([int] $X, [int] $Y) {
    Adb @('shell','input','-d','0','tap',"$X","$Y") | Out-Null
    Start-Sleep -Milliseconds $ObservationMs
}
if (!$StartAtManagement -and !$MainMenu) {
    Adb @('shell','am','start','-n','io.github.mxwf.weeko/com.suda.yzune.wakeupschedule.schedule.ScheduleActivity') | Out-Null
    Start-Sleep -Milliseconds 1500
    Check '更多操作'
    Tap 1120 200
    Check '课表管理'
    Tap 1000 195
}
Check $(if ($MainMenu) { '更多操作' } else { '课表外观' })
$rows = @()
if (!$NoTrace) {
    $traceArgs = @('shell','atrace','--async_start','-b','32768','-a','io.github.mxwf.weeko')
    if ($SchedulingTrace) { $traceArgs += @('gfx','view','wm','am','sched','freq') }
    elseif (!$MotionTrace) { $traceArgs += @('gfx','view','wm','am','dalvik') }
    Adb $traceArgs | Out-Null
}
try {
    foreach ($path in $(if ($Paths.Count) { $Paths } elseif ($MainMenu) { @('Settings','About') } else { @('Information','Appearance') })) {
        $y = if ($path -eq 'Information') { 480 } else { 1400 }
        $title = switch ($path) { 'Settings' { '设置' }; 'About' { '关于 Weeko' }; 'Information' { '课表信息' }; 'Appearance' { '课表外观' } }
        for ($i = 1; $i -le $Runs; $i++) {
            foreach ($direction in @('Enter','Return')) {
                if ($MainMenu -and $direction -eq 'Enter') { Tap 1120 200; Check '课表管理' }
                Adb @('shell','dumpsys','gfxinfo','io.github.mxwf.weeko','reset') | Out-Null
                if ($direction -eq 'Enter') {
                    if ($MainMenu) { Tap 1000 $(if ($path -eq 'Settings') { 480 } else { 620 }) }
                    else { Tap 400 $y }
                }
                else { Adb @('shell','input','-d','0','keyevent','4') | Out-Null; Start-Sleep -Milliseconds $ObservationMs }
                $text = (Adb @('shell','dumpsys','gfxinfo','io.github.mxwf.weeko','framestats')) -join "`n"
                $text | Out-File -LiteralPath (Join-Path $directory "$path-$direction-$i.txt") -Encoding utf8
                $since = [long]([regex]::Match($text,'Stats since:\s*(\d+)ns').Groups[1].Value)
                $frames = @(); $header = $null
                foreach ($line in ($text -split "`n")) {
                    if ($line.StartsWith('Flags,IntendedVsync') -or $line.StartsWith('Flags,FrameTimelineVsyncId,')) { $header = $line.TrimEnd(',').Split(','); continue }
                    if ($header -and $line -match '^\d+,') {
                        $values = $line.TrimEnd(',').Split(','); $frame = @{}
                        for ($j = 0; $j -lt $header.Length; $j++) { $frame[$header[$j]] = [long] $values[$j] }
                        if ($frame.IntendedVsync -ge $since -and ($frame.Flags -band 1) -eq 0 -and $frame.FrameCompleted -gt $frame.IntendedVsync) {
                            $frames += [pscustomobject]@{ Ms=($frame.FrameCompleted-$frame.IntendedVsync)/1000000.; Late=($frame.FrameCompleted -gt $frame.FrameDeadline); UiMs=($frame.SyncQueued-$frame.HandleInputStart)/1000000. }
                        }
                    }
                }
                if (!$frames.Count) { throw "No fresh frame records: $path/$direction/$i" }
                $durations = @($frames.Ms | Sort-Object)
                $row = [pscustomobject]@{ Label=$Label; Path=$path; Direction=$direction; Run=$i; Frames=$frames.Count; Late=(@($frames | Where-Object Late).Count); P50=[math]::Round($durations[[math]::Ceiling($durations.Count*.50)-1],2); P95=[math]::Round($durations[[math]::Ceiling($durations.Count*.95)-1],2); Max=[math]::Round($durations[-1],2); MaxUi=[math]::Round(($frames.UiMs | Measure-Object -Maximum).Maximum,2) }
                $rows += $row; $row | Format-Table -AutoSize
                Check $(if ($direction -eq 'Enter') { $title } elseif ($MainMenu) { '更多操作' } else { '课表管理' })
            }
        }
    }
} finally {
    if (!$NoTrace) { Adb @('shell','atrace','--async_stop') | Out-File -LiteralPath (Join-Path $directory 'trace.txt') -Encoding utf8 }
    $rows | Export-Csv -LiteralPath (Join-Path $directory 'frames.csv') -NoTypeInformation -Encoding utf8
}
if (!$MainMenu) { Adb @('shell','input','-d','0','keyevent','4') | Out-Null }
"Saved $directory; fresh window frame records, ${ObservationMs}ms observation per action."
