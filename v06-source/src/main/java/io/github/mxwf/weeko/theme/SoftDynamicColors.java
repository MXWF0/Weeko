package io.github.mxwf.weeko.theme;

import android.app.Activity;
import android.content.Context;
import android.content.res.ColorStateList;
import android.content.res.TypedArray;
import android.graphics.Color;
import android.os.Build;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AbsSeekBar;
import android.widget.CompoundButton;
import android.widget.ImageView;
import android.widget.TextView;

import java.lang.reflect.Method;

public final class SoftDynamicColors {
    private static final int[][] COLOR_STATES = {
            {-android.R.attr.state_enabled},
            {android.R.attr.state_enabled, android.R.attr.state_pressed},
            {android.R.attr.state_enabled, android.R.attr.state_focused},
            {android.R.attr.state_enabled, android.R.attr.state_checked},
            {android.R.attr.state_enabled, android.R.attr.state_selected},
            {android.R.attr.state_enabled, android.R.attr.state_activated},
            {android.R.attr.state_enabled},
            {}
    };

    private SoftDynamicColors() {}

    public static int soften(int color) {
        return softenPrimary(color, false);
    }

    public static int softenPrimary(int color, boolean dark) {
        return softenHsl(color, dark ? 0.72f : 0.75f);
    }

    public static int softenSecondary(int color, boolean dark) {
        return softenHsl(color, dark ? 0.62f : 0.65f);
    }

    public static int softenTertiary(int color, boolean dark) {
        return softenHsl(color, dark ? 0.57f : 0.60f);
    }

    public static int resolveAccent(Context context, int fallback) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S
                || !context.getSharedPreferences("config", Context.MODE_PRIVATE)
                .getBoolean("dynamic_colors", false)) {
            return fallback;
        }
        boolean dark = (context.getResources().getConfiguration().uiMode
                & android.content.res.Configuration.UI_MODE_NIGHT_MASK)
                == android.content.res.Configuration.UI_MODE_NIGHT_YES;
        return softenPrimary(themeColor(context, "colorPrimary"), dark);
    }

    public static void apply(Activity activity) {
        apply(activity, activity.findViewById(android.R.id.content));
    }

    public static void apply(View content) {
        apply(content.getContext(), content);
    }

    private static void apply(Context context, View content) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S
                || !context.getSharedPreferences("config", Context.MODE_PRIVATE)
                .getBoolean("dynamic_colors", false)) {
            return;
        }
        boolean dark = (context.getResources().getConfiguration().uiMode
                & android.content.res.Configuration.UI_MODE_NIGHT_MASK)
                == android.content.res.Configuration.UI_MODE_NIGHT_YES;
        Palette palette = new Palette(context, dark);
        if (content != null) {
            apply(content, palette);
        }
    }

    private static int softenHsl(int color, float saturationScale) {
        float red = ((color >> 16) & 0xff) / 255f;
        float green = ((color >> 8) & 0xff) / 255f;
        float blue = (color & 0xff) / 255f;
        float maximum = Math.max(red, Math.max(green, blue));
        float minimum = Math.min(red, Math.min(green, blue));
        float delta = maximum - minimum;
        float lightness = (maximum + minimum) / 2f;
        if (delta == 0f) {
            return color;
        }

        float hue;
        if (maximum == red) {
            hue = 60f * (((green - blue) / delta) % 6f);
        } else if (maximum == green) {
            hue = 60f * (((blue - red) / delta) + 2f);
        } else {
            hue = 60f * (((red - green) / delta) + 4f);
        }
        if (hue < 0f) {
            hue += 360f;
        }
        float saturation = delta / (1f - Math.abs(2f * lightness - 1f));
        saturation *= saturationScale;

        float targetLuminance = luminance(color);
        float low = 0f;
        float high = 1f;
        int closest = color;
        float closestLuminanceDelta = Float.MAX_VALUE;
        for (int step = 0; step < 24; step++) {
            float candidateLightness = (low + high) / 2f;
            int candidate = hslToColor(color >>> 24, hue, saturation, candidateLightness);
            float candidateLuminance = luminance(candidate);
            float luminanceDelta = Math.abs(candidateLuminance - targetLuminance);
            if (luminanceDelta < closestLuminanceDelta) {
                closest = candidate;
                closestLuminanceDelta = luminanceDelta;
            }
            if (candidateLuminance < targetLuminance) {
                low = candidateLightness;
            } else {
                high = candidateLightness;
            }
        }
        return closest;
    }

    private static int hslToColor(int alpha, float hue, float saturation, float lightness) {
        float chroma = (1f - Math.abs(2f * lightness - 1f)) * saturation;
        float hueSector = hue / 60f;
        float second = chroma * (1f - Math.abs(hueSector % 2f - 1f));
        float red;
        float green;
        float blue;
        if (hueSector < 1f) {
            red = chroma;
            green = second;
            blue = 0f;
        } else if (hueSector < 2f) {
            red = second;
            green = chroma;
            blue = 0f;
        } else if (hueSector < 3f) {
            red = 0f;
            green = chroma;
            blue = second;
        } else if (hueSector < 4f) {
            red = 0f;
            green = second;
            blue = chroma;
        } else if (hueSector < 5f) {
            red = second;
            green = 0f;
            blue = chroma;
        } else {
            red = chroma;
            green = 0f;
            blue = second;
        }
        float match = lightness - chroma / 2f;
        return Color.argb(alpha,
                Math.round((red + match) * 255f),
                Math.round((green + match) * 255f),
                Math.round((blue + match) * 255f));
    }

    private static float luminance(int color) {
        return 0.2126f * linear(((color >> 16) & 0xff) / 255f)
                + 0.7152f * linear(((color >> 8) & 0xff) / 255f)
                + 0.0722f * linear((color & 0xff) / 255f);
    }

    private static float linear(float channel) {
        return channel <= 0.04045f
                ? channel / 12.92f
                : (float) Math.pow((channel + 0.055f) / 1.055f, 2.4d);
    }

    private static int themeColor(Context context, String attribute) {
        int attributeId = context.getResources().getIdentifier(
                attribute, "attr", context.getPackageName());
        TypedArray value = context.obtainStyledAttributes(new int[]{attributeId});
        int color = value.getColor(0, Color.TRANSPARENT);
        value.recycle();
        return color;
    }

    private static void apply(View view, Palette palette) {
        view.setBackgroundTintList(soften(view.getBackgroundTintList(), palette));
        if (view instanceof TextView) {
            TextView text = (TextView) view;
            text.setTextColor(soften(text.getTextColors(), palette));
            if (android.os.Build.VERSION.SDK_INT >= 23) {
                text.setCompoundDrawableTintList(soften(text.getCompoundDrawableTintList(), palette));
            }
        }
        if (view instanceof ImageView) {
            ImageView image = (ImageView) view;
            image.setImageTintList(soften(image.getImageTintList(), palette));
        }
        if (view instanceof CompoundButton) {
            CompoundButton button = (CompoundButton) view;
            button.setButtonTintList(soften(button.getButtonTintList(), palette));
            if (view.getClass().getName().contains("Switch")) {
                softenMethods(view, palette,
                        new String[][]{{"getThumbTintList", "setThumbTintList"},
                                {"getTrackTintList", "setTrackTintList"}});
            }
        }
        if (view instanceof AbsSeekBar) {
            AbsSeekBar seekBar = (AbsSeekBar) view;
            seekBar.setThumbTintList(soften(seekBar.getThumbTintList(), palette));
            seekBar.setProgressTintList(soften(seekBar.getProgressTintList(), palette));
        }
        if (isMaterialButton(view.getClass())) {
            softenMethods(view, palette, new String[][]{{"getIconTint", "setIconTint"}});
        }
        if (isMaterialSlider(view.getClass())) {
            softenMethods(view, palette, new String[][]{
                    {"getThumbTintList", "setThumbTintList"},
                    {"getTrackActiveTintList", "setTrackActiveTintList"},
                    {"getTickActiveTintList", "setTickActiveTintList"}
            });
        }
        if (view instanceof ViewGroup) {
            ViewGroup group = (ViewGroup) view;
            for (int index = 0; index < group.getChildCount(); index++) {
                apply(group.getChildAt(index), palette);
            }
        }
    }

    private static boolean isMaterialSlider(Class<?> type) {
        for (Class<?> current = type; current != null; current = current.getSuperclass()) {
            if ("com.google.android.material.slider.BaseSlider".equals(current.getName())) {
                return true;
            }
        }
        return false;
    }

    private static boolean isMaterialButton(Class<?> type) {
        for (Class<?> current = type; current != null; current = current.getSuperclass()) {
            if ("com.google.android.material.button.MaterialButton".equals(current.getName())) {
                return true;
            }
        }
        return false;
    }

    private static void softenMethods(View view, Palette palette, String[][] methodNames) {
        for (String[] names : methodNames) {
            try {
                Method getter = view.getClass().getMethod(names[0]);
                Method setter = view.getClass().getMethod(names[1], ColorStateList.class);
                ColorStateList colors = (ColorStateList) getter.invoke(view);
                ColorStateList adjusted = soften(colors, palette);
                if (adjusted != colors) {
                    setter.invoke(view, adjusted);
                }
            } catch (ReflectiveOperationException error) {
                throw new IllegalStateException("Unable to soften " + names[0], error);
            }
        }
    }

    private static ColorStateList soften(ColorStateList source, Palette palette) {
        if (source == null) {
            return null;
        }
        int[] colors = new int[COLOR_STATES.length];
        boolean changed = false;
        for (int index = 0; index < COLOR_STATES.length; index++) {
            int color = source.getColorForState(COLOR_STATES[index], source.getDefaultColor());
            colors[index] = palette.soften(color);
            changed |= colors[index] != color;
        }
        return changed ? new ColorStateList(COLOR_STATES, colors) : source;
    }

    private static final class Palette {
        private final int[] originals;
        private final int[] softened;

        private Palette(Context context, boolean dark) {
            int primary = themeColor(context, "colorPrimary");
            int primaryContainer = themeColor(context, "colorPrimaryContainer");
            int secondary = themeColor(context, "colorSecondary");
            int secondaryContainer = themeColor(context, "colorSecondaryContainer");
            int tertiary = themeColor(context, "colorTertiary");
            int tertiaryContainer = themeColor(context, "colorTertiaryContainer");
            int detailAccent = resourceColor(context, "weeko_v114_detail_accent");
            int detailAccentContainer = resourceColor(context, "weeko_v114_detail_accent_container");
            int softenedPrimary = softenPrimary(primary, dark);
            int softenedPrimaryContainer = softenPrimary(primaryContainer, dark);
            originals = new int[]{primary, primaryContainer, secondary, secondaryContainer,
                    tertiary, tertiaryContainer, detailAccent, detailAccentContainer};
            softened = new int[]{softenedPrimary, softenedPrimaryContainer,
                    softenSecondary(secondary, dark), softenSecondary(secondaryContainer, dark),
                    softenTertiary(tertiary, dark), softenTertiary(tertiaryContainer, dark),
                    softenedPrimary, softenedPrimaryContainer};
        }

        private int soften(int color) {
            int rgb = color & 0x00ffffff;
            for (int index = 0; index < originals.length; index++) {
                if (rgb == (originals[index] & 0x00ffffff)) {
                    return (color & 0xff000000) | (softened[index] & 0x00ffffff);
                }
            }
            return color;
        }
    }

    private static int resourceColor(Context context, String name) {
        int resourceId = context.getResources().getIdentifier(name, "color", context.getPackageName());
        return context.getResources().getColor(resourceId);
    }
}
