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
$sdk = (Resolve-Path -LiteralPath $AndroidSdkPath).Path
$jdk = if ([string]::IsNullOrWhiteSpace($JdkPath)) {
    $candidates = @(Get-ChildItem -LiteralPath (Split-Path $root -Parent) -Directory | ForEach-Object {
        Join-Path $_.FullName ".tools\jdk-17.0.20+8"
    } | Where-Object { Test-Path -LiteralPath (Join-Path $_ "bin\java.exe") })
    if (@($candidates).Count -ne 1) { throw "Expected one bundled JDK 17.0.20+8 under the codex tool directories." }
    (Resolve-Path -LiteralPath $candidates[0]).Path
} else { (Resolve-Path -LiteralPath $JdkPath).Path }
$keytool = Join-Path $jdk "bin\keytool.exe"
$buildTools = Join-Path $sdk "build-tools\36.0.0"
$keystore = (Resolve-Path -LiteralPath $KeystorePath).Path
$credential = (Resolve-Path -LiteralPath $CredentialPath).Path
$release = Join-Path $root "build\v1.0.1"
$logs = Join-Path $release "release-logs"
$expectedKeystoreSha256 = "2C3F4422CFA46D314C25B04984036BEC6DF3862E61CC68EBC5F83DD46B558C26"
$actualKeystoreSha256 = (Get-FileHash -LiteralPath $keystore -Algorithm SHA256).Hash.ToUpperInvariant()
if ($actualKeystoreSha256 -ne $expectedKeystoreSha256) { throw "The signing keystore is not the pinned Weeko release key: $actualKeystoreSha256" }

$securePassword = $null
$plainPassword = $null
$passwordPointer = [IntPtr]::Zero
try {
    $managedCredential = Import-Clixml -LiteralPath $credential
    if ($managedCredential.UserName -cne $KeyAlias) { throw "The managed signing credential alias does not match $KeyAlias." }
    $securePassword = $managedCredential.Password
    $managedCredential = $null
    $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
    $env:WEEKO_SIGNING_PASSWORD = $plainPassword
    $plainPassword = $null
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    $passwordPointer = [IntPtr]::Zero
    $env:JAVA_HOME = $jdk
    & $keytool -list -keystore $keystore -alias $KeyAlias -storepass:env WEEKO_SIGNING_PASSWORD
    if ($LASTEXITCODE -ne 0) { throw "The pinned Weeko release key could not be opened; no replacement key will be generated." }
    if ($VerifySigningKeyOnly) { Write-Output "The recorded Weeko signing key is available."; return }

    New-Item -ItemType Directory -Force -Path $release, $logs | Out-Null
    $pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
    & $pwsh -NoProfile -File (Join-Path $root "tools\build-weeko-v101-debug.ps1") -BaseApktoolProject $BaseApktoolProject -AndroidSdkPath $AndroidSdkPath -JdkPath $jdk -ApktoolJarPath $ApktoolJarPath *> (Join-Path $logs "debug-candidate-build.log")
    if ($LASTEXITCODE -ne 0) { throw "The v1.0.1 source and patch build failed; see release-logs/debug-candidate-build.log." }

    $unsigned = Join-Path $release "helper-v1-unsigned.apk"
    $aligned = Join-Path $release "Weeko-v1.0.1-release-aligned.apk"
    $final = Join-Path $release "Weeko-v1.0.1-release.apk"
    if (!(Test-Path -LiteralPath $unsigned)) { throw "The v1.0.1 unsigned candidate was not produced." }
    if (Test-Path -LiteralPath $aligned) { Remove-Item -LiteralPath $aligned -Force }
    & (Join-Path $buildTools "zipalign.exe") -f -p 4 $unsigned $aligned *> (Join-Path $logs "zipalign.log")
    if ($LASTEXITCODE -ne 0) { throw "Release zip alignment failed." }
    if (Test-Path -LiteralPath $final) { Remove-Item -LiteralPath $final -Force }
    & (Join-Path $buildTools "apksigner.bat") sign --ks $keystore --ks-key-alias $KeyAlias --ks-pass env:WEEKO_SIGNING_PASSWORD --key-pass env:WEEKO_SIGNING_PASSWORD --out $final $aligned *> (Join-Path $logs "apksigner-sign.log")
    if ($LASTEXITCODE -ne 0) { throw "Release signing failed with the recorded key." }
    & (Join-Path $buildTools "zipalign.exe") -c -P 4 -v 4 $final *> (Join-Path $logs "zipalign-verify.log")
    if ($LASTEXITCODE -ne 0) { throw "Final release APK zip alignment verification failed." }
    $signatureOutput = & (Join-Path $buildTools "apksigner.bat") verify --verbose --print-certs $final 2>&1
    $signatureOutput | Set-Content -LiteralPath (Join-Path $logs "apksigner-verify.log") -Encoding UTF8
    if ($LASTEXITCODE -ne 0) { throw "Final release APK signature verification failed." }
    $certificateLine = $signatureOutput | Where-Object { $_ -match 'Signer #1 certificate SHA-256 digest:' } | Select-Object -First 1
    if ($null -eq $certificateLine) { throw "Final release signing certificate digest was not reported." }
    $certificateSha256 = ($certificateLine -split ':', 2)[1].Trim().ToUpperInvariant()
    if ($certificateSha256 -ne "E654E9A275921CB213CD0AE3EB5D8C35FD5DDE1C84E32F71D3B6D42EED328CD5") { throw "Final APK certificate does not match the Weeko v3 release certificate." }
    $badging = & (Join-Path $buildTools "aapt2.exe") dump badging $final
    if ($LASTEXITCODE -ne 0) { throw "Final release APK metadata inspection failed." }
    $badging | Set-Content -LiteralPath (Join-Path $logs "apk-badging.txt") -Encoding UTF8
    if ($badging[0] -notmatch "^package: name='io.github.mxwf.weeko' versionCode='13' versionName='1.0.1'") { throw "Final APK package or version does not match v1.0.1." }
    $hash = (Get-FileHash -LiteralPath $final -Algorithm SHA256).Hash.ToUpperInvariant()
    $size = (Get-Item -LiteralPath $final).Length
    Set-Content -LiteralPath (Join-Path $release "v1.0.1-release-summary.txt") -Value @(
        "path=$final", "sha256=$hash", "size=$size", "package=io.github.mxwf.weeko",
        "versionCode=13", "versionName=1.0.1", "signingKey=$KeyAlias",
        "signingCertificateSha256=$certificateSha256", "keystoreSha256=$actualKeystoreSha256"
    ) -Encoding UTF8
    Write-Output "Built $final"
    Write-Output "SHA-256 $hash"
} finally {
    if (Test-Path Env:WEEKO_SIGNING_PASSWORD) { Remove-Item Env:WEEKO_SIGNING_PASSWORD }
    $plainPassword = $null
    if ($passwordPointer -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer); $passwordPointer = [IntPtr]::Zero }
    if ($null -ne $securePassword) { $securePassword.Dispose(); $securePassword = $null }
}
