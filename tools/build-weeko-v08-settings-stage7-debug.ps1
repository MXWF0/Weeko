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
    if (@($jdkCandidates).Count -ne 1) { throw "Expected one bundled JDK 17.0.20+8 under the codex tool directories." }
    (Resolve-Path -LiteralPath $jdkCandidates[0]).Path
} else { (Resolve-Path -LiteralPath $JdkPath).Path }
$javac = Join-Path $jdk "bin\javac.exe"
$d8 = Join-Path $sdk "build-tools\36.0.0\d8.bat"
$androidJar = Join-Path $sdk "platforms\android-35\android.jar"
$sourceRoot = Join-Path $root "v06-source\src\main\java"
$sourceClasses = Join-Path $root "build\v0.6\source-classes-stage7"
$sourceDexOutput = Join-Path $root "build\v0.6\source-dex"
$sourceDex = Join-Path $sourceDexOutput "classes.dex"
$sourceFiles = @(Get-ChildItem -LiteralPath $sourceRoot -Recurse -Filter "*.java" | Select-Object -ExpandProperty FullName)
$release = Join-Path $root "build\v0.8"
New-Item -ItemType Directory -Force -Path $release | Out-Null
foreach ($required in @($javac, $d8, $androidJar, $sourceRoot)) {
    if (!(Test-Path -LiteralPath $required)) { throw "Required Stage 7 source-build input is missing: $required" }
}
if ($sourceFiles.Count -eq 0) { throw "No Weeko source files were found." }
if (Test-Path -LiteralPath $sourceClasses) { Remove-Item -LiteralPath $sourceClasses -Recurse -Force }
if (Test-Path -LiteralPath $sourceDexOutput) { Remove-Item -LiteralPath $sourceDexOutput -Recurse -Force }
New-Item -ItemType Directory -Force -Path $sourceClasses, $sourceDexOutput | Out-Null
$javacArgs = @("-encoding", "UTF-8", "-source", "8", "-target", "8", "-classpath", $androidJar, "-d", $sourceClasses) + $sourceFiles
& $javac @javacArgs *> (Join-Path $release "settings-stage7-source-javac.log")
if ($LASTEXITCODE -ne 0) { throw "Weeko source compilation failed." }
$classFiles = @(Get-ChildItem -LiteralPath $sourceClasses -Recurse -Filter "*.class" | Select-Object -ExpandProperty FullName)
$env:JAVA_HOME = $jdk
& $d8 --lib $androidJar --min-api 21 --output $sourceDexOutput @classFiles *> (Join-Path $release "settings-stage7-source-d8.log")
if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $sourceDex)) { throw "Weeko source dex compilation failed." }

$stage5 = Join-Path $root "tools\build-weeko-v08-settings-stage5-debug.ps1"
$text = [IO.File]::ReadAllText($stage5)
$text = $text.Replace("settings-stage5", "settings-stage7")
$text = $text.Replace("versionCode=9", "versionCode=11")
$text = $text.Replace("versionCode: 9", "versionCode: 11")
$text = $text.Replace("versionCode='9'", "versionCode='11'")
$text = $text.Replace("versionName=0.8.0-settings-stage5", "versionName=0.8.0-settings-stage7")
$text = $text.Replace("versionName 0.8.0-settings-stage5", "versionName 0.8.0-settings-stage7")
$text = $text.Replace("replay-weeko-v08-settings-stage5-patches.ps1", "replay-weeko-v08-settings-stage7-patches.ps1")
$generated = Join-Path $root "tools\.build-weeko-v08-settings-stage7-generated.ps1"
[IO.File]::WriteAllText($generated, $text, [Text.UTF8Encoding]::new($false))
try {
    & (Get-Command pwsh.exe).Source -NoProfile -File $generated -BaseApktoolProject $BaseApktoolProject -AndroidSdkPath $AndroidSdkPath -JdkPath $JdkPath -ApktoolJarPath $ApktoolJarPath
    if ($LASTEXITCODE -ne 0) { throw "Stage 7 APK build failed." }
} finally {
    if (Test-Path -LiteralPath $generated) { Remove-Item -LiteralPath $generated -Force }
}
