param(
    [switch] $VerifySigningKeyOnly,
    [Parameter(Mandatory = $true)] [string] $KeystorePath,
    [Parameter(Mandatory = $true)] [string] $CredentialPath,
    [string] $AndroidSdkPath = "E:\codex\Android\.tools\android-sdk",
    [string] $JdkPath = "",
    [string] $ApktoolJarPath = "E:\codex\Android\.tools\build\apktool_2.10.0.jar",
    [string] $BaseApktoolProject = "build\v0.6\repro-apktool",
    [string] $KeyAlias = "weeko-release-v3"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$source = Join-Path $root "tools\build-weeko-v11-release.ps1"
$text = [IO.File]::ReadAllText($source)
$text = $text.Replace("build\v1.1.0", "build\v1.1.1")
$text = $text.Replace("build-weeko-v11-debug.ps1", "build-weeko-v111-debug.ps1")
$text = $text.Replace("Weeko-v1.1.0", "Weeko-v1.1.1")
$text = $text.Replace("v1.1.0-release-summary.txt", "v1.1.1-release-summary.txt")
$text = $text.Replace("versionCode='14'", "versionCode='15'")
$text = $text.Replace("versionCode=14", "versionCode=15")
$text = $text.Replace("1.1.0", "1.1.1")
$generated = Join-Path $root "tools\.build-weeko-v111-release-generated.ps1"
[IO.File]::WriteAllText($generated, $text, [Text.UTF8Encoding]::new($false))
try {
    $arguments = @(
        "-NoProfile", "-File", $generated,
        "-KeystorePath", $KeystorePath,
        "-CredentialPath", $CredentialPath,
        "-AndroidSdkPath", $AndroidSdkPath,
        "-JdkPath", $JdkPath,
        "-ApktoolJarPath", $ApktoolJarPath,
        "-BaseApktoolProject", $BaseApktoolProject,
        "-KeyAlias", $KeyAlias
    )
    if ($VerifySigningKeyOnly) { $arguments += "-VerifySigningKeyOnly" }
    & (Get-Command pwsh.exe).Source @arguments
    if ($LASTEXITCODE -ne 0) { throw "Weeko v1.1.1 release build failed." }
} finally {
    if (Test-Path -LiteralPath $generated) { Remove-Item -LiteralPath $generated -Force }
}
