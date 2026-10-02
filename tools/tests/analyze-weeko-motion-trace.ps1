param([Parameter(Mandatory)][string] $Directory, [int] $AppPid = 0, [int] $MinimumRun = 1)
$ErrorActionPreference = 'Stop'
$stacks = @{}; $spans = @(); $renderSpans = @(); $appSpans = @()
foreach ($line in [IO.File]::ReadLines((Join-Path $Directory 'trace.txt'))) {
    if ($line -notmatch '-(?<tid>\d+)\s+\(\s*(?<pid>\d+)\)\s+\[\d+\]\s+\S+\s+(?<time>\d+\.\d+): tracing_mark_write: (?<event>.*)$') { continue }
    $process = [int] $Matches.pid
    $tid = $Matches.tid; $time = [double]::Parse($Matches.time,[Globalization.CultureInfo]::InvariantCulture); $event = $Matches.event
    if (!$stacks.ContainsKey($tid)) { $stacks[$tid] = [Collections.Generic.Stack[object]]::new() }
    if ($event -match '^B\|\d+\|(.+)$') { $stacks[$tid].Push([pscustomobject]@{Name=$Matches[1]; Start=$time}) }
    elseif ($event -match '^E' -and $stacks[$tid].Count) {
        $span = $stacks[$tid].Pop()
        if ($AppPid -ne 0 -and $process -eq $AppPid -and ($time-$span.Start) -ge .001) {
            $appSpans += [pscustomobject]@{Name=$span.Name; Thread=$tid; Start=$span.Start; Ms=($time-$span.Start)*1000}
        }
        if ($span.Name -match '^(performTraversals|measure|layout|draw|DrawFrame|syncFrameState|flush drawing commands|dequeueBuffer|queueBuffer|inflate|Record View|Upload)') {
            $renderSpans += [pscustomobject]@{Name=$span.Name; Thread=$tid; Start=$span.Start; Ms=($time-$span.Start)*1000}
        }
        if ($span.Name.StartsWith('Weeko.')) { $spans += [pscustomobject]@{Name=$span.Name; Thread=$tid; Start=$span.Start; Ms=($time-$span.Start)*1000} }
    }
}
if ($AppPid -ne 0) {
    $appSpans | Export-Csv -LiteralPath (Join-Path $Directory 'app-spans.csv') -NoTypeInformation -Encoding utf8
    $appSpans | Sort-Object Ms -Descending | Select-Object -First 80 | Export-Csv -LiteralPath (Join-Path $Directory 'long-app-spans.csv') -NoTypeInformation -Encoding utf8
}
$renderSpans | Sort-Object Ms -Descending | Select-Object -First 40 | Export-Csv -LiteralPath (Join-Path $Directory 'long-render-spans.csv') -NoTypeInformation -Encoding utf8
if (!$spans.Count) { throw 'No matched Weeko trace spans.' }
if (!($spans.Name -contains 'Weeko.capture')) {
    $allocations = @($spans | Where-Object Name -eq 'Weeko.capture.allocate')
    $draws = @($spans | Where-Object Name -eq 'Weeko.capture.draw')
    if ($allocations.Count -ne $draws.Count) { throw 'Incomplete capture trace pairs.' }
    for ($i = 0; $i -lt $allocations.Count; $i++) {
        $spans += [pscustomobject]@{Name='Weeko.capture'; Thread=$allocations[$i].Thread; Start=$allocations[$i].Start; Ms=($draws[$i].Start-$allocations[$i].Start)*1000+$draws[$i].Ms}
    }
}
$spans | Export-Csv -LiteralPath (Join-Path $Directory 'trace-spans.csv') -NoTypeInformation -Encoding utf8
$summary = foreach ($group in ($spans | Group-Object Name)) {
    $sorted = @($group.Group.Ms | Sort-Object)
    [pscustomobject]@{ Name=$group.Name; Count=$sorted.Count; P50=[math]::Round($sorted[[math]::Ceiling($sorted.Count*.5)-1],3); P95=[math]::Round($sorted[[math]::Ceiling($sorted.Count*.95)-1],3); Max=[math]::Round($sorted[-1],3) }
}
$summary | Export-Csv -LiteralPath (Join-Path $Directory 'trace-summary.csv') -NoTypeInformation -Encoding utf8
$summary | Format-Table -AutoSize
$groups = @{}
foreach ($file in (Get-ChildItem -LiteralPath $Directory -Filter '*-*.txt')) {
    if ($file.BaseName -notmatch '^(Information|Appearance|Settings|About)-(Enter|Return)-(\d+)$') { continue }
    if ([int]$Matches[3] -lt $MinimumRun) { continue }
    $key = "$($Matches[1])/$($Matches[2])"
    if (!$groups.ContainsKey($key)) { $groups[$key] = @() }
    $text = Get-Content -LiteralPath $file.FullName -Raw
    $since = [long]([regex]::Match($text,'Stats since:\s*(\d+)ns').Groups[1].Value)
    $header = $null
    foreach ($line in ($text -split "`n")) {
        if ($line.StartsWith('Flags,')) { $header = $line.Trim().TrimEnd(',').Split(','); continue }
        if ($header -and $line -match '^\d+,') {
            $values = $line.Trim().TrimEnd(',').Split(','); $frame = @{}
            for ($j=0; $j -lt $header.Length; $j++) { $frame[$header[$j]] = [long]$values[$j] }
            if ($frame.IntendedVsync -ge $since -and ($frame.Flags -band 1) -eq 0 -and $frame.FrameCompleted -gt $frame.IntendedVsync) {
                $duration = $frame.FrameCompleted-$frame.IntendedVsync
                $groups[$key] += [pscustomobject]@{Ms=$duration/1000000.; OverBudget=($duration -gt $frame.FrameInterval)}
            }
        }
    }
}
$frames = foreach ($key in ($groups.Keys | Sort-Object)) {
    $sorted = @($groups[$key].Ms | Sort-Object)
    [pscustomobject]@{Path=$key; Frames=$sorted.Count; OverBudget=(@($groups[$key] | Where-Object OverBudget).Count); P50=[math]::Round($sorted[[math]::Ceiling($sorted.Count*.5)-1],2); P95=[math]::Round($sorted[[math]::Ceiling($sorted.Count*.95)-1],2); Max=[math]::Round($sorted[-1],2)}
}
$summaryFile = if ($MinimumRun -eq 1) { 'frames-summary.csv' } else { "frames-summary-from-run$MinimumRun.csv" }
$frames | Export-Csv -LiteralPath (Join-Path $Directory $summaryFile) -NoTypeInformation -Encoding utf8
$frames | Format-Table -AutoSize
