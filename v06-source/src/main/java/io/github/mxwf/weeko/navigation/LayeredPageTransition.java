package io.github.mxwf.weeko.navigation;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ValueAnimator;
import android.app.Activity;
import android.app.Application;
import android.app.ActivityOptions;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Picture;
import android.graphics.Rect;
import android.graphics.RenderEffect;
import android.graphics.Shader;
import android.os.Build;
import android.os.Bundle;
import android.os.Trace;
import android.util.TypedValue;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.view.animation.DecelerateInterpolator;
import android.view.animation.Transformation;
import android.widget.FrameLayout;
import java.util.IdentityHashMap;
import java.util.ArrayList;
import io.github.mxwf.weeko.popup.GlassPopupBackground;

/** Shared page motion. Dialogs and external activities retain their own transitions. */
public final class LayeredPageTransition {
    private static final long DURATION = 320;
    private static final float DIM = 0.18f;
    private static final IdentityHashMap<Activity, PageSession> pages = new IdentityHashMap<>();
    private static final IdentityHashMap<Activity, ReturnMotion> returns = new IdentityHashMap<>();
    private static final ArrayList<PendingPage> pending = new ArrayList<>();

    private LayeredPageTransition() {}


    public static void install(Application application) {
        application.registerActivityLifecycleCallbacks(new Application.ActivityLifecycleCallbacks() {
            @Override public void onActivityCreated(Activity activity, Bundle state) {
                for (int i = 0; i < pending.size(); i++) {
                    PendingPage page = pending.get(i);
                    if (page.name.equals(activity.getClass().getName())) {
                        pending.remove(i);
                        pages.put(activity, new PageSession(activity, page.source, page.sample));
                        break;
                    }
                }
            }
            @Override public void onActivityStarted(Activity activity) {}
            @Override public void onActivityResumed(Activity activity) { resumed(activity); }
            @Override public void onActivityPaused(Activity activity) {
                PageSession page = pages.get(activity);
                if (page != null) page.interrupt();
                ReturnMotion motion = returns.remove(activity);
                if (motion != null) motion.clear();
            }
            @Override public void onActivityStopped(Activity activity) {}
            @Override public void onActivitySaveInstanceState(Activity activity, Bundle state) {}
            @Override public void onActivityDestroyed(Activity activity) { destroyed(activity); }
        });
    }

    public static void start(Context context, Intent intent) {
        if (prepare(context, intent)) {
            int hold = context.getResources().getIdentifier("weeko_layered_window_hold_v115", "anim", context.getPackageName());
            context.startActivity(intent, ActivityOptions.makeCustomAnimation(context, hold, hold).toBundle());
        } else context.startActivity(intent);
    }

    public static void startForResult(Activity activity, Intent intent, int request, Bundle options) {
        if (prepare(activity, intent)) {
            int hold = activity.getResources().getIdentifier("weeko_layered_window_hold_v115", "anim", activity.getPackageName());
            Bundle motion = ActivityOptions.makeCustomAnimation(activity, hold, hold).toBundle();
            if (options != null) motion.putAll(options);
            options = motion;
        }
        activity.startActivityForResult(intent, request, options);
    }

    private static boolean prepare(Context context, Intent intent) {
        if (intent.getComponent() == null
                || !context.getPackageName().equals(intent.getComponent().getPackageName())) return false;
        String name = intent.getComponent().getClassName();
        // This legacy activity only forwards in onCreate, before it has a laid-out window.
        // Launch the actual page once and capture the visible source, not the empty redirect.
        if (name.equals("com.suda.yzune.wakeupschedule.intro.AboutActivity")) {
            name = "io.github.mxwf.weeko.about.WeekoAboutActivity";
            intent.setClassName(context, name);
        }
        if (name.endsWith("PasswordVaultActivity") || name.endsWith("SplashActivity")
                || name.endsWith("WidgetStyleConfigActivity")) return false;
        while (context instanceof ContextWrapper && !(context instanceof Activity)) {
            context = ((ContextWrapper) context).getBaseContext();
        }
        if (!(context instanceof Activity)) return false;
        Activity activity = (Activity) context;
        if (activity.getClass().getName().endsWith("SplashActivity")) return false;
        ViewGroup content = activity.findViewById(android.R.id.content);
        PageSession source = pages.get(activity);
        if (source != null) source.interrupt();
        pending.add(new PendingPage(name, activity, capture(content)));
        return true;
    }

    public static void resumed(Activity activity) {
        PageSession page = pages.get(activity);
        if (page != null) page.enter();
        ReturnMotion motion = returns.get(activity);
        if (motion != null) motion.start();
    }

    public static void destroyed(Activity activity) {
        PageSession page = pages.remove(activity);
        if (page != null) page.dispose();
        ReturnMotion motion = returns.remove(activity);
        if (motion != null) motion.clear();
    }

    /** Preserve synchronous finish semantics; the resumed page owns the return animation. */
    public static boolean finish(Activity activity) {
        PageSession page = pages.get(activity);
        if (page != null && !page.finished) {
            page.interrupt();
            page.finished = true;
            ReturnMotion old = returns.remove(page.source);
            if (old != null) old.clear();
            if (!page.source.isDestroyed()) returns.put(page.source,
                    new ReturnMotion(page.source, capture(page.content)));
        }
        return false;
    }

    private static void releasePressed(View view) {
        view.setPressed(false);
        view.jumpDrawablesToCurrentState();
        if (view instanceof ViewGroup) {
            ViewGroup group = (ViewGroup) view;
            for (int i = 0; i < group.getChildCount(); i++) releasePressed(group.getChildAt(i));
        }
    }

    private static PageSnapshot capture(ViewGroup view) {
        Trace.beginSection("Weeko.capture");
        releasePressed(view);
        int width = view.getWidth(), height = view.getHeight();
        Picture commands = Build.VERSION.SDK_INT >= 31 ? new Picture() : null;
        Trace.beginSection("Weeko.capture.allocate");
        Bitmap bitmap = commands == null ? Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888) : null;
        Canvas canvas = commands == null ? new Canvas(bitmap) : commands.beginRecording(width, height);
        Trace.endSection();
        TypedValue surface = new TypedValue();
        view.getContext().getTheme().resolveAttribute(android.R.attr.colorBackground, surface, true);
        // Flatten transparent root pixels too, so blurred glyph edges never reveal live glyphs below.
        canvas.drawColor(surface.data);
        Trace.beginSection("Weeko.capture.draw");
        view.draw(canvas);
        Trace.endSection();
        if (commands != null) commands.endRecording();
        Trace.endSection();
        return new PageSnapshot(commands, bitmap);
    }

    /** A single full-resolution, opaque recording shared by all frames of the motion. */
    private static final class PageSnapshot {
        final Picture commands;
        Bitmap pixels;
        PageSnapshot(Picture commands, Bitmap pixels) {
            this.commands = commands;
            this.pixels = pixels;
        }
        void release() {
            pixels = null;
        }
    }

    private static final class PendingPage {
        final String name;
        final Activity source;
        final PageSnapshot sample;
        PendingPage(String name, Activity source, PageSnapshot sample) {
            this.name = name; this.source = source; this.sample = sample;
        }
    }

    private static final class PageSession implements ViewTreeObserver.OnPreDrawListener {
        final Activity activity;
        final Activity source;
        PageSnapshot sample;
        ViewGroup content;
        Underlay layer;
        ValueAnimator animator;
        float progress;
        boolean started, finished;
        final Runnable firstFrame = () -> {
            if (!finished && layer != null) animate(1f);
        };
        final Runnable frameCommitted = () -> content.postOnAnimation(firstFrame);

        PageSession(Activity activity, Activity source, PageSnapshot sample) {
            this.activity = activity; this.source = source; this.sample = sample;
        }

        void enter() {
            if (started) return;
            started = true;
            content = activity.findViewById(android.R.id.content);
            ViewGroup host = (ViewGroup) content.getParent();
            Trace.beginSection(host instanceof android.widget.LinearLayout ? "Weeko.host.linear" : "Weeko.host.other");
            Trace.endSection();
            if (!(host instanceof FrameLayout)) {
                // Platform Activity decor can stack its content vertically. The
                // backdrop must overlap it, not consume the incoming page's height.
                FrameLayout stacked = new FrameLayout(activity);
                int index = host.indexOfChild(content);
                ViewGroup.LayoutParams params = content.getLayoutParams();
                host.removeView(content);
                host.addView(stacked, index, params);
                stacked.addView(content, new FrameLayout.LayoutParams(-1, -1));
                host = stacked;
            }
            layer = new Underlay(host, sample, false);
            sample = null;
            // Insert before the first traversal, not from onPreDraw where addView
            // requests a second layout of the destination's entire view tree.
            host.addView(layer, host.indexOfChild(content), new ViewGroup.LayoutParams(-1, -1));
            // The destination is an opaque page, not a second translucent image of the source.
            TypedValue surface = new TypedValue();
            activity.getTheme().resolveAttribute(android.R.attr.colorBackground, surface, true);
            content.setBackgroundColor(surface.data);
            content.getViewTreeObserver().addOnPreDrawListener(this);
        }

        @Override public boolean onPreDraw() {
            content.getViewTreeObserver().removeOnPreDrawListener(this);
            layer.setX(content.getLeft());
            layer.setY(content.getTop());
            update(0f);
            if (Build.VERSION.SDK_INT >= 29 && content.isHardwareAccelerated()) {
                // The first traversal may spend longer than a frame laying out a
                // new window. Start against the committed frame, not its stale
                // pre-layout vsync timestamp, which skips the start of the slide.
                content.getViewTreeObserver().registerFrameCommitCallback(frameCommitted);
            } else animate(1f);
            return true;
        }

        void update(float fraction) {
            Trace.beginSection("Weeko.enter.update");
            progress = fraction;
            if (Build.VERSION.SDK_INT >= 29) Trace.setCounter("Weeko.enter.progress", Math.round(fraction * 1000));
            content.setTranslationX(content.getWidth() * (1f - fraction));
            layer.setTranslationX(-content.getWidth() * 0.2f * fraction);
            layer.update(fraction);
            Trace.endSection();
        }

        void animate(float to) {
            cancelAnimator();
            animator = ValueAnimator.ofFloat(progress, to);
            animator.setDuration(DURATION);
            animator.setInterpolator(new DecelerateInterpolator());
            animator.addUpdateListener(value -> update((float) value.getAnimatedValue()));
            animator.addListener(new AnimatorListenerAdapter() {
                @Override public void onAnimationEnd(Animator animation) {
                    layer.clear();
                    layer = null;
                    animator = null;
                }
            });
            animator.start();
        }

        void cancelAnimator() {
            if (animator != null) {
                animator.removeAllListeners();
                animator.cancel();
                animator = null;
            }
        }

        void interrupt() {
            if (finished) return;
            if (content != null) content.getViewTreeObserver().removeOnPreDrawListener(this);
            if (content != null && Build.VERSION.SDK_INT >= 29) {
                content.getViewTreeObserver().unregisterFrameCommitCallback(frameCommitted);
                content.removeCallbacks(firstFrame);
            }
            cancelAnimator();
            if (layer != null) {
                update(1f);
                layer.clear();
                layer = null;
            }
            if (sample != null) {
                sample.release();
                sample = null;
            }
        }

        void clear() {
            cancelAnimator();
            if (content != null) {
                content.getViewTreeObserver().removeOnPreDrawListener(this);
            }
            // A dying window already owns this child. Do not mutate its child array during detach.
            if (layer != null) { layer.release(); layer = null; }
            if (sample != null) sample.release();
            sample = null;
        }

        void dispose() {
            cancelAnimator();
            // onDestroy can precede the last window frame. Release after actual detachment.
            if (content != null && content.isAttachedToWindow()) {
                content.getViewTreeObserver().removeOnPreDrawListener(this);
                content.addOnAttachStateChangeListener(new View.OnAttachStateChangeListener() {
                    @Override public void onViewAttachedToWindow(View view) {}
                    @Override public void onViewDetachedFromWindow(View view) {
                        view.removeOnAttachStateChangeListener(this);
                        clear();
                    }
                });
            } else clear();
        }
    }

    private static final class ReturnMotion implements ViewTreeObserver.OnPreDrawListener {
        final Activity activity;
        PageSnapshot outgoing;
        ViewGroup content;
        Underlay back, front;
        ValueAnimator animator;
        boolean started;
        final Runnable firstFrame = () -> {
            if (back != null) animate();
        };
        final Runnable frameCommitted = () -> content.postOnAnimation(firstFrame);

        ReturnMotion(Activity activity, PageSnapshot outgoing) { this.activity = activity; this.outgoing = outgoing; }

        void start() {
            if (started) return;
            started = true;
            content = activity.findViewById(android.R.id.content);
            content.getViewTreeObserver().addOnPreDrawListener(this);
        }

        @Override public boolean onPreDraw() {
            content.getViewTreeObserver().removeOnPreDrawListener(this);
            back = new Underlay(content);
            front = new Underlay(content, outgoing, true);
            outgoing = null;
            front.update(0f);
            update(1f);
            if (Build.VERSION.SDK_INT >= 29 && content.isHardwareAccelerated()) {
                content.getViewTreeObserver().registerFrameCommitCallback(frameCommitted);
            } else animate();
            return true;
        }

        void animate() {
            animator = ValueAnimator.ofFloat(1f, 0f);
            animator.setDuration(DURATION);
            animator.setInterpolator(new DecelerateInterpolator());
            animator.addUpdateListener(value -> update((float) value.getAnimatedValue()));
            animator.addListener(new AnimatorListenerAdapter() {
                @Override public void onAnimationEnd(Animator animation) {
                    returns.remove(activity);
                    clear();
                }
            });
            animator.start();
        }

        void update(float fraction) {
            Trace.beginSection("Weeko.return.update");
            if (Build.VERSION.SDK_INT >= 29) Trace.setCounter("Weeko.return.progress", Math.round(fraction * 1000));
            back.setTranslationX(-content.getWidth() * 0.2f * fraction);
            back.update(fraction);
            front.setTranslationX(content.getWidth() * (1f - fraction));
            Trace.endSection();
        }

        void clear() {
            if (animator != null) {
                animator.removeAllListeners();
                animator.cancel();
                animator = null;
            }
            if (content != null) content.getViewTreeObserver().removeOnPreDrawListener(this);
            if (content != null && Build.VERSION.SDK_INT >= 29) {
                content.getViewTreeObserver().unregisterFrameCommitCallback(frameCommitted);
                content.removeCallbacks(firstFrame);
            }
            if (front != null) { front.clear(); front = null; }
            if (back != null) { back.clear(); back = null; }
            if (outgoing != null) outgoing.release();
            outgoing = null;
        }
    }

    public static Animation load(Context context, int id, View view) {
        String name = context.getResources().getResourceEntryName(id);
        int role;
        switch (name) {
            case "nav_default_enter_anim": role = 0; break;
            case "nav_default_exit_anim": role = 1; break;
            case "nav_default_pop_enter_anim": role = 2; break;
            case "nav_default_pop_exit_anim": role = 3; break;
            default: return AnimationUtils.loadAnimation(context, id);
        }
        return new PageAnimation(view, role);
    }

    private static final class PageAnimation extends Animation {
        private final View target;
        private final int role;
        private Underlay layer;
        private int width;

        PageAnimation(View target, int role) {
            this.target = target;
            this.role = role;
            setDuration(DURATION);
            setInterpolator(new DecelerateInterpolator());
        }

        @Override public void initialize(int width, int height, int parentWidth, int parentHeight) {
            super.initialize(width, height, parentWidth, parentHeight);
            this.width = parentWidth;
            if (role == 1 || role == 2) layer = new Underlay((ViewGroup) target);
        }

        @Override protected void applyTransformation(float fraction, Transformation transform) {
            float x = role == 0 ? 1f - fraction : role == 3 ? fraction
                    : role == 1 ? -0.2f * fraction : -0.2f * (1f - fraction);
            transform.getMatrix().setTranslate(width * x, 0f);
            if (layer != null) {
                layer.update(role == 1 ? fraction : 1f - fraction);
                if (fraction == 1f) { layer.clear(); layer = null; }
            }
        }

        @Override public void cancel() {
            super.cancel();
            if (layer != null) { layer.clear(); layer = null; }
        }
    }

    private static final class Underlay extends FrameLayout {
        private final ViewGroup parent;
        private PageSnapshot sample;
        private final Paint paint = new Paint(Paint.FILTER_BITMAP_FLAG);
        private final Rect destination = new Rect();
        private final View dim;
        private Bitmap pixels;
        private float progress;
        private final View image;

        Underlay(ViewGroup parent) {
            this(parent, capture(parent), true);
        }

        Underlay(ViewGroup parent, PageSnapshot sample, boolean overlay) {
            super(parent.getContext());
            this.parent = parent;
            int width = parent.getWidth(), height = parent.getHeight();
            this.sample = sample;
            pixels = sample.pixels;
            if (Build.VERSION.SDK_INT >= 31) {
                Trace.beginSection(pixels != null ? "Weeko.snapshot.ready" : "Weeko.snapshot.commands");
                Trace.endSection();
            }
            image = new View(parent.getContext()) {
                @Override protected void onDraw(Canvas canvas) {
                    Trace.beginSection("Weeko.snapshot.draw");
                    drawSample(canvas);
                    Trace.endSection();
                }
            };
            if (Build.VERSION.SDK_INT >= 31) image.setLayerType(View.LAYER_TYPE_HARDWARE, null);
            addView(image, new FrameLayout.LayoutParams(-1, -1));
            dim = new View(parent.getContext());
            dim.setBackgroundColor(0xff000000);
            dim.setAlpha(0f);
            addView(dim, new FrameLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
            if (Build.VERSION.SDK_INT < 31) {
                blurred = sample.pixels.copy(Bitmap.Config.ARGB_8888, true);
                GlassPopupBackground.blur(blurred, Math.max(1, Math.round(
                        getResources().getDisplayMetrics().density * 6f)));
            }
            if (overlay) {
                measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
                        MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY));
                layout(0, 0, width, height);
            }
            destination.set(0, 0, width, height);
            this.overlay = overlay;
            setElevation(overlay ? getResources().getDisplayMetrics().density * 32f : 0f);
            setOutlineProvider(null);
            if (overlay) parent.getOverlay().add(this);
        }

        private Bitmap blurred;
        private final boolean overlay;

        @Override protected void onSizeChanged(int width, int height, int oldWidth, int oldHeight) {
            destination.set(0, 0, width, height);
        }

        private void drawSample(Canvas canvas) {
            // Select once at construction; never swap the sampled image during a motion.
            if (pixels != null) canvas.drawBitmap(pixels, null, destination, paint);
            else canvas.drawPicture(sample.commands, destination);
            if (blurred != null) {
                paint.setAlpha(Math.round(255 * progress));
                canvas.drawBitmap(blurred, null, destination, paint);
                paint.setAlpha(255);
            }
        }

        void update(float fraction) {
            progress = fraction;
            dim.setAlpha(DIM * fraction);
            if (Build.VERSION.SDK_INT >= 31) {
                float radius = getResources().getDisplayMetrics().density * 6f * fraction;
                image.setRenderEffect(radius > 0f ? RenderEffect.createBlurEffect(radius, radius,
                        Shader.TileMode.CLAMP) : null);
            } else image.invalidate();
        }

        void clear() {
            if (overlay) parent.getOverlay().remove(this); else parent.removeView(this);
            release();
        }

        void release() {
            sample.release();
            sample = null;
            pixels = null;
            blurred = null;
        }
    }
}
