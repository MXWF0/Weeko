param([Parameter(Mandatory)][string] $Trace, [Parameter(Mandatory)][int] $Thread, [Parameter(Mandatory)][double] $Start, [Parameter(Mandatory)][double] $End)
$ErrorActionPreference = 'Stop'
$runs = @(); $waits = @(); $runningFrom = $null; $waitingFrom = $null; $state = ''
foreach ($line in [IO.File]::ReadLines($Trace)) {
    if ($line -notmatch '(\d+\.\d+): sched_switch: .*prev_pid=(\d+) .*prev_state=(\S+) ==> .*next_pid=(\d+)') { continue }
    $time = [double]$Matches[1]; $previous = [int]$Matches[2]; $previousState = $Matches[3]; $next = [int]$Matches[4]
    if ($time -gt $End) { break }
    if ($previous -eq $Thread) {
        if ($null -ne $runningFrom -and $time -gt $Start) { $runs += [math]::Max(0.0, $time-[math]::Max($Start,$runningFrom))*1000 }
        $runningFrom = $null; $waitingFrom = $time; $state = $previousState
    }
    if ($next -eq $Thread) {
        if ($null -ne $waitingFrom -and $time -gt $Start) {
            $waits += [pscustomobject]@{State=$state; Ms=[math]::Max(0.0,$time-[math]::Max($Start,$waitingFrom))*1000}
        }
        $waitingFrom = $null; $runningFrom = $time
    }
}
if ($null -ne $runningFrom) { $runs += ($End-[math]::Max($Start,$runningFrom))*1000 }
if ($null -ne $waitingFrom) { $waits += [pscustomobject]@{State=$state; Ms=($End-[math]::Max($Start,$waitingFrom))*1000} }
[pscustomobject]@{Thread=$Thread; WallMs=($End-$Start)*1000; OnCpuMs=($runs | Measure-Object -Sum).Sum; RunnableWaitMs=($waits | Where-Object State -like 'R*' | Measure-Object Ms -Sum).Sum; SleepingMs=($waits | Where-Object State -notlike 'R*' | Measure-Object Ms -Sum).Sum} | Format-List
$waits | Sort-Object Ms -Descending | Select-Object -First 8 | Format-Table -AutoSize
