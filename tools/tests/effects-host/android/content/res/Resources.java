package android.content.res;
public final class Resources {
    public String getResourceEntryName(int id) {
        if (id == 1) return "weeko_predictive_back";
        if (id == 2) return "weeko_advanced_materials";
        return "unrelated_setting";
    }
}
