.class public final Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
.super Landroid/widget/FrameLayout;
.source "FluentWeekRail.kt"

# interfaces
.implements Landroid/widget/SeekBar$OnSeekBarChangeListener;
.implements Ljava/lang/Runnable;


# static fields
.field private static OooO0o:Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;


# instance fields
.field private final OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;

.field private final OooO00o:Landroid/widget/SeekBar;

.field private final OooO0O0:Landroid/widget/TextView;

.field private final OooO0OO:Landroidx/appcompat/widget/AppCompatTextView;

.field private final OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;

.field private originalWeek:I


# direct methods
.method private constructor <init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    .locals 14

    invoke-direct {p0, p1}, Landroid/widget/FrameLayout;-><init>(Landroid/content/Context;)V

    iput-object p1, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;

    iget-object v0, p1, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;

    iget-object v1, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0o:Landroidx/appcompat/widget/AppCompatTextView;

    iput-object v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0OO:Landroidx/appcompat/widget/AppCompatTextView;

    iget-object v0, v0, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0oO:Landroidx/appcompat/widget/AppCompatTextView;

    iput-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;

    const v2, 0x7f0903ba
    invoke-virtual {p0, v2}, Landroid/view/View;->setId(I)V

    const/16 v2, 0x8
    invoke-virtual {p0, v2}, Landroid/view/View;->setVisibility(I)V

    const/4 v2, 0x0
    invoke-virtual {p0, v2}, Landroid/view/ViewGroup;->setClipChildren(Z)V

    const/high16 v2, 0x41800000    # 16.0f
    invoke-virtual {p0, v2}, Landroid/view/View;->setElevation(F)V

    new-instance v3, Landroid/widget/TextView;
    invoke-direct {v3, p1}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    iput-object v3, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0O0:Landroid/widget/TextView;

    const v4, 0x7f0903b9
    invoke-virtual {v3, v4}, Landroid/view/View;->setId(I)V

    const/16 v4, 0x11
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setGravity(I)V

    const/high16 v4, 0x41800000    # 16.0f
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setTextSize(F)V

    invoke-virtual {v1}, Landroid/widget/TextView;->getTextColors()Landroid/content/res/ColorStateList;
    move-result-object v4
    invoke-virtual {v4}, Landroid/content/res/ColorStateList;->getDefaultColor()I
    move-result v4
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setTextColor(I)V

    const-string v4, "选择周次"
    invoke-virtual {v3, v4}, Landroid/view/View;->setContentDescription(Ljava/lang/CharSequence;)V

    const/4 v4, -0x2
    const/16 v8, 0x30
    invoke-direct {p0, p1, v8}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v5
    new-instance v6, Landroid/widget/FrameLayout$LayoutParams;
    invoke-direct {v6, v4, v4}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V
    iput v5, v6, Landroid/view/ViewGroup$MarginLayoutParams;->leftMargin:I
    const/4 v4, 0x0
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->topMargin:I
    invoke-virtual {p0, v3, v6}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    new-instance v7, Landroid/widget/SeekBar;
    invoke-direct {v7, p1}, Landroid/widget/SeekBar;-><init>(Landroid/content/Context;)V
    iput-object v7, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO00o:Landroid/widget/SeekBar;

    const v4, 0x7f0903b8
    invoke-virtual {v7, v4}, Landroid/view/View;->setId(I)V

    const-string v4, "拖动选择周次"
    invoke-virtual {v7, v4}, Landroid/view/View;->setContentDescription(Ljava/lang/CharSequence;)V

    invoke-virtual {p1}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;
    move-result-object v4
    invoke-virtual {v4}, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o()Lcom/suda/yzune/wakeupschedule/bean/TableConfig;
    move-result-object v4
    invoke-virtual {v4}, Lcom/suda/yzune/wakeupschedule/bean/TableConfig;->getMaxWeek()I
    move-result v4
    const/4 v5, 0x1
    sub-int/2addr v4, v5
    invoke-virtual {v7, v4}, Landroid/widget/ProgressBar;->setMax(I)V

    invoke-virtual {p1}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;
    move-result-object v4
    iget v4, v4, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I
    sub-int/2addr v4, v5
    invoke-virtual {v7, v4}, Landroid/widget/ProgressBar;->setProgress(I)V

    const/16 v4, 0x30
    invoke-direct {p0, p1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v5
    new-instance v6, Landroid/widget/FrameLayout$LayoutParams;
    const/4 v4, -0x1
    invoke-direct {v6, v4, v5}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V
    const/16 v4, 0x30
    invoke-direct {p0, p1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v4
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->leftMargin:I
    const/16 v4, 0x18
    invoke-direct {p0, p1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v4
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->rightMargin:I
    const/16 v4, 0x1c
    invoke-direct {p0, p1, v4}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v4
    iput v4, v6, Landroid/view/ViewGroup$MarginLayoutParams;->topMargin:I
    invoke-virtual {p0, v7, v6}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    invoke-virtual {v7, p0}, Landroid/widget/SeekBar;->setOnSeekBarChangeListener(Landroid/widget/SeekBar$OnSeekBarChangeListener;)V

    iget-object v4, p1, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;
    iget-object v4, v4, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOo00:Landroidx/coordinatorlayout/widget/CoordinatorLayout;

    const/4 v5, -0x1
    const/16 v6, 0x60
    invoke-direct {p0, p1, v6}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v6
    new-instance v7, Landroid/view/ViewGroup$MarginLayoutParams;
    invoke-direct {v7, v5, v6}, Landroid/view/ViewGroup$MarginLayoutParams;-><init>(II)V
    const/16 v5, 0x40
    invoke-direct {p0, p1, v5}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o0(Landroid/content/Context;I)I
    move-result v5
    iput v5, v7, Landroid/view/ViewGroup$MarginLayoutParams;->topMargin:I
    invoke-virtual {v4, p0, v7}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    return-void
.end method

.method private OooO0o0(Landroid/content/Context;I)I
    .locals 2
    invoke-virtual {p1}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;
    move-result-object v0
    invoke-virtual {v0}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
    move-result-object v0
    iget v0, v0, Landroid/util/DisplayMetrics;->density:F
    int-to-float v1, p2
    mul-float/2addr v0, v1
    float-to-int v0, v0
    return v0
.end method

.method private OooO0oO(I)V
    .locals 5
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;
    const v1, 0x7f120238
    new-instance v2, Ljava/lang/Integer;
    invoke-direct {v2, p1}, Ljava/lang/Integer;-><init>(I)V
    const/4 v3, 0x1
    new-array v3, v3, [Ljava/lang/Object;
    const/4 v4, 0x0
    aput-object v2, v3, v4
    invoke-virtual {v0, v1, v3}, Landroid/content/Context;->getString(I[Ljava/lang/Object;)Ljava/lang/String;
    move-result-object v1
    iget-object v2, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0O0:Landroid/widget/TextView;
    invoke-virtual {v2, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    return-void
.end method

.method private OooO0oo()V
    .locals 5
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;
    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;
    move-result-object v1
    iget v1, v1, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I
    iget-object v2, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO00o:Landroid/widget/SeekBar;
    const/4 v3, 0x1
    sub-int v4, v1, v3
    invoke-virtual {v2, v4}, Landroid/widget/ProgressBar;->setProgress(I)V
    invoke-direct {p0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0oO(I)V
    return-void
.end method

.method private OooOO0()V
    .locals 4
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;
    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;
    move-result-object v1
    iget v1, v1, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I
    iput v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->originalWeek:I
    invoke-direct {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0oo()V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0OO:Landroidx/appcompat/widget/AppCompatTextView;
    const/16 v1, 0x8
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    const/4 v1, 0x0
    invoke-virtual {p0, v1}, Landroid/view/View;->setVisibility(I)V
    invoke-virtual {p0, p0}, Landroid/view/View;->removeCallbacks(Ljava/lang/Runnable;)Z
    const-wide/16 v1, 0xbb8
    invoke-virtual {p0, p0, v1, v2}, Landroid/view/View;->postDelayed(Ljava/lang/Runnable;J)Z
    return-void
.end method

.method private OooOO0O()V
    .locals 3
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;
    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;
    move-result-object v1
    iget v2, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->originalWeek:I
    iput v2, v1, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I
    new-instance v1, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    const/16 v2, 0x9
    invoke-direct {v1, v0, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
    const/4 v2, 0x0
    invoke-virtual {v1, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;->onMenuItemClick(Landroid/view/MenuItem;)Z
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0OO:Landroidx/appcompat/widget/AppCompatTextView;
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0Oo:Landroidx/appcompat/widget/AppCompatTextView;
    invoke-virtual {v0, v1}, Landroid/view/View;->setVisibility(I)V
    const/16 v1, 0x8
    invoke-virtual {p0, v1}, Landroid/view/View;->setVisibility(I)V
    invoke-virtual {p0, p0}, Landroid/view/View;->removeCallbacks(Ljava/lang/Runnable;)Z
    return-void
.end method

.method public static install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    .locals 1
    new-instance v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    invoke-direct {v0, p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    sput-object v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o:Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    return-void
.end method

.method public static toggle(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    .locals 2
    sget-object v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o:Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    if-eqz v0, :cond_0
    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->toggleInternal()V
    return-void
    :cond_0
    invoke-static {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    return-void
.end method

.method public toggleInternal()V
    .locals 2
    invoke-virtual {p0}, Landroid/view/View;->getVisibility()I
    move-result v0
    if-nez v0, :cond_0
    invoke-direct {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooOO0O()V
    return-void
    :cond_0
    invoke-direct {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooOO0()V
    return-void
.end method


# virtual methods
.method public onProgressChanged(Landroid/widget/SeekBar;IZ)V
    .locals 3
    if-eqz p3, :cond_0
    add-int/lit8 v0, p2, 0x1
    iget-object v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;
    invoke-virtual {v1}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0o()Lcom/suda/yzune/wakeupschedule/schedule/o0000O;
    move-result-object v1
    iput v0, v1, Lcom/suda/yzune/wakeupschedule/schedule/o0000O;->OooOO0o:I
    invoke-direct {p0, v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0oO(I)V
    new-instance v0, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;
    iget-object v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;
    const/16 v2, 0x9
    invoke-direct {v0, v1, v2}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Lcom/suda/yzune/wakeupschedule/schedule/o0OOO0o;->onMenuItemClick(Landroid/view/MenuItem;)Z
    :cond_0
    return-void
.end method

.method public onStartTrackingTouch(Landroid/widget/SeekBar;)V
    .locals 0
    invoke-virtual {p0, p0}, Landroid/view/View;->removeCallbacks(Ljava/lang/Runnable;)Z
    return-void
.end method

.method public onStopTrackingTouch(Landroid/widget/SeekBar;)V
    .locals 2
    const-wide/16 v0, 0xbb8
    invoke-virtual {p0, p0, v0, v1}, Landroid/view/View;->postDelayed(Ljava/lang/Runnable;J)Z
    return-void
.end method

.method public run()V
    .locals 0
    invoke-direct {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooOO0O()V
    return-void
.end method
