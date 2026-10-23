package io.github.mxwf.weeko.theme;

import android.content.Context;
import android.os.Build;

/** Independent, app-wide effect preferences. Missing values retain the documented defaults. */
public final class UiEffects {
    public static final String PREDICTIVE_BACK = "predictive_back";
    public static final String ADVANCED_MATERIALS = "advanced_materials";

    private UiEffects() {}

    public static boolean predictiveBack(Context context) {
        return Build.VERSION.SDK_INT >= 34 && context.getSharedPreferences("config", 0)
                .getBoolean(PREDICTIVE_BACK, false);
    }

    public static boolean advancedMaterials(Context context) {
        return context.getSharedPreferences("config", 0).getBoolean(ADVANCED_MATERIALS, true);
    }

    public static boolean change(Context context, int title, boolean checked) {
        String name = context.getResources().getResourceEntryName(title);
        String key;
        if (name.equals("weeko_predictive_back")) key = PREDICTIVE_BACK;
        else if (name.equals("weeko_advanced_materials")) key = ADVANCED_MATERIALS;
        else return false;
        if (!context.getSharedPreferences("config", 0).edit().putBoolean(key, checked).commit())
            throw new IllegalStateException("Unable to persist " + key);
        return true;
    }

    public static int surface(Context context, int color) {
        return advancedMaterials(context) ? color : color | 0xff000000;
    }
}
