param(
    [Parameter(Mandatory = $true)] [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
& $pwsh -NoProfile -File (Join-Path $root "tools\replay-weeko-v11-patches.ps1") -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "v1.1.0 patch replay failed; v1.1.1 patches were not applied." }

function Replace-V111ExactText {
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
    if ([regex]::Matches($content, [regex]::Escape($oldLf)).Count -ne 1) {
        throw "Expected one v1.1.1 match in $RelativePath"
    }
    $content = $content.Replace($oldLf, $newLf)
    if ($lineEnding -eq "`r`n") { $content = $content.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

Replace-V111ExactText "apktool.yml" "  versionCode: 14`n  versionName: 1.1.0" "  versionCode: 15`n  versionName: 1.1.1"
Replace-V111ExactText "AndroidManifest.xml" `
    '<activity android:exported="false" android:label="密码箱" android:name="io.github.mxwf.weeko.vault.PasswordVaultActivity" android:screenOrientation="portrait"/>' `
    '<activity android:exported="false" android:label="密码箱" android:name="io.github.mxwf.weeko.vault.PasswordVaultActivity" android:screenOrientation="portrait" android:theme="@style/Theme.MaterialComponents.DayNight.Dialog"/>'

Write-Output "Applied Weeko v1.1.1 vault dialog and compact editor patches to $project"
