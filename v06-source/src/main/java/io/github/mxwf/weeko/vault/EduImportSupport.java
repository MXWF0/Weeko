package io.github.mxwf.weeko.vault;

import android.content.Context;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.view.View;

/** Small UI bridge for first-entry education import notices. */
public final class EduImportSupport {
    private static final String PREFS = "config";
    private static final String EDU_NOTICE_CONFIRMED = "edu_notice_confirmed";
    private static final String EDU_URL_NOTICE_CONFIRMED = "edu_url_notice_confirmed";

    private EduImportSupport() {
    }

    public static void onEnter(Context context, View urlNotice, View confirmUrlNotice) {
        SharedPreferences preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        boolean urlConfirmed = preferences.getBoolean(EDU_URL_NOTICE_CONFIRMED, false);
        urlNotice.setVisibility(urlConfirmed ? View.GONE : View.VISIBLE);
        confirmUrlNotice.setOnClickListener(view -> {
            boolean written = preferences.edit().putBoolean(EDU_URL_NOTICE_CONFIRMED, true).commit();
            if (!written) {
                throw new IllegalStateException("Unable to persist edu_url_notice_confirmed");
            }
            urlNotice.setVisibility(View.GONE);
        });

    }

    public static boolean isNoticeConfirmed(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(EDU_NOTICE_CONFIRMED, false);
    }

    public static DialogInterface.OnClickListener noticeConfirmation(Context context) {
        SharedPreferences preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        return (dialog, which) -> {
            boolean written = preferences.edit().putBoolean(EDU_NOTICE_CONFIRMED, true).commit();
            if (!written) {
                throw new IllegalStateException("Unable to persist edu_notice_confirmed");
            }
        };
    }
}
