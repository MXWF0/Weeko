param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$stage3Script = Join-Path $PSScriptRoot "replay-weeko-v07-stage3-patches.ps1"

& $stage3Script -ProjectPath $project
if (!$?) { throw "Stage 3 patch replay failed; Stage 4 was not applied." }

function Replace-Stage4ExactText {
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

Replace-Stage4ExactText "apktool.yml" @'
  versionCode: 7
  versionName: 0.7.0-stage3
'@ @'
  versionCode: 7
  versionName: 0.7.0-stage4
'@

# Keep the bottom LinearLayout as an unattached compatibility object because
# existing inset plumbing still holds its reference, but remove it from the
# CoordinatorLayout. The schedule content remains the sole visible child and
# therefore keeps the full available height.
Replace-Stage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00000.smali" @'
    new-instance v5, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;

    .line 2195
    .line 2196
    const/4 v6, 0x0

    .line 2197
    invoke-direct {v5, v1, v6}, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;-><init>(Landroid/content/Context;Landroid/util/AttributeSet;)V

    .line 2198
    .line 2199
    .line 2200
    const/4 v13, 0x1

    .line 2201
    invoke-virtual {v5, v13}, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->Oooo0(Z)V

    .line 2202
    .line 2203
    .line 2204
    const/4 v15, 0x0

    .line 2205
    invoke-virtual {v5, v15}, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->Oooo0O0(I)V

    .line 2206
    .line 2207
    .line 2208
    iput-boolean v13, v5, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->Oooo:Z

    .line 2209
    .line 2210
    iput v11, v5, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->OooO0oO:I

    .line 2211
    .line 2212
    invoke-virtual {v3, v5}, Landroidx/coordinatorlayout/widget/OooO0OO;->OooO0O0(Landroidx/coordinatorlayout/widget/CoordinatorLayout$Behavior;)V

    .line 2213
    .line 2214
    .line 2215
    invoke-virtual {v4, v2, v3}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V
'@ @'
    invoke-virtual {v2, v3}, Landroid/view/View;->setLayoutParams(Landroid/view/ViewGroup$LayoutParams;)V
'@

# Do not obtain a BottomSheetBehavior from the unattached compatibility view.
Replace-Stage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    iget-object v12, v12, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOOoo:Landroid/widget/LinearLayout;

    .line 130
    .line 131
    invoke-static {v12}, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->OooOoo(Landroid/view/View;)Lcom/google/android/material/bottomsheet/BottomSheetBehavior;

    .line 132
    .line 133
    .line 134
    move-result-object v12

    .line 135
    iput-object v12, v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0o0:Lcom/google/android/material/bottomsheet/BottomSheetBehavior;
'@ @'
    const/4 v12, 0x0
    iput-object v12, v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0o0:Lcom/google/android/material/bottomsheet/BottomSheetBehavior;
'@

# The bottom bar no longer has a click target; leave the remaining top-row
# listener chain untouched.
Replace-Stage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    iget-object v12, v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0OO:Lcom/suda/yzune/wakeupschedule/schedule/o00000;

    .line 196
    .line 197
    if-eqz v12, :cond_1f

    .line 198
    .line 199
    new-instance v15, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;

    .line 200
    .line 201
    invoke-direct {v15, v0, v5}, Lcom/suda/yzune/wakeupschedule/schedule/o00oO0o;-><init>(Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;I)V

    .line 202
    .line 203
    .line 204
    iget-object v12, v12, Lcom/suda/yzune/wakeupschedule/schedule/o00000;->OooOOoo:Landroid/widget/LinearLayout;

    .line 205
    .line 206
    invoke-virtual {v12, v15}, Landroid/view/View;->setOnClickListener(Landroid/view/View$OnClickListener;)V
'@ @'
    # Stage 4 removes the bottom bar's click listener.
'@

# Back now always follows the activity's normal back stack; it no longer
# toggles a hidden bottom sheet.
Replace-Stage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
.method public final onBackPressed()V
    .locals 3

    .line 1
    iget-object v0, p0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0o0:Lcom/google/android/material/bottomsheet/BottomSheetBehavior;

    .line 2
    .line 3
    if-eqz v0, :cond_1

    .line 4
    .line 5
    iget v1, v0, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->OoooO0:I

    .line 6
    .line 7
    const/4 v2, 0x3

    .line 8
    if-ne v1, v2, :cond_0

    .line 9
    .line 10
    const/4 v1, 0x5

    .line 11
    invoke-virtual {v0, v1}, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->Oooo0OO(I)V

    .line 12
    .line 13
    .line 14
    return-void

    .line 15
    :cond_0
    invoke-super {p0}, Landroidx/activity/ComponentActivity;->onBackPressed()V

    .line 16
    .line 17
    .line 18
    return-void

    .line 19
    :cond_1
    const-string v0, "bottomSheetBehavior"

    .line 20
    .line 21
    invoke-static {v0}, Lkotlin/jvm/internal/OooOO0O;->OooOO0o(Ljava/lang/String;)V

    .line 22
    .line 23
    .line 24
    const/4 v0, 0x0

    .line 25
    throw v0
.end method
'@ @'
.method public final onBackPressed()V
    .locals 0

    invoke-super {p0}, Landroidx/activity/ComponentActivity;->onBackPressed()V

    return-void
.end method
'@

# Remove the three bottom-sheet-only state transitions while preserving all
# other click actions in this shared listener.
Replace-Stage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    :pswitch_2
    iget-object v1, v13, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0o0:Lcom/google/android/material/bottomsheet/BottomSheetBehavior;

    .line 569
    .line 570
    if-eqz v1, :cond_4

    .line 571
    .line 572
    const/4 v5, 0x5

    .line 573
    invoke-virtual {v1, v5}, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->Oooo0OO(I)V

    .line 574
    .line 575
    .line 576
    return-void

    .line 577
    :cond_4
    invoke-static {v10}, Lkotlin/jvm/internal/OooOO0O;->OooOO0o(Ljava/lang/String;)V

    .line 578
    .line 579
    .line 580
    throw v16
'@ @'
    :pswitch_2
    return-void
'@

Replace-Stage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    :pswitch_3
    sget v1, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OoooOoO:I

    .line 582
    .line 583
    iget-object v1, v13, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0o0:Lcom/google/android/material/bottomsheet/BottomSheetBehavior;

    .line 584
    .line 585
    if-eqz v1, :cond_5

    .line 586
    .line 587
    invoke-virtual {v1, v12}, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->Oooo0OO(I)V

    .line 588
    .line 589
    .line 590
    return-void

    .line 591
    :cond_5
    invoke-static {v10}, Lkotlin/jvm/internal/OooOO0O;->OooOO0o(Ljava/lang/String;)V

    .line 592
    .line 593
    .line 594
    throw v16
'@ @'
    :pswitch_3
    return-void
'@

Replace-Stage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o00oO0o.smali" @'
    :pswitch_7
    sget v1, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OoooOoO:I

    .line 668
    .line 669
    invoke-virtual {v13}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0O()V

    .line 670
    .line 671
    .line 672
    iget-object v1, v13, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0o0:Lcom/google/android/material/bottomsheet/BottomSheetBehavior;

    .line 673
    .line 674
    if-eqz v1, :cond_6

    .line 675
    .line 676
    const/4 v5, 0x5

    .line 677
    invoke-virtual {v1, v5}, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->Oooo0OO(I)V

    .line 678
    .line 679
    .line 680
    return-void

    .line 681
    :cond_6
    invoke-static {v10}, Lkotlin/jvm/internal/OooOO0O;->OooOO0o(Ljava/lang/String;)V

    .line 682
    .line 683
    .line 684
    throw v16
'@ @'
    :pswitch_7
    invoke-virtual {v13}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOo0O()V

    return-void
'@

# Dismissing the first-run intro and completing an import no longer animate a
# hidden schedule bottom sheet. Their non-UI work remains unchanged.
Replace-Stage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/o000oOoO.smali" @'
    iget-object v0, v7, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0o0:Lcom/google/android/material/bottomsheet/BottomSheetBehavior;

    .line 293
    .line 294
    if-eqz v0, :cond_1

    .line 295
    .line 296
    invoke-virtual {v0, v2}, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->Oooo0OO(I)V
'@ @'
    # Stage 4 removes the hidden bottom-sheet state transition.
'@

Replace-Stage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali" @'
    iget-object v3, v0, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0o0:Lcom/google/android/material/bottomsheet/BottomSheetBehavior;

    .line 395
    .line 396
    if-eqz v3, :cond_18

    .line 397
    .line 398
    new-instance v5, Lcom/suda/yzune/wakeupschedule/schedule/o000OOo;

    .line 399
    .line 400
    invoke-direct {v5, v0, v9}, Lcom/suda/yzune/wakeupschedule/schedule/o000OOo;-><init>(Landroid/view/KeyEvent$Callback;I)V

    .line 401
    .line 402
    .line 403
    iget-object v3, v3, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->OooooO0:Ljava/util/ArrayList;

    .line 404
    .line 405
    invoke-virtual {v3, v5}, Ljava/util/ArrayList;->contains(Ljava/lang/Object;)Z

    .line 406
    .line 407
    .line 408
    move-result v11

    .line 409
    if-nez v11, :cond_a

    .line 410
    .line 411
    invoke-virtual {v3, v5}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    .line 412
    .line 413
    .line 414
    :cond_a
'@ @'
    # Stage 4 removes the hidden bottom-sheet state listener.
'@

Replace-Stage4ExactText "smali/com/suda/yzune/wakeupschedule/schedule/Oooo000.smali" @'
    iget-object p1, v2, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->Oooo0o0:Lcom/google/android/material/bottomsheet/BottomSheetBehavior;

    .line 23
    .line 24
    if-eqz p1, :cond_1

    .line 25
    .line 26
    const/4 v4, 0x3

    .line 27
    invoke-virtual {p1, v4}, Lcom/google/android/material/bottomsheet/BottomSheetBehavior;->Oooo0OO(I)V
'@ @'
    # Stage 4 removes the hidden bottom-sheet state transition.
'@

Write-Output "Applied v0.7 Stage 4 bottom-bar removal patch to $project"
