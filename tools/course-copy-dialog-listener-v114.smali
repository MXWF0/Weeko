.class public final Lcom/suda/yzune/wakeupschedule/schedule/CourseCopyDialogListenerV114;
.super Ljava/lang/Object;
.source "SourceFile"

# interfaces
.implements Landroid/content/DialogInterface$OnClickListener;


# instance fields
.field private final courseSheet:Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;
.field private final sourceMenuItem:Landroid/view/MenuItem;


# direct methods
.method public constructor <init>(Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;Landroid/view/MenuItem;)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    iput-object p1, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseCopyDialogListenerV114;->courseSheet:Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;
    iput-object p2, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseCopyDialogListenerV114;->sourceMenuItem:Landroid/view/MenuItem;
    return-void
.end method


# virtual methods
.method public onClick(Landroid/content/DialogInterface;I)V
    .locals 3

    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseCopyDialogListenerV114;->courseSheet:Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;
    iget-object v1, p0, Lcom/suda/yzune/wakeupschedule/schedule/CourseCopyDialogListenerV114;->sourceMenuItem:Landroid/view/MenuItem;
    new-instance v2, Lcom/suda/yzune/wakeupschedule/schedule/OooO0o;
    invoke-direct {v2, v0, p2}, Lcom/suda/yzune/wakeupschedule/schedule/OooO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/CourseDetailBottomSheet;I)V
    invoke-interface {v2, v1}, Landroid/view/MenuItem$OnMenuItemClickListener;->onMenuItemClick(Landroid/view/MenuItem;)Z
    move-result v0
    return-void
.end method
