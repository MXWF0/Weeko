.class public final Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;
.super Ljava/lang/Object;
.source "FluentTopBar.kt"


# Stage 4 keeps the existing command/menu callbacks and only applies the
# shared hit target, theme tint, and text treatment at the view boundary.
.method private constructor <init>()V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method private static resolveColor(Landroid/content/Context;I)I
    .locals 4

    const/4 v0, 0x1
    new-array v0, v0, [I
    const/4 v1, 0x0
    aput p1, v0, v1
    invoke-virtual {p0, v0}, Landroid/content/Context;->obtainStyledAttributes([I)Landroid/content/res/TypedArray;
    move-result-object v2
    invoke-virtual {v2, v1, v1}, Landroid/content/res/TypedArray;->getColor(II)I
    move-result v3
    invoke-virtual {v2}, Landroid/content/res/TypedArray;->recycle()V
    return v3
.end method

.method private static dp(Landroid/content/Context;I)I
    .locals 2

    invoke-virtual {p0}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;
    move-result-object v0
    invoke-virtual {v0}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
    move-result-object v0
    iget v0, v0, Landroid/util/DisplayMetrics;->density:F
    int-to-float v1, p1
    mul-float/2addr v0, v1
    float-to-int v0, v0
    return v0
.end method

.method private static styleCommand(Landroid/content/Context;Landroid/widget/ImageButton;Ljava/lang/String;I)V
    .locals 5

    const/16 v2, 0x30
    invoke-static {p0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v0
    invoke-virtual {p1}, Landroid/view/View;->getLayoutParams()Landroid/view/ViewGroup$LayoutParams;
    move-result-object v1
    iput v0, v1, Landroid/view/ViewGroup$LayoutParams;->width:I
    iput v0, v1, Landroid/view/ViewGroup$LayoutParams;->height:I
    invoke-virtual {p1, v1}, Landroid/view/View;->setLayoutParams(Landroid/view/ViewGroup$LayoutParams;)V
    invoke-virtual {p1, v0}, Landroid/view/View;->setMinimumWidth(I)V
    invoke-virtual {p1, v0}, Landroid/view/View;->setMinimumHeight(I)V

    const/16 v2, 0xc
    invoke-static {p0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v0
    invoke-virtual {p1, v0, v0, v0, v0}, Landroid/view/View;->setPadding(IIII)V
    invoke-virtual {p1, p2}, Landroid/view/View;->setContentDescription(Ljava/lang/CharSequence;)V
    invoke-static {p3}, Landroid/content/res/ColorStateList;->valueOf(I)Landroid/content/res/ColorStateList;
    move-result-object v0
    invoke-virtual {p1, v0}, Landroid/widget/ImageView;->setImageTintList(Landroid/content/res/ColorStateList;)V
    return-void
.end method

.method private static styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    .locals 3

    const/16 v2, 0x30
    invoke-static {p0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v0
    invoke-virtual {p1, v0}, Landroid/view/View;->setMinimumHeight(I)V
    const/16 v2, 0x8
    invoke-static {p0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v0
    const/4 v1, 0x0
    invoke-virtual {p1, v0, v1, v0, v1}, Landroid/view/View;->setPadding(IIII)V
    const/16 v0, 0x11
    invoke-virtual {p1, v0}, Landroid/widget/TextView;->setGravity(I)V
    invoke-virtual {p1, p2}, Landroid/widget/TextView;->setTextColor(I)V
    return-void
.end method

.method private static styleRail(Landroid/content/Context;Landroid/view/View;III)V
    .locals 7

    const v0, 0x7f0903b9
    invoke-virtual {p1, v0}, Landroid/view/View;->findViewById(I)Landroid/view/View;
    move-result-object v0
    check-cast v0, Landroid/widget/TextView;
    invoke-virtual {v0, p2}, Landroid/widget/TextView;->setTextColor(I)V

    const v1, 0x7f0903b8
    invoke-virtual {p1, v1}, Landroid/view/View;->findViewById(I)Landroid/view/View;
    move-result-object v1
    check-cast v1, Landroid/widget/SeekBar;
    invoke-static {p3}, Landroid/content/res/ColorStateList;->valueOf(I)Landroid/content/res/ColorStateList;
    move-result-object v2
    invoke-virtual {v1, v2}, Landroid/widget/ProgressBar;->setProgressTintList(Landroid/content/res/ColorStateList;)V
    invoke-virtual {v1, v2}, Landroid/widget/AbsSeekBar;->setThumbTintList(Landroid/content/res/ColorStateList;)V
    invoke-virtual {p1, v2}, Landroid/view/View;->setForegroundTintList(Landroid/content/res/ColorStateList;)V

    new-instance v3, Landroid/graphics/drawable/GradientDrawable;
    invoke-direct {v3}, Landroid/graphics/drawable/GradientDrawable;-><init>()V
    invoke-virtual {v3, p4}, Landroid/graphics/drawable/GradientDrawable;->setColor(I)V
    const/16 v5, 0xe6
    invoke-virtual {v3, v5}, Landroid/graphics/drawable/Drawable;->setAlpha(I)V
    const/16 v4, 0x10
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v4
    int-to-float v4, v4
    invoke-virtual {v3, v4}, Landroid/graphics/drawable/GradientDrawable;->setCornerRadius(F)V
    invoke-virtual {p1, v3}, Landroid/view/View;->setBackground(Landroid/graphics/drawable/Drawable;)V
    const/4 v4, 0x4
    invoke-static {p0, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->dp(Landroid/content/Context;I)I
    move-result v4
    int-to-float v4, v4
    invoke-virtual {p1, v4}, Landroid/view/View;->setElevation(F)V
    return-void
.end method

.method public static install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    .locals 10

    const v0, 0x7f040119
    invoke-static {p0, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->resolveColor(Landroid/content/Context;I)I
    move-result v0
    const v1, 0x7f040122
    invoke-static {p0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->resolveColor(Landroid/content/Context;I)I
    move-result v1
    const v2, 0x7f040132
    invoke-static {p0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->resolveColor(Landroid/content/Context;I)I
    move-result v2
    move v5, v2

    iget-object v2, p0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->Oooo00O:Landroidx/appcompat/widget/AppCompatImageButton;
    const-string v4, "打开导航"
    invoke-static {p0, v3, v4, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleCommand(Landroid/content/Context;Landroid/widget/ImageButton;Ljava/lang/String;I)V
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oo:Landroidx/appcompat/widget/AppCompatImageButton;
    const-string v4, "添加课程"
    invoke-static {p0, v3, v4, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleCommand(Landroid/content/Context;Landroid/widget/ImageButton;Ljava/lang/String;I)V
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO:Landroidx/appcompat/widget/AppCompatImageButton;
    const-string v4, "导入课程"
    invoke-static {p0, v3, v4, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleCommand(Landroid/content/Context;Landroid/widget/ImageButton;Ljava/lang/String;I)V
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOO0O:Landroidx/appcompat/widget/AppCompatImageButton;
    const-string v4, "更多操作"
    invoke-static {p0, v3, v4, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleCommand(Landroid/content/Context;Landroid/widget/ImageButton;Ljava/lang/String;I)V

    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o0:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V
    iget-object v3, v2, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oO:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-static {p0, v3, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleText(Landroid/content/Context;Landroid/widget/TextView;I)V

    const v4, 0x7f0903ba
    invoke-virtual {p0, v4}, Landroid/app/Activity;->findViewById(I)Landroid/view/View;
    move-result-object v4
    invoke-static {p0, v4, v0, v1, v5}, Lcom/suda/yzune/wakeupschedule/schedule/FluentTopBar;->styleRail(Landroid/content/Context;Landroid/view/View;III)V
    return-void
.end method
