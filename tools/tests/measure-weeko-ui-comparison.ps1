param([Parameter(Mandatory)][string]$Label, [int]$Samples = 3)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding
$adb = 'E:\codex\tools\android-sdk\platform-tools\adb.exe'
$results = @()
function Invoke-Adb([string[]]$Arguments) {
    $output = & $adb @Arguments
    if ($LASTEXITCODE -ne 0) { throw "ADB failed: $($Arguments -join ' ')" }
    return $output
}
function Tap([int]$X, [int]$Y) { Invoke-Adb @('shell','input','-d','0','tap',"$X","$Y") | Out-Null; Start-Sleep -Milliseconds 700 }
function Check-Title([string]$Title) {
    Invoke-Adb @('shell','uiautomator','dump','/sdcard/weeko-review.xml') | Out-Null
    [xml]$ui = Invoke-Adb @('shell','cat','/sdcard/weeko-review.xml')
    if (!($ui.SelectNodes('//node') | Where-Object { $_.text -eq $Title -or $_.'content-desc' -eq $Title })) { throw "Expected UI: $Title" }
}
foreach ($flow in @('Menu','VaultFirst','VaultReopen','WeekRail')) {
    for ($sample = 1; $sample -le $Samples; $sample++) {
        Invoke-Adb @('shell','am','force-stop','io.github.mxwf.weeko') | Out-Null
        $startup = Invoke-Adb @('shell','am','start','-W','-f','0x10008000','-n','io.github.mxwf.weeko/com.suda.yzune.wakeupschedule.SplashActivity')
        Start-Sleep -Milliseconds 1200
        Check-Title '更多操作'
        if ($flow -like 'Vault*') {
            Tap 1120 200; Check-Title '课表管理'; Tap 850 480
            Check-Title '设置'
            Invoke-Adb @('shell','input','-d','0','swipe','650','2360','650','900','600') | Out-Null
            Start-Sleep -Milliseconds 700
            Check-Title '密码箱'
            if ($flow -eq 'VaultReopen') {
                Tap 160 1960
                Check-Title '完成'
                Invoke-Adb @('shell','input','-d','0','keyevent','4') | Out-Null
                Start-Sleep -Milliseconds 700
            }
        }
        Invoke-Adb @('shell','dumpsys','gfxinfo','io.github.mxwf.weeko','reset') | Out-Null
        if ($flow -eq 'Menu') { Tap 1120 200 }
        elseif ($flow -like 'Vault*') { Tap 160 1960 }
        else {
            Tap 205 250
            Invoke-Adb @('shell','input','-d','0','swipe','360','370','890','370','1000') | Out-Null
            Invoke-Adb @('shell','input','-d','0','swipe','890','370','360','370','1000') | Out-Null
        }
        Start-Sleep -Milliseconds 1000
        $frames = (Invoke-Adb @('shell','dumpsys','gfxinfo','io.github.mxwf.weeko')) -join "`n"
        $memory = (Invoke-Adb @('shell','dumpsys','meminfo','io.github.mxwf.weeko')) -join "`n"
        $row = [pscustomobject]@{
            Label=$Label; Flow=$flow; Sample=$sample
            ColdStartMs=([regex]::Match(($startup -join "`n"),'TotalTime:\s*(\d+)')).Groups[1].Value
            Frames=([regex]::Match($frames,'Total frames rendered:\s*(\d+)')).Groups[1].Value
            Janky=([regex]::Match($frames,'Janky frames:\s*(\d+)')).Groups[1].Value
            P95Ms=([regex]::Match($frames,'95th percentile:\s*(\d+)')).Groups[1].Value
            P99Ms=([regex]::Match($frames,'99th percentile:\s*(\d+)')).Groups[1].Value
            PssKB=([regex]::Match($memory,'TOTAL PSS:\s*(\d+)')).Groups[1].Value
        }
        if (!$row.Frames -or [int]$row.Frames -eq 0) { throw "No valid frames for $flow/$sample" }
        if ($flow -eq 'Menu') { Check-Title '课表管理' }
        elseif ($flow -like 'Vault*') { Check-Title '完成' }
        $results += $row
        $results | Export-Csv -LiteralPath (Join-Path $PSScriptRoot "..\..\build\v1.1.5\ui-measurement-$Label.csv") -NoTypeInformation -Encoding UTF8
        $row | Format-Table -AutoSize
    }
}
$output = Join-Path $PSScriptRoot "..\..\build\v1.1.5\ui-measurement-$Label.csv"
$results | Export-Csv -LiteralPath $output -NoTypeInformation -Encoding UTF8
"Saved $output; fixed-window frame statistics, not tap-to-first-frame latency."
