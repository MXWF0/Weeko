package io.github.mxwf.weeko.popup;

import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.drawable.BitmapDrawable;
import android.view.View;
import android.widget.PopupWindow;

public final class GlassPopupBackground {
    private GlassPopupBackground() {}

    /** Cascade menus own their shadow; the toolbar and timetable remain untouched. */
    public static void applyTopBarMenu(View anchor, PopupWindow popup) {
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

    public static void apply(View anchor, PopupWindow popup) {
        View content = popup.getContentView();
        content.post(() -> {
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
            blur(sample, 3);

            Resources resources = content.getResources();
            Bitmap glass = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
            Canvas glassCanvas = new Canvas(glass);
            Path outline = new Path();
            float radius = 20 * resources.getDisplayMetrics().density;
            outline.addRoundRect(new RectF(0, 0, width, height), radius, radius, Path.Direction.CW);
            glassCanvas.clipPath(outline);
            glassCanvas.drawBitmap(sample, null, new Rect(0, 0, width, height), new Paint(Paint.FILTER_BITMAP_FLAG));
            sample.recycle();
            int tintId = resources.getIdentifier("weeko_v114_popup_glass", "color", content.getContext().getPackageName());
            int tint = resources.getColor(tintId);
            glassCanvas.drawColor(tint);
            content.setBackground(new BitmapDrawable(resources, glass));
        });
    }

    private static void blur(Bitmap bitmap, int radius) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        int[] input = new int[width * height];
        int[] horizontal = new int[input.length];
        int[] output = new int[input.length];
        bitmap.getPixels(input, 0, width, 0, 0, width, height);
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int red = 0, green = 0, blue = 0, count = 0;
                for (int offset = -radius; offset <= radius; offset++) {
                    int sampleX = Math.max(0, Math.min(width - 1, x + offset));
                    int color = input[y * width + sampleX];
                    red += (color >> 16) & 255;
                    green += (color >> 8) & 255;
                    blue += color & 255;
                    count++;
                }
                horizontal[y * width + x] = 0xff000000 | (red / count << 16) | (green / count << 8) | blue / count;
            }
        }
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int red = 0, green = 0, blue = 0, count = 0;
                for (int offset = -radius; offset <= radius; offset++) {
                    int sampleY = Math.max(0, Math.min(height - 1, y + offset));
                    int color = horizontal[sampleY * width + x];
                    red += (color >> 16) & 255;
                    green += (color >> 8) & 255;
                    blue += color & 255;
                    count++;
                }
                output[y * width + x] = 0xff000000 | (red / count << 16) | (green / count << 8) | blue / count;
            }
        }
        bitmap.setPixels(output, 0, width, 0, 0, width, height);
    }
}
