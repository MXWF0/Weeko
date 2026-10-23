param([string] $ProjectPath = 'build/v1.2.1/repro-apktool-v1')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$project = Join-Path $root $ProjectPath
$source = Join-Path $root 'v06-source/src/main/java/io/github/mxwf/weeko'
$policy = [IO.File]::ReadAllText((Join-Path $source 'theme/UiEffects.java'))
foreach ($pattern in @('SDK_INT >= 34', 'getBoolean\(PREDICTIVE_BACK, false\)',
        'getBoolean\(ADVANCED_MATERIALS, true\)', 'putBoolean\(key, checked\).commit\(\)', 'color \| 0xff000000')) {
    if ($policy -notmatch $pattern) { throw "Missing effects policy: $pattern" }
}
$motion = [IO.File]::ReadAllText((Join-Path $source 'navigation/LayeredPageTransition.java'))
if ($motion -match 'PRIORITY_OVERLAY') { throw 'App callbacks must not outrank IME back handling' }
foreach ($pattern in @('if \(UiEffects.predictiveBack\(activity\)\)', 'ordinaryBack = activity::onBackPressed',
        'unregisterOnBackInvokedCallback\(ordinaryBack\)', 'unregisterOnBackInvokedCallback\(backGesture\)',
        'registerOnSharedPreferenceChangeListener\(effectsChanged\)', 'DURATION = 320', 'DIM = 0.18f',
        'UiEffects.advancedMaterials\(getContext\(\)\)\s*\? .*?6f \* fraction : 0f',
        'SDK_INT < 31 && UiEffects.advancedMaterials')) {
    if ($motion -notmatch $pattern) { throw "Missing shared transition policy: $pattern" }
}
foreach ($file in @('popup/GlassDialogSurface.java','popup/GlassPopupBackground.java',
        'popup/CourseDetailBlurFallbackV115.java','vault/PasswordVaultActivity.java','schedule/WeekRailController.java')) {
    if ([IO.File]::ReadAllText((Join-Path $source $file)) -notmatch 'UiEffects.advancedMaterials') {
        throw "Material pipeline not gated: $file"
    }
}
[xml]$manifest = [IO.File]::ReadAllText((Join-Path $project 'AndroidManifest.xml'))
$ns = 'http://schemas.android.com/apk/res/android'
$editor = @($manifest.manifest.application.activity | Where-Object {$_.GetAttribute('name',$ns) -like '*.course_add.AddCourseActivity'})[0]
if ($editor.GetAttribute('enableOnBackInvokedCallback',$ns) -ne 'true') { throw 'Editor runtime callback cannot opt in' }
foreach ($name in @('TimeSettingsActivity','ScheduleManageActivity','ScheduleSettingsActivity','SchoolListActivity','LoginWebActivity','PasswordVaultActivity')) {
    $entry = @($manifest.manifest.application.activity | Where-Object {$_.GetAttribute('name',$ns).EndsWith('.'+$name)})[0]
    if ($entry.GetAttribute('enableOnBackInvokedCallback',$ns) -ne 'true') { throw "Page cannot opt in: $name" }
}
foreach ($pattern in @('base_view.BaseActivity', 'new BackGesture\(activity, null\)',
        'FragmentBackStack', 'stack.history.add\(capture\(\(ViewGroup\) target\)\)',
        'stack.current = target', 'stack.dispose\(\)', 'stack.resetPreview\(\)')) {
    if ($motion -notmatch $pattern) { throw "Shared predictive page coverage missing: $pattern" }
}
$frameworkBack = [IO.File]::ReadAllText((Join-Path $project 'smali/androidx/activity/Oooo000.smali'))
if ($frameworkBack -notmatch 'LayeredPageTransition;->frameworkBackRegistered\(Ljava/lang/Object;\)V') {
    throw 'NavHost can replace the shared native back callback'
}
$materialBack = [IO.File]::ReadAllText((Join-Path $project 'smali/o000o00.1/oo0o0Oo.smali'))
if ($materialBack -notmatch 'UiEffects;->predictiveBack' -or $materialBack -notmatch 'weeko_v121_material_plain_back') {
    throw 'Material sheets bypass predictive-back preference'
}
$vaultMotion = [IO.File]::ReadAllText((Join-Path $source 'vault/PasswordVaultActivity.java'))
if ($vaultMotion -notmatch 'UiEffects.predictiveBack\(this\) && sheetRoot != null\s*\? new VaultBackGesture' -or
        $vaultMotion -notmatch 'unregisterOnBackInvokedCallback\(systemBack\)' -or
        $vaultMotion -notmatch 'animateSheetRebound\(\)') { throw 'Vault predictive cancel/cleanup missing' }
if ($vaultMotion -notmatch '(?s)if \(backPreview\) \{\s*backPreview = false;\s*cancelSheetAnimation\(\);\s*sheetRoot.setTranslationY\(0f\);\s*sheetRoot.setAlpha\(1f\);\s*backdropFraction = 1f;') {
    throw 'Vault paused predictive gesture leaves partial alpha/backdrop progress on resume'
}
$settings = [IO.File]::ReadAllText((Join-Path $project 'smali/com/suda/yzune/wakeupschedule/settings/SettingsActivity.smali'))
foreach ($title in @('0x7f12024a','0x7f12024b')) {
    if ([regex]::Matches($settings,[regex]::Escape($title)).Count -ne 1) { throw "Switch duplicated or missing: $title" }
}
$details = [IO.File]::ReadAllText((Join-Path $project 'smali/com/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet.smali'))
if ($details -notmatch 'UiEffects;->advancedMaterials\(Landroid/content/Context;\)Z\s+move-result v8\s+if-eqz v8, :weeko_v114_skip_sheet_blur') {
    throw 'Course detail installs native blur/callbacks in solid mode'
}
$metadata = [IO.File]::ReadAllText((Join-Path $project 'apktool.yml'))
if ($metadata -notmatch 'versionCode: 21' -or $metadata -notmatch 'versionName: 1.2.1') { throw 'Version must be 1.2.1 / 21' }
# Compare business bytecode to the preserved v1.2.0 reconstruction, not a changed source checkout.
$previous = Join-Path $root 'build/v1.2.0/repro-apktool-v1/smali/com/suda/yzune/wakeupschedule'
$current = Join-Path $project 'smali/com/suda/yzune/wakeupschedule'
    foreach ($file in Get-ChildItem $previous -Recurse -File) {
        $relative = $file.FullName.Substring($previous.Length + 1)
        if ($relative -in @('settings\SettingsActivity.smali','settings\OooOOO.smali','schedule\CourseDetailBottomSheet.smali','schedule\OooOOO0.smali')) { continue }
        $new = Join-Path $current $relative
        $expected = [IO.File]::ReadAllText($file.FullName).Replace("`r", '')
        if ($relative -eq 'schedule\FluentSchedulePalette.smali') {
            $expected = $expected.Replace('    invoke-virtual {v0, p3}, Landroid/widget/TextView;->setTextColor(I)V',
                "    invoke-virtual {v0, p3}, Landroid/widget/TextView;->setTextColor(I)V`n    invoke-static {v0, p3}, Lio/github/mxwf/weeko/theme/SoftDynamicColors;->styleDateHighlight(Landroid/widget/TextView;I)V")
        }
        if (!(Test-Path -LiteralPath $new) -or $expected -cne [IO.File]::ReadAllText($new).Replace("`r", '')) {
            throw "Unrelated business bytecode changed: $relative"
        }
    }
$deleteMenu = [IO.File]::ReadAllText((Join-Path $current 'schedule/OooOOO0.smali'))
if ($deleteMenu -notmatch 'filled-new-array \{v6, v3\}, \[Ljava/lang/String;' -or
        $deleteMenu -match 'iput-object v6, v7, Landroidx/appcompat/app/OooO;->OooO0o:Ljava/lang/CharSequence;') {
    throw 'Delete confirmation must show the original first two scopes, without a message hiding its list'
}
$originalDelete = [IO.File]::ReadAllText((Join-Path $previous 'schedule/OooOOO0.smali')).Replace("`r",'')
$expectedDelete = $originalDelete.Replace('filled-new-array {v6, v3, v5}, [Ljava/lang/String;', 'filled-new-array {v6, v3}, [Ljava/lang/String;')
$expectedDelete = $expectedDelete.Replace(@'
    const v6, 0x7f1200d9
    invoke-virtual {v4, v6}, Landroidx/fragment/app/oo0o0Oo;->OooOOO(I)Ljava/lang/String;
    move-result-object v6
    iput-object v6, v7, Landroidx/appcompat/app/OooO;->OooO0o:Ljava/lang/CharSequence;
'@.Replace("`r",''), '')
if ($expectedDelete -cne $deleteMenu.Replace("`r",'')) { throw 'Delete dispatch changed beyond the two display edits' }
$vault = [IO.File]::ReadAllText((Join-Path $source 'vault/PasswordVaultActivity.java')).Replace("`r",'')
$oldVault = (git -C $root show HEAD:v06-source/src/main/java/io/github/mxwf/weeko/vault/PasswordVaultActivity.java) -join "`n"
foreach ($method in @('key','readRecords','writeRecords')) {
    $pattern = '(?ms)^    private [^\n]+\b' + $method + '\([^\n]*\).*?(?=^    private )'
    $before = [regex]::Match($oldVault,$pattern).Value.Trim()
    $after = [regex]::Match($vault,$pattern).Value.Trim()
    if (!$before -or $before -cne $after) { throw "Vault cryptography/storage changed: $method" }
}
Write-Output 'PASS static policy/defaults/persistence guards, shared callbacks/material gates, version and preserved business/crypto boundaries. Not a device interaction result.'
