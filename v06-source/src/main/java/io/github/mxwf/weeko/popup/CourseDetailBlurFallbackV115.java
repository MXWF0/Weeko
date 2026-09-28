package io.github.mxwf.weeko.popup;

import android.graphics.RenderEffect;
import android.graphics.Shader;
import android.content.Context;
import android.view.View;
import android.view.WindowManager;

public final class CourseDetailBlurFallbackV115 {
    private CourseDetailBlurFallbackV115() {}

    public static void update(View content, int radius) {
        WindowManager windowManager = (WindowManager) content.getContext()
                .getSystemService(Context.WINDOW_SERVICE);
        if (windowManager.isCrossWindowBlurEnabled()) {
            return;
        }
        if (radius <= 0) {
            content.setRenderEffect(null);
            return;
        }
        content.setRenderEffect(RenderEffect.createBlurEffect(
                radius, radius, Shader.TileMode.CLAMP));
    }

    public static void clear(View content) {
        content.setRenderEffect(null);
    }
}
