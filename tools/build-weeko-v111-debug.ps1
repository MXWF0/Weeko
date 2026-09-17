param(
    [string] $BaseApktoolProject = "build\v0.6\repro-apktool",
    [string] $AndroidSdkPath = "E:\codex\Android\.tools\android-sdk",
    [string] $JdkPath = "",
    [string] $ApktoolJarPath = "E:\codex\Android\.tools\build\apktool_2.10.0.jar"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$source = Join-Path $root "tools\build-weeko-v11-debug.ps1"
$text = [IO.File]::ReadAllText($source)
$text = $text.Replace("build\v1.1.0", "build\v1.1.1")
$text = $text.Replace("replay-weeko-v11-patches.ps1", "replay-weeko-v111-patches.ps1")
$text = $text.Replace("versionCode=14", "versionCode=15")
$text = $text.Replace("versionCode: 14", "versionCode: 15")
$text = $text.Replace("versionCode=''14''", "versionCode=''15''")
$text = $text.Replace("1.1.0", "1.1.1")
$text = $text.Replace("v1.1.0", "v1.1.1")
$generated = Join-Path $root "tools\.build-weeko-v111-debug-generated.ps1"
[IO.File]::WriteAllText($generated, $text, [Text.UTF8Encoding]::new($false))
try {
    & (Get-Command pwsh.exe).Source -NoProfile -File $generated -BaseApktoolProject $BaseApktoolProject -AndroidSdkPath $AndroidSdkPath -JdkPath $JdkPath -ApktoolJarPath $ApktoolJarPath
    if ($LASTEXITCODE -ne 0) { throw "Weeko v1.1.1 debug build failed." }
} finally {
    if (Test-Path -LiteralPath $generated) { Remove-Item -LiteralPath $generated -Force }
}
