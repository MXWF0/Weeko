.class public final Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;
.super Lo000OOO/OooO0O0;
.source "SourceFile"

.field private final window:Landroid/view/Window;
.field private final fallbackView:Landroid/view/View;
.field private final maxRadius:I
.field private final maxDim:F
.field private lastRadius:I

.method public constructor <init>(Landroid/view/Window;Landroid/view/View;I)V
    .locals 2

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    iput-object p1, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->window:Landroid/view/Window;
    iput-object p2, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->fallbackView:Landroid/view/View;
    iput p3, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->maxRadius:I
    invoke-virtual {p1}, Landroid/view/Window;->getAttributes()Landroid/view/WindowManager$LayoutParams;
    move-result-object v0
    iget v1, v0, Landroid/view/WindowManager$LayoutParams;->dimAmount:F
    iput v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->maxDim:F
    const/4 v0, -0x1
    iput v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->lastRadius:I
    return-void
.end method

.method public OooO0O0(Landroid/view/View;)V
    .locals 0

    invoke-direct {p0, p1}, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->updateBlur(Landroid/view/View;)V
    return-void
.end method

.method public OooO0OO(Landroid/view/View;I)V
    .locals 0

    invoke-direct {p0, p1}, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->updateBlur(Landroid/view/View;)V
    return-void
.end method

.method private updateBlur(Landroid/view/View;)V
    .locals 5

    invoke-virtual {p1}, Landroid/view/View;->getParent()Landroid/view/ViewParent;
    move-result-object v0
    check-cast v0, Landroid/view/View;
    invoke-virtual {v0}, Landroid/view/View;->getHeight()I
    move-result v0
    invoke-virtual {p1}, Landroid/view/View;->getTop()I
    move-result v1
    sub-int/2addr v0, v1
    invoke-virtual {p1}, Landroid/view/View;->getHeight()I
    move-result v1
    int-to-float v0, v0
    int-to-float v1, v1
    div-float/2addr v0, v1
    const/4 v1, 0x0
    invoke-static {v0, v1}, Ljava/lang/Math;->max(FF)F
    move-result v0
    const/high16 v1, 0x3f800000
    invoke-static {v0, v1}, Ljava/lang/Math;->min(FF)F
    move-result v0
    iget v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->maxRadius:I
    int-to-float v1, v1
    mul-float/2addr v0, v1
    float-to-int v0, v0
    iget v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->lastRadius:I
    if-eq v0, v1, :done
    iput v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->lastRadius:I
    iget-object v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->window:Landroid/view/Window;
    invoke-virtual {v1, v0}, Landroid/view/Window;->setBackgroundBlurRadius(I)V
    iget-object v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->fallbackView:Landroid/view/View;
    invoke-static {v1, v0}, Lio/github/mxwf/weeko/popup/CourseDetailBlurFallbackV115;->update(Landroid/view/View;I)V
    iget-object v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->window:Landroid/view/Window;
    invoke-virtual {v1}, Landroid/view/Window;->getAttributes()Landroid/view/WindowManager$LayoutParams;
    move-result-object v2
    invoke-virtual {v2, v0}, Landroid/view/WindowManager$LayoutParams;->setBlurBehindRadius(I)V
    iget v3, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->maxDim:F
    int-to-float v4, v0
    iget v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailGlassBlurCallbackV115;->maxRadius:I
    int-to-float v0, v0
    div-float/2addr v4, v0
    mul-float/2addr v3, v4
    iput v3, v2, Landroid/view/WindowManager$LayoutParams;->dimAmount:F
    invoke-virtual {v1, v2}, Landroid/view/Window;->setAttributes(Landroid/view/WindowManager$LayoutParams;)V

    :done
    return-void
.end method
