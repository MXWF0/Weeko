import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import io.github.mxwf.weeko.theme.UiEffects;
import java.util.HashMap;
import java.util.Map;

/** Source policy unit test only. This does not establish Android gesture or disk behavior. */
public final class UiEffectsPolicyTest {
    private static final class Preferences implements SharedPreferences {
        final Map<String, Boolean> data = new HashMap<>();
        boolean writable = true;
        public boolean getBoolean(String key, boolean fallback) { return data.getOrDefault(key, fallback); }
        public Editor edit() {
            return new Editor() {
                String key; boolean value;
                public Editor putBoolean(String key, boolean value) { this.key = key; this.value = value; return this; }
                public boolean commit() { if (writable) data.put(key, value); return writable; }
            };
        }
    }
    private static Context context(Preferences prefs) {
        return new Context() {
            public SharedPreferences getSharedPreferences(String name, int mode) {
                if (!name.equals("config") || mode != 0) throw new AssertionError("Wrong preference store");
                return prefs;
            }
        };
    }
    private static void require(boolean value) { if (!value) throw new AssertionError(); }
    public static void main(String[] args) {
        Preferences prefs = new Preferences();
        Context first = context(prefs);
        Build.VERSION.SDK_INT = 36;
        require(!UiEffects.predictiveBack(first) && UiEffects.advancedMaterials(first));
        require(prefs.data.isEmpty());
        for (int sdk : new int[]{21, 33, 34, 36}) {
            Build.VERSION.SDK_INT = sdk;
            for (int combination = 0; combination < 4; combination++) {
                boolean predictive = (combination & 1) != 0, material = (combination & 2) != 0;
                boolean previousMaterial = UiEffects.advancedMaterials(first);
                require(UiEffects.change(first, 1, predictive));
                require(UiEffects.advancedMaterials(first) == previousMaterial);
                require(UiEffects.change(first, 2, material));
                Context reopened = context(prefs);
                require(UiEffects.predictiveBack(reopened) == (sdk >= 34 && predictive));
                require(UiEffects.advancedMaterials(reopened) == material);
                require(UiEffects.surface(reopened, 0xb3123456) == (material ? 0xb3123456 : 0xff123456));
            }
        }
        int count = prefs.data.size();
        require(!UiEffects.change(first, 3, true) && count == prefs.data.size());
        prefs.writable = false;
        boolean failed = false;
        try { UiEffects.change(first, 1, false); } catch (IllegalStateException expected) { failed = true; }
        require(failed);
        System.out.println("PASS host source policy: defaults, 4 combinations x 4 SDK gates, retained preferences, opaque surface, unrelated setting and commit-failure propagation. NOT an Android runtime/persistence test.");
    }
}
