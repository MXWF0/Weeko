.class public final Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
.super Landroid/widget/FrameLayout;
.source "FluentWeekRail.kt"

.field private static OooO0o:Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;

.field private final OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;
.field private final OooO00o:Lio/github/mxwf/weeko/schedule/WeekRailController;

.method private constructor <init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    .locals 5

    invoke-direct {p0, p1}, Landroid/widget/FrameLayout;-><init>(Landroid/content/Context;)V
    iput-object p1, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO:Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;

    const v0, 0x7f0903ba
    invoke-virtual {p0, v0}, Landroid/view/View;->setId(I)V
    const/16 v0, 0x8
    invoke-virtual {p0, v0}, Landroid/view/View;->setVisibility(I)V

    iget-object v0, p1, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;
    const/4 v3, 0x0
    new-array v3, v3, [Landroid/view/View;
    invoke-static {p0, p1, v3}, Lio/github/mxwf/weeko/schedule/WeekRailController;->attach(Landroid/widget/FrameLayout;Ljava/lang/Object;[Landroid/view/View;)Lio/github/mxwf/weeko/schedule/WeekRailController;
    move-result-object v0
    iput-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO00o:Lio/github/mxwf/weeko/schedule/WeekRailController;
    return-void
.end method

.method public static install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    .locals 3
    new-instance v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    invoke-direct {v0, p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    sput-object v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o:Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    iget-object v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;
    iget-object v1, v1, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooO0OO:Landroidx/viewpager2/widget/ViewPager2;
    iget-object v1, v1, Landroidx/viewpager2/widget/ViewPager2;->OooOOoo:Landroidx/viewpager2/widget/OooO0O0;
    iget-object v1, v1, Landroidx/viewpager2/widget/OooO0O0;->OooO0O0:Ljava/lang/Object;
    check-cast v1, Ljava/util/ArrayList;
    new-instance v2, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekPageCallback;
    invoke-direct {v2, p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekPageCallback;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    invoke-virtual {v1, v2}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    return-void
.end method

.method public static updateFromPage(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V
    .locals 1
    sget-object v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o:Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    if-eqz v0, :week_page_sync_done
    iget-object v0, v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO00o:Lio/github/mxwf/weeko/schedule/WeekRailController;
    invoke-virtual {v0, p1}, Lio/github/mxwf/weeko/schedule/WeekRailController;->syncFromPage(I)V
    :week_page_sync_done
    return-void
.end method

.method public static returnToCurrent(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    .locals 2
    sget-object v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o:Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    if-eqz v0, :rail_return_without_controller
    iget-object v1, v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO00o:Lio/github/mxwf/weeko/schedule/WeekRailController;
    invoke-virtual {v1}, Lio/github/mxwf/weeko/schedule/WeekRailController;->returnToCurrent()V
    return-void
    :rail_return_without_controller
    invoke-static {p0}, Lio/github/mxwf/weeko/schedule/WeekRailController;->returnToCurrent(Ljava/lang/Object;)V
    return-void
.end method

.method public static toggle(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    .locals 1
    sget-object v0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO0o:Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;
    if-eqz v0, :rail_install_on_toggle
    invoke-virtual {v0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->toggleInternal()V
    return-void
    :rail_install_on_toggle
    invoke-static {p0}, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->install(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;)V
    return-void
.end method

.method public toggleInternal()V
    .locals 1
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/FluentWeekRail;->OooO00o:Lio/github/mxwf/weeko/schedule/WeekRailController;
    invoke-virtual {v0}, Lio/github/mxwf/weeko/schedule/WeekRailController;->toggle()V
    return-void
.end method
