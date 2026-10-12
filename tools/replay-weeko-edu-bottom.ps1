param([Parameter(Mandatory=$true)][string]$ProjectPath)
$ErrorActionPreference='Stop'
$project=(Resolve-Path -LiteralPath $ProjectPath).Path
foreach ($variant in @('layout','layout-v22')) {
    $path=Join-Path $project "res/$variant/fragment_web_view_login.xml"
    [xml]$layout=[IO.File]::ReadAllText($path)
    $android='http://schemas.android.com/apk/res/android'
    $app='http://schemas.android.com/apk/res-auto'
    $ns=[Xml.XmlNamespaceManager]::new($layout.NameTable)
    $ns.AddNamespace('android',$android)
    $top=$layout.SelectSingleNode('//*[@android:id="@id/appbar_layout"]',$ns)
    $top.SetAttribute('paddingTop',$android,'0dp')
    $top.SetAttribute('paddingBottom',$android,'0dp')
    $url=$layout.SelectSingleNode('//*[@android:id="@id/et_url"]',$ns)
    $field=$url.ParentNode
    $field.SetAttribute('style','@style/Widget.Material3.TextInputLayout.OutlinedBox.Dense')
    $field.RemoveAttribute('hint',$android)
    $field.SetAttribute('hintEnabled',$app,'false')
    $field.SetAttribute('boxStrokeColor',$app,'@color/weeko_edu_url_stroke')
    $field.SetAttribute('layout_marginStart',$android,'8dp')
    foreach ($corner in @('TopStart','TopEnd','BottomStart','BottomEnd')) {
        $field.SetAttribute("boxCornerRadius$corner",$app,'12dp')
    }
    $url.SetAttribute('hint',$android,'在此输入教务网址')
    $url.SetAttribute('minHeight',$android,'44dp')
    $url.SetAttribute('textSize',$android,'15sp')
    $url.SetAttribute('paddingTop',$android,'6dp')
    $url.SetAttribute('paddingBottom',$android,'6dp')
    $url.SetAttribute('paddingStart',$android,'12dp')
    $url.SetAttribute('paddingEnd',$android,'12dp')
    $url.SetAttribute('scrollHorizontally',$android,'true')
    $bar=$layout.SelectSingleNode('//*[@android:id="@id/ll_bottom"]',$ns)
    $scroll=$bar.SelectSingleNode('HorizontalScrollView')
    $scroll.SetAttribute('layout_width',$android,'0dp')
    $scroll.SetAttribute('layout_weight',$android,'1')
    $scroll.SetAttribute('paddingEnd',$android,'8dp')
    $bar.SetAttribute('gravity',$android,'center_vertical')
    $group=$scroll.FirstChild
    $group.SetAttribute('singleLine',$app,'true')
    $group.SetAttribute('chipSpacingHorizontal',$app,'4dp')
    $group.SetAttribute('singleSelection',$app,'false')
    $mode=$layout.SelectSingleNode('//*[@android:id="@id/chip_mode"]',$ns)
    $vault=$layout.SelectSingleNode('//*[@android:id="@id/chip_password"]',$ns)
    foreach ($chip in @($mode,$vault)) {
        $chip.SetAttribute('style','@style/WeekoEduBottomChip')
        $chip.RemoveAttribute('layout_marginStart',$android)
    }
    $mode.SetAttribute('checkable',$android,'true')
    $help=$vault.CloneNode($true)
    $help.RemoveAttribute('id',$android)
    $help.SetAttribute('tag',$android,'weeko_edu_help')
    $help.SetAttribute('text',$android,'帮助')
    $group.AppendChild($help) | Out-Null
    $original=$layout.SelectSingleNode('//*[@android:id="@id/fab_tips"]',$ns)
    $original.SetAttribute('visibility',$android,'gone')
    $layout.Save($path)
}
New-Item -ItemType Directory -Force (Join-Path $project 'res/color') | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'weeko-edu-bottom-v120.xml') (Join-Path $project 'res/values/weeko_edu_bottom.xml')
foreach ($name in @('foreground','surface','ripple')) {
    Copy-Item (Join-Path $PSScriptRoot "weeko-edu-bottom-$name.xml") (Join-Path $project "res/color/weeko_edu_bottom_$name.xml")
}
Copy-Item (Join-Path $PSScriptRoot 'weeko-edu-url-stroke.xml') (Join-Path $project 'res/color/weeko_edu_url_stroke.xml')
$path=Join-Path $project 'smali/com/suda/yzune/wakeupschedule/schedule_import/WebViewLoginFragment.smali'
$code=[IO.File]::ReadAllText($path)
$target='    invoke-static {v1, v5}, Lkotlin/jvm/internal/OooOO0O;->OooO0o0(Ljava/lang/Object;Ljava/lang/String;)V'
$start=$code.IndexOf('.method public onViewCreated(')
$at=$code.IndexOf($target,$start)
if ($at -lt 0) {throw 'Missing original view binding entry'}
$at+=$target.Length
$code=$code.Insert($at,"`n    invoke-static {v1}, Lio/github/mxwf/weeko/import_ui/EduBottomBar;->bind(Landroid/view/View;)V")
[IO.File]::WriteAllText($path,$code,[Text.UTF8Encoding]::new($false))
