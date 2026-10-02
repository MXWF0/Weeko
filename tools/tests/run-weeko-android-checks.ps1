$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$jdk = Join-Path $root '.tools\jdk-17.0.20.1+1'
$sdk = 'E:\codex\tools\android-sdk'
$output = Join-Path $root 'build\v1.1.5\android-checks'
New-Item -ItemType Directory -Force -Path (Join-Path $output 'classes') | Out-Null
$sources = @(Get-ChildItem (Join-Path $root 'v06-source\src\main\java') -Recurse -Filter '*.java' | Select-Object -ExpandProperty FullName)
$sources += Join-Path $PSScriptRoot 'WeekoV115Stage1Checks.java'
$sources += Join-Path $PSScriptRoot 'WeekoGlassChecks.java'
& (Join-Path $jdk 'bin\javac.exe') -encoding UTF-8 -source 8 -target 8 -classpath (Join-Path $sdk 'platforms\android-35\android.jar') -d (Join-Path $output 'classes') @sources
if ($LASTEXITCODE -ne 0) { throw 'Android checks compilation failed' }
& (Join-Path $jdk 'bin\jar.exe') cf (Join-Path $output 'input.jar') -C (Join-Path $output 'classes') .
if ($LASTEXITCODE -ne 0) { throw 'Android checks JAR failed' }
$env:JAVA_HOME = $jdk
& (Join-Path $sdk 'build-tools\36.0.0\d8.bat') --lib (Join-Path $sdk 'platforms\android-35\android.jar') --min-api 21 --output (Join-Path $output 'checks.jar') (Join-Path $output 'input.jar')
if ($LASTEXITCODE -ne 0) { throw 'Android checks DEX failed' }
$adb = Join-Path $sdk 'platform-tools\adb.exe'
& $adb push (Join-Path $output 'checks.jar') /data/local/tmp/weeko-checks.jar
if ($LASTEXITCODE -ne 0) { throw 'Android checks push failed' }
foreach ($class in @('WeekoV115Stage1Checks','io.github.mxwf.weeko.popup.WeekoGlassChecks')) {
    & $adb shell "CLASSPATH=/data/local/tmp/weeko-checks.jar app_process /system/bin $class"
    if ($LASTEXITCODE -ne 0) { throw "Android checks failed: $class" }
}
