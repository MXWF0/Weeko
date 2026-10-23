import android.content.Context;
import android.content.ContextWrapper;
import android.content.res.ColorStateList;
import android.os.Looper;
import android.view.ContextThemeWrapper;
import android.view.View;
import android.view.WindowManager;
import io.github.mxwf.weeko.popup.CourseDetailBlurFallbackV115;
import io.github.mxwf.weeko.theme.SoftDynamicColors;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

/** Standalone Android checks; does not read or modify Weeko user data. */
public final class WeekoV115Stage1Checks {
    public static void main(String[] args) throws Exception {
        Looper.prepareMainLooper();
        Class<?> thread = Class.forName("android.app.ActivityThread");
        Object activityThread = thread.getMethod("systemMain").invoke(null);
        Context system = (Context) thread.getMethod("getSystemContext").invoke(activityThread);
        Context app = system.createPackageContext("io.github.mxwf.weeko", 0);
        Context themed = new ContextThemeWrapper(app, 0x7f13000b);
        Class<?> paletteType = Class.forName(SoftDynamicColors.class.getName() + "$Palette");
        Constructor<?> constructor = paletteType.getDeclaredConstructor(Context.class, boolean.class);
        constructor.setAccessible(true);
        Object palette = constructor.newInstance(themed, false);
        Field originals = paletteType.getDeclaredField("originals");
        originals.setAccessible(true);
        int accent = ((int[]) originals.get(palette))[0] & 0xffffff;
        int enabled = android.R.attr.state_enabled;
        int checked = android.R.attr.state_checked;
        int pressed = android.R.attr.state_pressed;
        int focused = android.R.attr.state_focused;
        int custom = 0x7f04ffff;
        int[][] states = {{-enabled, checked}, {enabled, pressed, checked},
                {enabled, checked}, {enabled, focused}, {custom}, {}};
        int[] colors = new int[states.length];
        for (int i = 0; i < colors.length; i++) colors[i] = ((255 - i * 20) << 24) | accent;
        ColorStateList source = new ColorStateList(states, colors);
        Method adjust = SoftDynamicColors.class.getDeclaredMethod("soften", ColorStateList.class, paletteType);
        adjust.setAccessible(true);
        ColorStateList result = (ColorStateList) adjust.invoke(null, source, palette);
        Method color = paletteType.getDeclaredMethod("soften", int.class);
        color.setAccessible(true);
        for (int mask = 0; mask < 32; mask++) {
            int[] attrs = {enabled, checked, pressed, focused, custom};
            int[] state = new int[Integer.bitCount(mask)];
            int next = 0;
            for (int i = 0; i < attrs.length; i++) if ((mask & (1 << i)) != 0) state[next++] = attrs[i];
            int expected = (int) color.invoke(palette, source.getColorForState(state, source.getDefaultColor()));
            if (result.getColorForState(state, result.getDefaultColor()) != expected) {
                throw new AssertionError("Color state mismatch: " + mask);
            }
        }
        System.out.println("PASS: 32 color state combinations, order and alpha preserved");

        CourseDetailBlurFallbackV115 fallback = new CourseDetailBlurFallbackV115(new View(themed));
        Field applied = CourseDetailBlurFallbackV115.class.getDeclaredField("appliedRadius");
        applied.setAccessible(true);
        fallback.update(6);
        if (applied.getFloat(fallback) != 6f) throw new AssertionError("Fallback not applied");
        fallback.update(3.25f);
        if (applied.getFloat(fallback) != 3.25f) throw new AssertionError("Fractional progressive blur not updated");
        fallback.update(0);
        if (applied.getFloat(fallback) != 0f) throw new AssertionError("Blur not cleared");
        fallback.update(6);
        fallback.close();
        if (applied.getFloat(fallback) != 0f) throw new AssertionError("Closed fallback retained blur");
        System.out.println("PASS: app-owned progressive blur and close cleanup");
    }
}
