param([Parameter(Mandatory=$true)][string]$ProjectPath)
$ErrorActionPreference='Stop'
$project=(Resolve-Path -LiteralPath $ProjectPath).Path
function Replace-Reminder($relative,$old,$new) {
    $path=Join-Path $project $relative
    $text=[IO.File]::ReadAllText($path).Replace("`r",'')
    $old=$old.Replace("`r",'')
    if ([regex]::Matches($text,[regex]::Escape($old)).Count -ne 1) {throw "Reminder patch target not unique: $relative"}
    [IO.File]::WriteAllText($path,$text.Replace($old,$new.Replace("`r",'')),[Text.UTF8Encoding]::new($false))
}
$query='smali/com/suda/yzune/wakeupschedule/today_appwidget/TodayCourseAppWidget$onUpdate$2.smali'
Replace-Reminder $query '# instance fields' ".field private weekoPlans:Ljava/util/ArrayList;`n`n# instance fields"
Replace-Reminder $query @'
    invoke-interface {v1}, Ljava/lang/Iterable;->iterator()Ljava/util/Iterator;
'@ @'
    new-instance v8, Ljava/util/ArrayList;
    invoke-direct {v8}, Ljava/util/ArrayList;-><init>()V
    iput-object v8, v5, Lcom/suda/yzune/wakeupschedule/today_appwidget/TodayCourseAppWidget$onUpdate$2;->weekoPlans:Ljava/util/ArrayList;
    invoke-interface {v1}, Ljava/lang/Iterable;->iterator()Ljava/util/Iterator;
'@
$path=Join-Path $project $query
$text=[IO.File]::ReadAllText($path).Replace("`r",'')
$pattern='(?s)    :goto_7\n.*?    :goto_9\n'
if ([regex]::Matches($text,$pattern).Count -ne 1) {throw 'Reminder scheduling block not unique'}
$replacement=@'
    :goto_7
    iget-object v8, v5, Lcom/suda/yzune/wakeupschedule/today_appwidget/TodayCourseAppWidget$onUpdate$2;->weekoPlans:Ljava/util/ArrayList;
    invoke-static {v8, v14, v11}, Lio/github/mxwf/weeko/reminder/ReminderPlanBridge;->add(Ljava/util/ArrayList;Lcom/suda/yzune/wakeupschedule/bean/CourseBean;Ljava/lang/String;)V
    :goto_9

'@
[IO.File]::WriteAllText($path,[regex]::Replace($text,$pattern,$replacement),[Text.UTF8Encoding]::new($false))
Replace-Reminder $query @'
    :goto_d
    return-object v7
'@ @'
    :goto_d
    iget-object v0, v5, Lcom/suda/yzune/wakeupschedule/today_appwidget/TodayCourseAppWidget$onUpdate$2;->$context:Landroid/content/Context;
    iget-object v1, v5, Lcom/suda/yzune/wakeupschedule/today_appwidget/TodayCourseAppWidget$onUpdate$2;->weekoPlans:Ljava/util/ArrayList;
    invoke-static {v0, v1}, Lio/github/mxwf/weeko/reminder/PreClassReminder;->reconcile(Landroid/content/Context;Ljava/util/ArrayList;)V
    return-object v7
'@
# Ignore outstanding legacy reminder alarms, not Widget broadcasts or rendering.
Replace-Reminder 'smali/com/suda/yzune/wakeupschedule/today_appwidget/TodayCourseAppWidget.smali' @'
    const-string v6, "io.github.mxwf.weeko.action.CANCEL_REMINDER"
'@ @'
    if-eqz v4, :weeko_legacy_non_reminder
    return-void
    :weeko_legacy_non_reminder
    const-string v6, "io.github.mxwf.weeko.action.CANCEL_REMINDER"
'@
Replace-Reminder 'smali/com/suda/yzune/wakeupschedule/App.smali' @'
    invoke-static {p0}, Lio/github/mxwf/weeko/navigation/LayeredPageTransition;->install(Landroid/app/Application;)V
'@ @'
    invoke-static {p0}, Lio/github/mxwf/weeko/navigation/LayeredPageTransition;->install(Landroid/app/Application;)V
    invoke-static {p0}, Lio/github/mxwf/weeko/reminder/PreClassReminder;->install(Landroid/app/Application;)V
'@
$activity='smali/com/suda/yzune/wakeupschedule/schedule/ScheduleActivity.smali'
$settings='smali/com/suda/yzune/wakeupschedule/settings/AdvancedSettingsActivity.smali'
Replace-Reminder $settings @'
    :cond_2
    const/4 v15, 0x0
'@ @'
    :cond_2
    move-object/from16 v23, v6
    goto/16 :cond_5
    const/4 v15, 0x0
'@
Replace-Reminder $settings @'
    move-result-object v3

    .line 276
    const v11, 0x7f1201cf
'@ @'
    move-result-object v3
    const-string v3, "按设置的提前分钟数提醒当前课表的课程，上课时自动撤销。无需添加桌面小部件。请允许通知和精确提醒；系统后台限制可能影响到达时间。"

    .line 276
    const v11, 0x7f1201cf
'@
Replace-Reminder $activity @'
    invoke-super {p0, p1}, Landroidx/activity/ComponentActivity;->onNewIntent(Landroid/content/Intent;)V
'@ @'
    invoke-super {p0, p1}, Landroidx/activity/ComponentActivity;->onNewIntent(Landroid/content/Intent;)V
    invoke-static {p0, p1}, Lio/github/mxwf/weeko/reminder/PreClassReminder;->selectTable(Landroid/content/Context;Landroid/content/Intent;)Z
    move-result v0
    if-eqz v0, :weeko_reminder_no_reload
    invoke-virtual {p0}, Lcom/suda/yzune/wakeupschedule/schedule/ScheduleActivity;->OooOoO0()V
    :weeko_reminder_no_reload
'@
# Cold launch: apply the target before the original initialization reads config.
Replace-Reminder $activity @'
    invoke-super/range {p0 .. p1}, Lcom/suda/yzune/wakeupschedule/base_view/BaseActivity;->onCreate(Landroid/os/Bundle;)V
'@ @'
    invoke-super/range {p0 .. p1}, Lcom/suda/yzune/wakeupschedule/base_view/BaseActivity;->onCreate(Landroid/os/Bundle;)V
    invoke-virtual {v0}, Landroid/app/Activity;->getIntent()Landroid/content/Intent;
    move-result-object v11
    invoke-static {v0, v11}, Lio/github/mxwf/weeko/reminder/PreClassReminder;->selectTable(Landroid/content/Context;Landroid/content/Intent;)Z
'@
Replace-Reminder 'AndroidManifest.xml' '</application>' @'
    <receiver android:name="io.github.mxwf.weeko.reminder.PreClassReminder" android:exported="false">
        <intent-filter>
            <action android:name="android.intent.action.BOOT_COMPLETED"/>
            <action android:name="android.intent.action.TIME_SET"/>
            <action android:name="android.intent.action.TIMEZONE_CHANGED"/>
            <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        </intent-filter>
    </receiver>
    </application>
'@
$dir=Join-Path $project 'smali/io/github/mxwf/weeko/reminder'
New-Item -ItemType Directory -Path $dir -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'preclass-reminder-bridge.smali') -Destination (Join-Path $dir 'ReminderPlanBridge.smali')
[IO.File]::WriteAllText((Join-Path $project 'res/drawable/ic_notification.xml'),@'
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFFFF" android:pathData="M4,3h16v18H4zM7,6v2h10V6zM7,11v2h10v-2zM7,16v2h7v-2z" android:fillType="evenOdd"/>
</vector>
'@,[Text.UTF8Encoding]::new($false))
Write-Output 'Applied local pre-class reminder lifecycle; original query/week rules and Widget rendering retained.'

