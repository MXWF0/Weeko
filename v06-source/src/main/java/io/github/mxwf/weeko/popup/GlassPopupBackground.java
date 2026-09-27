package io.github.mxwf.weeko.popup;

import android.content.res.Resources;
import android.content.res.Configuration;
import android.content.res.TypedArray;
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
            if (content.getContext().getSharedPreferences("config", 0)
                    .getBoolean("dynamic_colors", false)) {
                int attr = resources.getIdentifier("colorSurface", "attr", content.getContext().getPackageName());
                TypedArray themeColor = content.getContext().obtainStyledAttributes(new int[]{attr});
                int surface = themeColor.getColor(0, tint);
                themeColor.recycle();
                boolean dark = (resources.getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK)
                        == Configuration.UI_MODE_NIGHT_YES;
                tint = (surface & 0x00ffffff) | (dark ? 0xc4000000 : 0xb8000000);
            }
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
