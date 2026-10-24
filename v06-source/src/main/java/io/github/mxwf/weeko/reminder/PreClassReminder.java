package io.github.mxwf.weeko.reminder;

import android.app.*;
import android.appwidget.AppWidgetManager;
import android.content.*;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.media.AudioManager;
import android.os.*;
import android.service.notification.StatusBarNotification;
import java.util.*;

/** Local pre-class notifications; the original query supplies today's occurrences. */
public final class PreClassReminder extends BroadcastReceiver {
    private static final String CHANNEL = "weeko_preclass";
    private static final String STATE = "weeko_preclass_state";
    private static final String REFRESH = "refresh", SHOW = "show", END = "end", DISMISS = "dismiss";
    private static final String TAG = "weeko.preclass";
    private static SharedPreferences.OnSharedPreferenceChangeListener listener;

    public static void install(Application app) {
        listener = (prefs, key) -> {
            if ("course_reminder".equals(key) || "reminder_min".equals(key)
                    || "show_table_id".equals(key)) requestRefresh(app);
        };
        app.getSharedPreferences("config", 0).registerOnSharedPreferenceChangeListener(listener);
        requestRefresh(app);
    }

    private static void requestRefresh(Context context) {
        context.sendBroadcast(new Intent(context, PreClassReminder.class).setAction(REFRESH));
    }

    private static SharedPreferences state(Context c) { return c.getSharedPreferences(STATE, 0); }
    private static NotificationManager notifications(Context c) {
        return (NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE);
    }
    private static AlarmManager alarms(Context c) { return (AlarmManager) c.getSystemService(Context.ALARM_SERVICE); }
    private static boolean allowed(Context c) {
        return c.getSharedPreferences("config", 0).getBoolean("course_reminder", false)
                && (Build.VERSION.SDK_INT < 33 || c.checkSelfPermission("android.permission.POST_NOTIFICATIONS") == PackageManager.PERMISSION_GRANTED)
                && (Build.VERSION.SDK_INT < 24 || notifications(c).areNotificationsEnabled());
    }
    private static String key(Bundle row) { return row.getInt("table") + "/" + row.getInt("course") + "/" + row.getLong("start"); }
    private static PendingIntent event(Context c, String action, String key) {
        return PendingIntent.getBroadcast(c, 0, new Intent(c, PreClassReminder.class)
                .setAction(action).addFlags(SHOW.equals(action) || END.equals(action) ? Intent.FLAG_RECEIVER_FOREGROUND : 0)
                .setData(new Uri.Builder().scheme("weeko-reminder").authority(action).appendPath(key).build())
                .putExtra("key", key), PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }
    private static void at(Context c, long time, PendingIntent event) {
        AlarmManager alarm = alarms(c);
        if (Build.VERSION.SDK_INT >= 31 && !alarm.canScheduleExactAlarms()) {
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, time, event);
        } else if (Build.VERSION.SDK_INT >= 23) {
            alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, time, event);
        } else alarm.setExact(AlarmManager.RTC_WAKEUP, time, event);
    }
    private static void remove(Context c, String key) {
        alarms(c).cancel(event(c, SHOW, key));
        alarms(c).cancel(event(c, END, key));
        notifications(c).cancel(TAG + key, 1);
    }

    /** Called once after the original asynchronous course/time query completes. */
    public static void reconcile(Context c, ArrayList<Bundle> rows) {
        try { reconcileRows(c, rows); }
        finally { if (c instanceof QueryContext) ((QueryContext) c).pending.finish(); }
    }

    private static void reconcileRows(Context c, ArrayList<Bundle> rows) {
        SharedPreferences prefs = state(c);
        Set<String> previous = new HashSet<>(prefs.getStringSet("planned", Collections.emptySet()));
        Set<String> planned = new HashSet<>();
        SharedPreferences.Editor edit = prefs.edit();
        long now = System.currentTimeMillis();
        for (String saved : prefs.getAll().keySet()) {
            if (saved.startsWith("dismissed:") && Long.parseLong(saved.substring(saved.lastIndexOf('/') + 1)) <= now)
                edit.remove(saved);
        }
        int minutes = c.getSharedPreferences("config", 0).getInt("reminder_min", 20);
        if (allowed(c) && rows != null) for (Bundle row : rows) {
            String[] clock = row.getString("time").split(":");
            Calendar start = Calendar.getInstance();
            start.set(Calendar.HOUR_OF_DAY, Integer.parseInt(clock[0]));
            start.set(Calendar.MINUTE, Integer.parseInt(clock[1]));
            start.set(Calendar.SECOND, 0);
            start.set(Calendar.MILLISECOND, 0);
            if (start.getTimeInMillis() <= now) continue;
            row.putLong("start", start.getTimeInMillis());
            row.putLong("show", start.getTimeInMillis() - minutes * 60000L);
            String key = key(row);
            planned.add(key);
            if (row.getLong("show") > now) {
                // Moving the lead time later must retract an already visible card.
                notifications(c).cancel(TAG + key, 1);
                edit.remove("seen:" + key);
            }
            // Persist only scheduling state; not part of Weeko's course backup.
            Intent record = new Intent().putExtras(row);
            edit.putString("row:" + key, record.toUri(Intent.URI_INTENT_SCHEME));
        }
        for (String old : previous) if (!planned.contains(old)) {
            remove(c, old);
            edit.remove("row:" + old).remove("seen:" + old);
        }
        edit.putStringSet("planned", planned);
        if (!edit.commit()) throw new IllegalStateException("Cannot persist pre-class schedule");
        for (String key : planned) {
            Bundle row = read(c, key);
            at(c, row.getLong("start"), event(c, END, key));
            if (row.getLong("show") <= now) show(c, key, row);
            else at(c, row.getLong("show"), event(c, SHOW, key));
        }
        if (Build.VERSION.SDK_INT >= 23) for (StatusBarNotification n : notifications(c).getActiveNotifications()) {
            if (Build.VERSION.SDK_INT >= 26 && "schedule_reminder".equals(n.getNotification().getChannelId()))
                notifications(c).cancel(n.getTag(), n.getId());
        }
        Calendar midnight = Calendar.getInstance();
        midnight.add(Calendar.DATE, 1);
        midnight.set(Calendar.HOUR_OF_DAY, 0); midnight.set(Calendar.MINUTE, 0);
        midnight.set(Calendar.SECOND, 0); midnight.set(Calendar.MILLISECOND, 0);
        if (allowed(c)) at(c, midnight.getTimeInMillis(), event(c, REFRESH, "day"));
        else alarms(c).cancel(event(c, REFRESH, "day"));
    }

    private static Bundle read(Context c, String key) {
        String value = state(c).getString("row:" + key, null);
        if (value == null) return null; // A removed/changed occurrence can have an in-flight alarm.
        try { return Intent.parseUri(value, Intent.URI_INTENT_SCHEME).getExtras(); }
        catch (java.net.URISyntaxException e) { throw new IllegalStateException("Invalid reminder record", e); }
    }

    private static void show(Context c, String key, Bundle row) {
        long remaining = row.getLong("start") - System.currentTimeMillis();
        if (!allowed(c) || remaining <= 0 || System.currentTimeMillis() < row.getLong("show")
                || state(c).getBoolean("dismissed:" + key, false)) return;
        NotificationManager manager = notifications(c);
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(new NotificationChannel(CHANNEL, "课前提醒", NotificationManager.IMPORTANCE_DEFAULT));
            if (manager.getNotificationChannel(CHANNEL).getImportance() == NotificationManager.IMPORTANCE_NONE) return;
        }
        boolean seen = state(c).getBoolean("seen:" + key, false);
        boolean visible = Build.VERSION.SDK_INT < 23;
        if (Build.VERSION.SDK_INT >= 23) for (StatusBarNotification n : manager.getActiveNotifications())
            if ((TAG + key).equals(n.getTag())) visible = true;
        if (seen && !visible) return; // System/user removed it: do not resurrect this occurrence.
        int silence = c.getSharedPreferences("config", 0).getInt("silence_mode", 0);
        if (!seen && silence != 0 && (Build.VERSION.SDK_INT < 23 || manager.isNotificationPolicyAccessGranted())) {
            ((AudioManager) c.getSystemService(Context.AUDIO_SERVICE)).setRingerMode(
                    silence == 1 ? AudioManager.RINGER_MODE_SILENT : AudioManager.RINGER_MODE_VIBRATE);
        }
        Intent open = new Intent().setClassName(c, "com.suda.yzune.wakeupschedule.schedule.ScheduleActivity")
                .setData(new Uri.Builder().scheme("weeko-reminder").authority("open").appendPath(key).build())
                .putExtra("weeko_reminder_table", row.getInt("table"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent target = PendingIntent.getActivity(c, 0, open, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        String content = row.getString("time") + " 上课";
        String room = row.getString("room");
        if (room != null && !room.trim().isEmpty()) content += " · " + room;
        Notification.Builder builder = Build.VERSION.SDK_INT >= 26 ? new Notification.Builder(c, CHANNEL) : new Notification.Builder(c);
        builder.setSmallIcon(c.getResources().getIdentifier("ic_notification", "drawable", c.getPackageName()))
                .setContentTitle(row.getString("name")).setContentText(content)
                .setContentIntent(target).setOngoing(c.getSharedPreferences("config", 0)
                        .getBoolean("reminder_on_going", false)).setOnlyAlertOnce(true)
                .setCategory(Notification.CATEGORY_REMINDER).setVisibility(Notification.VISIBILITY_PRIVATE)
                .setDeleteIntent(event(c, DISMISS, key))
                .addAction(0, "关闭本次", event(c, DISMISS, key));
        if (seen) builder.setSound(null).setVibrate(null);
        if (Build.VERSION.SDK_INT >= 26) builder.setTimeoutAfter(remaining);
        manager.notify(TAG + key, 1, builder.build());
        if (!state(c).edit().putBoolean("seen:" + key, true).commit())
            throw new IllegalStateException("Cannot persist reminder delivery");
    }

    /** Select the notification's own table before the original screen loads/reloads it. */
    public static boolean selectTable(Context c, Intent intent) {
        if (!intent.hasExtra("weeko_reminder_table")) return false;
        int table = intent.getIntExtra("weeko_reminder_table", -1);
        if (table < 1) return false;
        if (!c.getSharedPreferences("config", 0).edit().putInt("show_table_id", table).commit())
            throw new IllegalStateException("Cannot select reminder timetable");
        return true;
    }

    @Override public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        if (REFRESH.equals(action) || Intent.ACTION_BOOT_COMPLETED.equals(action)
                || Intent.ACTION_TIME_CHANGED.equals(action) || Intent.ACTION_TIMEZONE_CHANGED.equals(action)
                || Intent.ACTION_MY_PACKAGE_REPLACED.equals(action)) {
            if (!context.getSharedPreferences("config", 0).getBoolean("has_intro", false)) return;
            QueryContext query = new QueryContext(context, goAsync());
            // Reuse the released app's coroutine query, with no Widget IDs to render.
            try {
                Class<?> type = Class.forName("com.suda.yzune.wakeupschedule.today_appwidget.TodayCourseAppWidget");
                type.getMethod("onUpdate", Context.class, AppWidgetManager.class, int[].class)
                        .invoke(type.getConstructor().newInstance(), query, AppWidgetManager.getInstance(context), new int[0]);
            } catch (ReflectiveOperationException e) {
                query.pending.finish();
                throw new IllegalStateException("Reminder query bridge failed", e);
            }
            return;
        }
        String key = intent.getStringExtra("key");
        if (key == null) return;
        if (DISMISS.equals(action)) {
            if (!state(context).edit().putBoolean("dismissed:" + key, true).commit())
                throw new IllegalStateException("Cannot persist reminder dismissal");
            remove(context, key);
        } else if (END.equals(action)) notifications(context).cancel(TAG + key, 1);
        else if (SHOW.equals(action)) {
            Bundle row = read(context, key);
            if (row != null) show(context, key, row);
        }
    }

    private static final class QueryContext extends ContextWrapper {
        final PendingResult pending;
        QueryContext(Context base, PendingResult pending) { super(base); this.pending = pending; }
    }
}

