package io.github.mxwf.weeko.popup;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.Canvas;
import android.graphics.ColorFilter;
import android.graphics.Outline;
import android.graphics.PixelFormat;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;
import io.github.mxwf.weeko.about.G2ShapeDrawable;

public final class CourseDetailG2SheetDrawableV114 extends Drawable {
    private final G2ShapeDrawable surface;

    public CourseDetailG2SheetDrawableV114(Context context) {
        Resources resources = context.getResources();
        int baseColor = GlassDialogSurface.surfaceColor(context, "weeko_v114_detail_sheet");
        surface = new G2ShapeDrawable(baseColor, 0, 0,
                32f * resources.getDisplayMetrics().density, true);
    }

    @Override
    public void draw(Canvas canvas) {
        surface.draw(canvas);
    }

    @Override
    protected void onBoundsChange(Rect bounds) {
        surface.setBounds(bounds);
    }

    @Override
    public void getOutline(Outline outline) {
        surface.getOutline(outline);
    }

    @Override
    public void setAlpha(int alpha) {
        surface.setAlpha(alpha);
        invalidateSelf();
    }

    @Override
    public void setColorFilter(ColorFilter colorFilter) {
        surface.setColorFilter(colorFilter);
        invalidateSelf();
    }

    @Override
    public int getOpacity() {
        return PixelFormat.TRANSLUCENT;
    }
}
