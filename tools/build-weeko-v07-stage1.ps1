param(
    [switch] $VerifySigningKeyOnly,
    [Parameter(Mandatory = $true)]
    [string] $KeystorePath,
    [Parameter(Mandatory = $true)]
    [string] $AndroidSdkPath,
    [Parameter(Mandatory = $true)]
    [string] $JdkPath,
    [Parameter(Mandatory = $true)]
    [string] $ApktoolJarPath,
    [string] $BaseApktoolProject = "build\v0.6\repro-apktool",
    [string] $KeyAlias = "weeko-release-v2",
    [string] $CredentialPath
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$sdk = (Resolve-Path -LiteralPath $AndroidSdkPath).Path
$jdk = (Resolve-Path -LiteralPath $JdkPath).Path
$java = Join-Path $jdk "bin\java.exe"
$keytool = Join-Path $jdk "bin\keytool.exe"
$apktoolJar = (Resolve-Path -LiteralPath $ApktoolJarPath).Path
$buildTools = Join-Path $sdk "build-tools\36.0.0"
$baseApktoolProject = if ([IO.Path]::IsPathRooted($BaseApktoolProject)) {
    (Resolve-Path -LiteralPath $BaseApktoolProject).Path
} else {
    (Resolve-Path -LiteralPath (Join-Path $root $BaseApktoolProject)).Path
}
$release = Join-Path $root "build\v0.7"
$logs = Join-Path $release "logs"
$baseline = Join-Path $root "build\v0.6\Weeko-v0.6.0-test1.apk"
$sourceDex = Join-Path $root "build\v0.6\source-dex\classes.dex"
$patchScript = Join-Path $root "tools\replay-weeko-v07-stage1-patches.ps1"
$apktoolProject = Join-Path $release "repro-apktool"
$unsigned = Join-Path $release "Weeko-v0.7.0-stage1-unsigned.apk"
$aligned = Join-Path $release "Weeko-v0.7.0-stage1-aligned.apk"
$final = Join-Path $release "Weeko-v0.7.0-stage1.apk"
$keystore = if ([IO.Path]::IsPathRooted($KeystorePath)) { $KeystorePath } else { Join-Path $root $KeystorePath }
$credentialFile = if ([string]::IsNullOrWhiteSpace($CredentialPath)) {
    $null
} elseif ([IO.Path]::IsPathRooted($CredentialPath)) {
    $CredentialPath
} else {
    Join-Path $root $CredentialPath
}

foreach ($required in @($baseline, $sourceDex, $keystore, $keytool, $patchScript, $apktoolJar)) {
    if (!(Test-Path -LiteralPath $required)) { throw "Required v0.7 build input is missing: $required" }
}

$expectedKeystoreSha256 = "55BAF3F146013658A1E5ED4E0F0ADEC7AE27C5E8A8E1403E4424271430806888"
$actualKeystoreSha256 = (Get-FileHash -LiteralPath $keystore -Algorithm SHA256).Hash.ToUpperInvariant()
if ($actualKeystoreSha256 -ne $expectedKeystoreSha256) {
    throw "The signing keystore is not the pinned Weeko release key: $actualKeystoreSha256"
}
$expectedBaselineSha256 = "3A4F0E8C11727B8A0A3DB0A31C752490F0CC5DFB2D6C58B8D248C27474B6D5B1"
$actualBaselineSha256 = (Get-FileHash -LiteralPath $baseline -Algorithm SHA256).Hash.ToUpperInvariant()
if ($actualBaselineSha256 -ne $expectedBaselineSha256) {
    throw "The v0.6 behavior baseline hash does not match the recorded release: $actualBaselineSha256"
}

$securePassword = $null
$plainPassword = $null
$passwordPointer = [IntPtr]::Zero
try {
    if ($null -ne $credentialFile) {
        if (!(Test-Path -LiteralPath $credentialFile)) { throw "The DPAPI-protected signing credential was not found: $credentialFile" }
        $managedCredential = Import-Clixml -LiteralPath $credentialFile
        if ($managedCredential.UserName -cne $KeyAlias) { throw "The managed signing credential alias does not match $KeyAlias." }
        $securePassword = $managedCredential.Password
        $managedCredential = $null
    } else {
        $securePassword = Read-Host "Weeko signing password" -AsSecureString
    }
    $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
    $env:WEEKO_SIGNING_PASSWORD = $plainPassword
    $plainPassword = $null
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    $passwordPointer = [IntPtr]::Zero

    $env:JAVA_HOME = $jdk
    & $keytool -list -keystore $keystore -alias $KeyAlias -storepass:env WEEKO_SIGNING_PASSWORD
    if ($LASTEXITCODE -ne 0) { throw "The pinned Weeko release key could not be opened; no replacement key will be generated." }
    if ($VerifySigningKeyOnly) {
        Write-Output "The recorded Weeko signing key is available."
        return
    }

    New-Item -ItemType Directory -Force -Path $release, $logs | Out-Null
    if (Test-Path -LiteralPath $apktoolProject) { Remove-Item -LiteralPath $apktoolProject -Recurse -Force }
    Copy-Item -LiteralPath $baseApktoolProject -Destination $apktoolProject -Recurse -Force
    & (Join-Path $PSHOME "powershell.exe") -NoProfile -ExecutionPolicy Bypass -File $patchScript -ProjectPath $apktoolProject *> (Join-Path $logs "patch-replay.log")
    if ($LASTEXITCODE -ne 0) { throw "v0.7 Stage 1 patch replay failed; see logs/patch-replay.log." }
    Set-Content -LiteralPath (Join-Path $logs "apktool-source.txt") -Value @(
        "baseProject=$baseApktoolProject",
        "baseProjectApktoolYmlSha256=$((Get-FileHash -LiteralPath (Join-Path $baseApktoolProject 'apktool.yml') -Algorithm SHA256).Hash.ToUpperInvariant())",
        "replayedProject=$apktoolProject",
        "stage=1"
    ) -Encoding UTF8

    if (Test-Path -LiteralPath $unsigned) { Remove-Item -LiteralPath $unsigned -Force }
    & $java -jar $apktoolJar b $apktoolProject -o $unsigned -f *> (Join-Path $logs "apktool-build.log")
    if ($LASTEXITCODE -ne 0) { throw "apktool rebuild failed; see logs/apktool-build.log." }

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $inStream = [IO.File]::OpenRead($unsigned)
    $inZip = [IO.Compression.ZipArchive]::new($inStream, [IO.Compression.ZipArchiveMode]::Read, $false)
    $inDexEntries = @($inZip.Entries | Where-Object { $_.FullName -match '^classes(\d*)\.dex$' })
    $maxNumber = 1
    foreach ($entry in $inDexEntries) {
        if ($entry.Name -match '^classes(\d+)\.dex$') {
            $number = [int]$Matches[1]
            if ($number -gt $maxNumber) { $maxNumber = $number }
        }
    }
    $newName = "classes$($maxNumber + 1).dex"
    $repacked = "$unsigned.repacked"
    if (Test-Path -LiteralPath $repacked) { Remove-Item -LiteralPath $repacked -Force }
    $outStream = [IO.File]::Open($repacked, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $outZip = [IO.Compression.ZipArchive]::new($outStream, [IO.Compression.ZipArchiveMode]::Create, $false)
    $fixedZipTimestamp = [DateTimeOffset]::new(1980, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
    try {
        foreach ($entry in $inZip.Entries) {
            $level = if ($entry.FullName -eq "resources.arsc") { [IO.Compression.CompressionLevel]::NoCompression } else { [IO.Compression.CompressionLevel]::Optimal }
            $copy = $outZip.CreateEntry($entry.FullName, $level)
            $copy.LastWriteTime = $fixedZipTimestamp
            $input = $entry.Open()
            try {
                $output = $copy.Open()
                try { $input.CopyTo($output) } finally { $output.Dispose() }
            } finally { $input.Dispose() }
        }
        $newEntry = $outZip.CreateEntry($newName, [IO.Compression.CompressionLevel]::Optimal)
        $newEntry.LastWriteTime = $fixedZipTimestamp
        $input = [IO.File]::OpenRead($sourceDex)
        try {
            $output = $newEntry.Open()
            try { $input.CopyTo($output) } finally { $output.Dispose() }
        } finally { $input.Dispose() }
    } finally {
        $outZip.Dispose(); $outStream.Dispose(); $inZip.Dispose(); $inStream.Dispose()
    }
    Move-Item -LiteralPath $repacked -Destination $unsigned -Force
    Set-Content -LiteralPath (Join-Path $logs "source-dex-injection.txt") -Value "Injected independently compiled Weeko v0.6 source dex as $newName" -Encoding UTF8

    if (Test-Path -LiteralPath $aligned) { Remove-Item -LiteralPath $aligned -Force }
    & (Join-Path $buildTools "zipalign.exe") -f -p 4 $unsigned $aligned *> (Join-Path $logs "zipalign.log")
    if ($LASTEXITCODE -ne 0) { throw "zipalign failed; see logs/zipalign.log." }
    if (Test-Path -LiteralPath $final) { Remove-Item -LiteralPath $final -Force }
    & (Join-Path $buildTools "apksigner.bat") sign --ks $keystore --ks-key-alias $KeyAlias --ks-pass env:WEEKO_SIGNING_PASSWORD --key-pass env:WEEKO_SIGNING_PASSWORD --out $final $aligned *> (Join-Path $logs "apksigner-sign.log")
    if ($LASTEXITCODE -ne 0) { throw "APK signing failed with the recorded key; see logs/apksigner-sign.log." }

    & (Join-Path $buildTools "zipalign.exe") -c -P 4 -v 4 $final *> (Join-Path $logs "zipalign-verify.log")
    if ($LASTEXITCODE -ne 0) { throw "Final APK zip alignment verification failed." }
    $signatureOutput = & (Join-Path $buildTools "apksigner.bat") verify --verbose --print-certs $final 2>&1
    $signatureOutput | Set-Content -LiteralPath (Join-Path $logs "apksigner-verify.log") -Encoding UTF8
    if ($LASTEXITCODE -ne 0) { throw "Final APK signature verification failed." }
    $certificateLine = $signatureOutput | Where-Object { $_ -match 'Signer #1 certificate SHA-256 digest:' } | Select-Object -First 1
    if ($null -eq $certificateLine) { throw "Final signing certificate digest was not reported." }
    $certificateSha256 = ($certificateLine -split ':', 2)[1].Trim().ToUpperInvariant()
    if ($certificateSha256 -ne "E114CA20A1DD4726E83FF511C290AD30278D37E09703AB1BC788405BBC759E21") { throw "Final APK certificate does not match the permanent Weeko v2 certificate." }

    $badging = & (Join-Path $buildTools "aapt2.exe") dump badging $final
    if ($LASTEXITCODE -ne 0) { throw "APK metadata inspection failed." }
    $badging | Set-Content -LiteralPath (Join-Path $logs "apk-badging.txt") -Encoding UTF8
    if ($badging[0] -notmatch "^package: name='io.github.mxwf.weeko' versionCode='7' versionName='0.7.0-stage1'") { throw "Actual APK package or version does not match v0.7 Stage 1." }

    $finalHash = (Get-FileHash -LiteralPath $final -Algorithm SHA256).Hash.ToUpperInvariant()
    $finalSize = (Get-Item -LiteralPath $final).Length
    Set-Content -LiteralPath (Join-Path $logs "release-summary.txt") -Value @(
        "path=$final",
        "sha256=$finalHash",
        "size=$finalSize",
        "package=io.github.mxwf.weeko",
        "versionCode=7",
        "versionName=0.7.0-stage1",
        "signingKey=$KeyAlias",
        "signingCertificateSha256=$certificateSha256",
        "keystoreSha256=$actualKeystoreSha256",
        "stage=1"
    ) -Encoding UTF8
    Write-Output "Built $final"
    Write-Output "SHA-256 $finalHash"
} finally {
    if (Test-Path Env:WEEKO_SIGNING_PASSWORD) { Remove-Item Env:WEEKO_SIGNING_PASSWORD }
    $plainPassword = $null
    if ($passwordPointer -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer); $passwordPointer = [IntPtr]::Zero }
    if ($null -ne $securePassword) { $securePassword.Dispose(); $securePassword = $null }
}
