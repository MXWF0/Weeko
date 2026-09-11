param(
    [Parameter(Mandatory = $true)] [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
$stage7 = Join-Path $root "tools\replay-weeko-v08-settings-stage7-patches.ps1"
& $pwsh -NoProfile -File $stage7 -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw "Stage 7 replay failed; v1.0.0 metadata was not applied." }

$metadataPath = Join-Path $project "apktool.yml"
$metadata = [IO.File]::ReadAllText($metadataPath)
$old = "  versionCode: 11`n  versionName: 0.8.0-settings-stage7"
$new = "  versionCode: 12`n  versionName: 1.0.0"
$normalized = $metadata.Replace("`r", "")
if ([regex]::Matches($normalized, [regex]::Escape($old)).Count -ne 1) {
    throw "Expected one Stage 7 version block in apktool.yml."
}
$normalized = $normalized.Replace($old, $new)
[IO.File]::WriteAllText($metadataPath, $normalized, [Text.UTF8Encoding]::new($false))

$privacyPath = Join-Path $project "smali\com\suda\yzune\wakeupschedule\utils\o00O0O.smali"
$privacy = [IO.File]::ReadAllText($privacyPath).Replace("`r", "")
$privacyPattern = '(?m)^    const-string v0, "Weeko .*0\.6\.0-test1 .*"$'
$privacyNew = '    const-string v0, "Weeko 课程表隐私与使用说明\n\nWeeko 将课程数据和大多数设置保存在当前设备。课程导入、在线分享和申请适配可能访问学校或旧版服务，请勿提交密码、Cookie、Token 或个人信息。关于页的更新检查仅访问 Weeko GitHub Releases API。\n\nv1.0.0 起 Weeko 使用新的长期正式签名，旧版本不能直接覆盖升级。迁移前请导出所有课表并确认备份可用，课表文件不等于完整应用备份。v1.0.0 后续版本沿用同一签名。"'
if ([regex]::Matches($privacy, $privacyPattern).Count -ne 1) {
    throw "Expected one legacy privacy notice in o00O0O.smali."
}
$privacy = [regex]::Replace($privacy, $privacyPattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $privacyNew })
[IO.File]::WriteAllText($privacyPath, $privacy, [Text.UTF8Encoding]::new($false))

$clubOlds = @(
    '<string name="wakeup_club">Weeko 过渡内测版</string>',
    '<string name="wakeup_club">Weeko 過渡內測版</string>'
)
$clubNew = '<string name="wakeup_club">Weeko 课程表</string>'
$clubReplacements = 0
foreach ($stringsPath in @(Get-ChildItem -LiteralPath (Join-Path $project "res") -Recurse -Filter "strings.xml")) {
    $strings = [IO.File]::ReadAllText($stringsPath.FullName)
    $count = 0
    foreach ($clubOld in $clubOlds) {
        $count += [regex]::Matches($strings, [regex]::Escape($clubOld)).Count
        $strings = $strings.Replace($clubOld, $clubNew)
    }
    if ($count -gt 0) {
        [IO.File]::WriteAllText($stringsPath.FullName, $strings, [Text.UTF8Encoding]::new($false))
        $clubReplacements += $count
    }
}
if ($clubReplacements -eq 0) { throw "Expected at least one legacy wakeup_club label." }
Write-Output "Applied Weeko v1.0.0 metadata and Stage 7 patches to $project"
