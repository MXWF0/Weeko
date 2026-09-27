.class public final Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailHeightLimiter;
.super Ljava/lang/Object;
.source "SourceFile"

.implements Landroid/view/View$OnLayoutChangeListener;

.field private final root:Landroid/view/View;
.field private final scroll:Landroid/view/View;
.field private final maxHeight:I

.method public constructor <init>(Landroid/view/View;Landroid/view/View;I)V
    .locals 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    iput-object p1, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailHeightLimiter;->root:Landroid/view/View;
    iput-object p2, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailHeightLimiter;->scroll:Landroid/view/View;
    iput p3, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailHeightLimiter;->maxHeight:I
    return-void
.end method

.method public onLayoutChange(Landroid/view/View;IIIIIIII)V
    .locals 10
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailHeightLimiter;->root:Landroid/view/View;
    invoke-virtual {v0, p0}, Landroid/view/View;->removeOnLayoutChangeListener(Landroid/view/View$OnLayoutChangeListener;)V
    invoke-virtual {v0}, Landroid/view/View;->getRootView()Landroid/view/View;
    move-result-object v1
    check-cast v1, Landroid/widget/FrameLayout;
    invoke-virtual {v0}, Landroid/view/View;->getContext()Landroid/content/Context;
    move-result-object v3
    new-instance v2, Landroid/view/View;
    invoke-direct {v2, v3}, Landroid/view/View;-><init>(Landroid/content/Context;)V
    invoke-virtual {v3}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;
    move-result-object v4
    invoke-virtual {v3}, Landroid/content/Context;->getPackageName()Ljava/lang/String;
    move-result-object v5
    const-string v6, "weeko_v114_detail_navigation_bar"
    const-string v7, "color"
    invoke-virtual {v4, v6, v7, v5}, Landroid/content/res/Resources;->getIdentifier(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v8
    invoke-virtual {v4, v8}, Landroid/content/res/Resources;->getColor(I)I
    move-result v8
    invoke-virtual {v2, v8}, Landroid/view/View;->setBackgroundColor(I)V
    invoke-virtual {v0}, Landroid/view/View;->getRootWindowInsets()Landroid/view/WindowInsets;
    move-result-object v4
    invoke-virtual {v4}, Landroid/view/WindowInsets;->getSystemWindowInsetBottom()I
    move-result v4
    new-instance v5, Landroid/widget/FrameLayout$LayoutParams;
    const/4 v6, -0x1
    const/16 v7, 0x50
    invoke-direct {v5, v6, v4, v7}, Landroid/widget/FrameLayout$LayoutParams;-><init>(III)V
    invoke-virtual {v1, v2, v5}, Landroid/widget/FrameLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V
    iget v2, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailHeightLimiter;->maxHeight:I
    invoke-virtual {v0}, Landroid/view/View;->getHeight()I
    move-result v1
    if-le v1, v2, :done

    invoke-virtual {v0}, Landroid/view/View;->getLayoutParams()Landroid/view/ViewGroup$LayoutParams;
    move-result-object v1
    iput v2, v1, Landroid/view/ViewGroup$LayoutParams;->height:I
    invoke-virtual {v0, v1}, Landroid/view/View;->setLayoutParams(Landroid/view/ViewGroup$LayoutParams;)V

    invoke-virtual {v0}, Landroid/view/View;->getPaddingTop()I
    move-result v3
    invoke-virtual {v0}, Landroid/view/View;->getPaddingBottom()I
    move-result v1
    add-int/2addr v3, v1
    move-object v4, v0
    check-cast v4, Landroidx/appcompat/widget/LinearLayoutCompat;
    const/4 v5, 0x0
    invoke-virtual {v4}, Landroid/view/ViewGroup;->getChildCount()I
    move-result v2

    :child_loop
    if-ge v5, v2, :children_done
    invoke-virtual {v4, v5}, Landroid/view/ViewGroup;->getChildAt(I)Landroid/view/View;
    move-result-object v1
    iget-object p1, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailHeightLimiter;->scroll:Landroid/view/View;
    if-eq v1, p1, :next_child
    invoke-virtual {v1}, Landroid/view/View;->getMeasuredHeight()I
    move-result v1
    add-int/2addr v3, v1
    :next_child
    add-int/lit8 v5, v5, 0x1
    goto :child_loop

    :children_done
    iget v2, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailHeightLimiter;->maxHeight:I
    sub-int/2addr v2, v3
    iget-object v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailHeightLimiter;->scroll:Landroid/view/View;
    invoke-virtual {v1}, Landroid/view/View;->getLayoutParams()Landroid/view/ViewGroup$LayoutParams;
    move-result-object v3
    iput v2, v3, Landroid/view/ViewGroup$LayoutParams;->height:I
    invoke-virtual {v1, v3}, Landroid/view/View;->setLayoutParams(Landroid/view/ViewGroup$LayoutParams;)V
    invoke-virtual {v0}, Landroid/view/View;->requestLayout()V

    :done
    return-void
.end method
