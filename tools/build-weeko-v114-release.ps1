param(
    [string] $AndroidSdkPath = "E:\codex\tools\android-sdk",
    [string] $JdkPath = "",
    [string] $ApktoolJarPath = "E:\codex\tools\apktool_2.11.1.jar",
    [string] $BaseApktoolProject = "build\v0.6\repro-apktool"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$release = Join-Path $root "build\v1.1.4"
$unsigned = Join-Path $release "helper-v1-unsigned.apk"
$buildTools = Join-Path $AndroidSdkPath "build-tools\36.0.0"
$jdk = if ([string]::IsNullOrWhiteSpace($JdkPath)) {
    $candidates = @(Get-ChildItem -LiteralPath (Split-Path $root -Parent) -Directory | ForEach-Object {
        Join-Path $_.FullName ".tools\jdk-17.0.20+8"
    } | Where-Object { Test-Path -LiteralPath (Join-Path $_ "bin\java.exe") })
    if (@($candidates).Count -ne 1) { throw "Expected one bundled JDK 17.0.20+8 under the codex tool directories." }
    (Resolve-Path -LiteralPath $candidates[0]).Path
} else { (Resolve-Path -LiteralPath $JdkPath).Path }
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source

& $pwsh -NoProfile -File (Join-Path $PSScriptRoot "build-weeko-v114-debug.ps1") `
    -BaseApktoolProject $BaseApktoolProject `
    -AndroidSdkPath $AndroidSdkPath `
    -JdkPath $JdkPath `
    -ApktoolJarPath $ApktoolJarPath
if ($LASTEXITCODE -ne 0) { throw "Weeko v1.1.4 candidate build failed." }
if (!(Test-Path -LiteralPath $unsigned)) { throw "The Weeko v1.1.4 unsigned APK was not produced." }

$badging = & (Join-Path $buildTools "aapt2.exe") dump badging $unsigned
if ($LASTEXITCODE -ne 0) { throw "Unsigned APK metadata inspection failed." }
if ($badging[0] -notmatch "^package: name='io.github.mxwf.weeko' versionCode='18' versionName='1.1.4'") {
    throw "Unsigned APK package or version does not match v1.1.4."
}

$oldJavaHome = $env:JAVA_HOME
try {
    $env:JAVA_HOME = $jdk
    $signatureOutput = & (Join-Path $buildTools "apksigner.bat") verify --verbose --print-certs $unsigned 2>&1
    $signatureExitCode = $LASTEXITCODE
} finally {
    $env:JAVA_HOME = $oldJavaHome
}
if ($signatureExitCode -eq 0) { throw "The release candidate is signed; expected an unsigned APK." }
if (($signatureOutput -join "`n") -notmatch 'ERROR: Missing META-INF/MANIFEST\.MF') {
    $signatureOutput | ForEach-Object { Write-Output $_ }
    throw "The release candidate failed apksigner verification for a reason other than being unsigned."
}

Write-Output "Built unsigned APK: $unsigned"
