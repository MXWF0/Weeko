param(
    [string] $BaseApktoolProject = "build\v0.6\repro-apktool",
    [string] $AndroidSdkPath = "E:\codex\Android\.tools\android-sdk",
    [string] $JdkPath = "",
    [string] $ApktoolJarPath = "E:\codex\Android\.tools\build\apktool_2.10.0.jar"
)
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$stage5 = Join-Path $root "tools\build-weeko-v08-settings-stage5-debug.ps1"
$text = [IO.File]::ReadAllText($stage5).Replace("settings-stage5", "settings-stage6").Replace("versionCode=9", "versionCode=10").Replace("versionCode: 9", "versionCode: 10").Replace("versionCode='9'", "versionCode='10'").Replace("versionName=0.8.0-settings-stage5", "versionName=0.8.0-settings-stage6")
[IO.File]::WriteAllText((Join-Path $root "tools\.build-weeko-v08-settings-stage6-generated.ps1"), $text, [Text.UTF8Encoding]::new($false))
try { & (Get-Command pwsh.exe).Source -NoProfile -File (Join-Path $root "tools\.build-weeko-v08-settings-stage6-generated.ps1") -BaseApktoolProject $BaseApktoolProject -AndroidSdkPath $AndroidSdkPath -JdkPath $JdkPath -ApktoolJarPath $ApktoolJarPath; if ($LASTEXITCODE -ne 0) { throw "Stage 6 build failed." } } finally { Remove-Item -LiteralPath (Join-Path $root "tools\.build-weeko-v08-settings-stage6-generated.ps1") -Force }
