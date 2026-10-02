package io.github.mxwf.weeko.about;

import android.graphics.Canvas;
import android.graphics.ColorFilter;
import android.graphics.Paint;
import android.graphics.Outline;
import android.graphics.Rect;
import android.graphics.Path;
import android.graphics.PixelFormat;
import android.graphics.drawable.Drawable;

/**
 * Continuous-corner background shared by Weeko surfaces.
 * Each corner uses two cubic Beziers with matching first and second derivatives
 * at their join. Collinear end controls make the curvature zero at each straight edge.
 */
public class G2ShapeDrawable extends Drawable {
    private final Paint fill = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path path = new Path();
    private final float strokeWidth;
    private final float cornerRadius;
    private final boolean topOnly;
    private final int fillAlpha;
    private final int strokeAlpha;

    public G2ShapeDrawable(int fillColor, int strokeColor, float strokeWidth, float cornerRadius) {
        this(fillColor, strokeColor, strokeWidth, cornerRadius, false);
    }

    public G2ShapeDrawable(int fillColor, int strokeColor, float strokeWidth, float cornerRadius, boolean topOnly) {
        this.strokeWidth = strokeWidth;
        this.cornerRadius = cornerRadius;
        this.topOnly = topOnly;
        fillAlpha = android.graphics.Color.alpha(fillColor);
        strokeAlpha = android.graphics.Color.alpha(strokeColor);
        fill.setStyle(Paint.Style.FILL);
        fill.setColor(fillColor);
        stroke.setStyle(Paint.Style.STROKE);
        stroke.setStrokeWidth(strokeWidth);
        stroke.setColor(strokeColor);
    }

    private void corner(float x0, float y0, float vx0, float vy0,
                        float x1, float y1, float vx1, float vy1) {
        float mx = (x0 + x1) * 0.5f + (vx0 - vx1) * 0.32f;
        float my = (y0 + y1) * 0.5f + (vy0 - vy1) * 0.32f;
        path.cubicTo(x0 + vx0 * 0.28f, y0 + vy0 * 0.28f,
                x0 + vx0 * 0.64f, y0 + vy0 * 0.64f, mx, my);
        path.cubicTo(x1 - vx1 * 0.64f, y1 - vy1 * 0.64f,
                x1 - vx1 * 0.28f, y1 - vy1 * 0.28f, x1, y1);
    }

    @Override
    protected void onBoundsChange(Rect bounds) {
        float halfStroke = strokeWidth * 0.5f;
        float left = getBounds().left + halfStroke;
        float top = getBounds().top + halfStroke;
        float right = getBounds().right - halfStroke;
        float bottom = getBounds().bottom - halfStroke;
        float radius = Math.min(cornerRadius, Math.min((right - left) * 0.5f,
                (bottom - top) * (topOnly ? 1f : 0.5f)));
        path.reset();
        path.moveTo(left + radius, top);
        path.lineTo(right - radius, top);
        corner(right - radius, top, radius, 0f, right, top + radius, 0f, radius);
        if (topOnly) {
            path.lineTo(right, bottom);
            path.lineTo(left, bottom);
        } else {
            path.lineTo(right, bottom - radius);
            corner(right, bottom - radius, 0f, radius, right - radius, bottom, -radius, 0f);
            path.lineTo(left + radius, bottom);
            corner(left + radius, bottom, -radius, 0f, left, bottom - radius, 0f, -radius);
        }
        path.lineTo(left, top + radius);
        corner(left, top + radius, 0f, -radius, left + radius, top, radius, 0f);
        path.close();
    }

    @Override
    public void getOutline(Outline outline) {
        if (getBounds().isEmpty()) outline.setEmpty();
        else outline.setConvexPath(path);
    }

    public void clip(Canvas canvas) {
        canvas.clipPath(path);
    }

    @Override
    public void draw(Canvas canvas) {
        canvas.drawPath(path, fill);
        if (strokeWidth > 0f) {
            canvas.drawPath(path, stroke);
        }
    }

    @Override
    public void setAlpha(int alpha) {
        fill.setAlpha(fillAlpha * alpha / 255);
        stroke.setAlpha(strokeAlpha * alpha / 255);
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
