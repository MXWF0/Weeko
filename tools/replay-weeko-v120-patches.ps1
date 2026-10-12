param([Parameter(Mandatory = $true)] [string] $ProjectPath)
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
& (Get-Command pwsh.exe).Source -NoProfile -File (Join-Path $PSScriptRoot 'replay-weeko-v115-patches.ps1') -ProjectPath $project
if ($LASTEXITCODE -ne 0) { throw 'v1.1.5 baseline replay failed' }
foreach ($name in @('base', 'detail', 'footer')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "weeko-v120-add-$name.xml") -Destination (Join-Path $project "res/layout/weeko_v120_add_$name.xml") -Force
}
function Replace-V120Text($relative, $old, $replacement) {
    $path = Join-Path $project $relative
    $text = [IO.File]::ReadAllText($path).Replace("`r", '')
    $old = $old.Replace("`r", '')
    if ([regex]::Matches($text, [regex]::Escape($old)).Count -ne 1) { throw "Expected one v1.2.0 patch target: $relative" }
    [IO.File]::WriteAllText($path, $text.Replace($old, $replacement.Replace("`r", '')), [Text.UTF8Encoding]::new($false))
}
Replace-V120Text 'apktool.yml' 'versionCode: 19' 'versionCode: 20'
Replace-V120Text 'apktool.yml' 'versionName: 1.1.5' 'versionName: 1.2.0'
Replace-V120Text 'AndroidManifest.xml' '<application android:allowBackup="true"' '<application android:enableOnBackInvokedCallback="false" android:allowBackup="true"'
$manifestPath = Join-Path $project 'AndroidManifest.xml'
$manifestText = [IO.File]::ReadAllText($manifestPath)
[xml]$manifest = $manifestText
$androidNamespace = 'http://schemas.android.com/apk/res/android'
foreach ($entry in $manifest.manifest.application.activity) {
    $name = $entry.GetAttribute('name', $androidNamespace)
    $type = $name
    while ($type.StartsWith('com.suda.yzune.wakeupschedule.') -or $type -eq 'io.github.mxwf.weeko.about.WeekoAboutActivity') {
        if ($type -eq 'com.suda.yzune.wakeupschedule.base_view.BaseListActivity' -or
                $type -eq 'io.github.mxwf.weeko.about.WeekoAboutActivity') {
            $pattern = '<activity\b[^>]*android:name="' + [regex]::Escape($name) + '"[^>]*>'
            $manifestText = [regex]::Replace($manifestText, $pattern, {
                param($match)
                $match.Value.Replace('<activity ', '<activity android:enableOnBackInvokedCallback="true" ')
            })
            break
        }
        $classPath = Join-Path $project ('smali/' + $type.Replace('.', '/') + '.smali')
        $super = [regex]::Match([IO.File]::ReadAllText($classPath), '(?m)^\.super L([^;]+);')
        if (!$super.Success) { throw "Missing Activity superclass: $type" }
        $type = $super.Groups[1].Value.Replace('/', '.')
    }
}
[IO.File]::WriteAllText($manifestPath, $manifestText, [Text.UTF8Encoding]::new($false))
$activity = 'smali/com/suda/yzune/wakeupschedule/course_add/AddCourseActivity.smali'
Replace-V120Text $activity 'invoke-virtual {v5, v6, v4}, Landroid/view/LayoutInflater;->inflate(ILandroid/view/ViewGroup;)Landroid/view/View;' 'invoke-static {v5, v6, v4}, Lio/github/mxwf/weeko/editor/AddCourseAppearanceV120;->inflate(Landroid/view/LayoutInflater;ILandroid/view/ViewGroup;)Landroid/view/View;'
Replace-V120Text 'smali/o0000oo0.2/OooOo00.smali' 'invoke-virtual {p2, v1, p1, v0}, Landroid/view/LayoutInflater;->inflate(ILandroid/view/ViewGroup;Z)Landroid/view/View;' 'invoke-static {p2, v1, p1, v0}, Lio/github/mxwf/weeko/editor/AddCourseAppearanceV120;->inflate(Landroid/view/LayoutInflater;ILandroid/view/ViewGroup;Z)Landroid/view/View;'
Replace-V120Text $activity @'
    invoke-static {v2, v5}, Lo0000oo0/OooOo00;->OooOOoo(Lo0000oo0/OooOo00;Landroid/view/View;)V
'@ @'
    invoke-static {v5, p1}, Lio/github/mxwf/weeko/editor/CourseInlineFields;->base(Landroid/view/View;Ljava/lang/Object;)V
    invoke-static {p0, v5}, Lio/github/mxwf/weeko/editor/AddCourseAppearanceV120;->header(Landroid/app/Activity;Landroid/view/View;)V
    invoke-static {v2, v5}, Lo0000oo0/OooOo00;->OooOOoo(Lo0000oo0/OooOo00;Landroid/view/View;)V
'@
Replace-V120Text $activity @'
    invoke-virtual {p1, p2}, Lcom/suda/yzune/wakeupschedule/bean/CourseBaseBean;->setColor(Ljava/lang/String;)V
'@ @'
    invoke-virtual {p1, p2}, Lcom/suda/yzune/wakeupschedule/bean/CourseBaseBean;->setColor(Ljava/lang/String;)V
    iget-object p1, p0, Lcom/suda/yzune/wakeupschedule/course_add/AddCourseActivity;->Oooo0o0:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {p1}, Landroid/widget/TextView;->getCurrentTextColor()I
    move-result p1
    invoke-static {p0, p1}, Lio/github/mxwf/weeko/editor/AddCourseAppearanceV120;->selectedColor(Landroid/app/Activity;I)V
'@
Replace-V120Text $activity @'
    invoke-static {p1, v0}, LOooo0oo/o00O00OO;->OooOOO0(Landroid/view/View;LOooo0oo/o000O00O;)V
'@ @'
    invoke-static {p1, v0}, LOooo0oo/o00O00OO;->OooOOO0(Landroid/view/View;LOooo0oo/o000O00O;)V
    invoke-static {p0}, Lio/github/mxwf/weeko/editor/AddCourseAppearanceV120;->isEditor(Landroid/content/Context;)Z
    move-result v0
    if-eqz v0, :weeko_v120_footer_done
    invoke-static {p0, p1}, Lio/github/mxwf/weeko/editor/AddCourseAppearanceV120;->footer(Landroid/app/Activity;Landroid/view/View;)Landroid/view/View;
    move-result-object p1
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/course_add/AddCourseActivity;->Oooo:Lcom/suda/yzune/wakeupschedule/course_add/OooOo;
    invoke-static {v0, p1}, Lo0000oo0/OooOo00;->OooOOo(Lo0000oo0/OooOo00;Landroid/view/View;)V
    :weeko_v120_footer_done
'@
Replace-V120Text 'smali/com/suda/yzune/wakeupschedule/course_add/OooOo.smali' @'
    :cond_4
    return-void
'@ @'
    :cond_4
    iget-object v0, p1, Landroidx/recyclerview/widget/oOO00O;->itemView:Landroid/view/View;
    invoke-virtual {p1}, Landroidx/recyclerview/widget/oOO00O;->getLayoutPosition()I
    move-result v1
    invoke-static {v0, v1}, Lio/github/mxwf/weeko/editor/AddCourseAppearanceV120;->detail(Landroid/view/View;I)V
    invoke-static {v0, p2, v1}, Lio/github/mxwf/weeko/editor/CourseInlineFields;->detail(Landroid/view/View;Ljava/lang/Object;I)V
    return-void
'@
Replace-V120Text 'smali/com/suda/yzune/wakeupschedule/course_add/o00Ooo.smali' @'
    invoke-virtual {p1, p3}, Lo0000oo0/OooOo00;->Oooo00o(I)V
'@ @'
    invoke-virtual {p1, p3}, Lo0000oo0/OooOo00;->Oooo00o(I)V
    invoke-static {v4}, Lio/github/mxwf/weeko/editor/AddCourseAppearanceV120;->isEditor(Landroid/content/Context;)Z
    move-result p2
    if-eqz p2, :weeko_v120_renumber_done
    iget-object p2, p1, Lo0000oo0/OooOo00;->OooO0o0:Ljava/util/List;
    invoke-interface {p2}, Ljava/util/List;->size()I
    move-result p2
    const/4 p3, 0x1
    invoke-virtual {p1, p3, p2}, Lo0000oo0/OooOo00;->OooO0oO(II)V
    :weeko_v120_renumber_done
'@
Replace-V120Text 'smali/com/suda/yzune/wakeupschedule/course_add/AddCourseActivity$initHeaderView$1.smali' @'
    invoke-virtual {v0, v3}, Landroid/view/ViewGroup;->addView(Landroid/view/View;)V
'@ @'
    invoke-static {v3}, Lio/github/mxwf/weeko/editor/AddCourseAppearanceV120;->chip(Landroid/view/View;)V
    invoke-virtual {v0, v3}, Landroid/view/ViewGroup;->addView(Landroid/view/View;)V
'@
Replace-V120Text 'smali/com/suda/yzune/wakeupschedule/course_add/OooOo00.smali' @'
    invoke-virtual {p1, p3, p3, p3, p2}, Landroid/graphics/Rect;->set(IIII)V
'@ @'
    invoke-virtual {p1, p3, p3, p3, p2}, Landroid/graphics/Rect;->set(IIII)V
    iget-object p2, p0, Lcom/suda/yzune/wakeupschedule/course_add/OooOo00;->OooO0O0:Ljava/lang/Object;
    check-cast p2, Landroid/app/Activity;
    invoke-static {p2, p1}, Lio/github/mxwf/weeko/editor/AddCourseAppearanceV120;->spacing(Landroid/app/Activity;Landroid/graphics/Rect;)V
'@
Replace-V120Text 'smali/androidx/fragment/app/OooO0OO.smali' @'
    :cond_1
    return-object v0
'@ @'
    :cond_1
    invoke-static {v0, p0}, Lio/github/mxwf/weeko/editor/AddCourseAppearanceV120;->inputDialog(Landroid/app/Dialog;Ljava/lang/Object;)V
    return-object v0
'@
Replace-V120Text $activity @'
    :cond_0
    invoke-virtual {v0}, LOooOoO0/o00000O;->OooO0oO()Landroidx/appcompat/app/OooOOO;
'@ @'
    :cond_0
    invoke-virtual {v0}, LOooOoO0/o00000O;->OooO0oO()Landroidx/appcompat/app/OooOOO;
    move-result-object v0
    invoke-static {p0, v0}, Lio/github/mxwf/weeko/editor/AddCourseAppearanceV120;->backPrompt(Landroid/app/Activity;Landroid/app/Dialog;)V
'@
Replace-V120Text 'smali/com/suda/yzune/wakeupschedule/course_add/OooOo.smali' @'
    :pswitch_1
    check-cast p2, Lcom/suda/yzune/wakeupschedule/bean/CourseEditBean;
'@ @'
    :pswitch_1
    iget-object v3, p1, Landroidx/recyclerview/widget/oOO00O;->itemView:Landroid/view/View;
    invoke-static {v3}, Lio/github/mxwf/weeko/editor/CourseInlineFields;->unbind(Landroid/view/View;)V
    check-cast p2, Lcom/suda/yzune/wakeupschedule/bean/CourseEditBean;
'@
foreach ($kind in @(0, 1)) {
    $suffix = $kind + 5
    $relative = 'smali/com/suda/yzune/wakeupschedule/course_add/AddCourseActivity$initAdapter$1$' + $suffix + '.smali'
    $type = 'Lcom/suda/yzune/wakeupschedule/course_add/AddCourseActivity$initAdapter$1$' + $suffix + ';'
    $dialogRegister = if ($kind -eq 0) { 'v2' } else { 'v3' }
    $kindRegister = if ($kind -eq 0) { 'v3' } else { 'v2' }
    Replace-V120Text $relative "    invoke-virtual {$dialogRegister, p1, v0}, Landroidx/fragment/app/o0OoOo0;->OoooOOo(Landroidx/fragment/app/o0000OO0;Ljava/lang/String;)V" @"
    iget-object p1, p0, ${type}->this`$0:Lcom/suda/yzune/wakeupschedule/course_add/AddCourseActivity;
    iget v0, p0, ${type}->`$position:I
    const/4 $kindRegister, 0x$kind
    invoke-static {p1, $dialogRegister, v0, $kindRegister}, Lio/github/mxwf/weeko/editor/CourseInlineFields;->recommendations(Landroid/app/Activity;Ljava/lang/Object;II)V
"@
}
Replace-V120Text 'smali/com/suda/yzune/wakeupschedule/course_add/OooOo.smali' @'
    move-result-object p2

    .line 407
    invoke-virtual {p1, v0, p2}, Lcom/chad/library/adapter/base/viewholder/BaseViewHolder;->setText(ILjava/lang/CharSequence;)Lcom/chad/library/adapter/base/viewholder/BaseViewHolder;
'@ @'
    move-result-object v1

    .line 407
    invoke-virtual {p1, v0, v1}, Lcom/chad/library/adapter/base/viewholder/BaseViewHolder;->setText(ILjava/lang/CharSequence;)Lcom/chad/library/adapter/base/viewholder/BaseViewHolder;
'@
Replace-V120Text $activity @'
.method public final OooOoO0()V
    .locals 4
'@ @'
.method public final OooOoO0()V
    .locals 4
    invoke-static {p0}, Lio/github/mxwf/weeko/editor/CourseInlineFields;->validate(Landroid/app/Activity;)Z
    move-result v0
    if-nez v0, :weeko_inline_save_valid
    return-void
    :weeko_inline_save_valid
'@
Replace-V120Text 'smali/com/suda/yzune/wakeupschedule/settings/TimeSettingsActivity.smali' @'
    invoke-virtual {v0}, LOooOoO0/o00000O;->OooO0oO()Landroidx/appcompat/app/OooOOO;
'@ @'
    invoke-virtual {v0}, LOooOoO0/o00000O;->OooO0oO()Landroidx/appcompat/app/OooOOO;
    move-result-object v0
    invoke-static {v0}, Lio/github/mxwf/weeko/editor/CourseInlineFields;->backPrompt(Landroid/app/Dialog;)V
'@
# These ART profiles belong to the original DEX, not the rebuilt overlay DEX.
# Keep the baseline intact and remove only its incompatible packaging assets.
foreach ($profile in @('baseline.prof', 'baseline.profm')) {
    $path = Join-Path $project "assets/dexopt/$profile"
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path }
}
Write-Output 'Applied shared v1.2.0 inline course fields and existing discard actions; removed stale original DEX profiles.'
