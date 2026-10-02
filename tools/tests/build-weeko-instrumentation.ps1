$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$output = Join-Path $root 'build\v1.1.5\instrumentation'
$sdk = 'E:\codex\tools\android-sdk'
$jdk = Join-Path $root '.tools\jdk-17.0.20.1+1'
$buildTools = Join-Path $sdk 'build-tools\36.0.0'
$android = Join-Path $sdk 'platforms\android-35\android.jar'
New-Item -ItemType Directory -Force -Path (Join-Path $output 'classes'),(Join-Path $output 'dex') | Out-Null
& (Join-Path $jdk 'bin\javac.exe') -encoding UTF-8 -source 8 -target 8 -classpath $android -d (Join-Path $output 'classes') (Join-Path $PSScriptRoot 'instrumentation\WeekoUiChecks.java')
if ($LASTEXITCODE -ne 0) { throw 'Instrumentation compilation failed' }
& (Join-Path $jdk 'bin\jar.exe') cf (Join-Path $output 'input.jar') -C (Join-Path $output 'classes') .
if ($LASTEXITCODE -ne 0) { throw 'Instrumentation JAR failed' }
$env:JAVA_HOME = $jdk
& (Join-Path $buildTools 'd8.bat') --lib $android --min-api 23 --output (Join-Path $output 'dex') (Join-Path $output 'input.jar')
if ($LASTEXITCODE -ne 0) { throw 'Instrumentation DEX failed' }
$unsigned = Join-Path $output 'unsigned.apk'
& (Join-Path $buildTools 'aapt2.exe') link -I $android --manifest (Join-Path $PSScriptRoot 'instrumentation\AndroidManifest.xml') -o $unsigned
if ($LASTEXITCODE -ne 0) { throw 'Instrumentation resource link failed' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::Open($unsigned,[IO.Compression.ZipArchiveMode]::Update)
try { [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,(Join-Path $output 'dex\classes.dex'),'classes.dex') | Out-Null } finally { $zip.Dispose() }
$final = Join-Path $output 'weeko-local-checks.apk'
$credential = Import-Clixml -LiteralPath 'E:\codex\Weeko-signing\weeko-release-v3.credential.xml'
$passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)
try {
    $env:WEEKO_TEST_SIGNING_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
    & (Join-Path $buildTools 'apksigner.bat') sign --ks 'E:\codex\Weeko-signing\weeko-release-v3.p12' --ks-key-alias weeko-release-v3 --ks-pass env:WEEKO_TEST_SIGNING_PASSWORD --key-pass env:WEEKO_TEST_SIGNING_PASSWORD --out $final $unsigned
    if ($LASTEXITCODE -ne 0) { throw 'Instrumentation signing failed' }
} finally {
    Remove-Item Env:WEEKO_TEST_SIGNING_PASSWORD
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    $credential.Password.Dispose()
}
& (Join-Path $sdk 'platform-tools\adb.exe') install -r $final
if ($LASTEXITCODE -ne 0) { throw 'Instrumentation install failed' }
$testResult = & (Join-Path $sdk 'platform-tools\adb.exe') shell am instrument -w io.github.mxwf.weeko.tests/io.github.mxwf.weeko.tests.WeekoUiChecks
$testResult
if ($LASTEXITCODE -ne 0) { throw 'Instrumentation execution failed' }
if (($testResult -join "`n") -notmatch 'INSTRUMENTATION_RESULT: stream=PASS:') { throw 'Instrumentation did not pass' }
