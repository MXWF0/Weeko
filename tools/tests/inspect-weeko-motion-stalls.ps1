param([Parameter(Mandatory)][string] $Directory, [double]$Start = 0, [double]$End = 0)
$ErrorActionPreference = 'Stop'
$spans = Import-Csv (Join-Path $Directory 'app-spans.csv')
if ($End -gt $Start) {
    $spans | Where-Object { [double]$_.Start -ge $Start -and [double]$_.Start -le $End } | Sort-Object {[double]$_.Start} | Format-List
}
$motions = @(); $motion = @()
foreach ($line in [IO.File]::ReadLines((Join-Path $Directory 'trace.txt'))) {
    if ($line -match '(\d+\.\d+): tracing_mark_write: C\|\d+\|Weeko.enter.progress\|(\d+)') {
        $item = [pscustomobject]@{Time=[double]$Matches[1]; Progress=[int]$Matches[2]}
        if ($motion.Count -and $item.Time - $motion[-1].Time -gt 1) { $motions += ,$motion; $motion = @() }
        $motion += $item
    }
}
if ($motion.Count) { $motions += ,$motion }
foreach ($motion in $motions) {
    $motion | Select-Object -First 7 | Format-Table -AutoSize
}
$rows = foreach ($motion in $motions) {
    $positive = @($motion | Where-Object { $_.Progress -gt 0 })
    $gaps = @()
    for ($index = 1; $index -lt $motion.Count; $index++) {
        if ($motion[$index-1].Progress -gt 0 -and $motion[$index-1].Progress -lt 1000) {
            $gaps += ($motion[$index].Time-$motion[$index-1].Time)*1000
        }
    }
    [pscustomobject]@{ Start=$motion[0].Time; Samples=$motion.Count; FirstStep=$positive[0].Progress/10.; LargestMovingGapMs=[math]::Round(($gaps | Measure-Object -Maximum).Maximum,2) }
}
$rows | Export-Csv (Join-Path $Directory 'motion-progress.csv') -NoTypeInformation -Encoding utf8
$rows | Format-Table -AutoSize
