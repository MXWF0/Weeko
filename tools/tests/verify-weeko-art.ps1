$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$bin = Join-Path $root '.tools\webp-1.4.0\libwebp-1.4.0-windows-x64\bin'
$assets = Join-Path $root 'tools\assets\weeko-v115'
New-Item -ItemType Directory -Force -Path $assets | Out-Null
foreach ($name in @('weeko_launcher_art','weeko_launcher_foreground_art','weeko_launcher_monochrome_art')) {
    $source = Join-Path $root "build\v1.1.5\repro-apktool-v1\res\drawable-nodpi\$name.png"
    $target = Join-Path $assets "$name.webp"
    $decoded = Join-Path $root "build\v1.1.5\$name-decoded.png"
    & (Join-Path $bin 'cwebp.exe') -quiet -lossless -exact -m 6 $source -o $target
    if ($LASTEXITCODE -ne 0) { throw 'Lossless WebP encoding failed' }
    & (Join-Path $bin 'dwebp.exe') -quiet $target -o $decoded
    if ($LASTEXITCODE -ne 0) { throw 'Lossless WebP decoding failed' }
    $original = [Drawing.Bitmap]::new($source)
    $restored = [Drawing.Bitmap]::new($decoded)
    try {
        if ($original.Size -ne $restored.Size) { throw 'Image dimensions changed' }
        $rect = [Drawing.Rectangle]::new(0,0,$original.Width,$original.Height)
        $left = $original.LockBits($rect,[Drawing.Imaging.ImageLockMode]::ReadOnly,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $right = $restored.LockBits($rect,[Drawing.Imaging.ImageLockMode]::ReadOnly,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $a = [byte[]]::new($left.Stride*$original.Height)
            $b = [byte[]]::new($right.Stride*$restored.Height)
            [Runtime.InteropServices.Marshal]::Copy($left.Scan0,$a,0,$a.Length)
            [Runtime.InteropServices.Marshal]::Copy($right.Scan0,$b,0,$b.Length)
            if ([Convert]::ToBase64String($a) -cne [Convert]::ToBase64String($b)) { throw "ARGB pixel mismatch: $name" }
        } finally { $original.UnlockBits($left); $restored.UnlockBits($right) }
        "PASS $name : original=$((Get-Item $source).Length) lossless=$((Get-Item $target).Length), ARGB pixels identical"
    } finally { $original.Dispose(); $restored.Dispose() }
}
