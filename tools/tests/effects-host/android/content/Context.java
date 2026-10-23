package android.content;
import android.content.res.Resources;
public abstract class Context {
    public abstract SharedPreferences getSharedPreferences(String name, int mode);
    public Resources getResources() { return new Resources(); }
}
