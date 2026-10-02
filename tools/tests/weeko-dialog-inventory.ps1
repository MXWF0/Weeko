$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$project = Join-Path $root 'build\v1.1.5\repro-apktool-v1'
$pattern = 'new-instance[^\r\n]+Landroid/(app/(AlertDialog(\$Builder)?|Dialog|ProgressDialog)|widget/PopupWindow);|->show(AtLocation|AsDropDown)\('
$matches = foreach ($directory in Get-ChildItem -LiteralPath $project -Directory -Filter 'smali*') {
    foreach ($file in Get-ChildItem -LiteralPath $directory.FullName -Recurse -File -Filter '*.smali') {
        $text = [IO.File]::ReadAllText($file.FullName)
        $hits = [regex]::Matches($text, $pattern)
        if ($hits.Count) {
            [pscustomobject]@{ File=[IO.Path]::GetRelativePath($project,$file.FullName); Calls=($hits.Value -join '; ') }
        }
    }
}
$matches | Export-Csv -LiteralPath (Join-Path $root 'build\v1.1.5\dialog-inventory.csv') -Encoding UTF8 -NoTypeInformation
$matches | Format-Table -Wrap -AutoSize
