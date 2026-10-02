package io.github.mxwf.weeko.popup;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.res.TypedArray;
import android.content.res.ColorStateList;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.drawable.RippleDrawable;
import android.os.Build;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.AbsListView;
import io.github.mxwf.weeko.about.G2ShapeDrawable;
import io.github.mxwf.weeko.theme.SoftDynamicColors;
import java.lang.ref.WeakReference;

/** Shared visual treatment for Weeko-owned confirmation, choice and input dialogs. */
public final class GlassDialogSurface {
    private static WeakReference<Dialog> visibleSheet = new WeakReference<>(null);
    private GlassDialogSurface() {}

    public static AlertDialog show(AlertDialog.Builder builder) {
        AlertDialog dialog = builder.show();
        apply(dialog);
        return dialog;
    }

    public static void apply(Dialog dialog) {
        Window window = dialog.getWindow();
        View decor = window.getDecorView();
        float density = decor.getResources().getDisplayMetrics().density;
        Context context = dialog.getContext();
        clearSurfacePanels(dialog);
        int tint = surfaceColor(context, "weeko_v114_detail_sheet");
        int border = context.getResources().getColor(context.getResources().getIdentifier(
                "weeko_v114_popup_outline", "color", context.getPackageName()));
        window.setBackgroundDrawable(new G2ShapeDrawable(tint, border, density * 0.5f, density * 24f));
        decor.setElevation(density * 4f);
        decor.setClipToOutline(true);
        // A sampled local surface keeps custom G2 outlines independent of window blur support.
        if (Build.VERSION.SDK_INT >= 31) {
            window.setBackgroundBlurRadius(0);
            window.clearFlags(WindowManager.LayoutParams.FLAG_BLUR_BEHIND);
        }
        applyFallback(dialog, decor, tint, border, 24f, false);
    }

    private static void applyFallback(Dialog dialog, View surface, int tint, int border, float radius, boolean topOnly) {
            Context owner = dialog.getContext();
            while (owner instanceof ContextWrapper && !(owner instanceof Activity)) {
                owner = ((ContextWrapper) owner).getBaseContext();
            }
            if (owner instanceof Activity) {
                View root = ((Activity) owner).getWindow().getDecorView();
                Dialog sheet = visibleSheet.get();
                View sheetRoot = null;
                if (sheet != null && sheet != dialog && sheet.isShowing()) {
                    Context sheetOwner = sheet.getContext();
                    while (sheetOwner instanceof ContextWrapper && !(sheetOwner instanceof Activity)) {
                        sheetOwner = ((ContextWrapper) sheetOwner).getBaseContext();
                    }
                    if (sheetOwner == owner) sheetRoot = sheet.getWindow().getDecorView();
                }
                View overlay = sheetRoot;
                surface.post(() -> {
                    if (!dialog.isShowing()) return;
                    int[] position = new int[2];
                    int[] origin = new int[2];
                    surface.getLocationOnScreen(position);
                    root.getLocationOnScreen(origin);
                    float density = surface.getResources().getDisplayMetrics().density;
                    Bitmap sample = Bitmap.createBitmap(Math.max(1, surface.getWidth() / 4),
                            Math.max(1, surface.getHeight() / 4), Bitmap.Config.ARGB_8888);
                    Canvas canvas = new Canvas(sample);
                    canvas.scale(sample.getWidth() / (float) surface.getWidth(),
                            sample.getHeight() / (float) surface.getHeight());
                    canvas.translate(origin[0] - position[0], origin[1] - position[1]);
                    root.draw(canvas);
                    if (overlay != null) {
                        int[] overlayOrigin = new int[2];
                        overlay.getLocationOnScreen(overlayOrigin);
                        canvas.translate(overlayOrigin[0] - origin[0], overlayOrigin[1] - origin[1]);
                        overlay.draw(canvas);
                    }
                    GlassPopupBackground.blur(sample, Math.max(1, Math.round(density * 6f / 4f)));
                    GlassSurfaceDrawable background = new GlassSurfaceDrawable(sample, tint, border, density, radius, topOnly);
                    if (topOnly) surface.setBackground(background);
                    else dialog.getWindow().setBackgroundDrawable(background);
                });
            }
    }

    static int surfaceColor(Context context, String name) {
        int base = context.getResources().getColor(context.getResources().getIdentifier(name, "color", context.getPackageName()));
        if (Build.VERSION.SDK_INT < 31 || !context.getSharedPreferences("config", Context.MODE_PRIVATE)
                .getBoolean("dynamic_colors", false)) return base;
        int attribute = context.getResources().getIdentifier("colorSurface", "attr", context.getPackageName());
        TypedArray values = context.obtainStyledAttributes(new int[]{attribute});
        int surface = values.getColor(0, base);
        values.recycle();
        int accent = SoftDynamicColors.resolveAccent(context, base);
        return Color.argb(Color.alpha(base),
                Math.round(Color.red(surface) * 0.94f + Color.red(accent) * 0.06f),
                Math.round(Color.green(surface) * 0.94f + Color.green(accent) * 0.06f),
                Math.round(Color.blue(surface) * 0.94f + Color.blue(accent) * 0.06f));
    }

    public static void applyFragment(Dialog dialog) {
        dialog.getWindow().getDecorView().post(() -> {
            if (!dialog.isShowing()) return;
            int sheetId = dialog.getContext().getResources().getIdentifier("design_bottom_sheet", "id", dialog.getContext().getPackageName());
            if (dialog.findViewById(sheetId) != null) return;
            if (dialog.getWindow().getDecorView().getBackground() instanceof G2ShapeDrawable) return;
            apply(dialog);
        });
    }

    public static void applySheet(Dialog dialog) {
        visibleSheet = new WeakReference<>(dialog);
        Window window = dialog.getWindow();
        window.getDecorView().post(() -> {
            if (!dialog.isShowing()) return;
            Context context = dialog.getContext();
            int id = context.getResources().getIdentifier("design_bottom_sheet", "id", context.getPackageName());
            View sheet = dialog.findViewById(id);
            roundMaterialSurfaces(sheet);
            // The course detail already owns its progressive blur and G2 surface.
            if (sheet.getBackground() instanceof CourseDetailG2SheetDrawableV114) return;
            float density = sheet.getResources().getDisplayMetrics().density;
            int tint = surfaceColor(context, "weeko_v114_detail_sheet");
            sheet.setBackground(new G2ShapeDrawable(tint, 0, 0, density * 32f, true));
            sheet.setClipToOutline(true);
            sheet.setElevation(density * 2f);
            if (Build.VERSION.SDK_INT >= 31 && window.getWindowManager().isCrossWindowBlurEnabled()) {
                window.addFlags(WindowManager.LayoutParams.FLAG_BLUR_BEHIND);
                WindowManager.LayoutParams attributes = window.getAttributes();
                attributes.setBlurBehindRadius(Math.round(density * 6f));
                window.setAttributes(attributes);
            } else {
                applyFallback(dialog, sheet, tint, 0, 32f, true);
            }
        });
    }

    private static void roundMaterialSurfaces(View view) {
        try {
            Class<?> type = view.getClass();
            if ("com.google.android.material.card.MaterialCardView".equals(type.getName())) {
                ColorStateList colors = (ColorStateList) type.getMethod("getCardBackgroundColor").invoke(view);
                float radius = (float) type.getMethod("getRadius").invoke(view);
                int stroke = (int) type.getMethod("getStrokeColor").invoke(view);
                int width = (int) type.getMethod("getStrokeWidth").invoke(view);
                view.setBackground(new G2ShapeDrawable(colors.getDefaultColor(), stroke, width, radius));
                view.setForeground(null);
                view.setClipToOutline(true);
            } else if ("com.google.android.material.button.MaterialButton".equals(type.getName())) {
                if (view.getBackground() instanceof RippleDrawable
                        && ((RippleDrawable) view.getBackground()).getDrawable(0) instanceof G2ShapeDrawable) return;
                ColorStateList colors = view.getBackgroundTintList();
                ColorStateList ripple = (ColorStateList) type.getMethod("getRippleColor").invoke(view);
                int radius = (int) type.getMethod("getCornerRadius").invoke(view);
                G2ShapeDrawable fill = new G2ShapeDrawable(colors.getDefaultColor(), 0, 0, radius);
                G2ShapeDrawable mask = new G2ShapeDrawable(Color.WHITE, 0, 0, radius);
                view.setBackgroundTintList(null);
                view.setBackground(new RippleDrawable(ripple, fill, mask));
            }
        } catch (ReflectiveOperationException error) {
            throw new IllegalStateException("Unable to align Material surface outline", error);
        }
        if (view instanceof ViewGroup) {
            ViewGroup group = (ViewGroup) view;
            for (int i = 0; i < group.getChildCount(); i++) roundMaterialSurfaces(group.getChildAt(i));
        }
    }

    private static void clearSurfacePanels(Dialog dialog) {
        Context context = dialog.getContext();
        for (String name : new String[]{"parentPanel", "topPanel", "contentPanel", "customPanel", "custom", "buttonPanel", "mtrl_picker_fullscreen"}) {
            int id = context.getResources().getIdentifier(name, "id", context.getPackageName());
            if (id == 0) id = context.getResources().getIdentifier(name, "id", "android");
            View panel = dialog.findViewById(id);
            if (panel != null) panel.setBackground(null);
        }
        clearListBackgrounds(dialog.getWindow().getDecorView());
    }

    private static void clearListBackgrounds(View view) {
        if (view instanceof AbsListView) {
            view.setBackground(null);
            Context context = view.getContext();
            int id = context.getResources().getIdentifier("weeko_v114_popup_item_pressed", "color", context.getPackageName());
            float radius = view.getResources().getDisplayMetrics().density * 16f;
            ((AbsListView) view).setSelector(new RippleDrawable(ColorStateList.valueOf(context.getResources().getColor(id)),
                    null, new G2ShapeDrawable(Color.WHITE, 0, 0, radius)));
        } else if (view instanceof ViewGroup) {
            ViewGroup group = (ViewGroup) view;
            for (int i = 0; i < group.getChildCount(); i++) clearListBackgrounds(group.getChildAt(i));
        }
    }
}
