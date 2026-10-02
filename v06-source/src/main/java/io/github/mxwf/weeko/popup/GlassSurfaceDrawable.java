package io.github.mxwf.weeko.popup;

import android.graphics.Bitmap;
import android.graphics.BitmapShader;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.Shader;
import io.github.mxwf.weeko.about.G2ShapeDrawable;

/** One reduced-resolution sample; drawing and outline share the continuous contour. */
final class GlassSurfaceDrawable extends G2ShapeDrawable {
    private final Paint samplePaint = new Paint(Paint.FILTER_BITMAP_FLAG);
    private final Bitmap sample;
    private final BitmapShader shader;

    GlassSurfaceDrawable(Bitmap sample, int tint, int border, float density, float radius) {
        this(sample, tint, border, density, radius, false);
    }

    GlassSurfaceDrawable(Bitmap sample, int tint, int border, float density, float radius, boolean topOnly) {
        super(tint, border, density * 0.5f, density * radius, topOnly);
        this.sample = sample;
        shader = new BitmapShader(sample, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP);
        samplePaint.setShader(shader);
    }

    @Override protected void onBoundsChange(Rect bounds) {
        super.onBoundsChange(bounds);
        Matrix matrix = new Matrix();
        matrix.setScale(bounds.width() / (float) sample.getWidth(),
                bounds.height() / (float) sample.getHeight());
        matrix.postTranslate(bounds.left, bounds.top);
        shader.setLocalMatrix(matrix);
    }

    @Override public void draw(Canvas canvas) {
        int save = canvas.save();
        clip(canvas);
        canvas.drawRect(getBounds(), samplePaint);
        super.draw(canvas);
        canvas.restoreToCount(save);
    }
}
