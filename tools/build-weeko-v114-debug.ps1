param(
    [string] $BaseApktoolProject = "build\v0.6\repro-apktool",
    [string] $AndroidSdkPath = "E:\codex\tools\android-sdk",
    [string] $JdkPath = "",
    [string] $ApktoolJarPath = "E:\codex\tools\apktool_2.11.1.jar"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$source = Join-Path $root "tools\build-weeko-v113-debug.ps1"
$text = [IO.File]::ReadAllText($source)
$text = $text.Replace("build\v1.1.3", "build\v1.1.4")
$text = $text.Replace("replay-weeko-v113-patches.ps1", "replay-weeko-v114-patches.ps1")
$text = $text.Replace("versionCode=17", "versionCode=18")
$text = $text.Replace("versionCode: 17", "versionCode: 18")
$text = $text.Replace("versionCode=''17''", "versionCode=''18''")
$text = $text.Replace("1.1.3", "1.1.4")
$text = $text.Replace("v1.1.3", "v1.1.4")
$generated = Join-Path $root "tools\.build-weeko-v114-debug-generated.ps1"
[IO.File]::WriteAllText($generated, $text, [Text.UTF8Encoding]::new($false))
try {
    & (Get-Command pwsh.exe).Source -NoProfile -File $generated -BaseApktoolProject $BaseApktoolProject -AndroidSdkPath $AndroidSdkPath -JdkPath $JdkPath -ApktoolJarPath $ApktoolJarPath
    if ($LASTEXITCODE -ne 0) { throw "Weeko v1.1.4 debug build failed." }
} finally {
    if (Test-Path -LiteralPath $generated) { Remove-Item -LiteralPath $generated -Force }
}
