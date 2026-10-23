param([string] $JdkPath = '.tools\jdk-17.0.20.1+1', [string] $OutputDirectory = 'effects-verification', [switch] $Formal)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$candidate = Join-Path $root "build/v1.2.1/$OutputDirectory"
if (Test-Path -LiteralPath $candidate) { throw "Verification output already exists: $candidate" }
New-Item -ItemType Directory -Path $candidate | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'build/v1.2.1/helper-v1-unsigned.apk') -Destination (Join-Path $candidate 'helper-v1-unsigned.apk')
$source = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'sign-weeko-v114-release.ps1'))
$source = $source.Replace('v1.1.4', 'v1.2.1').Replace('1.1.4', '1.2.1')
$source = $source.Replace("versionCode='18'", "versionCode='21'").Replace('versionCode=18', 'versionCode=21')
if (!$Formal) { $source = $source.Replace('Weeko-v1.2.1-release.apk', 'Weeko-v1.2.1-verification.apk') }
$generated = Join-Path $PSScriptRoot '.sign-weeko-v121-verification-generated.ps1'
[IO.File]::WriteAllText($generated, $source, [Text.UTF8Encoding]::new($false))
try {
    & (Get-Command pwsh.exe).Source -NoProfile -File $generated -UnsignedApkPath (Join-Path $candidate 'helper-v1-unsigned.apk') -JdkPath (Join-Path $root $JdkPath)
    if ($LASTEXITCODE -ne 0) { throw 'Weeko v1.2.1 verification signing failed' }
} finally { Remove-Item -LiteralPath $generated -Force }
