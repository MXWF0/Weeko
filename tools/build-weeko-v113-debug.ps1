param(
    [string] $BaseApktoolProject = "build\v0.6\repro-apktool",
    [string] $AndroidSdkPath = "E:\codex\Android\.tools\android-sdk",
    [string] $JdkPath = "",
    [string] $ApktoolJarPath = "E:\codex\Android\.tools\build\apktool_2.10.0.jar"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$source = Join-Path $root "tools\build-weeko-v112-debug.ps1"
$text = [IO.File]::ReadAllText($source)
$text = $text.Replace("build\v1.1.2", "build\v1.1.3")
$text = $text.Replace("replay-weeko-v112-patches.ps1", "replay-weeko-v113-patches.ps1")
$text = $text.Replace("versionCode=16", "versionCode=17")
$text = $text.Replace("versionCode: 16", "versionCode: 17")
$text = $text.Replace("versionCode=''16''", "versionCode=''17''")
$text = $text.Replace("1.1.2", "1.1.3")
$text = $text.Replace("v1.1.2", "v1.1.3")
$generated = Join-Path $root "tools\.build-weeko-v113-debug-generated.ps1"
[IO.File]::WriteAllText($generated, $text, [Text.UTF8Encoding]::new($false))
try {
    & (Get-Command pwsh.exe).Source -NoProfile -File $generated -BaseApktoolProject $BaseApktoolProject -AndroidSdkPath $AndroidSdkPath -JdkPath $JdkPath -ApktoolJarPath $ApktoolJarPath
    if ($LASTEXITCODE -ne 0) { throw "Weeko v1.1.3 debug build failed." }
} finally {
    if (Test-Path -LiteralPath $generated) { Remove-Item -LiteralPath $generated -Force }
}
