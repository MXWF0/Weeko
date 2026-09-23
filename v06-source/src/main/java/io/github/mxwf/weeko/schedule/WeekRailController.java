package io.github.mxwf.weeko.schedule;

import android.animation.ValueAnimator;
import android.content.Context;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.graphics.Path;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.view.ViewTreeObserver;
import android.view.animation.DecelerateInterpolator;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.TextView;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

/**
 * Visual controller for the schedule week rail. The schedule keeps owning the
 * selected week; this class only mirrors that value and invokes the existing
 * refresh action after a user selection.
 */
public final class WeekRailController implements SeekBar.OnSeekBarChangeListener {
    // The first weekday cell in each ViewPager page header.
    private static final int FIRST_WEEKDAY_HEADER_ID = 0x7f0900a2;
    private static final int BACKDROP_SCALE = 4;
    private static final int BACKDROP_BLUR_RADIUS = 5;
    private static final int BACKDROP_BLUR_PASSES = 3;
    private static final int BLUE = 0xff2f80ff;
    private static final int LIGHT_SURFACE = 0xfff7faff;
    private static final int DARK_SURFACE = 0xff1c222b;
    private static final int LIGHT_PRIMARY = 0xff172238;
    private static final int DARK_PRIMARY = 0xffedf3ff;
    private static final int LIGHT_SECONDARY = 0xff637089;
    private static final int DARK_SECONDARY = 0xffaab8cd;

    private final FrameLayout rail;
    private final Object activity;
    private final View[] dateViews;
    private final Context context;
    private final TextView title;
    private final TextView subtitle;
    private final TextView thisWeek;
    private final SeekBar seekBar;
    private final RailThumbDrawable thumb;
    private final RailOverlay overlay;
    private final BackdropBlurView backdrop;
    private final int density;
    private ViewGroup rootParent;
    private boolean showing;
    private boolean railPositioned;
    private int maxWeek;
    private int realWeek;

    private final Runnable hideTask = new Runnable() {
        @Override
        public void run() {
            hide();
        }
    };

    private final Runnable backdropTask = new Runnable() {
        @Override
        public void run() {
            refreshBackdrop();
        }
    };

    private final ViewTreeObserver.OnGlobalLayoutListener positionListener =
            new ViewTreeObserver.OnGlobalLayoutListener() {
                @Override
                public void onGlobalLayout() {
                    if (showing) {
                        scheduleBackdropRefresh();
                    } else {
                        updateRailPosition();
                    }
                }
            };

    private WeekRailController(FrameLayout rail, Object activity, View[] dateViews) {
        this.rail = rail;
        this.activity = activity;
        this.dateViews = dateViews;
        this.context = rail.getContext();
        this.density = Math.max(1, (int) (context.getResources().getDisplayMetrics().density + 0.5f));
        boolean dark = isDark(context);

        rail.setClipChildren(false);
        rail.setElevation(dp(2));
        rail.setBackground(railOutline(context));
        rail.setVisibility(View.GONE);

        backdrop = new BackdropBlurView(context, surfaceBackground(context, dark), dp(18));
        rail.addView(backdrop, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

        LinearLayout row = new LinearLayout(context);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(dp(12), 0, dp(10), 0);
        rail.addView(row, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

        LinearLayout labels = new LinearLayout(context);
        labels.setOrientation(LinearLayout.VERTICAL);
        labels.setGravity(Gravity.CENTER_VERTICAL);
        // Keep the compatibility title node for FluentTopBar.styleRail, but
        // let the track use the full middle width in v1.1.2.
        labels.setVisibility(View.GONE);
        row.addView(labels, new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT));

        title = new TextView(context);
        title.setId(0x7f0903b9);
        title.setTextSize(16f);
        title.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        title.setSingleLine(true);
        title.setTextColor(dark ? DARK_PRIMARY : LIGHT_PRIMARY);
        title.setContentDescription("选择周次");
        labels.addView(title, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        subtitle = new TextView(context);
        subtitle.setTextSize(11f);
        subtitle.setSingleLine(true);
        subtitle.setTextColor(dark ? DARK_SECONDARY : LIGHT_SECONDARY);
        labels.addView(subtitle, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        FrameLayout sliderHost = new FrameLayout(context);
        LinearLayout.LayoutParams sliderHostParams = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT, 1f);
        sliderHostParams.rightMargin = dp(10);
        row.addView(sliderHost, sliderHostParams);

        maxWeek = readMaxWeek();
        overlay = new RailOverlay(context, dark ? 0xff7694c4 : 0xff7f9bc8, BLUE);
        overlay.setMaxWeek(maxWeek);
        sliderHost.addView(overlay, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

        seekBar = new SeekBar(context);
        seekBar.setId(0x7f0903b8);
        seekBar.setMax(Math.max(0, maxWeek - 1));
        seekBar.setProgress(Math.max(0, readPageWeek() - 1));
        seekBar.setPadding(dp(4), 0, dp(4), 0);
        seekBar.setSplitTrack(false);
        seekBar.setProgressDrawable(new RailTrackDrawable(BLUE,
                dark ? 0xff516079 : 0xffc6d3e6, dp(2)));
        thumb = new RailThumbDrawable(BLUE, dp(5), dp(3));
        seekBar.setThumb(thumb);
        seekBar.setContentDescription("拖动选择周次");
        seekBar.setOnSeekBarChangeListener(this);
        FrameLayout.LayoutParams sliderParams = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(40), Gravity.CENTER_VERTICAL);
        sliderHost.addView(seekBar, sliderParams);

        thisWeek = new TextView(context);
        thisWeek.setText("本周");
        thisWeek.setTextSize(14f);
        thisWeek.setGravity(Gravity.CENTER);
        thisWeek.setSingleLine(true);
        thisWeek.setTextColor(BLUE);
        thisWeek.setContentDescription("本周");
        thisWeek.setPadding(dp(8), 0, dp(8), 0);
        thisWeek.setBackground(outlineBackground(context, BLUE, dark));
        thisWeek.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                WeekRailController.returnToCurrent(activity);
                scheduleHide();
            }
        });
        row.addView(thisWeek, new LinearLayout.LayoutParams(dp(58), dp(36)));

        updateUi(readPageWeek());
    }

    public static WeekRailController attach(FrameLayout rail, Object activity, View[] dateViews) {
        WeekRailController controller = new WeekRailController(rail, activity, dateViews);
        ViewGroup parent = (ViewGroup) findFieldValue(activity, "Oooo0OO", "OooOo00");
        controller.rootParent = parent;
        ViewGroup.MarginLayoutParams params = new ViewGroup.MarginLayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, controller.dp(52));
        params.leftMargin = controller.dp(8);
        params.rightMargin = controller.dp(8);
        params.topMargin = 0;
        parent.addView(rail, params);
        parent.getViewTreeObserver().addOnGlobalLayoutListener(controller.positionListener);
        controller.updateRailPosition();
        return controller;
    }

    public void toggle() {
        if (showing) {
            hide();
        } else {
            show();
        }
    }

    public void syncFromPage(int week) {
        updateUi(week);
        scheduleBackdropRefresh();
    }

    public void returnToCurrent() {
        returnToCurrent(activity);
    }

    public static void returnToCurrent(Object activity) {
        Object state = invokeNoArg(activity, "OooOo0o");
        Object table = invokeNoArg(state, "OooOO0o");
        String startDate = (String) invokeNoArg(table, "getStartDate");
        int max = ((Integer) invokeNoArg(table, "getMaxWeek")).intValue();
        int current = calculateCurrentWeek(startDate, max);
        selectPage(activity, current - 1, true);
        WeekRailController controller = currentController(activity);
        if (controller != null) {
            controller.updateUi(current);
            controller.scheduleBackdropRefresh();
        }
    }

    private static WeekRailController currentController(Object activity) {
        try {
            Class<?> railClass = Class.forName(
                    "com.suda.yzune.wakeupschedule.schedule.FluentWeekRail");
            Field field = railClass.getDeclaredField("OooO0o");
            field.setAccessible(true);
            Object rail = field.get(null);
            if (rail == null) {
                return null;
            }
            Field controller = railClass.getDeclaredField("OooO00o");
            controller.setAccessible(true);
            return (WeekRailController) controller.get(rail);
        } catch (ReflectiveOperationException error) {
            throw new IllegalStateException("Unable to access the week rail", error);
        }
    }

    private void show() {
        removeHideCallbacks();
        updateRailPosition();
        updateUi(readPageWeek());
        showing = true;
        for (View dateView : dateViews) {
            dateView.animate().cancel();
            dateView.setVisibility(View.VISIBLE);
            dateView.setAlpha(1f);
            dateView.animate().alpha(0f).setDuration(180L).start();
        }
        rail.animate().cancel();
        rail.setVisibility(View.VISIBLE);
        rail.setAlpha(0f);
        rail.animate().alpha(1f).setDuration(180L).start();
        scheduleBackdropRefresh();
        scheduleHide();
    }

    private void hide() {
        removeHideCallbacks();
        if (!showing && rail.getVisibility() != View.VISIBLE) {
            return;
        }
        showing = false;
        removeBackdropCallbacks();
        for (View dateView : dateViews) {
            dateView.animate().cancel();
            dateView.setVisibility(View.VISIBLE);
            dateView.animate().alpha(1f).setDuration(180L).start();
        }
        rail.animate().cancel();
        rail.animate().alpha(0f).setDuration(180L).withEndAction(new Runnable() {
            @Override
            public void run() {
                rail.setVisibility(View.GONE);
                rail.setAlpha(1f);
            }
        }).start();
    }

    private void scheduleHide() {
        removeHideCallbacks();
        rail.postDelayed(hideTask, 2500L);
    }

    private void removeHideCallbacks() {
        rail.removeCallbacks(hideTask);
    }

    private void scheduleBackdropRefresh() {
        if (!showing) {
            return;
        }
        removeBackdropCallbacks();
        rail.postDelayed(backdropTask, 72L);
    }

    private void removeBackdropCallbacks() {
        rail.removeCallbacks(backdropTask);
    }

    private boolean updateRailPosition() {
        ViewGroup pager = (ViewGroup) viewPager();
        Object pageHolder = invoke(pager.getChildAt(0), "Oooo000",
                new Class<?>[]{int.class}, new Object[]{Integer.valueOf(readPageWeek() - 1)});
        if (pageHolder == null) {
            return false;
        }
        View page = (View) getFieldValue(pageHolder, "itemView");
        View header = page.findViewById(FIRST_WEEKDAY_HEADER_ID);
        if (header == null || header.getWidth() == 0 || header.getHeight() == 0
                || rootParent == null) {
            return false;
        }
        int[] headerLocation = new int[2];
        int[] parentLocation = new int[2];
        header.getLocationInWindow(headerLocation);
        rootParent.getLocationInWindow(parentLocation);
        int left = headerLocation[0] - parentLocation[0];
        int right = left + header.getWidth();
        ViewParent headerParent = header.getParent();
        if (headerParent instanceof ViewGroup) {
            ViewGroup headerGroup = (ViewGroup) headerParent;
            for (int id = FIRST_WEEKDAY_HEADER_ID + 1;
                 id < FIRST_WEEKDAY_HEADER_ID + 7; id++) {
                View day = headerGroup.findViewById(id);
                if (day != null && day.getVisibility() == View.VISIBLE) {
                    int[] dayLocation = new int[2];
                    day.getLocationInWindow(dayLocation);
                    right = Math.max(right, dayLocation[0] - parentLocation[0] + day.getWidth());
                }
            }
        }
        int top = headerLocation[1] - parentLocation[1] - rootParent.getPaddingTop();
        left -= rootParent.getPaddingLeft();
        right = rootParent.getWidth() - rootParent.getPaddingRight() - right;
        int height = header.getHeight();
        ViewGroup.MarginLayoutParams params =
                (ViewGroup.MarginLayoutParams) rail.getLayoutParams();
        if (params.leftMargin != left || params.rightMargin != right
                || params.topMargin != top || params.height != height) {
            params.leftMargin = left;
            params.rightMargin = right;
            params.topMargin = top;
            params.height = height;
            rail.setLayoutParams(params);
        }
        railPositioned = true;
        return true;
    }

    private void refreshBackdrop() {
        if (!showing || !railPositioned || rootParent == null
                || rail.getWidth() == 0 || rail.getHeight() == 0) {
            return;
        }
        int width = Math.max(1, rail.getWidth() / BACKDROP_SCALE);
        int height = Math.max(1, rail.getHeight() / BACKDROP_SCALE);
        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        canvas.scale(width / (float) rail.getWidth(), height / (float) rail.getHeight());
        canvas.translate(-rail.getLeft(), -rail.getTop());
        float alpha = rail.getAlpha();
        rail.setAlpha(0f);
        try {
            rootParent.draw(canvas);
        } finally {
            rail.setAlpha(alpha);
        }
        blur(bitmap, BACKDROP_BLUR_RADIUS, BACKDROP_BLUR_PASSES);
        backdrop.setBitmap(bitmap);
    }

    private static void blur(Bitmap bitmap, int radius, int passes) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        int[] pixels = new int[width * height];
        int[] temporary = new int[pixels.length];
        int[] output = new int[pixels.length];
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height);
        for (int pass = 0; pass < passes; pass++) {
            blurAxis(pixels, temporary, width, height, radius, true);
            blurAxis(temporary, output, width, height, radius, false);
            System.arraycopy(output, 0, pixels, 0, pixels.length);
        }
        bitmap.setPixels(pixels, 0, width, 0, 0, width, height);
    }

    private static void blurAxis(int[] source, int[] destination, int width,
                                 int height, int radius, boolean horizontal) {
        int lines = horizontal ? height : width;
        int length = horizontal ? width : height;
        for (int line = 0; line < lines; line++) {
            for (int position = 0; position < length; position++) {
                int alpha = 0;
                int red = 0;
                int green = 0;
                int blue = 0;
                int count = 0;
                for (int sample = Math.max(0, position - radius);
                     sample <= Math.min(length - 1, position + radius); sample++) {
                    int index = horizontal ? line * width + sample : sample * width + line;
                    int color = source[index];
                    alpha += Color.alpha(color);
                    red += Color.red(color);
                    green += Color.green(color);
                    blue += Color.blue(color);
                    count++;
                }
                int index = horizontal ? line * width + position : position * width + line;
                destination[index] = Color.argb(alpha / count, red / count,
                        green / count, blue / count);
            }
        }
    }

    private void updateUi(int week) {
        maxWeek = readMaxWeek();
        if (week < 1) {
            week = 1;
        }
        if (week > maxWeek) {
            week = maxWeek;
        }
        realWeek = calculateRealWeek();
        seekBar.setMax(Math.max(0, maxWeek - 1));
        seekBar.setProgress(Math.max(0, week - 1));
        title.setText("第 " + week + " 周");
        subtitle.setText("当前第 " + realWeek + " 周");
        thisWeek.setAlpha(week == realWeek ? 0.55f : 1f);
        thisWeek.setEnabled(week != realWeek);
        overlay.setMaxWeek(maxWeek);
        overlay.setRealWeek(realWeek);
        overlay.invalidate();
    }

    private int readPageWeek() {
        return ((Integer) invokeNoArg(viewPager(), "getCurrentItem")).intValue() + 1;
    }

    private int readMaxWeek() {
        Object state = invokeNoArg(activity, "OooOo0o");
        Object table = invokeNoArg(state, "OooOO0o");
        return ((Integer) invokeNoArg(table, "getMaxWeek")).intValue();
    }

    private int calculateRealWeek() {
        Object state = invokeNoArg(activity, "OooOo0o");
        Object table = invokeNoArg(state, "OooOO0o");
        String startDate = (String) invokeNoArg(table, "getStartDate");
        return calculateCurrentWeek(startDate, readMaxWeek());
    }

    private static int calculateCurrentWeek(String startDate, int maxWeek) {
        int week = ((Integer) invokeStatic(
                "com.suda.yzune.wakeupschedule.utils.OooO0OO",
                "OooO0o0", new Class<?>[]{String.class, int.class, boolean.class},
                new Object[]{startDate, Integer.valueOf(30), Boolean.FALSE})).intValue();
        if (week < 1) {
            return 1;
        }
        return Math.min(week, maxWeek);
    }

    private Object viewPager() {
        return findFieldValue(activity, "Oooo0OO", "OooO0OO");
    }

    private static void selectPage(Object activity, int pageIndex, boolean smoothScroll) {
        Object pager = findFieldValue(activity, "Oooo0OO", "OooO0OO");
        invoke(pager, "OooO0OO", new Class<?>[]{int.class, boolean.class},
                new Object[]{Integer.valueOf(pageIndex), Boolean.valueOf(smoothScroll)});
    }

    private static Object invoke(Object receiver, String name,
                                 Class<?>[] parameters, Object[] values) {
        try {
            Method method = findMethod(receiver.getClass(), name, parameters);
            method.setAccessible(true);
            return method.invoke(receiver, values);
        } catch (ReflectiveOperationException error) {
            throw new IllegalStateException("Unable to invoke " + name, error);
        }
    }

    @Override
    public void onProgressChanged(SeekBar bar, int progress, boolean fromUser) {
        if (!fromUser) {
            return;
        }
        int week = progress + 1;
        selectPage(activity, week - 1, true);
        updateUi(week);
    }

    @Override
    public void onStartTrackingTouch(SeekBar bar) {
        removeHideCallbacks();
        thumb.animateTo(true);
    }

    @Override
    public void onStopTrackingTouch(SeekBar bar) {
        thumb.animateTo(false);
        scheduleBackdropRefresh();
        scheduleHide();
    }

    private int dp(int value) {
        return value * density;
    }

    private static boolean isDark(Context context) {
        int mode = context.getResources().getConfiguration().uiMode
                & Configuration.UI_MODE_NIGHT_MASK;
        return mode == Configuration.UI_MODE_NIGHT_YES;
    }

    private static GradientDrawable surfaceBackground(Context context, boolean dark) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(dark ? 0xd01c222b : 0xd0f7faff);
        drawable.setCornerRadius(18f * context.getResources().getDisplayMetrics().density);
        drawable.setStroke(1, dark ? 0x4a5e7192 : 0x3d5d7db5);
        return drawable;
    }

    private static GradientDrawable railOutline(Context context) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(Color.TRANSPARENT);
        drawable.setCornerRadius(18f * context.getResources().getDisplayMetrics().density);
        return drawable;
    }

    private static GradientDrawable outlineBackground(Context context, int color, boolean dark) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(dark ? 0x263e73c4 : 0x140f6fe8);
        drawable.setCornerRadius(18f * context.getResources().getDisplayMetrics().density);
        drawable.setStroke(1, dark ? 0x997faeff : 0x667fb5ff);
        return drawable;
    }

    private static Object findFieldValue(Object receiver, String ownerField, String childField) {
        Object owner = getFieldValue(receiver, ownerField);
        return getFieldValue(owner, childField);
    }

    private static Object getFieldValue(Object receiver, String name) {
        try {
            Field field = findField(receiver.getClass(), name);
            field.setAccessible(true);
            return field.get(receiver);
        } catch (ReflectiveOperationException error) {
            throw new IllegalStateException("Unable to read " + name, error);
        }
    }

    private static Field findField(Class<?> type, String name) throws NoSuchFieldException {
        Class<?> current = type;
        while (current != null) {
            try {
                return current.getDeclaredField(name);
            } catch (NoSuchFieldException ignored) {
                current = current.getSuperclass();
            }
        }
        throw new NoSuchFieldException(name);
    }

    private static Object invokeNoArg(Object receiver, String name) {
        try {
            Method method = findMethod(receiver.getClass(), name);
            method.setAccessible(true);
            return method.invoke(receiver);
        } catch (ReflectiveOperationException error) {
            throw new IllegalStateException("Unable to invoke " + name, error);
        }
    }

    private static Method findMethod(Class<?> type, String name, Class<?>... parameters)
            throws NoSuchMethodException {
        Class<?> current = type;
        while (current != null) {
            try {
                return current.getDeclaredMethod(name, parameters);
            } catch (NoSuchMethodException ignored) {
                current = current.getSuperclass();
            }
        }
        throw new NoSuchMethodException(name);
    }

    private static Object invokeStatic(String className, String methodName,
                                       Class<?>[] parameters, Object[] values) {
        try {
            Class<?> type = Class.forName(className);
            Method method = findMethod(type, methodName, parameters);
            method.setAccessible(true);
            return method.invoke(null, values);
        } catch (ReflectiveOperationException error) {
            throw new IllegalStateException("Unable to invoke " + methodName, error);
        }
    }

    private static final class RailTrackDrawable extends Drawable {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final int activeColor;
        private final int inactiveColor;
        private final float stroke;
        private int alpha = 255;

        RailTrackDrawable(int activeColor, int inactiveColor, float stroke) {
            this.activeColor = activeColor;
            this.inactiveColor = inactiveColor;
            this.stroke = stroke;
        }

        @Override
        public void draw(Canvas canvas) {
            Rect bounds = getBounds();
            float y = bounds.centerY();
            float left = bounds.left + stroke;
            float right = bounds.right - stroke;
            paint.setStrokeCap(Paint.Cap.ROUND);
            paint.setStrokeWidth(stroke);
            paint.setAlpha(alpha);
            paint.setColor(inactiveColor);
            canvas.drawLine(left, y, right, y, paint);
            float ratio = getLevel() / 10000f;
            paint.setColor(activeColor);
            canvas.drawLine(left, y, left + (right - left) * ratio, y, paint);
        }

        @Override
        protected boolean onLevelChange(int level) {
            invalidateSelf();
            return true;
        }

        @Override
        public void setAlpha(int alpha) {
            this.alpha = alpha;
            invalidateSelf();
        }

        @Override
        public void setColorFilter(android.graphics.ColorFilter filter) {
            paint.setColorFilter(filter);
            invalidateSelf();
        }

        @Override
        public int getOpacity() {
            return PixelFormat.TRANSLUCENT;
        }
    }

    private static final class BackdropBlurView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.FILTER_BITMAP_FLAG);
        private final Path clipPath = new Path();
        private final RectF bounds = new RectF();
        private final Drawable surface;
        private final float cornerRadius;
        private Bitmap bitmap;

        BackdropBlurView(Context context, Drawable surface, float cornerRadius) {
            super(context);
            this.surface = surface;
            this.cornerRadius = cornerRadius;
        }

        void setBitmap(Bitmap next) {
            bitmap = next;
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            bounds.set(0f, 0f, getWidth(), getHeight());
            clipPath.reset();
            clipPath.addRoundRect(bounds, cornerRadius, cornerRadius, Path.Direction.CW);
            int save = canvas.save();
            canvas.clipPath(clipPath);
            if (bitmap != null) {
                canvas.drawBitmap(bitmap, null, bounds, paint);
            }
            surface.setBounds(0, 0, getWidth(), getHeight());
            surface.draw(canvas);
            canvas.restoreToCount(save);
        }
    }

    private static final class RailThumbDrawable extends Drawable {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final float baseRadius;
        private final float haloSize;
        private float scale = 1f;
        private float haloAlpha;
        private int alpha = 255;
        private ValueAnimator animation;

        RailThumbDrawable(int color, float radius, float haloSize) {
            paint.setColor(color);
            baseRadius = radius;
            this.haloSize = haloSize;
        }

        @Override
        public void draw(Canvas canvas) {
            float radius = baseRadius * scale;
            if (haloAlpha > 0f) {
                paint.setAlpha((int) (alpha * haloAlpha));
                canvas.drawCircle(getBounds().centerX(), getBounds().centerY(),
                        radius + haloSize, paint);
            }
            paint.setAlpha(alpha);
            canvas.drawCircle(getBounds().centerX(), getBounds().centerY(), radius, paint);
        }

        @Override
        public int getIntrinsicWidth() {
            return (int) (baseRadius * 2f + 12f);
        }

        @Override
        public int getIntrinsicHeight() {
            return (int) (baseRadius * 2f + 12f);
        }

        @Override
        public void setAlpha(int alpha) {
            this.alpha = alpha;
            paint.setAlpha(alpha);
            invalidateSelf();
        }

        @Override
        public void setColorFilter(android.graphics.ColorFilter filter) {
            paint.setColorFilter(filter);
            invalidateSelf();
        }

        @Override
        public int getOpacity() {
            return PixelFormat.TRANSLUCENT;
        }

        void animateTo(boolean dragging) {
            if (animation != null) {
                animation.cancel();
            }
            final float startScale = scale;
            final float startHalo = haloAlpha;
            final float targetScale = dragging ? 1.18f : 1f;
            final float targetHalo = dragging ? 0.48f : 0f;
            ValueAnimator next = ValueAnimator.ofFloat(0f, 1f);
            next.setDuration(dragging ? 140L : 180L);
            next.setInterpolator(new DecelerateInterpolator());
            next.addUpdateListener(new ValueAnimator.AnimatorUpdateListener() {
                @Override
                public void onAnimationUpdate(ValueAnimator valueAnimator) {
                    float fraction = valueAnimator.getAnimatedFraction();
                    scale = startScale + (targetScale - startScale) * fraction;
                    haloAlpha = startHalo + (targetHalo - startHalo) * fraction;
                    invalidateSelf();
                }
            });
            animation = next;
            next.start();
        }
    }

    private static final class RailOverlay extends View {
        private final Paint tickPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint markerPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final float tickSize;
        private int maxWeek = 1;
        private int realWeek = 1;

        RailOverlay(Context context, int tickColor, int markerColor) {
            super(context);
            float density = context.getResources().getDisplayMetrics().density;
            tickSize = Math.max(1f, density);
            tickPaint.setColor(tickColor);
            tickPaint.setStrokeWidth(tickSize);
            markerPaint.setColor(markerColor);
            markerPaint.setStyle(Paint.Style.STROKE);
            markerPaint.setStrokeWidth(Math.max(1.5f, density * 2f));
            setWillNotDraw(false);
        }

        void setMaxWeek(int maxWeek) {
            this.maxWeek = Math.max(1, maxWeek);
        }

        void setRealWeek(int realWeek) {
            this.realWeek = Math.max(1, Math.min(maxWeek, realWeek));
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            if (maxWeek <= 1) {
                return;
            }
            float left = getPaddingLeft() + tickSize * 2f;
            float right = getWidth() - getPaddingRight() - tickSize * 2f;
            float y = getHeight() / 2f;
            int middle = (maxWeek + 1) / 2;
            drawTick(canvas, left, right, y, 1);
            if (middle > 1 && middle < maxWeek) {
                drawTick(canvas, left, right, y, middle);
            }
            drawTick(canvas, left, right, y, maxWeek);
            float ratio = (realWeek - 1f) / (maxWeek - 1f);
            canvas.drawCircle(left + (right - left) * ratio, y,
                    Math.max(4f, tickSize * 5f), markerPaint);
        }

        private void drawTick(Canvas canvas, float left, float right, float y, int week) {
            float ratio = (week - 1f) / (maxWeek - 1f);
            float x = left + (right - left) * ratio;
            canvas.drawLine(x, y - tickSize * 3f, x, y + tickSize * 3f, tickPaint);
        }
    }
}
