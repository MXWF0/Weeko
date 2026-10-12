package io.github.mxwf.weeko.editor;

import android.app.Activity;
import android.app.Dialog;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.res.ColorStateList;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.RippleDrawable;
import android.graphics.drawable.StateListDrawable;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.LinearLayout;
import android.widget.HorizontalScrollView;
import android.widget.TextView;
import io.github.mxwf.weeko.about.G2ShapeDrawable;
import io.github.mxwf.weeko.theme.SoftDynamicColors;

/** Presentation only. All controls retain the original editor IDs and callbacks. */
public final class AddCourseAppearanceV120 {
    private AddCourseAppearanceV120() {}

    public static boolean isEditor(Context context) {
        while (context instanceof ContextWrapper && !(context instanceof Activity))
            context = ((ContextWrapper) context).getBaseContext();
        return context instanceof Activity
                && context.getClass().getName().equals("com.suda.yzune.wakeupschedule.course_add.AddCourseActivity");
    }

    public static void inputDialog(Dialog dialog, Object fragment) {
        if (isEditor(dialog.getContext()) && fragment.getClass().getName().equals("o00O0o0.OooO0OO")) {
            dialog.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_ALT_FOCUSABLE_IM);
            dialog.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
        }
    }

    public static void backPrompt(Activity activity, Dialog prompt) {
        CourseInlineFields.backPrompt(prompt);
    }

    public static void inlineField(TextView field) {
        field.setTag("weeko_field");
        style(field);
    }

    public static void recommendation(TextView chip) {
        Context context = chip.getContext();
        int accent = SoftDynamicColors.resolveAccent(context, color(context, "md_theme_primary"));
        chip.setTextSize(14);
        chip.setTextColor(color(context, "md_theme_onSurface"));
        chip.setPadding((int) dp(context, 14), (int) dp(context, 10), (int) dp(context, 14), (int) dp(context, 10));
        chip.setMinHeight((int) dp(context, 48));
        chip.setMaxWidth(context.getResources().getDisplayMetrics().widthPixels - (int) dp(context, 96));
        chip.setBackground(new RippleDrawable(ColorStateList.valueOf((accent & 0xffffff) | 0x18000000),
                shape(context, blend(color(context, "md_theme_surface"), accent, 0.075f), 0, 24),
                shape(context, Color.WHITE, 0, 24)));
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-2, -2);
        params.setMarginEnd((int) dp(context, 8));
        params.topMargin = (int) dp(context, 6);
        chip.setLayoutParams(params);
    }

    private static int resource(Context context, String type, String name) {
        return context.getResources().getIdentifier(name, type, context.getPackageName());
    }

    private static int color(Context context, String name) {
        return context.getResources().getColor(resource(context, "color", name));
    }

    private static float dp(Context context, float value) {
        return value * context.getResources().getDisplayMetrics().density;
    }

    public static View inflate(LayoutInflater inflater, int layout, ViewGroup parent, boolean attach) {
        Context context = inflater.getContext();
        if (isEditor(context)) {
            String name = context.getResources().getResourceEntryName(layout);
            if (name.equals("item_add_course_base")) layout = resource(context, "layout", "weeko_v120_add_base");
            if (name.equals("item_add_course_detail")) layout = resource(context, "layout", "weeko_v120_add_detail");
        }
        View result = inflater.inflate(layout, parent, attach);
        if (isEditor(context)) style(result);
        return result;
    }

    public static View inflate(LayoutInflater inflater, int layout, ViewGroup parent) {
        return inflate(inflater, layout, parent, parent != null);
    }

    private static G2ShapeDrawable shape(Context context, int fill, int stroke, float radius) {
        return new G2ShapeDrawable(fill, stroke, stroke == 0 ? 0f : dp(context, 1), dp(context, radius));
    }

    private static void style(View view) {
        Context context = view.getContext();
        String tag = String.valueOf(view.getTag());
        int surface = color(context, "md_theme_surface");
        int accent = SoftDynamicColors.resolveAccent(context, color(context, "md_theme_primary"));
        int border = (color(context, "md_theme_onSurfaceVariant") & 0xffffff) | 0x26000000;
        if (tag.equals("weeko_card")) view.setBackground(shape(context, surface, 0, 24));
        if (tag.equals("weeko_time_group"))
            view.setBackground(shape(context, blend(surface, accent, 0.045f), 0, 16));
        if (tag.equals("weeko_action") || tag.equals("weeko_action_field") || tag.equals("weeko_time_options")) {
            int fill = tag.equals("weeko_action") ? Color.TRANSPARENT : surface;
            int outline = tag.equals("weeko_action") ? 0 : border;
            view.setBackground(new RippleDrawable(ColorStateList.valueOf((accent & 0xffffff) | 0x18000000),
                    shape(context, fill, outline, 12), shape(context, Color.WHITE, 0, 12)));
            view.setClipToOutline(true);
        }
        if (tag.equals("weeko_time_options") && (context.getResources().getConfiguration().screenWidthDp < 390
                || context.getResources().getConfiguration().fontScale > 1.15f)) {
            LinearLayout row = (LinearLayout) view;
            row.setOrientation(LinearLayout.VERTICAL);
            LinearLayout.LayoutParams time = (LinearLayout.LayoutParams) row.getChildAt(0).getLayoutParams();
            time.width = ViewGroup.LayoutParams.MATCH_PARENT;
            time.weight = 0;
            row.getChildAt(0).setLayoutParams(time);
            row.getChildAt(1).getLayoutParams().width = ViewGroup.LayoutParams.MATCH_PARENT;
        }
        if (tag.equals("weeko_field")) {
            StateListDrawable field = new StateListDrawable();
            field.addState(new int[]{android.R.attr.state_focused}, shape(context, surface, accent, 12));
            field.addState(new int[]{}, shape(context, surface, border, 12));
            view.setBackground(field);
        }
        if (view instanceof ViewGroup) {
            ViewGroup group = (ViewGroup) view;
            for (int i = 0; i < group.getChildCount(); i++) style(group.getChildAt(i));
        }
    }

    private static int blend(int base, int tint, float amount) {
        return Color.rgb(Math.round(Color.red(base) * (1 - amount) + Color.red(tint) * amount),
                Math.round(Color.green(base) * (1 - amount) + Color.green(tint) * amount),
                Math.round(Color.blue(base) * (1 - amount) + Color.blue(tint) * amount));
    }

    public static void header(Activity activity, View root) {
        if (!isEditor(activity)) return;
        LinearLayout colors = root.findViewWithTag("weeko_colors");
        int[] choices = activity.getResources().getIntArray(resource(activity, "array", "customizedColors"));
        TextView current = root.findViewById(resource(activity, "id", "tv_color"));
        for (int choice : choices) {
            ColorChoice swatch = new ColorChoice(activity, choice);
            swatch.setOnClickListener(view -> {
                try {
                    activity.getClass().getMethod("OooO0o", int.class, int.class).invoke(activity, 0, choice);
                } catch (ReflectiveOperationException error) {
                    throw new IllegalStateException("Original course color callback failed", error);
                }
            });
            colors.addView(swatch, new LinearLayout.LayoutParams((int) dp(activity, 48), (int) dp(activity, 48)));
        }
        syncColors(colors, current.getCurrentTextColor());
        SoftDynamicColors.apply(root);
    }

    public static void selectedColor(Activity activity, int selected) {
        if (!isEditor(activity)) return;
        LinearLayout colors = activity.findViewById(android.R.id.content).findViewWithTag("weeko_colors");
        syncColors(colors, selected);
    }

    private static void syncColors(LinearLayout colors, int selected) {
        Context context = colors.getContext();
        int count = context.getResources().getIntArray(resource(context, "array", "customizedColors")).length;
        if (colors.getChildCount() > count) colors.removeViewAt(count);
        int selectedIndex = -1;
        for (int i = 0; i < colors.getChildCount(); i++) {
            ColorChoice choice = (ColorChoice) colors.getChildAt(i);
            choice.setSelected(choice.color == selected);
            if (choice.isSelected()) selectedIndex = i;
            choice.invalidate();
        }
        if (selectedIndex == -1) {
            ColorChoice custom = new ColorChoice(context, selected);
            custom.setContentDescription("自定义课程颜色");
            custom.setSelected(true);
            custom.setOnClickListener(view -> colors.getRootView().findViewById(resource(context, "id", "ll_color")).performClick());
            colors.addView(custom, new LinearLayout.LayoutParams((int) dp(context, 48), (int) dp(context, 48)));
            selectedIndex = count;
        }
        int index = selectedIndex;
        colors.post(() -> {
            HorizontalScrollView scroll = (HorizontalScrollView) colors.getParent();
            scroll.scrollTo(Math.max(0, (int) dp(context, index * 48 + 24) - scroll.getWidth() / 2), 0);
        });
    }

    public static void chip(View chip) {
        if (!isEditor(chip.getContext())) return;
        TextView label = (TextView) chip;
        label.setTextSize(14);
        label.setMaxWidth(chip.getResources().getDisplayMetrics().widthPixels - (int) dp(chip.getContext(), 72));
        label.setMinHeight((int) dp(chip.getContext(), 48));
        int accent = SoftDynamicColors.resolveAccent(chip.getContext(), color(chip.getContext(), "md_theme_primary"));
        int fill = blend(color(chip.getContext(), "md_theme_surface"), accent, 0.075f);
        try {
            chip.getClass().getMethod("setChipCornerRadius", float.class).invoke(chip, dp(chip.getContext(), 24));
            chip.getClass().getMethod("setChipStrokeWidth", float.class).invoke(chip, 0f);
            chip.getClass().getMethod("setChipBackgroundColor", ColorStateList.class).invoke(chip, ColorStateList.valueOf(fill));
        } catch (ReflectiveOperationException error) {
            throw new IllegalStateException("Course recommendation styling failed", error);
        }
        SoftDynamicColors.apply(chip);
    }

    public static void detail(View root, int position) {
        if (!isEditor(root.getContext())) return;
        Context context = root.getContext();
        TextView title = root.findViewWithTag("weeko_time_title");
        title.setVisibility(position == 1 ? View.VISIBLE : View.GONE);
        root.setBackground(new G2ShapeDrawable(color(context, "md_theme_surface"), 0, 0,
                position == 1 ? dp(context, 24) : 0, true));
        TextView number = root.findViewById(resource(context, "id", "tv_item"));
        number.setText("时间段 " + position);
        SoftDynamicColors.apply(root);
    }

    public static void spacing(Activity activity, Rect spacing) {
        if (isEditor(activity)) spacing.bottom = 0;
    }

    public static View footer(Activity activity, View originalAddButton) {
        originalAddButton.setVisibility(View.GONE);
        ViewGroup list = activity.findViewById(resource(activity, "id", "anko_layout"));
        list.setPadding((int) dp(activity, 16), (int) dp(activity, 8), (int) dp(activity, 16), (int) dp(activity, 24));
        list.setClipToPadding(false);
        list.setScrollBarStyle(View.SCROLLBARS_OUTSIDE_OVERLAY);
        // Edit mode installs its LayoutManager after loading the existing course.
        View footer = LayoutInflater.from(activity).inflate(resource(activity, "layout", "weeko_v120_add_footer"), null);
        footer.setLayoutParams(new ViewGroup.LayoutParams(-1, -2));
        footer.setBackground(new G2ShapeDrawable(color(activity, "md_theme_surface"), 0, 0, dp(activity, 24), true) {
            @Override public void draw(Canvas canvas) {
                int save = canvas.save();
                canvas.rotate(180, getBounds().exactCenterX(), getBounds().exactCenterY());
                super.draw(canvas);
                canvas.restoreToCount(save);
            }
        });
        TextView add = footer.findViewById(resource(activity, "id", "tv_add"));
        int accent = SoftDynamicColors.resolveAccent(activity, color(activity, "md_theme_primary"));
        add.setBackgroundTintList(ColorStateList.valueOf(blend(color(activity, "md_theme_surface"), accent, 0.1f)));
        add.setTextColor(accent);
        add.setOnClickListener(view -> originalAddButton.performClick());
        SoftDynamicColors.apply(footer);
        return footer;
    }

    private static final class ColorChoice extends View {
        private final int color;
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        ColorChoice(Context context, int color) {
            super(context);
            this.color = color;
            setContentDescription("课程颜色 " + Integer.toHexString(color & 0xffffff));
            setFocusable(true);
            setBackground(new RippleDrawable(ColorStateList.valueOf((color & 0xffffff) | 0x22000000), null,
                    shape(context, Color.WHITE, 0, 24)));
        }
        @Override protected void onDraw(Canvas canvas) {
            float cx = getWidth() / 2f, cy = getHeight() / 2f;
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(color);
            canvas.drawCircle(cx, cy, dp(getContext(), 15), paint);
            if (isSelected()) {
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(dp(getContext(), 1.5f));
                canvas.drawCircle(cx, cy, dp(getContext(), 19), paint);
                paint.setColor((Color.red(color) * 299 + Color.green(color) * 587 + Color.blue(color) * 114) > 155000
                        ? 0xff20252b : Color.WHITE);
                paint.setStrokeWidth(dp(getContext(), 2));
                canvas.drawLine(cx - dp(getContext(), 6), cy, cx - dp(getContext(), 1), cy + dp(getContext(), 5), paint);
                canvas.drawLine(cx - dp(getContext(), 1), cy + dp(getContext(), 5), cx + dp(getContext(), 7), cy - dp(getContext(), 5), paint);
            }
        }
    }
}
