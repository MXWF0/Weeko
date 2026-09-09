param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage6Script = Join-Path $PSScriptRoot "replay-weeko-v08-fluent-stage6-patches.ps1"

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $stage6Script -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "Fluent Stage 6 patch replay failed; Fluent Stage 7 was not applied." }

function Replace-FluentStage7ExactText {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Old,
        [Parameter(Mandatory = $true)] [string] $New
    )
    $path = Join-Path $project $RelativePath
    if (!(Test-Path -LiteralPath $path)) { throw "Patch input is missing: $RelativePath" }
    $original = [IO.File]::ReadAllText($path)
    $lineEnding = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $content = $original.Replace("`r", "")
    $oldLf = $Old.Replace("`r", "").TrimEnd("`n")
    $newLf = $New.Replace("`r", "").TrimEnd("`n")
    $first = $content.IndexOf($oldLf, [StringComparison]::Ordinal)
    if ($first -lt 0) { throw "Expected original text was not found in $RelativePath" }
    $second = $content.IndexOf($oldLf, $first + $oldLf.Length, [StringComparison]::Ordinal)
    if ($second -ge 0) { throw "Expected original text occurs more than once in $RelativePath" }
    $updated = $content.Remove($first, $oldLf.Length).Insert($first, $newLf)
    if ($lineEnding -eq "`r`n") { $updated = $updated.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $updated, [Text.UTF8Encoding]::new($false))
}

Replace-FluentStage7ExactText "apktool.yml" @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage6
'@ @'
  versionCode: 7
  versionName: 0.7.0-fluent-stage7
'@

# Keep a visible 48dp navigation target at the leading edge. The date, week,
# and weekday labels share one 64dp inset so the two-line information block
# reads as a unit without colliding with that target.
Replace-FluentStage7ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali" @'
    add-int v4, v7, v7

    int-to-float v4, v4
'@ @'
    add-int v4, v7, v7
    add-int v4, v4, v4

    int-to-float v4, v4
'@

Replace-FluentStage7ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali" @'
    neg-int v7, v7

    int-to-float v7, v7
'@ @'
    int-to-float v7, v7
'@

Write-Output "Applied Fluent UI Stage 7 left-header layout patch to $project"
