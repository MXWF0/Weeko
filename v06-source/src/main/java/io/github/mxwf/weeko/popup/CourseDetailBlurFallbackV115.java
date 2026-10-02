package io.github.mxwf.weeko.popup;

import android.graphics.RenderEffect;
import android.graphics.Shader;
import android.content.Context;
import android.view.View;
import android.view.WindowManager;
import java.util.function.Consumer;

public final class CourseDetailBlurFallbackV115 implements Consumer<Boolean> {
    private final View content;
    private final WindowManager windowManager;
    private int radius;
    private int appliedRadius;

    public CourseDetailBlurFallbackV115(View content) {
        this.content = content;
        windowManager = (WindowManager) content.getContext()
                .getSystemService(Context.WINDOW_SERVICE);
        windowManager.addCrossWindowBlurEnabledListener(this);
    }

    public void update(int radius) {
        this.radius = radius;
        accept(windowManager.isCrossWindowBlurEnabled());
    }

    @Override
    public void accept(Boolean enabled) {
        int nextRadius = enabled ? 0 : radius;
        if (nextRadius == appliedRadius) return;
        appliedRadius = nextRadius;
        content.setRenderEffect(nextRadius == 0 ? null : RenderEffect.createBlurEffect(
                nextRadius, nextRadius, Shader.TileMode.CLAMP));
    }

    public void close() {
        windowManager.removeCrossWindowBlurEnabledListener(this);
        radius = 0;
        appliedRadius = 0;
        content.setRenderEffect(null);
    }

}
