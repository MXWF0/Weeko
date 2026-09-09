param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path

function Replace-ExactText {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Old,
        [Parameter(Mandatory = $true)] [string] $New
    )
    $path = Join-Path $project $RelativePath
    if (!(Test-Path -LiteralPath $path)) { throw "Patch input is missing: $RelativePath" }
    $original = [IO.File]::ReadAllText($path)
    $lineEnding = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $content = $original.Replace("`r`n", "`n")
    $oldLf = $Old.Replace("`r`n", "`n")
    $newLf = $New.Replace("`r`n", "`n")
    $first = $content.IndexOf($oldLf, [StringComparison]::Ordinal)
    if ($first -lt 0) { throw "Expected original text was not found in $RelativePath" }
    $second = $content.IndexOf($oldLf, $first + $oldLf.Length, [StringComparison]::Ordinal)
    if ($second -ge 0) { throw "Expected original text occurs more than once in $RelativePath" }
    $updated = $content.Remove($first, $oldLf.Length).Insert($first, $newLf)
    if ($lineEnding -eq "`r`n") { $updated = $updated.Replace("`n", "`r`n") }
    [IO.File]::WriteAllText($path, $updated, [Text.UTF8Encoding]::new($false))
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)] [string] $RelativePath,
        [Parameter(Mandatory = $true)] [string] $Content
    )
    $path = Join-Path $project $RelativePath
    [IO.File]::WriteAllText($path, $Content.Replace("`r`n", "`n"), [Text.UTF8Encoding]::new($false))
}

Replace-ExactText "apktool.yml" @'
  versionCode: 6
  versionName: 0.6.0-test1
'@ @'
  versionCode: 7
  versionName: 0.7.0-stage1
'@

Replace-ExactText "res/values/public.xml" @'
    <public type="drawable" name="week_widget_preview" id="0x7f080140" />
'@ @'
    <public type="drawable" name="week_widget_preview" id="0x7f080140" />
    <public type="drawable" name="weeko_nav_menu" id="0x7f080141" />
'@
Replace-ExactText "res/values/public.xml" @'
    <public type="id" name="x_right" id="0x7f0903b6" />
'@ @'
    <public type="id" name="x_right" id="0x7f0903b6" />
    <public type="id" name="weeko_nav_left" id="0x7f0903b7" />
'@
Replace-ExactText "res/values/public.xml" @'
    <public type="string" name="week_widget_description" id="0x7f120239" />
'@ @'
    <public type="string" name="week_widget_description" id="0x7f120239" />
    <public type="string" name="weeko_nav_share" id="0x7f12023a" />
'@

Replace-ExactText "res/values/strings.xml" @'
</resources>
'@ @'
    <string name="weeko_nav_share">Share</string>
</resources>
'@
Replace-ExactText "res/values-zh-rCN/strings.xml" @'
</resources>
'@ @'
    <string name="weeko_nav_share">分享</string>
</resources>
'@

Write-Utf8NoBom "res/drawable/weeko_nav_menu.xml" @'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="?colorControlNormal">
    <path
        android:fillColor="@android:color/white"
        android:pathData="M3,6h18v2H3zM3,11h18v2H3zM3,16h18v2H3z" />
</vector>
'@

Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    const/16 v2, 0x8

    .line 6
    .line 7
    const/4 v3, 0x7

    .line 8
    const/4 v4, 0x6

    .line 9
    const/4 v5, 0x5

    .line 10
    const/4 v6, 0x3

    .line 11
    const/4 v7, 0x4
'@ @'
    const/16 v2, 0x8

    .line 6
    .line 7
    const/4 v3, 0x7

    .line 8
    const/4 v4, 0x6

    .line 9
    const/4 v5, 0x5

    .line 10
    const/4 v6, 0x3

    .line 11
    const/16 v7, 0xc
'@

Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    iget-object v12, v12, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0O:Landroidx/appcompat/widget/AppCompatImageButton;

    .line 186
    .line 187
    new-instance v15, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;

    .line 188
    .line 189
    invoke-direct {v15, v0, v7}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    .line 190
    .line 191
    .line 192
    invoke-virtual {v12, v15}, Landroid/view/View;->setOnClickListener(Landroid/view/View$OnClickListener;)V
'@ @'
    iget-object v12, v12, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0O:Landroidx/appcompat/widget/AppCompatImageButton;

    new-instance v15, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;

    invoke-direct {v15, v0, v7}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    invoke-virtual {v12, v15}, Landroid/view/View;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    iget-object v12, v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;

    iget-object v12, v12, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->Oooo00O:Landroidx/appcompat/widget/AppCompatImageButton;

    new-instance v15, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;

    invoke-direct {v15, v0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    invoke-virtual {v12, v15}, Landroid/view/View;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    const-string v14, "has_intro"

    .line 223
    .line 224
    iget-object v12, v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;
'@

Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    return-void
.end method


# virtual methods
'@ @'
    return-void
.end method

.method public static final stage1ShowRightMenu(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;Landroid/view/View;)V
    .locals 7

    move-object/from16 v0, p0
    move-object/from16 v1, p1

    const/4 v4, 0x0
    const/4 v5, 0x3
    invoke-static {v1, v4, v5}, Lcom/suda/yzune/wakeupschedule/utils/OooO0o;->OooO0OO(Landroid/view/View;II)Lme/saket/cascade/OooOO0;
    move-result-object v1

    iget-object v2, v1, Lme/saket/cascade/OooOO0;->OooO0oo:LOooOO0/o00O0O;

    const v3, 0x7f120225
    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;
    move-result-object v3
    check-cast v3, LOooOO0/o00Ooo;
    const v4, 0x7f0800e2
    invoke-virtual {v3, v4}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;
    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    const/16 v5, 0xb
    invoke-direct {v4, v0, v5}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
    invoke-interface {v3, v4}, Landroid/view/MenuItem;->setOnMenuItemClickListener(Landroid/view/MenuItem$OnMenuItemClickListener;)Landroid/view/MenuItem;

    const v3, 0x7f12023a
    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;
    move-result-object v3
    check-cast v3, LOooOO0/o00Ooo;
    const v4, 0x7f0800c1
    invoke-virtual {v3, v4}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;
    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    const/16 v5, 0xc
    invoke-direct {v4, v0, v5}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
    invoke-interface {v3, v4}, Landroid/view/MenuItem;->setOnMenuItemClickListener(Landroid/view/MenuItem$OnMenuItemClickListener;)Landroid/view/MenuItem;

    const v3, 0x7f120228
    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;
    move-result-object v3
    check-cast v3, LOooOO0/o00Ooo;
    const v4, 0x7f0800c0
    invoke-virtual {v3, v4}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;
    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    const/16 v5, 0xd
    invoke-direct {v4, v0, v5}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
    invoke-interface {v3, v4}, Landroid/view/MenuItem;->setOnMenuItemClickListener(Landroid/view/MenuItem$OnMenuItemClickListener;)Landroid/view/MenuItem;

    const v3, 0x7f120219
    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;
    move-result-object v3
    check-cast v3, LOooOO0/o00Ooo;
    const v4, 0x7f0800b5
    invoke-virtual {v3, v4}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;
    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    const/16 v5, 0xe
    invoke-direct {v4, v0, v5}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
    invoke-interface {v3, v4}, Landroid/view/MenuItem;->setOnMenuItemClickListener(Landroid/view/MenuItem$OnMenuItemClickListener;)Landroid/view/MenuItem;

    invoke-static {v1}, Lme/saket/cascade/OooOO0;->OooO00o(Lme/saket/cascade/OooOO0;)V
    return-void
.end method


# virtual methods
'@

Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    iget v11, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;->OooO0oO:I

    .line 34
    .line 35
    packed-switch v11, :pswitch_data_0
'@ @'
    iget v11, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;->OooO0oO:I

    const/16 v0, 0xc

    if-eq v11, v0, :stage1_right_menu

    .line 34
    .line 35
    packed-switch v11, :pswitch_data_0

    goto :stage1_existing_default

    :stage1_right_menu
    invoke-static {v13, v1}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;->stage1ShowRightMenu(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;Landroid/view/View;)V

    return-void

    :stage1_existing_default
'@

Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;

    .line 65
    .line 66
    const/16 v5, 0x8

    .line 67
    .line 68
    invoke-direct {v4, v13, v5}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    .line 69
    .line 70
    .line 71
    invoke-interface {v3, v4}, Landroid/view/MenuItem;->setOnMenuItemClickListener(Landroid/view/MenuItem$OnMenuItemClickListener;)Landroid/view/MenuItem;
'@ @'
    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;

    .line 65
    .line 66
    const/16 v5, 0x8

    .line 67
    .line 68
    invoke-direct {v4, v13, v5}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    .line 69
    .line 70
    .line 71
    invoke-interface {v3, v4}, Landroid/view/MenuItem;->setOnMenuItemClickListener(Landroid/view/MenuItem$OnMenuItemClickListener;)Landroid/view/MenuItem;

    const v3, 0x7f120225

    invoke-virtual {v2, v3}, LOooOO0/o00O0O;->add(I)Landroid/view/MenuItem;

    move-result-object v3

    check-cast v3, LOooOO0/o00Ooo;

    const v4, 0x7f0800e2

    invoke-virtual {v3, v4}, LOooOO0/o00Ooo;->setIcon(I)Landroid/view/MenuItem;

    new-instance v4, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;

    const/16 v5, 0xb

    invoke-direct {v4, v13, v5}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    invoke-interface {v3, v4}, Landroid/view/MenuItem;->setOnMenuItemClickListener(Landroid/view/MenuItem$OnMenuItemClickListener;)Landroid/view/MenuItem;

    .line 74
    .line 75
    .line 76
    invoke-virtual {v13}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;
'@

Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o0OOO0o.smali" @'
    iget v8, p0, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;->OooO00o:I

    .line 15
    .line 16
    packed-switch v8, :pswitch_data_0
'@ @'
    iget v8, p0, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;->OooO00o:I

    const/16 v0, 0xb

    if-eq v8, v0, :stage1_schedule_manage

    const/16 v0, 0xc

    if-eq v8, v0, :stage1_share

    const/16 v0, 0xd

    if-eq v8, v0, :stage1_settings

    const/16 v0, 0xe

    if-eq v8, v0, :stage1_about

    const-string v0, "tableId"

    .line 15
    .line 16
    packed-switch v8, :pswitch_data_0
'@

Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o0OOO0o.smali" @'
    :pswitch_data_0
    .packed-switch 0x0
'@ @'
    :stage1_schedule_manage
    sget v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OoooOoO:I

    invoke-static {p1, v7}, Lkotlin/jvm/internal/OooOO0O;->OooO0o0(Ljava/lang/Object;Ljava/lang/String;)V

    new-instance p1, Landroid/content/Intent;

    const-class v0, Lcom/suda/yzune/wakeupschedule/schedule_manage/ScheduleManageActivity;

    invoke-direct {p1, v6, v0}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V

    invoke-virtual {v6}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;

    move-result-object v0

    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0()Lcom/suda/yzune/wakeupschedule/bean/TableBean;

    move-result-object v0

    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/bean/TableBean;->getId()I

    move-result v0

    const-string v1, "selectedTableId"

    invoke-virtual {p1, v1, v0}, Landroid/content/Intent;->putExtra(Ljava/lang/String;I)Landroid/content/Intent;

    iget-object v0, v6, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->o000oOoO:LOooO0OO/OooO0o;

    invoke-virtual {v0, p1}, LOooO0OO/OooO0o;->OooO00o(Ljava/lang/Object;)V

    return v5

    :stage1_share
    sget v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OoooOoO:I

    invoke-static {p1, v7}, Lkotlin/jvm/internal/OooOO0O;->OooO0o0(Ljava/lang/Object;Ljava/lang/String;)V

    iget-object v0, v6, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;

    iget-object v0, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0:Landroidx/appcompat/widget/AppCompatImageButton;

    new-instance v1, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;

    const/4 v2, 0x6

    invoke-direct {v1, v6, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    invoke-virtual {v1, v0}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;->onClick(Landroid/view/View;)V

    return v5

    :stage1_settings
    sget v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OoooOoO:I

    invoke-static {p1, v7}, Lkotlin/jvm/internal/OooOO0O;->OooO0o0(Ljava/lang/Object;Ljava/lang/String;)V

    new-instance p1, Landroid/content/Intent;

    const-class v0, Lcom/suda/yzune/wakeupschedule/settings/SettingsActivity;

    invoke-direct {p1, v6, v0}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V

    iget-object v0, v6, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->o000oOoO:LOooO0OO/OooO0o;

    invoke-virtual {v0, p1}, LOooO0OO/OooO0o;->OooO00o(Ljava/lang/Object;)V

    return v5

    :stage1_about
    sget v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OoooOoO:I

    invoke-static {p1, v7}, Lkotlin/jvm/internal/OooOO0O;->OooO0o0(Ljava/lang/Object;Ljava/lang/String;)V

    new-instance p1, Landroid/content/Intent;

    const-class v0, Lcom/suda/yzune/wakeupschedule/intro/AboutActivity;

    invoke-direct {p1, v6, v0}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V

    invoke-virtual {v6, p1}, Landroid/content/Context;->startActivity(Landroid/content/Intent;)V

    return v5

    :pswitch_data_0
    .packed-switch 0x0
'@

Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali" @'
.field public final OooO00o:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;

.field public final OooO0O0:Ljava/lang/Object;
'@ @'
.field public final OooO00o:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;

.field public final Oooo00O:Landroidx/appcompat/widget/AppCompatImageButton;

.field public final OooO0O0:Ljava/lang/Object;
'@

Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali" @'
    iput-object v2, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0O:Landroidx/appcompat/widget/AppCompatImageButton;

    .line 239
    .line 240
    new-instance v3, Landroidx/constraintlayout/widget/ConstraintLayout;
'@ @'
    iput-object v2, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0O:Landroidx/appcompat/widget/AppCompatImageButton;

    const-string v5, "更多操作"

    invoke-virtual {v2, v5}, Landroid/view/View;->setContentDescription(Ljava/lang/CharSequence;)V

    new-instance v15, Landroidx/appcompat/widget/AppCompatImageButton;

    invoke-direct {v15, v1}, Landroidx/appcompat/widget/AppCompatImageButton;-><init>(Landroid/content/Context;)V

    const v5, 0x7f0903b7

    invoke-virtual {v15, v5}, Landroid/view/View;->setId(I)V

    const v5, 0x7f080141

    invoke-virtual {v15, v5}, Landroidx/appcompat/widget/AppCompatImageButton;->setImageResource(I)V

    invoke-virtual {v15, v3}, Landroidx/appcompat/widget/AppCompatImageButton;->setBackgroundResource(I)V

    const-string v5, "打开导航"

    invoke-virtual {v15, v5}, Landroid/view/View;->setContentDescription(Ljava/lang/CharSequence;)V

    iput-object v15, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->Oooo00O:Landroidx/appcompat/widget/AppCompatImageButton;

    .line 239
    .line 240
    new-instance v3, Landroidx/constraintlayout/widget/ConstraintLayout;
'@

Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali" @'
    const/16 v8, 0x10

    .line 298
    .line 299
    int-to-float v8, v8
'@ @'
    const/16 v8, 0x40

    .line 298
    .line 299
    int-to-float v8, v8
'@

Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali" @'
    iput-object v3, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0o:Landroidx/constraintlayout/widget/ConstraintLayout;

    .line 679
    .line 680
    new-instance v2, Landroidx/recyclerview/widget/RecyclerView;
'@ @'
    iget-object v15, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->Oooo00O:Landroidx/appcompat/widget/AppCompatImageButton;

    new-instance v5, Landroidx/constraintlayout/widget/ConstraintLayout$LayoutParams;

    invoke-virtual {v15}, Landroid/view/View;->getContext()Landroid/content/Context;

    move-result-object v4

    invoke-virtual {v4}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;

    move-result-object v4

    invoke-virtual {v4}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;

    move-result-object v4

    iget v4, v4, Landroid/util/DisplayMetrics;->density:F

    const/16 v7, 0x20

    int-to-float v7, v7

    mul-float v4, v4, v7

    float-to-int v4, v4

    move v7, v4

    invoke-direct {v5, v4, v4}, Landroidx/constraintlayout/widget/ConstraintLayout$LayoutParams;-><init>(II)V

    const/4 v4, 0x0

    iput v4, v5, Landroidx/constraintlayout/widget/ConstraintLayout$LayoutParams;->OooOo00:I

    const v4, 0x7f090080

    iput v4, v5, Landroidx/constraintlayout/widget/ConstraintLayout$LayoutParams;->OooO:I

    const v4, 0x7f0900ac

    iput v4, v5, Landroidx/constraintlayout/widget/ConstraintLayout$LayoutParams;->OooOO0o:I

    shr-int/lit8 v7, v7, 0x1

    invoke-virtual {v5, v7}, Landroid/view/ViewGroup$MarginLayoutParams;->setMarginStart(I)V

    invoke-virtual {v3, v15, v5}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    iput-object v3, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0o:Landroidx/constraintlayout/widget/ConstraintLayout;

    .line 679
    .line 680
    new-instance v2, Landroidx/recyclerview/widget/RecyclerView;
'@

Replace-ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali" @'
    .line 581
    invoke-virtual {v5, v7}, Landroid/view/ViewGroup$MarginLayoutParams;->setMarginEnd(I)V

    .line 582
    .line 583
    .line 584
    invoke-virtual {v3, v15, v5}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V
'@ @'
    .line 581
    invoke-virtual {v5, v7}, Landroid/view/ViewGroup$MarginLayoutParams;->setMarginEnd(I)V

    .line 582
    .line 583
    .line 584
    iget-object v15, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0:Landroidx/appcompat/widget/AppCompatImageButton;

    invoke-virtual {v3, v15, v5}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V
'@

Write-Output "Applied v0.7 Stage 1 navigation resources and layout patch to $project"
