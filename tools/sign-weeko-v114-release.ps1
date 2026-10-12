param(
    [switch] $VerifySigningKeyOnly,
    [string] $UnsignedApkPath = "build\v1.1.4\helper-v1-unsigned.apk",
    [string] $KeystorePath = "E:\codex\Weeko-signing\weeko-release-v3.p12",
    [string] $CredentialPath = "E:\codex\Weeko-signing\weeko-release-v3.credential.xml",
    [string] $AndroidSdkPath = "E:\codex\tools\android-sdk",
    [string] $JdkPath = "",
    [string] $KeyAlias = "weeko-release-v3"
)

$ErrorActionPreference = "Stop"
$expectedSigningIdentity = "FA507XV\mxwfw"
$currentSigningIdentity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
if ($currentSigningIdentity -ine $expectedSigningIdentity) {
    throw "Weeko v3 signing must run as $expectedSigningIdentity to decrypt the existing DPAPI credential. Current identity: $currentSigningIdentity. No account switch or elevation was attempted."
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$jdk = if ([string]::IsNullOrWhiteSpace($JdkPath)) {
    $candidates = @(Get-ChildItem -LiteralPath (Split-Path $root -Parent) -Directory | ForEach-Object {
        Join-Path $_.FullName ".tools\jdk-17.0.20+8"
    } | Where-Object { Test-Path -LiteralPath (Join-Path $_ "bin\keytool.exe") })
    if (@($candidates).Count -ne 1) { throw "Expected one bundled JDK 17.0.20+8 under the codex tool directories." }
    (Resolve-Path -LiteralPath $candidates[0]).Path
} else { (Resolve-Path -LiteralPath $JdkPath).Path }
$keytool = Join-Path $jdk "bin\keytool.exe"
$keystore = (Resolve-Path -LiteralPath $KeystorePath).Path
$credential = (Resolve-Path -LiteralPath $CredentialPath).Path
$expectedKeystoreSha256 = "2C3F4422CFA46D314C25B04984036BEC6DF3862E61CC68EBC5F83DD46B558C26"
$actualKeystoreSha256 = (Get-FileHash -LiteralPath $keystore -Algorithm SHA256).Hash.ToUpperInvariant()
if ($actualKeystoreSha256 -ne $expectedKeystoreSha256) { throw "The signing keystore does not match the pinned Weeko v3 key." }

if (!$VerifySigningKeyOnly) {
    $sdk = (Resolve-Path -LiteralPath $AndroidSdkPath).Path
    $buildTools = Join-Path $sdk "build-tools\36.0.0"
    $unsigned = if ([IO.Path]::IsPathRooted($UnsignedApkPath)) {
        (Resolve-Path -LiteralPath $UnsignedApkPath).Path
    } else { (Resolve-Path -LiteralPath (Join-Path $root $UnsignedApkPath)).Path }
    $release = Split-Path -Parent $unsigned
    $logs = Join-Path $release "release-logs"
    $aligned = Join-Path $release "Weeko-v1.1.4-release-aligned.apk"
    $final = Join-Path $release "Weeko-v1.1.4-release.apk"
    $compact = Join-Path $release "helper-v1-compact-unsigned.apk"

    foreach ($required in @(
        (Join-Path $buildTools "zipalign.exe"),
        (Join-Path $buildTools "apksigner.bat"),
        (Join-Path $buildTools "aapt2.exe")
    )) {
        if (!(Test-Path -LiteralPath $required)) { throw "Required Android signing tool is missing: $required" }
    }

    $badging = & (Join-Path $buildTools "aapt2.exe") dump badging $unsigned
    if ($LASTEXITCODE -ne 0) { throw "Unsigned APK metadata inspection failed." }
    if ($badging[0] -notmatch "^package: name='io.github.mxwf.weeko' versionCode='18' versionName='1.1.4'") {
        throw "Input APK package or version does not match v1.1.4."
    }
    $unsignedSignature = & (Join-Path $buildTools "apksigner.bat") verify --verbose $unsigned 2>&1
    if ($LASTEXITCODE -eq 0) { throw "Input candidate is already signed; expected the unsigned v1.1.4 APK." }
    if (Test-Path -LiteralPath $aligned) { throw "Aligned output already exists: $aligned" }
    if (Test-Path -LiteralPath $final) { throw "Release output already exists: $final" }
}

$securePassword = $null
$plainPassword = $null
$passwordPointer = [IntPtr]::Zero
$oldJavaHome = $env:JAVA_HOME
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

    $keytoolOutput = & $keytool -list -keystore $keystore -alias $KeyAlias -storepass:env WEEKO_SIGNING_PASSWORD 2>&1
    if ($LASTEXITCODE -ne 0) {
        $keytoolOutput | ForEach-Object { Write-Output $_ }
        throw "The pinned Weeko v3 key could not be opened; no replacement key will be generated."
    }
    if ($VerifySigningKeyOnly) {
        Write-Output "The existing Weeko v3 credential decrypted and its key alias opened."
        return
    }

    New-Item -ItemType Directory -Force -Path $logs | Out-Null
    & (Join-Path $buildTools "aapt2.exe") optimize --enable-compact-entries -o $compact $unsigned *> (Join-Path $logs "aapt2-optimize.log")
    if ($LASTEXITCODE -ne 0) { throw "Release APK resource compaction failed." }
    & (Join-Path $buildTools "zipalign.exe") -f -p 4 $compact $aligned *> (Join-Path $logs "zipalign.log")
    if ($LASTEXITCODE -ne 0) { throw "Release zip alignment failed; see release-logs\zipalign.log." }
    & (Join-Path $buildTools "apksigner.bat") sign --ks $keystore --ks-key-alias $KeyAlias --ks-pass env:WEEKO_SIGNING_PASSWORD --key-pass env:WEEKO_SIGNING_PASSWORD --out $final $aligned *> (Join-Path $logs "apksigner-sign.log")
    if ($LASTEXITCODE -ne 0) { throw "Release signing failed with the recorded key; see release-logs\apksigner-sign.log." }

    & (Join-Path $buildTools "zipalign.exe") -c -P 4 -v 4 $final *> (Join-Path $logs "zipalign-verify.log")
    if ($LASTEXITCODE -ne 0) { throw "Final release APK zip alignment verification failed." }
    $signatureOutput = & (Join-Path $buildTools "apksigner.bat") verify --verbose --print-certs $final 2>&1
    $signatureOutput | Set-Content -LiteralPath (Join-Path $logs "apksigner-verify.log") -Encoding UTF8
    if ($LASTEXITCODE -ne 0) { throw "Final release APK signature verification failed." }
    $certificateLine = $signatureOutput | Where-Object { $_ -match 'Signer #1 certificate SHA-256 digest:' } | Select-Object -First 1
    if ($null -eq $certificateLine) { throw "Final release signing certificate digest was not reported." }
    $certificateSha256 = ($certificateLine -split ':', 2)[1].Trim().ToUpperInvariant()
    if ($certificateSha256 -ne "E654E9A275921CB213CD0AE3EB5D8C35FD5DDE1C84E32F71D3B6D42EED328CD5") {
        throw "Final APK certificate does not match the pinned Weeko v3 release certificate."
    }

    $badging = & (Join-Path $buildTools "aapt2.exe") dump badging $final
    if ($LASTEXITCODE -ne 0) { throw "Final release APK metadata inspection failed." }
    $badging | Set-Content -LiteralPath (Join-Path $logs "apk-badging.txt") -Encoding UTF8
    if ($badging[0] -notmatch "^package: name='io.github.mxwf.weeko' versionCode='18' versionName='1.1.4'") {
        throw "Final APK package or version does not match v1.1.4."
    }

    $hash = (Get-FileHash -LiteralPath $final -Algorithm SHA256).Hash.ToUpperInvariant()
    $size = (Get-Item -LiteralPath $final).Length
    Set-Content -LiteralPath (Join-Path $release "v1.1.4-release-summary.txt") -Value @(
        "path=$final", "sha256=$hash", "size=$size", "package=io.github.mxwf.weeko",
        "versionCode=18", "versionName=1.1.4", "signingKey=$KeyAlias",
        "signingCertificateSha256=$certificateSha256", "keystoreSha256=$actualKeystoreSha256"
    ) -Encoding UTF8
    Write-Output "Signed release APK: $final"
    Write-Output "SHA-256 $hash"
} finally {
    if (Test-Path Env:WEEKO_SIGNING_PASSWORD) { Remove-Item Env:WEEKO_SIGNING_PASSWORD }
    $plainPassword = $null
    if ($passwordPointer -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
        $passwordPointer = [IntPtr]::Zero
    }
    if ($null -ne $securePassword) {
        $securePassword.Dispose()
        $securePassword = $null
    }
    $env:JAVA_HOME = $oldJavaHome
}
