package io.github.mxwf.weeko.popup;

import android.graphics.RenderEffect;
import android.graphics.Shader;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.os.Build;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.view.Window;
import android.animation.ValueAnimator;
import android.view.animation.AnimationUtils;
import io.github.mxwf.weeko.theme.UiEffects;

public final class CourseDetailBlurFallbackV115 {
    private final View content;
    private float appliedRadius;
    private View legacyOverlay;
    private Bitmap legacySample;
    private ValueAnimator entranceAnimator;
    private View entranceDecor;
    private ViewTreeObserver.OnPreDrawListener entranceStart;
    private int entranceRadius;

    public CourseDetailBlurFallbackV115(View content) {
        this.content = content;
    }

    public void update(int radius) {
        update((float) radius);
    }

    public void update(float radius) {
        if (!UiEffects.advancedMaterials(content.getContext())) {
            if (appliedRadius != 0 || entranceStart != null || entranceAnimator != null) close();
            return;
        }
        if (entranceStart != null) return;
        if (entranceAnimator != null && entranceAnimator.isRunning()) return;
        applyRadius(radius);
    }

    public void interruptEntrance() {
        if (entranceStart != null) {
            entranceDecor.getViewTreeObserver().removeOnPreDrawListener(entranceStart);
            entranceStart = null;
        }
        if (entranceAnimator != null) entranceAnimator.cancel();
    }

    public void animateEntrance(Window window, int radius) {
        if (!UiEffects.advancedMaterials(content.getContext())) return;
        entranceRadius = radius;
        entranceDecor = window.getDecorView();
        entranceStart = () -> {
            entranceDecor.getViewTreeObserver().removeOnPreDrawListener(entranceStart);
            entranceStart = null;
            android.content.res.Resources resources = entranceDecor.getResources();
            String packageName = entranceDecor.getContext().getPackageName();
            int duration = resources.getIdentifier("m3_sys_motion_duration_medium4", "integer", packageName);
            int easing = resources.getIdentifier("m3_sys_motion_easing_emphasized", "interpolator", packageName);
            entranceAnimator = ValueAnimator.ofFloat(0f, entranceRadius);
            entranceAnimator.setDuration(resources.getInteger(duration));
            entranceAnimator.setInterpolator(AnimationUtils.loadInterpolator(entranceDecor.getContext(), easing));
            entranceAnimator.addUpdateListener(animation -> applyRadius((float) animation.getAnimatedValue()));
            entranceAnimator.start();
            return true;
        };
        entranceDecor.getViewTreeObserver().addOnPreDrawListener(entranceStart);
    }

    private void applyRadius(float radius) {
        if (!UiEffects.advancedMaterials(content.getContext())) radius = 0;
        if (radius == appliedRadius) return;
        appliedRadius = radius;
        if (Build.VERSION.SDK_INT >= 31) {
            content.setRenderEffect(radius == 0 ? null : RenderEffect.createBlurEffect(
                    radius, radius, Shader.TileMode.CLAMP));
        } else {
            if (legacyOverlay == null && radius > 0) {
                int width = content.getWidth(), height = content.getHeight();
                legacySample = Bitmap.createBitmap(Math.max(1, width / 4), Math.max(1, height / 4), Bitmap.Config.ARGB_8888);
                Canvas canvas = new Canvas(legacySample);
                canvas.scale(legacySample.getWidth() / (float) width, legacySample.getHeight() / (float) height);
                content.draw(canvas);
                GlassPopupBackground.blur(legacySample, Math.max(1, Math.round(
                        content.getResources().getDisplayMetrics().density * 6f / 4f)));
                legacyOverlay = new View(content.getContext()) {
                    private final Paint paint = new Paint(Paint.FILTER_BITMAP_FLAG);
                    private final Rect bounds = new Rect(0, 0, width, height);
                    @Override protected void onDraw(Canvas canvas) {
                        canvas.drawBitmap(legacySample, null, bounds, paint);
                    }
                };
                legacyOverlay.layout(0, 0, width, height);
                ((ViewGroup) content).getOverlay().add(legacyOverlay);
            }
            if (legacyOverlay != null) legacyOverlay.setAlpha(Math.min(1f, radius /
                    (content.getResources().getDisplayMetrics().density * 6f)));
        }
    }

    public void close() {
        interruptEntrance();
        appliedRadius = 0;
        if (Build.VERSION.SDK_INT >= 31) content.setRenderEffect(null);
        if (legacyOverlay != null) {
            ((ViewGroup) content).getOverlay().remove(legacyOverlay);
            legacyOverlay = null;
            legacySample = null;
        }
    }

}
