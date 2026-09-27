package io.github.mxwf.weeko.vault;

import android.app.Activity;
import android.app.AlertDialog;
import android.animation.ValueAnimator;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.RippleDrawable;
import android.os.Build;
import android.os.Bundle;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.system.ErrnoException;
import android.system.Os;
import android.text.InputType;
import android.text.TextUtils;
import android.text.method.PasswordTransformationMethod;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowManager;
import android.view.animation.DecelerateInterpolator;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.KeyStore;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

public final class PasswordVaultActivity extends Activity {
    private static final String KEY_ALIAS = "weeko_password_vault_aes_v1";
    private static final String FILE_NAME = "password-vault.bin";
    private static final int MAGIC = 0x57564c54;
    private static final int FORMAT_VERSION = 1;

    private final List<Record> records = new ArrayList<>();
    private LinearLayout sheetRoot;
    private ScrollView recordScroll;
    private LinearLayout list;
    private TextView status;
    private boolean useDynamicColors;
    private final Map<String, Integer> resolvedColors = new HashMap<>();

    public static void open(Context context) {
        context.startActivity(new Intent(context, PasswordVaultActivity.class));
        if (context instanceof Activity) {
            ((Activity) context).overridePendingTransition(0, 0);
        }
    }

    @Override
    public void finish() {
        super.finish();
        overridePendingTransition(0, 0);
    }

    @Override
    protected void attachBaseContext(Context base) {
        int themeMode = base.getSharedPreferences("config", Context.MODE_PRIVATE)
                .getInt("day_night_theme", 2);
        boolean systemDark = (base.getResources().getConfiguration().uiMode
                & Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES;
        boolean dark = themeMode == 1 || (themeMode == 2 && systemDark);
        Configuration effective = new Configuration(base.getResources().getConfiguration());
        effective.uiMode = (effective.uiMode & ~Configuration.UI_MODE_NIGHT_MASK)
                | (dark ? Configuration.UI_MODE_NIGHT_YES : Configuration.UI_MODE_NIGHT_NO);
        super.attachBaseContext(base.createConfigurationContext(effective));
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        useDynamicColors = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
                && getSharedPreferences("config", MODE_PRIVATE).getBoolean("dynamic_colors", false);
        if (useDynamicColors) {
            boolean dark = (getResources().getConfiguration().uiMode
                    & Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES;
            String overlayName = dark
                    ? "ThemeOverlay.Material3.DynamicColors.Dark"
                    : "ThemeOverlay.Material3.DynamicColors.Light";
            int overlayId = getResources().getIdentifier(overlayName, "style", getPackageName());
            getTheme().applyStyle(overlayId, true);
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            AlertDialog unavailableDialog = new AlertDialog.Builder(this)
                    .setTitle("无法使用密码箱")
                    .setMessage("密码箱需要 Android 6.0 或更高版本提供的 Keystore AES-GCM。")
                    .setPositiveButton("返回", (dialog, which) -> finish())
                    .setCancelable(false)
                    .show();
            styleDialog(unavailableDialog, false);
            return;
        }
        try {
            records.addAll(readRecords());
            buildScreen();
        } catch (IOException | GeneralSecurityException | JSONException exception) {
            showFatalError(exception);
        }
    }

    private int dp(float value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }

    private int color(String name) {
        Integer resolved = resolvedColors.get(name);
        if (resolved != null) {
            return resolved;
        }
        int id = getResources().getIdentifier(name, "color", getPackageName());
        int fallback = getResources().getColor(id);
        int result = fallback;
        if (useDynamicColors) {
            boolean dark = (getResources().getConfiguration().uiMode
                    & Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES;
            String systemColor = null;
            if (Build.VERSION.SDK_INT >= 34) {
                String mode = dark ? "_dark" : "_light";
                switch (name) {
                    case "md_theme_onSurface":
                        systemColor = "system_on_surface" + mode;
                        break;
                    case "md_theme_onSurfaceVariant":
                    case "weeko_v114_detail_icon":
                        systemColor = "system_on_surface_variant" + mode;
                        break;
                    case "weeko_v114_detail_sheet":
                    case "weeko_v114_detail_navigation_bar":
                        systemColor = "system_surface" + mode;
                        break;
                    case "weeko_v114_detail_card":
                        systemColor = "system_surface_container_low" + mode;
                        break;
                    case "weeko_v114_detail_outline":
                        systemColor = "system_outline_variant" + mode;
                        break;
                    case "weeko_v114_detail_accent":
                        systemColor = "system_primary" + mode;
                        break;
                    case "weeko_v114_detail_accent_container":
                        systemColor = "system_primary_container" + mode;
                        break;
                    case "weeko_v114_detail_danger":
                        systemColor = "system_error" + mode;
                        break;
                    case "weeko_v114_detail_danger_container":
                        systemColor = "system_error_container" + mode;
                        break;
                }
            } else {
                switch (name) {
                    case "md_theme_onSurface":
                        systemColor = dark ? "system_neutral1_100" : "system_neutral1_900";
                        break;
                    case "md_theme_onSurfaceVariant":
                    case "weeko_v114_detail_icon":
                        systemColor = dark ? "system_neutral2_200" : "system_neutral2_700";
                        break;
                    case "weeko_v114_detail_sheet":
                    case "weeko_v114_detail_navigation_bar":
                        systemColor = dark ? "system_neutral2_900" : "system_neutral2_50";
                        break;
                    case "weeko_v114_detail_card":
                        systemColor = dark ? "system_neutral2_900" : "system_neutral2_100";
                        break;
                    case "weeko_v114_detail_outline":
                        systemColor = dark ? "system_neutral2_700" : "system_neutral2_200";
                        break;
                    case "weeko_v114_detail_accent":
                        systemColor = dark ? "system_accent1_200" : "system_accent1_600";
                        break;
                    case "weeko_v114_detail_accent_container":
                        systemColor = dark ? "system_accent1_700" : "system_accent1_100";
                        break;
                }
            }
            if (systemColor != null) {
                int systemColorId = getResources().getIdentifier(systemColor, "color", "android");
                result = getResources().getColor(systemColorId);
            }
            if ("weeko_v114_detail_sheet".equals(name)
                    || "weeko_v114_detail_card".equals(name)
                    || "weeko_v114_detail_outline".equals(name)) {
                result = withAlpha(result, Color.alpha(fallback));
            }
        }
        resolvedColors.put(name, result);
        return result;
    }

    private int withAlpha(int color, int alpha) {
        return (color & 0x00ffffff) | (alpha << 24);
    }

    private TextView text(String value, float size, int textColor, boolean bold) {
        TextView view = new TextView(this);
        view.setText(value);
        view.setTextSize(TypedValue.COMPLEX_UNIT_SP, size);
        view.setTextColor(textColor);
        view.setLineSpacing(0f, 1.15f);
        view.setTypeface(Typeface.create(bold ? "sans-serif-medium" : "sans-serif", Typeface.NORMAL));
        return view;
    }

    private Button button(String value) {
        Button button = new Button(this);
        button.setText(value);
        button.setAllCaps(false);
        button.setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f);
        button.setMinHeight(dp(44));
        button.setPadding(dp(12), 0, dp(12), 0);
        return button;
    }

    private void styleButton(Button button, int background, int foreground, int cornerRadius, int elevation) {
        GradientDrawable shape = new GradientDrawable();
        shape.setColor(background);
        shape.setCornerRadius(dp(cornerRadius));
        button.setBackground(new RippleDrawable(
                ColorStateList.valueOf(withAlpha(foreground, 0x28)), shape, null));
        button.setTextColor(foreground);
        button.setStateListAnimator(null);
        button.setElevation(dp(elevation));
    }

    private void buttonIcon(Button button, String drawableName, int tint) {
        Drawable icon = getResources().getDrawable(
                getResources().getIdentifier(drawableName, "drawable", getPackageName())).mutate();
        icon.setTint(tint);
        button.setCompoundDrawablesWithIntrinsicBounds(icon, null, null, null);
        button.setCompoundDrawablePadding(dp(6));
    }

    private void styleDialog(AlertDialog dialog, boolean destructive) {
        GradientDrawable background = new GradientDrawable();
        background.setColor(color("weeko_v114_detail_sheet"));
        background.setCornerRadius(dp(24));
        background.setStroke(dp(1), color("weeko_v114_detail_outline"));
        Window window = dialog.getWindow();
        window.setBackgroundDrawable(background);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            window.addFlags(WindowManager.LayoutParams.FLAG_BLUR_BEHIND);
            WindowManager.LayoutParams blurAttributes = window.getAttributes();
            blurAttributes.setBlurBehindRadius(dp(6));
            window.setAttributes(blurAttributes);
            window.setBackgroundBlurRadius(dp(6));
        }
        dialog.getButton(AlertDialog.BUTTON_POSITIVE).setTextColor(color(
                destructive ? "weeko_v114_detail_danger" : "weeko_v114_detail_accent"));
        Button cancel = dialog.getButton(AlertDialog.BUTTON_NEGATIVE);
        if (cancel != null) {
            cancel.setTextColor(color("md_theme_onSurfaceVariant"));
        }
    }

    private void buildScreen() {
        int onSurface = color("md_theme_onSurface");
        int secondary = color("md_theme_onSurfaceVariant");
        int accent = color("weeko_v114_detail_accent");

        LinearLayout root = new LinearLayout(this);
        sheetRoot = root;
        root.setOrientation(LinearLayout.VERTICAL);
        GradientDrawable sheetBackground = new GradientDrawable();
        sheetBackground.setColor(withAlpha(color("weeko_v114_detail_sheet"), 0xd0));
        sheetBackground.setCornerRadii(new float[]{dp(28), dp(28), dp(28), dp(28), 0, 0, 0, 0});
        sheetBackground.setStroke(dp(1), color("weeko_v114_detail_outline"));
        root.setBackground(sheetBackground);
        root.setClipToOutline(true);
        root.setElevation(dp(8));
        root.setLayoutParams(new FrameLayout.LayoutParams(-1, -2, Gravity.BOTTOM));

        FrameLayout handleArea = new FrameLayout(this);
        View handle = new View(this);
        GradientDrawable handleBackground = new GradientDrawable();
        handleBackground.setColor(withAlpha(secondary, 0x66));
        handleBackground.setCornerRadius(dp(4));
        handle.setBackground(handleBackground);
        FrameLayout.LayoutParams handleParams = new FrameLayout.LayoutParams(dp(44), dp(5), Gravity.CENTER);
        handleArea.addView(handle, handleParams);
        handleArea.setContentDescription("下滑关闭密码箱");
        handleArea.setOnTouchListener(new View.OnTouchListener() {
            private float downY;

            @Override
            public boolean onTouch(View view, MotionEvent event) {
                if (event.getAction() == MotionEvent.ACTION_DOWN) {
                    downY = event.getRawY();
                    return true;
                }
                if (event.getAction() == MotionEvent.ACTION_UP) {
                    if (event.getRawY() - downY > dp(56)) {
                        finish();
                    }
                    return true;
                }
                return event.getAction() == MotionEvent.ACTION_MOVE || event.getAction() == MotionEvent.ACTION_CANCEL;
            }
        });
        root.addView(handleArea, new LinearLayout.LayoutParams(-1, dp(28)));

        LinearLayout toolbar = new LinearLayout(this);
        toolbar.setGravity(Gravity.CENTER_VERTICAL);
        toolbar.setPadding(dp(22), dp(2), dp(18), dp(12));
        LinearLayout heading = new LinearLayout(this);
        heading.setOrientation(LinearLayout.VERTICAL);
        TextView title = text("密码箱", 22f, onSurface, true);
        heading.addView(title, new LinearLayout.LayoutParams(-1, -2));
        status = text("", 13f, secondary, false);
        status.setPadding(0, dp(2), 0, 0);
        heading.addView(status, new LinearLayout.LayoutParams(-1, -2));
        toolbar.addView(heading, new LinearLayout.LayoutParams(0, -2, 1f));
        Button add = button("＋ 新增");
        styleButton(add, color("weeko_v114_detail_accent_container"), accent, 16, 0);
        add.setOnClickListener(view -> showEditor(null));
        toolbar.addView(add, new LinearLayout.LayoutParams(-2, dp(44)));
        root.addView(toolbar, new LinearLayout.LayoutParams(-1, -2));

        ScrollView scroll = new ScrollView(this);
        recordScroll = scroll;
        scroll.setClipToPadding(false);
        list = new LinearLayout(this);
        list.setOrientation(LinearLayout.VERTICAL);
        list.setPadding(dp(18), 0, dp(18), dp(12));
        scroll.addView(list, new ScrollView.LayoutParams(-1, -2));
        root.addView(scroll, new LinearLayout.LayoutParams(-1, -2));

        Button done = button("完成");
        styleButton(done, withAlpha(color("weeko_v114_detail_card"), 0xde), accent, 18, 0);
        done.setOnClickListener(view -> finish());
        LinearLayout.LayoutParams doneParams = new LinearLayout.LayoutParams(-1, dp(48));
        doneParams.setMargins(dp(18), dp(2), dp(18), dp(14));
        root.addView(done, doneParams);

        setContentView(root);
        configureBottomSheet(root);
        renderRecords();
    }

    private void configureBottomSheet(View root) {
        Window window = getWindow();
        window.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        window.setGravity(Gravity.BOTTOM);
        window.addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND);
        WindowManager.LayoutParams attributes = window.getAttributes();
        attributes.dimAmount = 0.38f;
        window.setAttributes(attributes);
        setFinishOnTouchOutside(true);

        window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION);
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
        window.setNavigationBarColor(color("weeko_v114_detail_navigation_bar"));
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            View decor = window.getDecorView();
            int flags = decor.getSystemUiVisibility();
            if ((getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK)
                    == Configuration.UI_MODE_NIGHT_YES) {
                flags &= ~View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
            } else {
                flags |= View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
            }
            decor.setSystemUiVisibility(flags | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
        } else {
            View decor = window.getDecorView();
            decor.setSystemUiVisibility(decor.getSystemUiVisibility()
                    | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.setNavigationBarContrastEnforced(false);
        }
        window.setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.WRAP_CONTENT);
        root.setOnApplyWindowInsetsListener((view, insets) -> {
            int bottom = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R
                    ? insets.getInsets(WindowInsets.Type.navigationBars()).bottom
                    : insets.getSystemWindowInsetBottom();
            view.setPadding(0, 0, 0, bottom);
            return insets;
        });
        root.requestApplyInsets();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            window.addFlags(WindowManager.LayoutParams.FLAG_BLUR_BEHIND);
            WindowManager.LayoutParams blurAttributes = window.getAttributes();
            blurAttributes.setBlurBehindRadius(0);
            window.setAttributes(blurAttributes);
            window.setBackgroundBlurRadius(0);
            root.postOnAnimation(() -> {
                ValueAnimator blurAnimator = ValueAnimator.ofInt(0, dp(6));
                blurAnimator.setDuration(250L);
                blurAnimator.setInterpolator(new DecelerateInterpolator(2f));
                blurAnimator.addUpdateListener(animation -> {
                    int radius = (int) animation.getAnimatedValue();
                    blurAttributes.setBlurBehindRadius(radius);
                    window.setAttributes(blurAttributes);
                    window.setBackgroundBlurRadius(radius);
                });
                blurAnimator.start();
            });
        }
    }

    private void updateSheetHeight() {
        sheetRoot.post(() -> {
            int maxHeight = (int) (getResources().getDisplayMetrics().heightPixels * 0.70f);
            LinearLayout.LayoutParams scrollParams = (LinearLayout.LayoutParams) recordScroll.getLayoutParams();
            scrollParams.height = ViewGroup.LayoutParams.WRAP_CONTENT;
            recordScroll.setLayoutParams(scrollParams);
            sheetRoot.measure(
                    View.MeasureSpec.makeMeasureSpec(getResources().getDisplayMetrics().widthPixels, View.MeasureSpec.EXACTLY),
                    View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED));
            int naturalHeight = sheetRoot.getMeasuredHeight();
            if (naturalHeight > maxHeight) {
                scrollParams.height = maxHeight - naturalHeight + recordScroll.getMeasuredHeight();
                recordScroll.setLayoutParams(scrollParams);
            }
            getWindow().setLayout(WindowManager.LayoutParams.MATCH_PARENT, Math.min(naturalHeight, maxHeight));
        });
    }

    private void renderRecords() {
        list.removeAllViews();
        status.setText(records.isEmpty()
                ? "已保存 0 个账号"
                : "已保存 " + records.size() + " 个账号");
        if (records.isEmpty()) {
            TextView empty = text("密码箱还是空的", 16f, color("md_theme_onSurfaceVariant"), false);
            empty.setGravity(Gravity.CENTER);
            empty.setPadding(0, dp(28), 0, dp(14));
            list.addView(empty, new LinearLayout.LayoutParams(-1, -2));
            Button add = button("新增账号");
            styleButton(add, color("weeko_v114_detail_accent_container"), color("weeko_v114_detail_accent"), 18, 0);
            add.setOnClickListener(view -> showEditor(null));
            LinearLayout.LayoutParams addParams = new LinearLayout.LayoutParams(-1, dp(48));
            addParams.setMargins(dp(16), 0, dp(16), dp(24));
            list.addView(add, addParams);
        } else {
            for (Record record : records) {
                list.addView(recordCard(record), cardParams());
            }
        }
        updateSheetHeight();
    }

    private LinearLayout.LayoutParams cardParams() {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-1, -2);
        params.setMargins(0, 0, 0, dp(12));
        return params;
    }

    private View accountRow(String label, String value, int foreground, int secondary) {
        LinearLayout row = new LinearLayout(this);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.addView(text(label, 13f, secondary, false), new LinearLayout.LayoutParams(dp(64), -2));
        TextView content = text(value, 14f, foreground, false);
        content.setSingleLine(true);
        content.setEllipsize(TextUtils.TruncateAt.END);
        row.addView(content, new LinearLayout.LayoutParams(0, -2, 1f));
        return row;
    }

    private View recordCard(Record record) {
        int onSurface = color("md_theme_onSurface");
        int secondary = color("md_theme_onSurfaceVariant");
        int accent = color("weeko_v114_detail_accent");
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(14), dp(16), dp(12));
        GradientDrawable background = new GradientDrawable();
        background.setColor(withAlpha(color("weeko_v114_detail_card"), 0xd4));
        background.setCornerRadius(dp(18));
        background.setStroke(dp(1), color("weeko_v114_detail_outline"));
        card.setBackground(background);

        String displayName = record.username;
        LinearLayout header = new LinearLayout(this);
        header.setGravity(Gravity.CENTER_VERTICAL);
        FrameLayout badge = new FrameLayout(this);
        GradientDrawable badgeBackground = new GradientDrawable();
        badgeBackground.setShape(GradientDrawable.OVAL);
        badgeBackground.setColor(withAlpha(accent, 0x22));
        badge.setBackground(badgeBackground);
        ImageView school = new ImageView(this);
        school.setImageResource(getResources().getIdentifier("ic_twotone_school_24", "drawable", getPackageName()));
        school.setImageTintList(ColorStateList.valueOf(accent));
        badge.addView(school, new FrameLayout.LayoutParams(dp(22), dp(22), Gravity.CENTER));
        header.addView(badge, new LinearLayout.LayoutParams(dp(42), dp(42)));
        LinearLayout.LayoutParams nameParams = new LinearLayout.LayoutParams(0, -2, 1f);
        nameParams.setMargins(dp(10), 0, 0, 0);
        header.addView(text(displayName, 17f, onSurface, true), nameParams);
        card.addView(header, new LinearLayout.LayoutParams(-1, -2));

        LinearLayout.LayoutParams usernameParams = new LinearLayout.LayoutParams(-1, -2);
        usernameParams.setMargins(0, dp(8), 0, 0);
        card.addView(accountRow("用户名", record.username, onSurface, secondary), usernameParams);
        LinearLayout.LayoutParams passwordParams = new LinearLayout.LayoutParams(-1, -2);
        passwordParams.setMargins(0, dp(4), 0, 0);
        card.addView(accountRow("密码", "••••••••••", onSurface, secondary), passwordParams);
        if (!record.notes.isEmpty()) {
            TextView notes = text(record.notes, 14f, secondary, false);
            notes.setPadding(0, dp(8), 0, 0);
            card.addView(notes, new LinearLayout.LayoutParams(-1, -2));
        }

        LinearLayout copyActions = new LinearLayout(this);
        Button copyUsername = button("复制用户名");
        styleButton(copyUsername, color("weeko_v114_detail_accent_container"), accent, 16, 0);
        buttonIcon(copyUsername, "ic_twotone_file_copy_24", accent);
        LinearLayout.LayoutParams copyUsernameParams = new LinearLayout.LayoutParams(0, dp(46), 1f);
        copyUsernameParams.setMargins(0, dp(12), dp(4), dp(4));
        copyUsername.setOnClickListener(view -> copy("教务用户名", record.username));
        copyActions.addView(copyUsername, copyUsernameParams);
        Button copyPassword = button("复制密码");
        styleButton(copyPassword, color("weeko_v114_detail_accent_container"), accent, 16, 0);
        buttonIcon(copyPassword, "ic_twotone_file_copy_24", accent);
        LinearLayout.LayoutParams copyPasswordParams = new LinearLayout.LayoutParams(0, dp(46), 1f);
        copyPasswordParams.setMargins(dp(4), dp(12), 0, dp(4));
        copyPassword.setOnClickListener(view -> copy("教务密码", record.password));
        copyActions.addView(copyPassword, copyPasswordParams);
        card.addView(copyActions, new LinearLayout.LayoutParams(-1, -2));

        LinearLayout editActions = new LinearLayout(this);
        Button edit = button("编辑");
        styleButton(edit, withAlpha(color("weeko_v114_detail_card"), 0x54), secondary, 16, 0);
        buttonIcon(edit, "ic_outline_edit_24", secondary);
        edit.setMinHeight(dp(40));
        edit.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f);
        LinearLayout.LayoutParams editParams = new LinearLayout.LayoutParams(0, dp(40), 1f);
        editParams.setMargins(0, dp(2), dp(4), 0);
        edit.setOnClickListener(view -> showEditor(record));
        editActions.addView(edit, editParams);
        Button delete = button("删除");
        styleButton(delete,
                withAlpha(color("weeko_v114_detail_card"), 0x54),
                color("weeko_v114_detail_danger"), 16, 0);
        buttonIcon(delete, "ic_outline_delete_outline_24", color("weeko_v114_detail_danger"));
        delete.setMinHeight(dp(40));
        delete.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f);
        LinearLayout.LayoutParams deleteParams = new LinearLayout.LayoutParams(0, dp(40), 1f);
        deleteParams.setMargins(dp(4), dp(2), 0, 0);
        delete.setOnClickListener(view -> confirmDelete(record));
        editActions.addView(delete, deleteParams);
        card.addView(editActions, new LinearLayout.LayoutParams(-1, -2));
        return card;
    }

    private void copy(String label, String value) {
        ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
        clipboard.setPrimaryClip(ClipData.newPlainText(label, value));
    }

    private EditText field(String hint, String value) {
        EditText field = new EditText(this);
        field.setHint(hint);
        field.setText(value);
        field.setSingleLine(true);
        field.setPadding(0, dp(8), 0, dp(8));
        return field;
    }

    private void showEditor(Record existing) {
        LinearLayout fields = new LinearLayout(this);
        fields.setOrientation(LinearLayout.VERTICAL);
        fields.setPadding(dp(20), 0, dp(20), 0);
        EditText username = field("用户名", existing == null ? "" : existing.username);
        EditText password = field("密码", existing == null ? "" : existing.password);
        password.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        password.setTransformationMethod(PasswordTransformationMethod.getInstance());
        EditText notes = field("备注", existing == null ? "" : existing.notes);
        notes.setSingleLine(false);
        notes.setMinLines(2);
        fields.addView(username);
        fields.addView(password);
        fields.addView(notes);
        ScrollView scroll = new ScrollView(this);
        scroll.addView(fields);

        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle(existing == null ? "新增账号" : "编辑账号")
                .setView(scroll)
                .setNegativeButton("取消", null)
                .setPositiveButton("保存", null)
                .create();
        dialog.setOnShowListener(ignored -> dialog.getButton(AlertDialog.BUTTON_POSITIVE)
                .setOnClickListener(view -> {
                    String usernameValue = username.getText().toString().trim();
                    String passwordValue = password.getText().toString();
                    if (usernameValue.isEmpty()) {
                        username.setError("请输入用户名");
                        return;
                    }
                    if (passwordValue.isEmpty()) {
                        password.setError("请输入密码");
                        return;
                    }
                    Record changed = new Record(
                            existing == null ? UUID.randomUUID().toString() : existing.id,
                            existing == null ? usernameValue : existing.name,
                            existing == null ? "" : existing.school,
                            usernameValue,
                            passwordValue,
                            notes.getText().toString().trim());
                    if (existing == null) {
                        records.add(changed);
                    } else {
                        records.set(records.indexOf(existing), changed);
                    }
                    persistAndRender();
                    dialog.dismiss();
                }));
        dialog.show();
        styleDialog(dialog, false);
    }

    private void confirmDelete(Record record) {
        AlertDialog confirmDialog = new AlertDialog.Builder(this)
                .setTitle("删除账号")
                .setMessage("确定删除“" + record.username + "”？")
                .setNegativeButton("取消", null)
                .setPositiveButton("删除", (dialog, which) -> {
                    records.remove(record);
                    persistAndRender();
                })
                .show();
        styleDialog(confirmDialog, true);
    }

    private void persistAndRender() {
        try {
            writeRecords(records);
            renderRecords();
        } catch (IOException | GeneralSecurityException | JSONException exception) {
            showStorageError(exception);
        }
    }

    private void showStorageError(Exception exception) {
        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("密码箱保存失败")
                .setMessage(exception.getClass().getSimpleName() + ": " + exception.getMessage())
                .setPositiveButton("关闭", null)
                .show();
        styleDialog(dialog, false);
    }

    private void showFatalError(Exception exception) {
        AlertDialog fatalDialog = new AlertDialog.Builder(this)
                .setTitle("密码箱无法打开")
                .setMessage(exception.getClass().getSimpleName() + ": " + exception.getMessage())
                .setPositiveButton("返回", (dialog, which) -> finish())
                .setCancelable(false)
                .show();
        styleDialog(fatalDialog, false);
    }

    private File vaultFile() {
        return new File(getNoBackupFilesDir(), FILE_NAME);
    }

    private SecretKey key() throws GeneralSecurityException, IOException {
        KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
        keyStore.load(null);
        if (!keyStore.containsAlias(KEY_ALIAS)) {
            KeyGenerator generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
            generator.init(new KeyGenParameterSpec.Builder(
                    KEY_ALIAS,
                    KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setRandomizedEncryptionRequired(true)
                    .build());
            generator.generateKey();
        }
        return (SecretKey) keyStore.getKey(KEY_ALIAS, null);
    }

    private List<Record> readRecords() throws IOException, GeneralSecurityException, JSONException {
        File file = vaultFile();
        List<Record> result = new ArrayList<>();
        if (!file.exists()) {
            return result;
        }
        byte[] iv;
        byte[] ciphertext;
        try (DataInputStream input = new DataInputStream(new FileInputStream(file))) {
            if (input.readInt() != MAGIC || input.readInt() != FORMAT_VERSION) {
                throw new IOException("Unsupported password vault format");
            }
            int ivLength = input.readInt();
            iv = new byte[ivLength];
            input.readFully(iv);
            int ciphertextLength = input.readInt();
            ciphertext = new byte[ciphertextLength];
            input.readFully(ciphertext);
            if (input.read() != -1) {
                throw new IOException("Unexpected trailing password vault data");
            }
        }
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, key(), new GCMParameterSpec(128, iv));
        JSONArray payload = new JSONArray(new String(cipher.doFinal(ciphertext), StandardCharsets.UTF_8));
        for (int index = 0; index < payload.length(); index++) {
            JSONObject item = payload.getJSONObject(index);
            result.add(new Record(
                    item.getString("id"),
                    item.getString("name"),
                    item.getString("school"),
                    item.getString("username"),
                    item.getString("password"),
                    item.getString("notes")));
        }
        return result;
    }

    private void writeRecords(List<Record> source) throws IOException, GeneralSecurityException, JSONException {
        JSONArray payload = new JSONArray();
        for (Record record : source) {
            JSONObject item = new JSONObject();
            item.put("id", record.id);
            item.put("name", record.name);
            item.put("school", record.school);
            item.put("username", record.username);
            item.put("password", record.password);
            item.put("notes", record.notes);
            payload.put(item);
        }
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, key());
        byte[] ciphertext = cipher.doFinal(payload.toString().getBytes(StandardCharsets.UTF_8));
        byte[] iv = cipher.getIV();
        File destination = vaultFile();
        File temporary = new File(destination.getParentFile(), FILE_NAME + ".tmp");
        try (FileOutputStream stream = new FileOutputStream(temporary);
             DataOutputStream output = new DataOutputStream(stream)) {
            output.writeInt(MAGIC);
            output.writeInt(FORMAT_VERSION);
            output.writeInt(iv.length);
            output.write(iv);
            output.writeInt(ciphertext.length);
            output.write(ciphertext);
            output.flush();
            stream.getFD().sync();
        }
        try {
            Os.rename(temporary.getAbsolutePath(), destination.getAbsolutePath());
        } catch (ErrnoException exception) {
            throw exception.rethrowAsIOException();
        }
    }

    private static final class Record {
        final String id;
        final String name;
        final String school;
        final String username;
        final String password;
        final String notes;

        Record(String id, String name, String school, String username, String password, String notes) {
            this.id = id;
            this.name = name;
            this.school = school;
            this.username = username;
            this.password = password;
            this.notes = notes;
        }
    }
}
