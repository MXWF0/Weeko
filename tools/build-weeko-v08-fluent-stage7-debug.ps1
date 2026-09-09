param(
    [string] $BaseApktoolProject = "build\v0.6\repro-apktool",
    [string] $AndroidSdkPath = "E:\codex\Android\.tools\android-sdk",
    [string] $JdkPath = "",
    [string] $ApktoolJarPath = "E:\codex\Android\.tools\build\apktool_2.10.0.jar"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$sdk = (Resolve-Path -LiteralPath $AndroidSdkPath).Path
$jdk = if ([string]::IsNullOrWhiteSpace($JdkPath)) {
    $jdkCandidates = @(Get-ChildItem -LiteralPath (Split-Path $root -Parent) -Directory | ForEach-Object {
        Join-Path $_.FullName ".tools\jdk-17.0.20+8"
    } | Where-Object { Test-Path -LiteralPath (Join-Path $_ "bin\java.exe") })
    if (@($jdkCandidates).Count -ne 1) { throw "Expected one bundled JDK 17.0.20+8 under the codex tools directories." }
    (Resolve-Path -LiteralPath $jdkCandidates[0]).Path
} else { (Resolve-Path -LiteralPath $JdkPath).Path }
$java = Join-Path $jdk "bin\java.exe"
$buildTools = Join-Path $sdk "build-tools\36.0.0"
$apktool = (Resolve-Path -LiteralPath $ApktoolJarPath).Path
$base = if ([IO.Path]::IsPathRooted($BaseApktoolProject)) {
    (Resolve-Path -LiteralPath $BaseApktoolProject).Path
} else { (Resolve-Path -LiteralPath (Join-Path $root $BaseApktoolProject)).Path }
$release = Join-Path $root "build\v0.8"
$project = Join-Path $release "repro-apktool-fluent-stage7"
$sourceDex = Join-Path $root "build\v0.6\source-dex\classes.dex"
$patchScript = Join-Path $root "tools\replay-weeko-v08-fluent-stage7-patches.ps1"
$unsigned = Join-Path $release "helper-fluent-stage7-unsigned.apk"
$aligned = Join-Path $release "Weeko-v0.7.0-fluent-stage7-debug-aligned.apk"
$final = Join-Path $release "Weeko-v0.7.0-fluent-stage7-debug.apk"
$debugKeystore = Join-Path $env:USERPROFILE ".android\debug.keystore"

foreach ($required in @($base, $sourceDex, $patchScript, $java, $apktool,
    (Join-Path $buildTools "zipalign.exe"), (Join-Path $buildTools "apksigner.bat"),
    (Join-Path $buildTools "aapt2.exe"), $debugKeystore)) {
    if (!(Test-Path -LiteralPath $required)) { throw "Required Fluent Stage 7 build input is missing: $required" }
}

New-Item -ItemType Directory -Force -Path $release | Out-Null
if (Test-Path -LiteralPath $project) { Remove-Item -LiteralPath $project -Recurse -Force }
Copy-Item -LiteralPath $base -Destination $project -Recurse -Force
$replayLog = Join-Path $release "fluent-stage7-replay.log"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $patchScript -ProjectPath $project *> $replayLog
if ($LASTEXITCODE -ne 0) { throw "Fluent Stage 7 patch replay failed; see $replayLog." }

if (Test-Path -LiteralPath $unsigned) { Remove-Item -LiteralPath $unsigned -Force }
& $java -jar $apktool b $project -o $unsigned -f *> (Join-Path $release "fluent-stage7-apktool-build.log")
if ($LASTEXITCODE -ne 0) { throw "Apktool rebuild failed." }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$inStream = [IO.File]::OpenRead($unsigned)
$inZip = [IO.Compression.ZipArchive]::new($inStream, [IO.Compression.ZipArchiveMode]::Read, $false)
$dexEntries = @($inZip.Entries | Where-Object { $_.FullName -match '^classes(\d*)\.dex$' })
$maxNumber = 1
foreach ($entry in $dexEntries) { if ($entry.Name -match '^classes(\d+)\.dex$' -and [int]$Matches[1] -gt $maxNumber) { $maxNumber = [int]$Matches[1] } }
$newName = "classes$($maxNumber + 1).dex"
$repacked = "$unsigned.repacked"
if (Test-Path -LiteralPath $repacked) { Remove-Item -LiteralPath $repacked -Force }
$outStream = [IO.File]::Open($repacked, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
$outZip = [IO.Compression.ZipArchive]::new($outStream, [IO.Compression.ZipArchiveMode]::Create, $false)
$fixedTimestamp = [DateTimeOffset]::new(1980, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
try {
    foreach ($entry in $inZip.Entries) {
        $level = if ($entry.FullName -eq "resources.arsc") { [IO.Compression.CompressionLevel]::NoCompression } else { [IO.Compression.CompressionLevel]::Optimal }
        $copy = $outZip.CreateEntry($entry.FullName, $level); $copy.LastWriteTime = $fixedTimestamp
        $input = $entry.Open(); try { $output = $copy.Open(); try { $input.CopyTo($output) } finally { $output.Dispose() } } finally { $input.Dispose() }
    }
    $newEntry = $outZip.CreateEntry($newName, [IO.Compression.CompressionLevel]::Optimal); $newEntry.LastWriteTime = $fixedTimestamp
    $input = [IO.File]::OpenRead($sourceDex); try { $output = $newEntry.Open(); try { $input.CopyTo($output) } finally { $output.Dispose() } } finally { $input.Dispose() }
} finally { $outZip.Dispose(); $outStream.Dispose(); $inZip.Dispose(); $inStream.Dispose() }
Move-Item -LiteralPath $repacked -Destination $unsigned -Force
Set-Content -LiteralPath (Join-Path $release "fluent-stage7-source-dex-injection.txt") -Value "Injected $sourceDex as $newName" -Encoding UTF8

if (Test-Path -LiteralPath $aligned) { Remove-Item -LiteralPath $aligned -Force }
& (Join-Path $buildTools "zipalign.exe") -f -p 4 $unsigned $aligned *> (Join-Path $release "fluent-stage7-zipalign.log")
if ($LASTEXITCODE -ne 0) { throw "Zip alignment failed." }
if (Test-Path -LiteralPath $final) { Remove-Item -LiteralPath $final -Force }
$env:JAVA_HOME = $jdk
& (Join-Path $buildTools "apksigner.bat") sign --ks $debugKeystore --ks-key-alias androiddebugkey --ks-pass pass:android --key-pass pass:android --out $final $aligned *> (Join-Path $release "fluent-stage7-apksigner-sign.log")
if ($LASTEXITCODE -ne 0) { throw "Debug signing failed." }
& (Join-Path $buildTools "zipalign.exe") -c -P 4 -v 4 $final *> (Join-Path $release "fluent-stage7-zipalign-verify.log")
if ($LASTEXITCODE -ne 0) { throw "Final zip alignment verification failed." }
$signatureOutput = & (Join-Path $buildTools "apksigner.bat") verify --verbose --print-certs $final 2>&1
$signatureOutput | Set-Content -LiteralPath (Join-Path $release "fluent-stage7-apksigner-verify.log") -Encoding UTF8
if ($LASTEXITCODE -ne 0) { throw "Final APK signature verification failed." }
$badging = & (Join-Path $buildTools "aapt2.exe") dump badging $final
if ($LASTEXITCODE -ne 0) { throw "APK metadata inspection failed." }
$badging | Set-Content -LiteralPath (Join-Path $release "fluent-stage7-apk-badging.txt") -Encoding UTF8
if ($badging[0] -notmatch "^package: name='io.github.mxwf.weeko' versionCode='7' versionName='0.7.0-fluent-stage7'") { throw "APK metadata does not match Fluent Stage 7." }

$hash = (Get-FileHash -LiteralPath $final -Algorithm SHA256).Hash.ToUpperInvariant()
$size = (Get-Item -LiteralPath $final).Length
Set-Content -LiteralPath (Join-Path $release "fluent-stage7-release-summary.txt") -Value @(
    "path=$final", "sha256=$hash", "size=$size", "package=io.github.mxwf.weeko",
    "versionCode=7", "versionName=0.7.0-fluent-stage7", "stage=fluent-stage7", "signing=androiddebug-debug"
) -Encoding UTF8
Write-Output "Built $final"
Write-Output "SHA-256 $hash"
