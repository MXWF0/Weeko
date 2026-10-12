param([string] $JdkPath = '.tools\jdk-17.0.20.1+1', [string] $OutputDirectory = 'formal-inline-fields-20261012')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$release = Join-Path $root "build/v1.2.0/$OutputDirectory"
if (Test-Path -LiteralPath $release) { throw "Release output already exists: $release" }
New-Item -ItemType Directory -Path $release | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'build/v1.2.0/helper-v1-unsigned.apk') -Destination (Join-Path $release 'helper-v1-unsigned.apk')
$source = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'sign-weeko-v114-release.ps1'))
$source = $source.Replace('v1.1.4', 'v1.2.0').Replace('1.1.4', '1.2.0')
$source = $source.Replace("versionCode='18'", "versionCode='20'").Replace('versionCode=18', 'versionCode=20')
$generated = Join-Path $PSScriptRoot '.sign-weeko-v120-release-generated.ps1'
[IO.File]::WriteAllText($generated, $source, [Text.UTF8Encoding]::new($false))
try {
    & (Get-Command pwsh.exe).Source -NoProfile -File $generated -UnsignedApkPath (Join-Path $release 'helper-v1-unsigned.apk') -JdkPath (Join-Path $root $JdkPath)
    if ($LASTEXITCODE -ne 0) { throw 'Weeko v1.2.0 release signing failed' }
} finally { Remove-Item -LiteralPath $generated -Force }
