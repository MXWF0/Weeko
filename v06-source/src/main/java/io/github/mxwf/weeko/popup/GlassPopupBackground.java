package io.github.mxwf.weeko.popup;

import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.drawable.RippleDrawable;
import android.os.Build;
import android.content.res.ColorStateList;
import android.view.ViewGroup;
import io.github.mxwf.weeko.about.G2ShapeDrawable;
import android.view.View;
import android.widget.PopupWindow;
import android.widget.AbsListView;
import android.widget.TextView;
import android.widget.ImageView;
import io.github.mxwf.weeko.theme.SoftDynamicColors;

public final class GlassPopupBackground {
    private GlassPopupBackground() {}

    /** Cascade menus own their shadow; the toolbar and timetable remain untouched. */
    public static void applyTopBarMenu(View anchor, PopupWindow popup) {
        // Keep the fade on the window compositor. A view-transition end
        // listener otherwise tears down this window during the next page's
        // first animation frames, blocking their shared UI thread.
        android.transition.Transition exit = popup.getExitTransition();
        android.os.Trace.beginSection("Weeko.menu.exit." + (exit == null ? "none" : exit.getClass().getSimpleName() + "." + exit.getDuration()));
        android.os.Trace.endSection();
        popup.setExitTransition(null);
        popup.setAnimationStyle(anchor.getResources().getIdentifier(
                "WeekoTopBarMenuWindowAnimationV115", "style", anchor.getContext().getPackageName()));
        apply(anchor, popup);
        View content = popup.getContentView();
        popup.setElevation(6f * content.getResources().getDisplayMetrics().density);
        content.post(() -> {
            if (!popup.isShowing()) return;
            float density = content.getResources().getDisplayMetrics().density;
            boolean dark = (content.getResources().getConfiguration().uiMode
                    & android.content.res.Configuration.UI_MODE_NIGHT_MASK)
                    == android.content.res.Configuration.UI_MODE_NIGHT_YES;
            float margin = 12f * density;
            int width = content.getWidth(), height = content.getHeight();
            Bitmap shade = Bitmap.createBitmap(Math.round((width + margin * 2f) / 2f),
                    Math.round((height + margin * 2f) / 2f), Bitmap.Config.ARGB_8888);
            Canvas shadeCanvas = new Canvas(shade);
            shadeCanvas.scale(0.5f, 0.5f);
            shadeCanvas.translate(margin, margin);
            android.graphics.Paint shadowPaint = new android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG);
            shadowPaint.setColor(0xff000000);
            shadowPaint.setStyle(android.graphics.Paint.Style.STROKE);
            shadowPaint.setStrokeWidth(density);
            shadowPaint.setShadowLayer(8f * density, 0f, 3f * density, dark ? 0x38000000 : 0x24000000);
            shadeCanvas.drawRoundRect(0f, 0f, width, height, 20f * density, 20f * density, shadowPaint);
            // Keep only the soft shadow: no filled silhouette or hard outline behind the glass.
            shadowPaint.clearShadowLayer();
            shadowPaint.setStrokeWidth(2f * density);
            shadowPaint.setXfermode(new android.graphics.PorterDuffXfermode(android.graphics.PorterDuff.Mode.CLEAR));
            shadeCanvas.drawRoundRect(0f, 0f, width, height, 20f * density, 20f * density, shadowPaint);
            android.graphics.Paint bitmapPaint = new android.graphics.Paint(android.graphics.Paint.FILTER_BITMAP_FLAG);
            android.graphics.RectF shadeBounds = new android.graphics.RectF(content.getLeft() - margin,
                    content.getTop() - margin, content.getLeft() + width + margin, content.getTop() + height + margin);
            android.graphics.drawable.Drawable shadow = new android.graphics.drawable.Drawable() {
                @Override public void draw(Canvas canvas) { canvas.drawBitmap(shade, null, shadeBounds, bitmapPaint); }
                @Override public void setAlpha(int alpha) {}
                @Override public void setColorFilter(android.graphics.ColorFilter filter) {}
                @Override public int getOpacity() { return android.graphics.PixelFormat.TRANSLUCENT; }
            };
            content.setElevation(0f);
            content.setClipToOutline(true);
            View background = (View) content.getParent();
            background.setBackground(shadow);
            background.setElevation(0f);
            background.setOutlineProvider(android.view.ViewOutlineProvider.BACKGROUND);
            ((android.view.ViewGroup) background.getParent()).setClipChildren(false);
            android.view.ViewGroup menu = (android.view.ViewGroup) content;
            for (int i = 0; i < menu.getChildCount(); i++) menuFeedback(menu.getChildAt(i), density);
            popup.update();
        });
    }

    private static void menuFeedback(View view, float density) {
        if (view.isClickable() || view instanceof android.widget.AbsListView) {
            int id = view.getResources().getIdentifier("weeko_v114_popup_item_pressed", "color",
                    view.getContext().getPackageName());
            int base = view.getResources().getColor(id);
            int color = (base & 0xff000000) | (io.github.mxwf.weeko.theme.SoftDynamicColors
                    .resolveAccent(view.getContext(), base) & 0x00ffffff);
            android.graphics.drawable.RippleDrawable ripple = new android.graphics.drawable.RippleDrawable(
                    android.content.res.ColorStateList.valueOf(color), null,
                    new io.github.mxwf.weeko.about.G2ShapeDrawable(0xffffffff, 0, 0, 16f * density));
            if (view instanceof android.widget.AbsListView) {
                ((android.widget.AbsListView) view).setSelector(ripple);
                ((android.widget.AbsListView) view).setDrawSelectorOnTop(true);
            } else view.setBackground(ripple);
        }
        if (view instanceof android.view.ViewGroup) {
            android.view.ViewGroup group = (android.view.ViewGroup) view;
            for (int i = 0; i < group.getChildCount(); i++) menuFeedback(group.getChildAt(i), density);
        }
    }

    public static void applyHint(View anchor, PopupWindow popup) {
        View content = popup.getContentView();
        Resources resources = content.getResources();
        String packageName = content.getContext().getPackageName();
        content.findViewById(resources.getIdentifier("balloon_card", "id", packageName)).setBackground(null);
        TextView text = content.findViewById(resources.getIdentifier("balloon_text", "id", packageName));
        text.setTextColor(resources.getColor(resources.getIdentifier("md_theme_onSurface", "color", packageName)));
        ImageView arrow = content.findViewById(resources.getIdentifier("balloon_arrow", "id", packageName));
        arrow.setImageTintList(ColorStateList.valueOf(GlassDialogSurface.surfaceColor(content.getContext(), "weeko_v114_popup_glass")));
        apply(anchor, popup);
    }

    public static void apply(View anchor, PopupWindow popup) {
        View content = popup.getContentView();
        content.post(() -> {
            if (!popup.isShowing()) return;
            int width = content.getWidth();
            int height = content.getHeight();
            int[] popupPosition = new int[2];
            int[] rootPosition = new int[2];
            content.getLocationOnScreen(popupPosition);
            View root = anchor.getRootView();
            root.getLocationOnScreen(rootPosition);

            Bitmap sample = Bitmap.createBitmap(Math.max(1, width / 4), Math.max(1, height / 4), Bitmap.Config.ARGB_8888);
            Canvas sampleCanvas = new Canvas(sample);
            sampleCanvas.scale(sample.getWidth() / (float) width, sample.getHeight() / (float) height);
            sampleCanvas.translate(rootPosition[0] - popupPosition[0], rootPosition[1] - popupPosition[1]);
            root.draw(sampleCanvas);
            blur(sample, Math.max(1, Math.round(6f * content.getResources().getDisplayMetrics().density / 4f)));

            Resources resources = content.getResources();
            int tint = GlassDialogSurface.surfaceColor(content.getContext(), "weeko_v114_popup_glass");
            float density = resources.getDisplayMetrics().density;
            int borderId = resources.getIdentifier("weeko_v114_popup_outline", "color", content.getContext().getPackageName());
            content.setBackground(new GlassSurfaceDrawable(sample, tint, resources.getColor(borderId), density, 20f));
            content.setClipToOutline(true);
            popup.setElevation(7f * density);
            content.setElevation(7f * density);
            if (content.getParent() instanceof ViewGroup) {
                ((ViewGroup) content.getParent()).setClipChildren(false);
            }
            if (Build.VERSION.SDK_INT >= 28) {
                content.setOutlineAmbientShadowColor(0x18000000);
                content.setOutlineSpotShadowColor(0x28000000);
            }
            if (content instanceof ViewGroup) {
                ViewGroup group = (ViewGroup) content;
                for (int index = 0; index < group.getChildCount(); index++) roundFeedback(group.getChildAt(index), density);
            }
        });
    }

    private static void roundFeedback(View view, float density) {
        if (view instanceof AbsListView || view.isClickable()) {
            int colorId = view.getResources().getIdentifier("weeko_v114_popup_item_pressed", "color", view.getContext().getPackageName());
            int base = view.getResources().getColor(colorId);
            int color = (base & 0xff000000)
                    | (SoftDynamicColors.resolveAccent(view.getContext(), base) & 0x00ffffff);
            G2ShapeDrawable mask = new G2ShapeDrawable(Color.WHITE, 0, 0, 16f * density);
            RippleDrawable ripple = new RippleDrawable(ColorStateList.valueOf(color), null, mask);
            if (view instanceof AbsListView) {
                ((AbsListView) view).setSelector(ripple);
                ((AbsListView) view).setDrawSelectorOnTop(true);
                return;
            }
            view.setBackground(ripple);
        }
        if (view instanceof ViewGroup) {
            ViewGroup group = (ViewGroup) view;
            for (int index = 0; index < group.getChildCount(); index++) roundFeedback(group.getChildAt(index), density);
        }
    }

    public static void blur(Bitmap bitmap, int radius) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        int[] input = new int[width * height];
        int[] horizontal = new int[input.length];
        bitmap.getPixels(input, 0, width, 0, 0, width, height);
        int count = radius * 2 + 1;
        for (int y = 0; y < height; y++) {
            int red = 0, green = 0, blue = 0;
            for (int offset = -radius; offset <= radius; offset++) {
                int color = input[y * width + Math.max(0, Math.min(width - 1, offset))];
                red += (color >> 16) & 255;
                green += (color >> 8) & 255;
                blue += color & 255;
            }
            for (int x = 0; x < width; x++) {
                horizontal[y * width + x] = 0xff000000 | (red / count << 16) | (green / count << 8) | blue / count;
                int removed = input[y * width + Math.max(0, x - radius)];
                int added = input[y * width + Math.min(width - 1, x + radius + 1)];
                red += ((added >> 16) & 255) - ((removed >> 16) & 255);
                green += ((added >> 8) & 255) - ((removed >> 8) & 255);
                blue += (added & 255) - (removed & 255);
            }
        }
        for (int x = 0; x < width; x++) {
            int red = 0, green = 0, blue = 0;
            for (int offset = -radius; offset <= radius; offset++) {
                int color = horizontal[Math.max(0, Math.min(height - 1, offset)) * width + x];
                red += (color >> 16) & 255;
                green += (color >> 8) & 255;
                blue += color & 255;
            }
            for (int y = 0; y < height; y++) {
                input[y * width + x] = 0xff000000 | (red / count << 16) | (green / count << 8) | blue / count;
                int removed = horizontal[Math.max(0, y - radius) * width + x];
                int added = horizontal[Math.min(height - 1, y + radius + 1) * width + x];
                red += ((added >> 16) & 255) - ((removed >> 16) & 255);
                green += ((added >> 8) & 255) - ((removed >> 8) & 255);
                blue += (added & 255) - (removed & 255);
            }
        }
        bitmap.setPixels(input, 0, width, 0, 0, width, height);
    }
}
