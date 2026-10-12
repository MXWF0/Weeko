param([string]$ProjectPath='build/v1.2.0/repro-apktool-v1')
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$nsUri='http://schemas.android.com/apk/res/android'
foreach ($variant in @('layout','layout-v22')) {
    [xml]$layout=[IO.File]::ReadAllText((Join-Path $root "$ProjectPath/res/$variant/fragment_web_view_login.xml"))
    $ns=[Xml.XmlNamespaceManager]::new($layout.NameTable)
    $ns.AddNamespace('android',$nsUri)
    $url=$layout.SelectSingleNode('//*[@android:id="@id/et_url"]',$ns)
    $field=$url.ParentNode
    if ($field.GetAttribute('hintEnabled','http://schemas.android.com/apk/res-auto') -ne 'false' -or
            $url.GetAttribute('hint',$nsUri) -ne '在此输入教务网址' -or
            $url.GetAttribute('singleLine',$nsUri) -ne 'true' -or
            $url.GetAttribute('scrollHorizontally',$nsUri) -ne 'true') {throw 'URL must use empty-only hint and single-line horizontal scrolling'}
    foreach ($corner in @('TopStart','TopEnd','BottomStart','BottomEnd')) {
        if ($field.GetAttribute("boxCornerRadius$corner",'http://schemas.android.com/apk/res-auto') -ne '12dp') {throw 'URL corners differ'}
    }
    foreach ($id in @('wv_course','et_url','fab_import','fab_tips','chip_mode','chip_password','btn_back')) {
        if ($layout.SelectNodes("//*[@android:id='@id/$id']",$ns).Count -ne 1) {throw "Missing/duplicate binding $variant $id"}
    }
    $bar=$layout.SelectSingleNode('//*[@android:id="@id/ll_bottom"]',$ns)
    $chips=$bar.SelectNodes('.//com.google.android.material.chip.Chip')
    if ($chips.Count -ne 3) {throw 'Expected three bottom actions'}
    foreach ($chip in $chips) {
        if ($chip.GetAttribute('style') -ne '@style/WeekoEduBottomChip') {throw 'Inconsistent action style'}
    }
    if ($layout.SelectSingleNode('//*[@android:id="@id/fab_tips"]',$ns).GetAttribute('visibility',$nsUri) -ne 'gone') {throw 'Old help FAB visible'}
    if (!$bar.SelectSingleNode('.//*[@android:tag="weeko_edu_help" and @android:text="帮助"]',$ns)) {throw 'Help missing in bottom bar'}
    if ($bar.SelectSingleNode('HorizontalScrollView').GetAttribute('layout_weight',$nsUri) -ne '1') {throw 'Scroll area may overflow'}
}
$bridge=[IO.File]::ReadAllText((Join-Path $root 'v06-source/src/main/java/io/github/mxwf/weeko/import_ui/EduBottomBar.java'))
if ($bridge -notmatch 'original.performClick\(\)' -or $bridge -match 'WebView|loadUrl|reload|PasswordVaultActivity') {throw 'UI bridge must reuse help without changing web/vault logic'}
$style=[xml][IO.File]::ReadAllText((Join-Path $root 'tools/weeko-edu-bottom-v120.xml'))
if ($style.SelectSingleNode('//item[@name="android:textSize"]').InnerText -ne '14sp') {throw 'Unexpected typography'}
if ($style.SelectSingleNode('//item[@name="chipIconVisible"]').InnerText -ne 'false' -or
        $style.SelectSingleNode('//item[@name="chipStrokeWidth"]')) {throw 'Use original outlined chips without icons'}
Write-Output 'PASS shared three-action style, responsive scroll, original help proxy and binding IDs; no web logic in bridge'
