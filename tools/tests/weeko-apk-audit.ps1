param([string]$Apk = 'build\v1.1.5\Weeko-v1.1.5-release.apk')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $Apk).Path)
try {
    $entries = @($archive.Entries | ForEach-Object {
        $category = if ($_.FullName -match '^classes.*\.dex$') { 'DEX' }
            elseif ($_.FullName -match '^res/') { 'res' }
            elseif ($_.FullName -match '^assets/') { 'assets' }
            elseif ($_.FullName -match '^lib/') { 'lib' }
            elseif ($_.FullName -eq 'resources.arsc') { 'resource-table' }
            else { 'other' }
        [pscustomobject]@{ Category=$category; Path=$_.FullName; Bytes=$_.Length; Compressed=$_.CompressedLength }
    })
    "APK bytes: $((Get-Item -LiteralPath $Apk).Length)"
    $entries | Group-Object Category | ForEach-Object {
        [pscustomobject]@{ Category=$_.Name; Entries=$_.Count; Bytes=($_.Group | Measure-Object Bytes -Sum).Sum; Compressed=($_.Group | Measure-Object Compressed -Sum).Sum }
    } | Format-Table -AutoSize
    $entries | Sort-Object Compressed -Descending | Select-Object -First 20 | Format-Table -AutoSize
} finally { $archive.Dispose() }
