package io.github.mxwf.weeko.about;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ActivityNotFoundException;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.WindowInsets;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

/**
 * Weeko-owned About and internal-test notes screen.
 *
 * This screen intentionally uses only Android platform UI classes. It does not
 * read the legacy database, preferences, network clients, or WakeUp adapters.
 */
public final class WeekoAboutActivity extends Activity {
    private int dp(float value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }

    private int color(String name) {
        int id = getResources().getIdentifier(name, "color", getPackageName());
        return getResources().getColor(id);
    }

    private TextView label(String value, float size, int color, boolean bold) {
        TextView view = new TextView(this);
        view.setText(value);
        view.setTextSize(TypedValue.COMPLEX_UNIT_SP, size);
        view.setTextColor(color);
        view.setLineSpacing(0f, 1.2f);
        if (bold) {
            view.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        } else {
            view.setTypeface(Typeface.create("sans-serif", Typeface.NORMAL));
        }
        return view;
    }

    private LinearLayout card(String title, String body, int surface, int text, int secondary) {
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(14), dp(16), dp(14));
        // The mother app uses the platform Material rounded shape for these
        // containers. Keep the same 16dp-equivalent radius instead of a
        // separate custom path whose curvature reads differently on-device.
        GradientDrawable cardBackground = new GradientDrawable();
        cardBackground.setColor(surface);
        cardBackground.setCornerRadius(dp(16));
        card.setBackground(cardBackground);

        TextView heading = label(title, 16f, text, true);
        heading.setLineSpacing(0f, 1f);
        card.addView(heading, new LinearLayout.LayoutParams(-1, -2));
        TextView content = label(body, 16f, secondary, false);
        content.setPadding(0, dp(8), 0, 0);
        content.setTextIsSelectable(true);
        card.addView(content, new LinearLayout.LayoutParams(-1, -2));
        return card;
    }

    private void addCard(LinearLayout parent, LinearLayout card) {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-1, -2);
        params.setMargins(0, 0, 0, dp(12));
        parent.addView(card, params);
    }

    private Button actionButton(String text, int textColor, int backgroundColor) {
        Button button = new Button(this);
        button.setText(text);
        button.setTextColor(textColor);
        button.setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f);
        button.setAllCaps(false);
        button.setMinHeight(dp(48));
        GradientDrawable background = new GradientDrawable();
        background.setColor(backgroundColor);
        background.setCornerRadius(dp(12));
        button.setBackground(background);
        return button;
    }

    private void addAction(LinearLayout parent, Button button) {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-1, -2);
        params.setMargins(0, 0, 0, dp(12));
        parent.addView(button, params);
    }

    private void showContactDialog() {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(20), dp(4), dp(20), 0);

        TextView hint = label("维护邮箱（可选择并复制）", 14f, color("md_theme_onSurfaceVariant"), false);
        TextView email = label("mxwfwdw@outlook.com", 16f, color("md_theme_onSurface"), true);
        email.setTextIsSelectable(true);
        box.addView(hint, new LinearLayout.LayoutParams(-1, -2));
        box.addView(email, new LinearLayout.LayoutParams(-1, -2));

        int dialogText = color("md_theme_onSurface");
        hint.setTextColor(color("md_theme_onSurfaceVariant"));
        email.setTextColor(dialogText);

        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("联系我们")
                .setView(box)
                .setNeutralButton("复制邮箱", null)
                .setPositiveButton("关闭", null)
                .create();
        dialog.setOnShowListener(ignored -> dialog.getButton(AlertDialog.BUTTON_NEUTRAL)
                .setOnClickListener(view -> {
                    ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
                    clipboard.setPrimaryClip(ClipData.newPlainText("Weeko 联系邮箱", "mxwfwdw@outlook.com"));
                }));
        dialog.show();
    }

    private String versionName() {
        try {
            PackageInfo info = getPackageManager().getPackageInfo(getPackageName(), 0);
            return info.versionName;
        } catch (PackageManager.NameNotFoundException exception) {
            throw new IllegalStateException("Weeko package metadata is unavailable", exception);
        }
    }

    private void openUrl(String url) {
        try {
            startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
        } catch (ActivityNotFoundException exception) {
            new AlertDialog.Builder(this)
                    .setTitle("无法打开链接")
                    .setMessage("设备上没有可处理此链接的应用。")
                    .setPositiveButton("关闭", null)
                    .show();
        }
    }

    private void checkForUpdates(Button trigger, GitHubUpdateChecker.Channel channel) {
        trigger.setEnabled(false);
        CharSequence originalText = trigger.getText();
        trigger.setText("正在检查…");
        GitHubUpdateChecker.check(channel, versionName(), new GitHubUpdateChecker.Callback() {
            @Override
            public void onResult(GitHubUpdateChecker.Result result) {
                // A network response can arrive after the user has left this Activity.
                if (isFinishing() || isDestroyed()) return;
                trigger.setEnabled(true);
                trigger.setText(originalText);
                showUpdateResult(result);
            }

            @Override
            public void onFailure(String message) {
                if (isFinishing() || isDestroyed()) return;
                trigger.setEnabled(true);
                trigger.setText(originalText);
                new AlertDialog.Builder(WeekoAboutActivity.this)
                        .setTitle("检查更新失败")
                        .setMessage(message)
                        .setPositiveButton("关闭", null)
                        .show();
            }
        });
    }

    private void showUpdateResult(GitHubUpdateChecker.Result result) {
        String message;
        if (result.updateAvailable) {
            message = "发现 Weeko " + result.version + "\n\n"
                    + (result.notes.isEmpty() ? "该 Release 未提供更新说明。" : result.notes)
                    + "\n\nAPK：" + result.assetName;
        } else {
            message = "当前已是此通道的最新版本。\n\nRelease：" + result.version;
        }

        AlertDialog.Builder dialog = new AlertDialog.Builder(this)
                .setTitle(result.updateAvailable ? "发现新版本" : "已是最新版本")
                .setMessage(message)
                .setNegativeButton("关闭", null)
                .setNeutralButton("发布页", (ignored, which) -> openUrl(result.releaseUrl));
        if (result.updateAvailable) {
            dialog.setPositiveButton("下载 APK", (ignored, which) -> openUrl(result.assetUrl));
        }
        dialog.show();
    }

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);

        boolean dark = (getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK)
                == Configuration.UI_MODE_NIGHT_YES;
        int background = color("md_theme_background");
        int surface = color("md_theme_surfaceContainerLow");
        int text = color("md_theme_onBackground");
        int secondary = color("md_theme_onSurfaceVariant");
        int blue = color("md_theme_primary");
        int buttonSurface = color("md_theme_surfaceContainerHigh");

        getWindow().setStatusBarColor(background);
        getWindow().setNavigationBarColor(background);
        if (!dark && Build.VERSION.SDK_INT >= 23) {
            int flags = View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
            if (Build.VERSION.SDK_INT >= 26) {
                flags |= View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
            }
            getWindow().getDecorView().setSystemUiVisibility(flags);
        }

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(background);

        LinearLayout toolbar = new LinearLayout(this);
        toolbar.setGravity(Gravity.CENTER_VERTICAL);
        toolbar.setPadding(0, dp(4), 0, dp(4));
        ImageButton back = new ImageButton(this);
        int backIcon = getResources().getIdentifier("ic_back", "drawable", getPackageName());
        back.setImageResource(backIcon);
        back.setContentDescription("返回");
        back.setBackgroundColor(Color.TRANSPARENT);
        back.setPadding(0, 0, 0, 0);
        toolbar.addView(back, new LinearLayout.LayoutParams(dp(56), dp(56)));
        TextView title = label("关于 Weeko", 22f, text, false);
        title.setLineSpacing(0f, 1f);
        title.setSingleLine(true);
        title.setEllipsize(TextUtils.TruncateAt.END);
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(0, -2, 1f);
        titleParams.setMargins(dp(4), 0, dp(12), 0);
        toolbar.addView(title, titleParams);
        back.setOnClickListener(view -> finish());
        root.addView(toolbar, new LinearLayout.LayoutParams(-1, -2));
        if (Build.VERSION.SDK_INT >= 21) {
            root.setOnApplyWindowInsetsListener((view, insets) -> {
                int topInset;
                if (Build.VERSION.SDK_INT >= 30) {
                    topInset = insets.getInsets(WindowInsets.Type.systemBars()).top;
                } else {
                    topInset = insets.getSystemWindowInsetTop();
                }
                toolbar.setPadding(0, topInset + dp(4), 0, dp(4));
                return insets;
            });
            root.requestApplyInsets();
        }

        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(dp(16), dp(12), dp(16), dp(24));

        TextView version = label("版本 " + versionName() + " · 过渡内测", 16f, blue, true);
        version.setLineSpacing(0f, 1f);
        version.setPadding(dp(16), dp(4), dp(16), dp(16));
        content.addView(version, new LinearLayout.LayoutParams(-1, -2));

        addCard(content, card("关于 Weeko",
                "Weeko 是面向高校学习的本地优先课程表。v0.6 继续以已验证的兼容母体维护课程、课表、作息和导入流程，并逐步替换可独立维护的区域。",
                surface, text, secondary));
        addCard(content, card("数据在本机",
                "课程数据库和大多数设置保存在当前设备。本页面不读取课程库或 SharedPreferences，也不会改变 Room v11、原有键名或 .wakeup_schedule 兼容格式。",
                surface, text, secondary));
        addCard(content, card("联网边界",
                "本页检查更新时仅访问 GitHub 的 MXWF0/Weeko Releases API，不内置 Token。教务导入、在线分享和申请适配仍来自兼容母体，可能访问旧版或学校服务；请勿提交密码、Cookie、Token 或个人信息。",
                surface, text, secondary));
        addCard(content, card("签名重置",
                "v0.6 起改用新的 Weeko 长期签名，不能直接覆盖 v0.5。迁移前请分别导出所有课表并确认备份可用，另行记录设置；课表文件不等于完整应用备份。卸载会删除本机应用数据。v0.6 后续版本沿用同一密钥。",
                surface, text, secondary));

        Button testUpdate = actionButton("检查测试版更新", blue, buttonSurface);
        testUpdate.setOnClickListener(view -> checkForUpdates(testUpdate, GitHubUpdateChecker.Channel.TEST));
        addAction(content, testUpdate);
        Button stableUpdate = actionButton("检查稳定版更新", blue, buttonSurface);
        stableUpdate.setOnClickListener(view -> checkForUpdates(stableUpdate, GitHubUpdateChecker.Channel.STABLE));
        addAction(content, stableUpdate);

        addCard(content, card("反馈与联系",
                "维护邮箱：mxwfwdw@outlook.com\n仅用于 Weeko 内测反馈；联系按钮只复制邮箱，不自动打开浏览器。",
                surface, text, secondary));
        Button contact = actionButton("联系我们", blue, buttonSurface);
        contact.setOnClickListener(view -> showContactDialog());
        addAction(content, contact);
        addCard(content, card("内测范围",
                "本版本只用于本地兼容性和功能验证，不得公开发布。遇到崩溃或 ANR，请保存设备型号、操作步骤和 logcat，再反馈给维护者。",
                surface, text, secondary));
        addCard(content, card("来源与许可证",
                "APK 保留兼容母体及第三方库的许可证和声明。本页为 Weeko 新增的平台源码，不代表旧版兼容母体的完整源码恢复。",
                surface, text, secondary));

        scroll.addView(content, new ScrollView.LayoutParams(-1, -2));
        root.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1f));
        setContentView(root);
    }
}
