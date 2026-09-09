package io.github.mxwf.weeko.about;

import android.graphics.Canvas;
import android.graphics.ColorFilter;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PixelFormat;
import android.graphics.drawable.Drawable;

/**
 * Platform-only continuous-corner background for the Weeko About screen.
 * Each corner is a quintic Hermite segment with zero second derivative at both
 * joins, so its curvature meets the straight edges at zero. The segment is
 * sampled finely for the Android canvas rasterizer.
 */
public final class G2ShapeDrawable extends Drawable {
    private final Paint fill = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path path = new Path();
    private final float strokeWidth;
    private final float cornerRadius;

    public G2ShapeDrawable(int fillColor, int strokeColor, float strokeWidth, float cornerRadius) {
        this.strokeWidth = strokeWidth;
        this.cornerRadius = cornerRadius;
        fill.setStyle(Paint.Style.FILL);
        fill.setColor(fillColor);
        stroke.setStyle(Paint.Style.STROKE);
        stroke.setStrokeWidth(strokeWidth);
        stroke.setColor(strokeColor);
    }

    private static float h00(float t) {
        return 1f - 10f * t * t * t + 15f * t * t * t * t - 6f * t * t * t * t * t;
    }

    private static float h10(float t) {
        return t - 6f * t * t * t + 8f * t * t * t * t - 3f * t * t * t * t * t;
    }

    private static float h01(float t) {
        return 10f * t * t * t - 15f * t * t * t * t + 6f * t * t * t * t * t;
    }

    private static float h11(float t) {
        return -4f * t * t * t + 7f * t * t * t * t - 3f * t * t * t * t * t;
    }

    private static float dh00(float t) {
        return -30f * t * t + 60f * t * t * t - 30f * t * t * t * t;
    }

    private static float dh10(float t) {
        return 1f - 18f * t * t + 32f * t * t * t - 15f * t * t * t * t;
    }

    private static float dh01(float t) {
        return 30f * t * t - 60f * t * t * t + 30f * t * t * t * t;
    }

    private static float dh11(float t) {
        return -12f * t * t + 28f * t * t * t - 15f * t * t * t * t;
    }

    private static float point(float t, float p0, float v0, float p1, float v1) {
        return h00(t) * p0 + h10(t) * v0 + h01(t) * p1 + h11(t) * v1;
    }

    private static float velocity(float t, float p0, float v0, float p1, float v1) {
        return dh00(t) * p0 + dh10(t) * v0 + dh01(t) * p1 + dh11(t) * v1;
    }

    private void corner(float x0, float y0, float vx0, float vy0,
                        float x1, float y1, float vx1, float vy1) {
        final int segments = 8;
        for (int i = 0; i < segments; i++) {
            float t0 = i / (float) segments;
            float t1 = (i + 1) / (float) segments;
            float dt = t1 - t0;
            float sx = point(t0, x0, vx0, x1, vx1);
            float sy = point(t0, y0, vy0, y1, vy1);
            float ex = point(t1, x0, vx0, x1, vx1);
            float ey = point(t1, y0, vy0, y1, vy1);
            float c1x = sx + velocity(t0, x0, vx0, x1, vx1) * dt / 3f;
            float c1y = sy + velocity(t0, y0, vy0, y1, vy1) * dt / 3f;
            float c2x = ex - velocity(t1, x0, vx0, x1, vx1) * dt / 3f;
            float c2y = ey - velocity(t1, y0, vy0, y1, vy1) * dt / 3f;
            path.cubicTo(c1x, c1y, c2x, c2y, ex, ey);
        }
    }

    @Override
    public void draw(Canvas canvas) {
        float halfStroke = strokeWidth * 0.5f;
        float left = getBounds().left + halfStroke;
        float top = getBounds().top + halfStroke;
        float right = getBounds().right - halfStroke;
        float bottom = getBounds().bottom - halfStroke;
        float radius = Math.min(cornerRadius, Math.min(right - left, bottom - top) * 0.5f);
        path.reset();
        path.moveTo(left + radius, top);
        path.lineTo(right - radius, top);
        corner(right - radius, top, radius, 0f, right, top + radius, 0f, radius);
        path.lineTo(right, bottom - radius);
        corner(right, bottom - radius, 0f, radius, right - radius, bottom, -radius, 0f);
        path.lineTo(left + radius, bottom);
        corner(left + radius, bottom, -radius, 0f, left, bottom - radius, 0f, -radius);
        path.lineTo(left, top + radius);
        corner(left, top + radius, 0f, -radius, left + radius, top, radius, 0f);
        path.close();
        canvas.drawPath(path, fill);
        if (strokeWidth > 0f) {
            canvas.drawPath(path, stroke);
        }
    }

    @Override
    public void setAlpha(int alpha) {
        fill.setAlpha(alpha);
        stroke.setAlpha(alpha);
        invalidateSelf();
    }

    @Override
    public void setColorFilter(ColorFilter colorFilter) {
        fill.setColorFilter(colorFilter);
        stroke.setColorFilter(colorFilter);
        invalidateSelf();
    }

    @Override
    public int getOpacity() {
        return PixelFormat.TRANSLUCENT;
    }
}
