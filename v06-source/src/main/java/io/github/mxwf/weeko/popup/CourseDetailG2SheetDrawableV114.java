package io.github.mxwf.weeko.popup;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.ColorFilter;
import android.graphics.Outline;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PixelFormat;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;

public final class CourseDetailG2SheetDrawableV114 extends Drawable {
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path path = new Path();
    private final float cornerRadius;
    private final int baseAlpha;

    public CourseDetailG2SheetDrawableV114(Context context) {
        Resources resources = context.getResources();
        int colorId = resources.getIdentifier(
                "weeko_v114_detail_sheet", "color", context.getPackageName());
        int color = resources.getColor(colorId);
        paint.setColor(color);
        baseAlpha = Color.alpha(color);
        cornerRadius = 32f * resources.getDisplayMetrics().density;
    }

    @Override
    public void draw(Canvas canvas) {
        canvas.drawPath(path, paint);
    }

    @Override
    protected void onBoundsChange(Rect bounds) {
        updatePath(bounds);
    }

    private void updatePath(Rect bounds) {
        float left = bounds.left;
        float top = bounds.top;
        float right = bounds.right;
        float bottom = bounds.bottom;
        float radius = Math.min(cornerRadius, Math.min((right - left) / 2f, bottom - top));
        float join = radius * 0.18f;
        float tangent = radius * 0.45f;

        path.reset();
        path.moveTo(left, bottom);
        path.lineTo(left, top + radius);
        path.cubicTo(left, top + radius - tangent,
                left, top + join * 2f,
                left + join, top + join);
        path.cubicTo(left + join * 2f, top,
                left + radius - tangent, top,
                left + radius, top);
        path.lineTo(right - radius, top);
        path.cubicTo(right - radius + tangent, top,
                right - join * 2f, top,
                right - join, top + join);
        path.cubicTo(right, top + join * 2f,
                right, top + radius - tangent,
                right, top + radius);
        path.lineTo(right, bottom);
        path.close();
        invalidateSelf();
    }

    @Override
    public void getOutline(Outline outline) {
        Rect bounds = getBounds();
        if (bounds.isEmpty()) {
            outline.setEmpty();
            return;
        }
        if (path.isEmpty()) {
            updatePath(bounds);
        }
        outline.setConvexPath(path);
    }

    @Override
    public void setAlpha(int alpha) {
        paint.setAlpha(baseAlpha * alpha / 255);
        invalidateSelf();
    }

    @Override
    public void setColorFilter(ColorFilter colorFilter) {
        paint.setColorFilter(colorFilter);
        invalidateSelf();
    }

    @Override
    public int getOpacity() {
        return PixelFormat.TRANSLUCENT;
    }
}
