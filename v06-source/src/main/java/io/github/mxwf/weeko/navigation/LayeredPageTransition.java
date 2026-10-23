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
import android.window.BackEvent;
import android.window.OnBackAnimationCallback;
import android.window.OnBackInvokedCallback;
import android.window.OnBackInvokedDispatcher;
import android.widget.FrameLayout;
import java.util.IdentityHashMap;
import java.util.ArrayList;
import java.util.WeakHashMap;
import io.github.mxwf.weeko.popup.GlassPopupBackground;
import io.github.mxwf.weeko.theme.UiEffects;

/** Shared page motion. Dialogs and external activities retain their own transitions. */
public final class LayeredPageTransition {
    private static final long DURATION = 320;
    private static final float DIM = 0.18f;
    private static final IdentityHashMap<Activity, PageSession> pages = new IdentityHashMap<>();
    private static final ArrayList<PendingPage> pending = new ArrayList<>();
    private static final IdentityHashMap<Activity, Boolean> launching = new IdentityHashMap<>();
    private static final WeakHashMap<View, Float> fragmentProgress = new WeakHashMap<>();
    private static final IdentityHashMap<ViewGroup, FragmentBackStack> fragmentBacks = new IdentityHashMap<>();
    private static final IdentityHashMap<Activity, OnBackInvokedCallback> restoredBacks = new IdentityHashMap<>();

    private LayeredPageTransition() {}


    public static void install(Application application) {
        application.getSharedPreferences("config", 0).registerOnSharedPreferenceChangeListener(effectsChanged);
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
                removeRestoredBack(activity);
                for (FragmentBackStack stack : fragmentBacks.values())
                    if (stack.activity == activity) stack.resetPreview();
                PageSession page = pages.get(activity);
                if (page != null) page.interrupt();
            }
            @Override public void onActivityStopped(Activity activity) {}
            @Override public void onActivitySaveInstanceState(Activity activity, Bundle state) {}
            @Override public void onActivityDestroyed(Activity activity) { destroyed(activity); }
        });
    }

    private static final android.content.SharedPreferences.OnSharedPreferenceChangeListener effectsChanged = (prefs, key) -> {
        if (!UiEffects.PREDICTIVE_BACK.equals(key) && !UiEffects.ADVANCED_MATERIALS.equals(key)) return;
        for (PageSession page : new ArrayList<>(pages.values())) {
            page.unregisterBack();
            if (page.interactive && !page.exiting) {
                page.interactive = false;
                page.animate(1f);
            }
            if (page.layer != null) page.layer.update(page.progress);
            if (page.activity.hasWindowFocus()) page.registerBack();
        }
        for (FragmentBackStack stack : fragmentBacks.values()) stack.resetPreview();
        for (Activity activity : new ArrayList<>(restoredBacks.keySet())) {
            removeRestoredBack(activity);
            if (activity.hasWindowFocus()) resumed(activity);
        }
    };

    public static void start(Context context, Intent intent) {
        if (navigationBusy(context, intent)) return;
        if (prepare(context, intent)) {
            int hold = context.getResources().getIdentifier("weeko_layered_window_hold_v115", "anim", context.getPackageName());
            context.startActivity(intent, ActivityOptions.makeCustomAnimation(context, hold, hold).toBundle());
        } else context.startActivity(intent);
    }

    public static void startForResult(Activity activity, Intent intent, int request, Bundle options) {
        if (navigationBusy(activity, intent)) return;
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
        launching.put(activity, true);
        return true;
    }

    private static boolean navigationBusy(Context context, Intent intent) {
        if (intent.getComponent() == null
                || !context.getPackageName().equals(intent.getComponent().getPackageName())) return false;
        while (context instanceof ContextWrapper && !(context instanceof Activity))
            context = ((ContextWrapper) context).getBaseContext();
        if (!(context instanceof Activity)) return false;
        PageSession page = pages.get((Activity) context);
        return launching.containsKey((Activity) context)
                || (page != null && (page.exiting || (page.started && page.progress < 1f)));
    }

    public static void resumed(Activity activity) {
        launching.remove(activity);
        PageSession page = pages.get(activity);
        if (page != null) {
            page.enter();
            page.registerBack();
        } else if (Build.VERSION.SDK_INT >= 33 && supportsActivityBack(activity)
                && !restoredBacks.containsKey(activity)) {
            OnBackInvokedCallback callback = UiEffects.predictiveBack(activity)
                    ? new BackGesture(activity, null) : activity::onBackPressed;
            restoredBacks.put(activity, callback);
            activity.getOnBackInvokedDispatcher().registerOnBackInvokedCallback(
                    OnBackInvokedDispatcher.PRIORITY_DEFAULT, callback);
        }
    }

    private static boolean supportsActivityBack(Activity activity) {
        if (activity.getClass().getName().equals("io.github.mxwf.weeko.about.WeekoAboutActivity")) return true;
        if (activity.getClass().getName().contains(".schedule_appwidget.")) return false;
        for (Class<?> type = activity.getClass(); type != null; type = type.getSuperclass())
            if (type.getName().equals("com.suda.yzune.wakeupschedule.base_view.BaseActivity")) return true;
        return false;
    }

    private static void removeRestoredBack(Activity activity) {
        OnBackInvokedCallback callback = restoredBacks.remove(activity);
        if (Build.VERSION.SDK_INT >= 33 && callback != null)
            activity.getOnBackInvokedDispatcher().unregisterOnBackInvokedCallback(callback);
    }

    /** NavHost enables its legacy bridge after navigation. Keep one native owner
     * at the SAME normal priority, then commit through the original dispatcher.
     * A higher priority would incorrectly intercept the input method's back. */
    public static void frameworkBackRegistered(Object dispatcher) {
        for (PageSession page : pages.values()) {
            if (page.activity.getOnBackInvokedDispatcher() != dispatcher) continue;
            OnBackInvokedCallback callback = page.backGesture != null ? page.backGesture : page.ordinaryBack;
            if (callback != null) {
                page.activity.getOnBackInvokedDispatcher().unregisterOnBackInvokedCallback(callback);
                page.activity.getOnBackInvokedDispatcher().registerOnBackInvokedCallback(
                        OnBackInvokedDispatcher.PRIORITY_DEFAULT, callback);
            }
            return;
        }
        for (Activity activity : restoredBacks.keySet()) {
            if (activity.getOnBackInvokedDispatcher() != dispatcher) continue;
            OnBackInvokedCallback callback = restoredBacks.get(activity);
            activity.getOnBackInvokedDispatcher().unregisterOnBackInvokedCallback(callback);
            activity.getOnBackInvokedDispatcher().registerOnBackInvokedCallback(
                    OnBackInvokedDispatcher.PRIORITY_DEFAULT, callback);
            return;
        }
    }

    public static void destroyed(Activity activity) {
        removeRestoredBack(activity);
        for (FragmentBackStack stack : new ArrayList<>(fragmentBacks.values())) {
            if (stack.activity == activity) {
                stack.dispose();
                fragmentBacks.remove(stack.container);
            }
        }
        launching.remove(activity);
        PageSession page = pages.remove(activity);
        if (page != null) page.dispose();
    }

    /** Reverse the same live progress before finishing the window. */
    public static boolean finish(Activity activity) {
        PageSession page = pages.get(activity);
        if (page != null && !page.finished) {
            return page.exit();
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
        boolean started, finished, exiting, interactive;
        BackGesture backGesture;
        OnBackInvokedCallback ordinaryBack;
        final Runnable firstFrame = () -> {
            if (!finished && !exiting && !interactive && layer != null) animate(1f);
        };
        final Runnable frameCommitted = () -> content.postOnAnimation(firstFrame);

        PageSession(Activity activity, Activity source, PageSnapshot sample) {
            this.activity = activity; this.source = source; this.sample = sample;
        }

        void enter() {
            if (started) return;
            started = true;
            // Dynamic themes can replace AppTheme's no-op window animation.
            // This session owns the complete slide, including window dismissal.
            activity.getWindow().setWindowAnimations(0);
            if (Build.VERSION.SDK_INT >= 34)
                activity.overrideActivityTransition(Activity.OVERRIDE_TRANSITION_CLOSE, 0, 0);
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
            opaquePage(content);
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
            if (Build.VERSION.SDK_INT >= 29) {
                Trace.setCounter("Weeko.page.progress", Math.round(fraction * 1000));
                Trace.setCounter("Weeko.page.direction", exiting ? -1 : interactive ? 0 : 1);
            }
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
                    animator = null;
                    if (to == 0f) {
                        unregisterBack();
                        finished = true;
                        activity.finish();
                        activity.overridePendingTransition(0, 0);
                    } else {
                        layer.clear();
                        layer = null;
                    }
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
            unregisterBack();
            if (content != null) content.getViewTreeObserver().removeOnPreDrawListener(this);
            if (content != null && Build.VERSION.SDK_INT >= 29) {
                content.getViewTreeObserver().unregisterFrameCommitCallback(frameCommitted);
                content.removeCallbacks(firstFrame);
            }
            cancelAnimator();
            if (layer != null) {
                update(exiting ? 0f : 1f);
                layer.clear();
                layer = null;
            }
            if (sample != null) {
                sample.release();
                sample = null;
            }
            if (exiting) {
                finished = true;
                activity.finish();
                activity.overridePendingTransition(0, 0);
            }
        }

        void stopScheduledEntrance() {
            content.getViewTreeObserver().removeOnPreDrawListener(this);
            if (Build.VERSION.SDK_INT >= 29) {
                content.getViewTreeObserver().unregisterFrameCommitCallback(frameCommitted);
                content.removeCallbacks(firstFrame);
            }
            cancelAnimator();
        }

        void revealSource() {
            if (layer != null) return;
            ViewGroup host = (ViewGroup) content.getParent();
            layer = new Underlay(host, capture(source.findViewById(android.R.id.content)), false);
            host.addView(layer, host.indexOfChild(content), new ViewGroup.LayoutParams(-1, -1));
            layer.setX(content.getLeft());
            layer.setY(content.getTop());
        }

        boolean exit() {
            if (exiting) return true;
            if (content == null || content.getWidth() == 0) {
                interrupt();
                finished = true;
                return false;
            }
            stopScheduledEntrance();
            revealSource();
            exiting = true;
            update(progress);
            animate(0f);
            return true;
        }

        void registerBack() {
            if (Build.VERSION.SDK_INT < 33 || backGesture != null || ordinaryBack != null) return;
            if (!supportsActivityBack(activity)) return;
            if (UiEffects.predictiveBack(activity)) {
                backGesture = new BackGesture(activity, this);
                activity.getOnBackInvokedDispatcher().registerOnBackInvokedCallback(
                        OnBackInvokedDispatcher.PRIORITY_DEFAULT, backGesture);
            } else {
                // A non-animated callback consumes system preview, then invokes the
                // original dispatcher (including unsaved-data confirmation).
                ordinaryBack = activity::onBackPressed;
                activity.getOnBackInvokedDispatcher().registerOnBackInvokedCallback(
                        OnBackInvokedDispatcher.PRIORITY_DEFAULT, ordinaryBack);
            }
        }

        void unregisterBack() {
            if (Build.VERSION.SDK_INT >= 34 && backGesture != null) {
                activity.getOnBackInvokedDispatcher().unregisterOnBackInvokedCallback(backGesture);
                backGesture = null;
            }
            if (Build.VERSION.SDK_INT >= 33 && ordinaryBack != null) {
                activity.getOnBackInvokedDispatcher().unregisterOnBackInvokedCallback(ordinaryBack);
                ordinaryBack = null;
            }
        }

        void clear() {
            unregisterBack();
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
            unregisterBack();
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

    private static final class BackGesture implements OnBackAnimationCallback {
        private final Activity activity;
        private final PageSession page;
        private FragmentBackStack fragment;
        private final DecelerateInterpolator easing = new DecelerateInterpolator();
        private float start;
        private boolean pagePreview;
        BackGesture(Activity activity, PageSession page) { this.activity = activity; this.page = page; }
        private boolean active() {
            return page == null ? restoredBacks.get(activity) == this
                    : page.backGesture == this && !page.exiting && !page.finished;
        }
        @Override public void onBackStarted(BackEvent event) {
            if (!active()) return;
            fragment = null;
            pagePreview = false;
            // Browser history is an in-page back, not a return to the school list.
            ArrayList<View> views = new ArrayList<>();
            views.add(activity.findViewById(android.R.id.content));
            for (int i = 0; i < views.size(); i++) {
                View view = views.get(i);
                if (view instanceof android.webkit.WebView && ((android.webkit.WebView) view).canGoBack()) return;
                if (view instanceof ViewGroup) {
                    ViewGroup group = (ViewGroup) view;
                    for (int child = 0; child < group.getChildCount(); child++) views.add(group.getChildAt(child));
                }
            }
            for (FragmentBackStack stack : fragmentBacks.values()) {
                if (stack.activity == activity && !stack.history.isEmpty()
                        && stack.current.isShown()) {
                    fragment = stack;
                    fragment.begin();
                    start = fragment.progress;
                    return;
                }
            }
            if (page == null) return;
            if (page.backGesture != this || page.exiting || page.finished) return;
            pagePreview = true;
            page.interactive = true;
            page.stopScheduledEntrance();
            page.revealSource();
            start = page.progress;
        }
        @Override public void onBackProgressed(BackEvent event) {
            if (!active()) return;
            if (fragment != null) { fragment.update(start * (1f - easing.getInterpolation(event.getProgress()))); return; }
            if (!pagePreview) return;
            if (page.backGesture != this || page.exiting || page.finished) return;
            page.update(start * (1f - easing.getInterpolation(event.getProgress())));
        }
        @Override public void onBackCancelled() {
            if (!active()) { fragment = null; return; }
            if (fragment != null) { fragment.restore(); fragment = null; return; }
            if (!pagePreview) return;
            if (page.backGesture != this || page.exiting || page.finished) return;
            page.interactive = false;
            page.animate(1f);
        }
        @Override public void onBackInvoked() {
            if (!active()) return;
            if (fragment != null) {
                FragmentBackStack stack = fragment;
                fragment = null;
                fragmentProgress.put(stack.container, stack.progress);
                activity.onBackPressed();
                // A prompt may consume back without popping. Decide at the next
                // traversal, after FragmentManager has applied its actual change.
                stack.container.getViewTreeObserver().addOnPreDrawListener(new ViewTreeObserver.OnPreDrawListener() {
                    @Override public boolean onPreDraw() {
                        stack.container.getViewTreeObserver().removeOnPreDrawListener(this);
                        if (stack.stage != null) stack.restore();
                        return true;
                    }
                });
                return;
            }
            if (!pagePreview) { activity.onBackPressed(); return; }
            if (page.backGesture != this || page.exiting || page.finished) return;
            page.interactive = false;
            page.activity.onBackPressed();
            // Unsaved-data prompts retain their existing choice and navigation.
            if (!page.exiting && !page.finished && page.layer != null) page.animate(1f);
        }
    }

    /** Preview only the internal page stack recorded by the four shared Nav animations.
     * The real NavHost/unsaved-data dispatcher is invoked only on gesture commit. */
    private static final class FragmentBackStack {
        final Activity activity;
        final ViewGroup container;
        final ArrayList<PageSnapshot> history = new ArrayList<>();
        View current;
        FrameLayout stage;
        Underlay layer;
        ValueAnimator animator;
        float progress = 1f;
        FragmentBackStack(ViewGroup container, Activity activity) {
            this.container = container; this.activity = activity;
        }
        void begin() {
            cancelAnimator();
            Animation motion = current.getAnimation();
            if (motion != null) motion.cancel();
            current.clearAnimation();
            Float interrupted = fragmentProgress.get(container);
            progress = interrupted == null ? 1f : interrupted;
            if (stage == null) {
                PageSnapshot saved = history.get(history.size() - 1);
                stage = new FrameLayout(activity);
                int width = current.getWidth(), height = current.getHeight();
                layer = new Underlay(stage, new PageSnapshot(saved.commands, saved.pixels), false);
                stage.addView(layer, new FrameLayout.LayoutParams(-1, -1));
                stage.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
                        View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY));
                stage.layout(current.getLeft(), current.getTop(), current.getRight(), current.getBottom());
                container.getOverlay().add(stage);
            }
            update(progress);
        }
        void update(float value) {
            progress = value;
            int width = current.getWidth();
            current.setTranslationX(width * (1f - value));
            layer.setTranslationX(-width * 0.2f * value);
            layer.update(value);
            stage.setClipBounds(new Rect(0, 0, Math.round(width * (1f - value)), current.getHeight()));
            if (Build.VERSION.SDK_INT >= 29) Trace.setCounter("Weeko.fragment.gesture", Math.round(value * 1000));
        }
        void restore() {
            cancelAnimator();
            animator = ValueAnimator.ofFloat(progress, 1f);
            animator.setDuration(DURATION);
            animator.setInterpolator(new DecelerateInterpolator());
            animator.addUpdateListener(value -> update((float) value.getAnimatedValue()));
            animator.addListener(new AnimatorListenerAdapter() {
                @Override public void onAnimationEnd(Animator animation) { resetPreview(); }
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
        void resetPreview() {
            cancelAnimator();
            if (stage == null) return;
            current.setTranslationX(0f);
            layer.release();
            container.getOverlay().remove(stage);
            stage = null;
            layer = null;
            fragmentProgress.remove(container);
        }
        void dispose() {
            resetPreview();
            for (PageSnapshot sample : history) sample.release();
            history.clear();
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

    private static void opaquePage(View page) {
        TypedValue surface = new TypedValue();
        page.getContext().getTheme().resolveAttribute(android.R.attr.colorBackground, surface, true);
        page.setBackgroundColor(surface.data);
    }

    private static final class PageAnimation extends Animation {
        private final View target;
        private final int role;
        private Underlay layer;
        private int width;
        private View container;
        private float returnStart = 1f;

        PageAnimation(View target, int role) {
            this.target = target;
            this.role = role;
            // Fragment roots can be transparent lists, unlike Activity content.
            // Both pages need the same opaque canvas before sampling or sliding.
            if (target.getBackground() == null) opaquePage(target);
            setDuration(DURATION);
            setInterpolator(new DecelerateInterpolator());
        }

        @Override public void initialize(int width, int height, int parentWidth, int parentHeight) {
            super.initialize(width, height, parentWidth, parentHeight);
            this.width = parentWidth;
            container = (View) target.getParent();
            ViewGroup host = (ViewGroup) container;
            FragmentBackStack stack = fragmentBacks.get(host);
            if (stack == null) {
                Context owner = target.getContext();
                while (owner instanceof ContextWrapper && !(owner instanceof Activity))
                    owner = ((ContextWrapper) owner).getBaseContext();
                stack = new FragmentBackStack(host, (Activity) owner);
                fragmentBacks.put(host, stack);
            }
            if (role == 2 || role == 3) {
                Float interrupted = fragmentProgress.get(container);
                if (interrupted != null) returnStart = interrupted;
                stack.resetPreview();
                fragmentProgress.put(container, returnStart);
            }
            if (role == 1) stack.history.add(capture((ViewGroup) target));
            if (role == 2 && !stack.history.isEmpty()) stack.history.remove(stack.history.size() - 1).release();
            if (role == 0 || role == 2) stack.current = target;
            if (role == 1 || role == 2) layer = new Underlay((ViewGroup) target);
        }

        @Override protected void applyTransformation(float fraction, Transformation transform) {
            float progress = role == 0 || role == 1 ? fraction : returnStart * (1f - fraction);
            if (Build.VERSION.SDK_INT >= 29) {
                Trace.setCounter("Weeko.fragment.role", role);
                Trace.setCounter("Weeko.fragment.progress", Math.round(progress * 1000));
            }
            if (fraction == 1f) fragmentProgress.remove(container);
            else fragmentProgress.put(container, progress);
            float x = role == 0 || role == 3 ? 1f - progress : -0.2f * progress;
            transform.getMatrix().setTranslate(width * x, 0f);
            if (layer != null) {
                layer.update(progress);
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
            // Cover the live source once; transparent snapshot gaps must not
            // reveal a second, unblurred copy of the source's text or controls.
            opaquePage(this);
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
            if (Build.VERSION.SDK_INT < 31 && UiEffects.advancedMaterials(getContext())) {
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
                float radius = UiEffects.advancedMaterials(getContext())
                        ? getResources().getDisplayMetrics().density * 6f * fraction : 0f;
                image.setRenderEffect(radius > 0f ? RenderEffect.createBlurEffect(radius, radius,
                        Shader.TileMode.CLAMP) : null);
            } else {
                if (!UiEffects.advancedMaterials(getContext())) blurred = null;
                image.invalidate();
            }
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
