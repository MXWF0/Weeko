param(
    [string] $BaseApktoolProject = "build\v0.6\repro-apktool",
    [string] $AndroidSdkPath = "E:\codex\Android\.tools\android-sdk",
    [string] $JdkPath = "",
    [string] $ApktoolJarPath = "E:\codex\Android\.tools\build\apktool_2.10.0.jar"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$stage7 = Join-Path $root "tools\build-weeko-v08-settings-stage7-debug.ps1"
$text = [IO.File]::ReadAllText($stage7)
$text = $text.Replace("build\v0.8", "build\v1.0")
$text = $text.Replace("replay-weeko-v08-settings-stage7-patches.ps1", "replay-weeko-v10-patches.ps1")
$text = $text.Replace("settings-stage7", "v1")
$text = $text.Replace("0.8.0-v1", "1.0.0")
$text = $text.Replace("versionCode=11", "versionCode=12")
$text = $text.Replace("versionCode: 11", "versionCode: 12")
$text = $text.Replace("versionCode='11'", "versionCode='12'")
$text = $text.Replace("versionName=0.8.0-settings-stage7", "versionName=1.0.0")
$text = $text.Replace("versionName 0.8.0-settings-stage7", "versionName 1.0.0")
$stage5ReleaseLine = '$text = [IO.File]::ReadAllText($stage5)'
$text = $text.Replace($stage5ReleaseLine, $stage5ReleaseLine + [Environment]::NewLine + '$text = $text.Replace("build\v0.8", "build\v1.0")')
$stage5PatchLine = '$text = $text.Replace("settings-stage5", "v1")'
$text = $text.Replace($stage5PatchLine, $stage5PatchLine + [Environment]::NewLine + '$text = $text.Replace("0.8.0-v1", "1.0.0")' + [Environment]::NewLine + '$text = $text.Replace("replay-weeko-v08-v1-patches.ps1", "replay-weeko-v10-patches.ps1")')
$generated = Join-Path $root "tools\.build-weeko-v10-debug-generated.ps1"
[IO.File]::WriteAllText($generated, $text, [Text.UTF8Encoding]::new($false))
try {
    & (Get-Command pwsh.exe).Source -NoProfile -File $generated -BaseApktoolProject $BaseApktoolProject -AndroidSdkPath $AndroidSdkPath -JdkPath $JdkPath -ApktoolJarPath $ApktoolJarPath
    if ($LASTEXITCODE -ne 0) { throw "Weeko v1.0.0 debug build failed." }
} finally {
    if (Test-Path -LiteralPath $generated) { Remove-Item -LiteralPath $generated -Force }
}
