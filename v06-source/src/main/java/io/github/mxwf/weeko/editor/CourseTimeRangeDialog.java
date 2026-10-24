package io.github.mxwf.weeko.editor;

import android.app.Activity;
import android.app.Dialog;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.Rect;
import android.graphics.drawable.RippleDrawable;
import android.os.Build;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.view.ViewTreeObserver;
import android.widget.LinearLayout;
import android.widget.NumberPicker;
import android.widget.ScrollView;
import android.widget.TextView;
import io.github.mxwf.weeko.about.G2ShapeDrawable;
import io.github.mxwf.weeko.popup.GlassDialogSurface;
import io.github.mxwf.weeko.theme.SoftDynamicColors;
import java.util.List;
import java.util.Locale;

/** One draft for both ends of a custom course time; only confirmation writes back. */
public final class CourseTimeRangeDialog {
    private final Activity activity;
    private final Object bean;
    private final Object adapter;
    private final int position;
    private final int accent, foreground, secondary, surface;
    private final int[] minutes = new int[2];
    private final TextView[] tabs = new TextView[2];
    private NumberPicker hour, minute;
    private final TextView error;
    private int selected;

    public static void show(Activity activity, int position, boolean start) {
        new CourseTimeRangeDialog(activity, position, start);
    }

    private static Object call(Object object, String method) throws ReflectiveOperationException {
        return object.getClass().getMethod(method).invoke(object);
    }

    private CourseTimeRangeDialog(Activity owner, int index, boolean start) {
        activity = owner;
        position = index;
        try {
            Object model = call(owner, "OooOo0o");
            bean = ((List<?>) model.getClass().getField("OooO0OO").get(model)).get(index);
            adapter = owner.getClass().getField("Oooo").get(owner);
            minutes[0] = parse((String) call(bean, "getStartTime"));
            minutes[1] = parse((String) call(bean, "getEndTime"));
        } catch (ReflectiveOperationException failure) {
            throw new IllegalStateException("Original course time binding failed", failure);
        }
        selected = start ? 0 : 1;
        foreground = color("md_theme_onSurface");
        secondary = color("md_theme_onSurfaceVariant");
        surface = color("md_theme_surface");
        accent = SoftDynamicColors.resolveAccent(owner, color("md_theme_primary"));

        Dialog dialog = new Dialog(owner);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        LinearLayout content = new LinearLayout(owner);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setFocusableInTouchMode(true);
        content.setPadding(dp(20), dp(20), dp(20), dp(16));
        TextView title = label("自定义时间", 20, foreground);
        title.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        content.addView(title);
        LinearLayout choices = new LinearLayout(owner);
        for (int i = 0; i < 2; i++) {
            final int side = i;
            TextView tab = label("", 18, foreground);
            tab.setGravity(Gravity.CENTER);
            tab.setMinHeight(dp(76));
            tab.setPadding(dp(8), dp(10), dp(8), dp(10));
            tab.setOnClickListener(view -> {
                content.requestFocus();
                minutes[selected] = hour.getValue() * 60 + minute.getValue();
                selected = side;
                hour.setValue(minutes[side] / 60);
                minute.setValue(minutes[side] % 60);
                update();
            });
            tabs[i] = tab;
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, -2, 1);
            if (i == 0) params.setMarginEnd(dp(8));
            choices.addView(tab, params);
        }
        LinearLayout.LayoutParams choiceParams = new LinearLayout.LayoutParams(-1, -2);
        choiceParams.topMargin = dp(20);
        content.addView(choices, choiceParams);

        LinearLayout wheels = new LinearLayout(owner);
        wheels.setGravity(Gravity.CENTER);
        hour = wheel(23, "小时");
        minute = wheel(59, "分钟");
        hour.setValue(minutes[selected] / 60);
        minute.setValue(minutes[selected] % 60);
        hour.setOnValueChangedListener((picker, old, value) -> changed());
        minute.setOnValueChangedListener((picker, old, value) -> changed());
        wheels.addView(hour, new LinearLayout.LayoutParams(0, dp(168), 1));
        TextView colon = label(":", 24, secondary);
        colon.setGravity(Gravity.CENTER);
        wheels.addView(colon, new LinearLayout.LayoutParams(dp(24), -1));
        wheels.addView(minute, new LinearLayout.LayoutParams(0, dp(168), 1));
        LinearLayout.LayoutParams wheelParams = new LinearLayout.LayoutParams(-1, -2);
        wheelParams.topMargin = dp(12);
        content.addView(wheels, wheelParams);
        error = label("", 13, color("weeko_v114_detail_danger"));
        error.setAccessibilityLiveRegion(View.ACCESSIBILITY_LIVE_REGION_POLITE);
        content.addView(error, new LinearLayout.LayoutParams(-1, -2));
        LinearLayout actions = new LinearLayout(owner);
        TextView cancel = action("取消", false);
        TextView confirm = action("确定", true);
        cancel.setOnClickListener(view -> dialog.dismiss());
        confirm.setOnClickListener(view -> {
            content.requestFocus();
            minutes[selected] = hour.getValue() * 60 + minute.getValue();
            if (minutes[1] <= minutes[0]) {
                error.setText("下课时间需晚于上课时间");
                return;
            }
            try {
                bean.getClass().getMethod("setStartTime", String.class).invoke(bean, clock(minutes[0]));
                bean.getClass().getMethod("setEndTime", String.class).invoke(bean, clock(minutes[1]));
                adapter.getClass().getMethod("OooO0o", int.class).invoke(adapter, position + 1);
            } catch (ReflectiveOperationException failure) {
                throw new IllegalStateException("Original course time update failed", failure);
            }
            dialog.dismiss();
        });
        actions.addView(cancel, new LinearLayout.LayoutParams(0, dp(48), 1));
        LinearLayout.LayoutParams confirmParams = new LinearLayout.LayoutParams(0, dp(48), 1);
        confirmParams.setMarginStart(dp(8));
        actions.addView(confirm, confirmParams);
        LinearLayout.LayoutParams actionParams = new LinearLayout.LayoutParams(-1, -2);
        actionParams.topMargin = dp(12);
        content.addView(actions, actionParams);

        ScrollView scroll = new ScrollView(owner);
        scroll.setFillViewport(true);
        scroll.addView(content);
        dialog.setContentView(scroll);
        dialog.setCanceledOnTouchOutside(true);
        dialog.show();
        Window window = dialog.getWindow();
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
        int width = Math.min(owner.getResources().getDisplayMetrics().widthPixels - dp(32), dp(360));
        window.setLayout(width, ViewGroup.LayoutParams.WRAP_CONTENT);
        // Floating windows do not consistently honor adjustResize on OEM keyboards.
        // Keep the whole action row inside the visible frame, rather than just the focused digit.
        View decor = window.getDecorView();
        Rect visible = new Rect();
        boolean[] inputUsed = {false};
        ViewTreeObserver.OnGlobalLayoutListener keyboardLayout = () -> {
            decor.getWindowVisibleDisplayFrame(visible);
            boolean keyboard = visible.bottom < owner.getResources().getDisplayMetrics().heightPixels - dp(100);
            inputUsed[0] |= keyboard;
            int height = Math.min(content.getHeight(), visible.height() - dp(32));
            WindowManager.LayoutParams params = window.getAttributes();
            // Do not move the action row back under a finger while the IME closes.
            int gravity = inputUsed[0] ? Gravity.TOP | Gravity.CENTER_HORIZONTAL : Gravity.CENTER;
            int y = inputUsed[0] ? dp(16) : 0;
            if (params.height != height || params.gravity != gravity || params.y != y) {
                params.height = height;
                params.gravity = gravity;
                params.y = y;
                window.setAttributes(params);
            }
        };
        decor.getViewTreeObserver().addOnGlobalLayoutListener(keyboardLayout);
        dialog.setOnDismissListener(ignored -> decor.getViewTreeObserver().removeOnGlobalLayoutListener(keyboardLayout));
        GlassDialogSurface.apply(dialog);
        update();
    }

    private void changed() {
        minutes[selected] = hour.getValue() * 60 + minute.getValue();
        tabs[selected].setText((selected == 0 ? "上课" : "下课") + "\n" + clock(minutes[selected]));
        error.setText("");
    }

    private void update() {
        for (int i = 0; i < 2; i++) {
            tabs[i].setText((i == 0 ? "上课" : "下课") + "\n" + clock(minutes[i]));
            tabs[i].setTextColor(i == selected ? accent : foreground);
            tabs[i].setSelected(i == selected);
            int fill = i == selected ? (accent & 0xffffff) | 0x18000000 : surface;
            tabs[i].setBackground(ripple(fill, i == selected ? accent : (secondary & 0xffffff) | 0x26000000));
        }
        error.setText("");
    }

    private NumberPicker wheel(int max, String description) {
        NumberPicker picker = new NumberPicker(activity);
        picker.setMinValue(0);
        picker.setMaxValue(max);
        picker.setWrapSelectorWheel(true);
        picker.setFormatter(value -> String.format(Locale.ROOT, "%02d", value));
        picker.setContentDescription(description);
        if (Build.VERSION.SDK_INT >= 29) {
            picker.setTextColor(foreground);
            picker.setTextSize(24 * activity.getResources().getDisplayMetrics().scaledDensity);
            picker.setSelectionDividerHeight(dp(1));
        }
        return picker;
    }

    private TextView action(String text, boolean filled) {
        TextView view = label(text, 15, accent);
        view.setGravity(Gravity.CENTER);
        view.setTextAlignment(View.TEXT_ALIGNMENT_CENTER);
        view.setBackground(ripple(filled ? (accent & 0xffffff) | 0x18000000 : Color.TRANSPARENT, 0));
        return view;
    }

    private RippleDrawable ripple(int fill, int stroke) {
        return new RippleDrawable(ColorStateList.valueOf((accent & 0xffffff) | 0x20000000),
                new G2ShapeDrawable(fill, stroke, stroke == 0 ? 0 : dp(1), dp(12)),
                new G2ShapeDrawable(Color.WHITE, 0, 0, dp(12)));
    }

    private TextView label(String text, int size, int color) {
        TextView view = new TextView(activity);
        view.setText(text);
        view.setTextSize(size);
        view.setTextColor(color);
        return view;
    }
    private int color(String name) {
        return activity.getResources().getColor(activity.getResources().getIdentifier(name, "color", activity.getPackageName()));
    }
    private int dp(float value) { return Math.round(value * activity.getResources().getDisplayMetrics().density); }
    private static int parse(String value) {
        if (value.isEmpty()) return 9 * 60; // Preserve the original picker's blank-value default.
        String[] parts = value.split(":");
        return Integer.parseInt(parts[0]) * 60 + Integer.parseInt(parts[1]);
    }
    private static String clock(int value) { return String.format(Locale.ROOT, "%02d:%02d", value / 60, value % 60); }
}

