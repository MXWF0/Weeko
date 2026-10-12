$ErrorActionPreference = 'Stop'
$weekoAdb = 'E:\codex\tools\android-sdk\platform-tools\adb.exe'
function Read-WeekoUi {
    & $weekoAdb shell uiautomator dump /sdcard/weeko-v120.xml | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read device UI' }
    [xml]$script:weekoUi = & $weekoAdb shell cat /sdcard/weeko-v120.xml
    if (!$script:weekoUi.SelectSingleNode('//node[@package="io.github.mxwf.weeko"]')) { throw 'Weeko not foreground; no clicks sent' }
}
function Find-WeekoNode([string]$selector) {
    $kind, $value = $selector.Split(':',2)
    $attribute = switch ($kind) { 'id' { 'resource-id' }; 'lastid' { 'resource-id' }; 'text' { 'text' }; 'desc' { 'content-desc' }; default { throw 'Unknown UI selector' } }
    if ($kind -eq 'id' -or $kind -eq 'lastid') { $value = 'io.github.mxwf.weeko:id/' + $value }
    if ($kind -eq 'lastid') { return @($script:weekoUi.SelectNodes("//node[@$attribute='$value']"))[-1] }
    return $script:weekoUi.SelectSingleNode("//node[@$attribute='$value']")
}
function Tap-Weeko([string]$selector) {
    Read-WeekoUi
    $node = Find-WeekoNode $selector
    if (!$node) { throw "UI control not visible: $selector" }
    $bounds = @([regex]::Matches($node.bounds,'\d+') | ForEach-Object {[int]$_.Value})
    if ($bounds[2] -le $bounds[0] -or $bounds[3] -le $bounds[1]) { throw "Control has no visible bounds: $selector" }
    & $weekoAdb shell input tap ([int](($bounds[0]+$bounds[2])/2)) ([int](($bounds[1]+$bounds[3])/2))
}
function Show-WeekoUi {
    Read-WeekoUi
    $script:weekoUi.SelectNodes('//node') | Where-Object { $_.text -or $_.'content-desc' } |
        ForEach-Object { $_.text + ' | ' + $_.'resource-id' + ' | ' + $_.'content-desc' + ' | ' + $_.bounds }
}
function Scroll-Weeko([string]$direction='down') {
    Read-WeekoUi
    if ($direction -eq 'down') { & $weekoAdb shell input swipe 650 2350 650 850 400 }
    else { & $weekoAdb shell input swipe 650 850 650 2350 400 }
}
function Fill-Weeko([string]$selector,[string]$text) {
    Tap-Weeko $selector
    & $weekoAdb shell input keycombination 113 29
    if ($LASTEXITCODE -ne 0) { throw 'Device does not support select-all input' }
    & $weekoAdb shell input text $text
    Read-WeekoUi
}
function Assert-WeekoText([string]$selector,[string]$expected) {
    Read-WeekoUi
    $node=Find-WeekoNode $selector
    if (!$node -or $node.text -ne $expected) { throw "Text mismatch at $selector, expected $expected" }
    Write-Output "PASS $selector = $expected"
}
