param(
    [string] $BaseApktoolProject = 'build\v0.6\repro-apktool',
    [string] $AndroidSdkPath = 'E:\codex\tools\android-sdk',
    [string] $JdkPath = '',
    [string] $ApktoolJarPath = 'E:\codex\tools\apktool_2.11.1.jar'
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$text = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'build-weeko-v114-debug.ps1'))
$text = $text.Replace('build\v1.1.4', 'build\v1.2.1')
$text = $text.Replace('replay-weeko-v114-patches.ps1', 'replay-weeko-v121-patches.ps1')
$text = $text.Replace('versionCode=18', 'versionCode=21').Replace('versionCode: 18', 'versionCode: 21').Replace("versionCode=''18''", "versionCode=''21''")
$text = $text.Replace('1.1.4', '1.2.1')
$generated = Join-Path $PSScriptRoot '.build-weeko-v121-debug-generated.ps1'
[IO.File]::WriteAllText($generated, $text, [Text.UTF8Encoding]::new($false))
try {
    & (Get-Command pwsh.exe).Source -NoProfile -File $generated -BaseApktoolProject $BaseApktoolProject -AndroidSdkPath $AndroidSdkPath -JdkPath $JdkPath -ApktoolJarPath $ApktoolJarPath
    if ($LASTEXITCODE -ne 0) { throw 'Weeko v1.2.1 build failed' }
} finally { Remove-Item -LiteralPath $generated -Force }
