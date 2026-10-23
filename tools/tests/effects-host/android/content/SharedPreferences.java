package android.content;
/** Only the Android signatures used by UiEffects; no emulated rendering or lifecycle. */
public interface SharedPreferences {
    boolean getBoolean(String key, boolean fallback);
    Editor edit();
    interface Editor {
        Editor putBoolean(String key, boolean value);
        boolean commit();
    }
}
