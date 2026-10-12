param([string] $ProjectPath = 'build/v1.2.0/repro-apktool-v1', [string] $PreviousPath = 'build/v1.1.5/repro-apktool-v1')
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
foreach ($entry in @(
    @{ Name='base'; Ids=@('rl_root','ll_course_name','et_name','sv_candidate_name','cg_candidate_name','ll_color','iv_color','tv_color','ll_credit','tv_credit','ll_note','tv_note') },
    @{ Name='detail'; Ids=@('tv_item','ib_delete','ll_weeks','et_weeks','ll_time','et_time','cb_own_time','ll_own_time','btn_start_time','btn_end_time','ll_teacher','et_teacher','ll_room','et_room','ll_note','tv_note') },
    @{ Name='footer'; Ids=@('tv_add') }
)) {
    [xml] $layout = [IO.File]::ReadAllText((Join-Path $root "tools/weeko-v120-add-$($entry.Name).xml"))
    $ids = @($layout.SelectNodes('//*') | ForEach-Object { $_.GetAttribute('id','http://schemas.android.com/apk/res/android') })
    foreach ($id in $entry.Ids) {
        if (@($ids | Where-Object { $_ -eq "@id/$id" }).Count -ne 1) { throw "Layout $($entry.Name) loses or duplicates $id" }
    }
    if ($layout.OuterXml -match 'maxLength|第1 - 18|酒店空间设计|博物馆空间设计') { throw 'Reference-only content became an input rule' }
    if ($entry.Name -in @('detail','footer') -and $layout.DocumentElement.GetAttribute('padding','http://schemas.android.com/apk/res/android')) { throw 'Nested horizontal card inset must not duplicate list padding' }
}
$unchanged = @('AddCourseActivity$saveData$1','AddCourseActivity$saveAndExit$1','AddCourseViewModel$initData$2','SelectTimeFragment','SelectWeekFragment','Oooo0')
foreach ($name in $unchanged) {
    $relative = "smali/com/suda/yzune/wakeupschedule/course_add/$name.smali"
    $old = [IO.File]::ReadAllText((Join-Path $root "$PreviousPath/$relative"))
    $new = [IO.File]::ReadAllText((Join-Path $root "$ProjectPath/$relative"))
    if ($old -ne $new) { throw "Business implementation changed: $name" }
}
$metadata = [IO.File]::ReadAllText((Join-Path $root "$ProjectPath/apktool.yml"))
if ($metadata -notmatch 'versionCode: 20' -or $metadata -notmatch 'versionName: 1.2.0') { throw 'Version metadata mismatch' }
$helper = [IO.File]::ReadAllText((Join-Path $root 'v06-source/src/main/java/io/github/mxwf/weeko/editor/AddCourseAppearanceV120.java'))
if ($helper -notmatch 'public static boolean isEditor\(Context context\)' -or
        $helper -notmatch 'if \(isEditor\(context\)\) style\(result\)' -or
        $helper -match 'isAdding\(') {
    throw 'Add and edit must share presentation and second-back discard'
}
$inline = [IO.File]::ReadAllText((Join-Path $root 'v06-source/src/main/java/io/github/mxwf/weeko/editor/CourseInlineFields.java'))
if ($helper -notmatch 'CourseInlineFields.backPrompt\(prompt\)' -or $inline -notmatch 'leave.performClick\(\)') { throw 'Second back must reuse the original discard destination' }
foreach ($binding in @('base', 'validate')) {
    if ([IO.File]::ReadAllText((Join-Path $root "$ProjectPath/smali/com/suda/yzune/wakeupschedule/course_add/AddCourseActivity.smali")) -notmatch "CourseInlineFields;->$binding\(") { throw "Missing inline $binding binding" }
}
foreach ($profile in @('baseline.prof', 'baseline.profm')) {
    if (Test-Path (Join-Path $root "$ProjectPath/assets/dexopt/$profile")) { throw "Stale original DEX profile still packaged: $profile" }
}
if ($helper -notmatch '"weeko_v120_add_footer"\), null\)' -or
        $helper -notmatch 'footer.setLayoutParams\(new ViewGroup.LayoutParams\(-1, -2\)\)') {
    throw 'Footer must not require a LayoutManager before editor data loads'
}
$activity = [IO.File]::ReadAllText((Join-Path $root "$ProjectPath/smali/com/suda/yzune/wakeupschedule/course_add/AddCourseActivity.smali"))
if ($activity -notmatch '->backPrompt\(Landroid/app/Activity;Landroid/app/Dialog;\)V') { throw 'Back prompt hook missing' }
if ($activity -notmatch '->isEditor\(Landroid/content/Context;\)Z') { throw 'Shared editor footer hook missing' }
Write-Output 'PASS: required control IDs, original save/viewmodel/selectors unchanged, shared add/edit appearance and second-back discard, v1.2.0 / 20.'
