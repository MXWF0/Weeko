package io.github.mxwf.weeko.import_ui;

import android.view.View;

/** Bottom-bar presentation bridge; the original help handler remains authoritative. */
public final class EduBottomBar {
    private EduBottomBar() {}

    public static void bind(View root) {
        View help = root.findViewWithTag("weeko_edu_help");
        int originalId = root.getResources().getIdentifier("fab_tips", "id", root.getContext().getPackageName());
        View original = root.findViewById(originalId);
        help.setOnClickListener(view -> original.performClick());
    }
}
