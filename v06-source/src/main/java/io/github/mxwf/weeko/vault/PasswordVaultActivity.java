package io.github.mxwf.weeko.vault;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.Bundle;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.system.ErrnoException;
import android.system.Os;
import android.text.InputType;
import android.text.method.PasswordTransformationMethod;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
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
import java.util.List;
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
    private LinearLayout list;
    private TextView status;

    public static void open(Context context) {
        context.startActivity(new Intent(context, PasswordVaultActivity.class));
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            new AlertDialog.Builder(this)
                    .setTitle("无法使用密码箱")
                    .setMessage("密码箱需要 Android 6.0 或更高版本提供的 Keystore AES-GCM。")
                    .setPositiveButton("返回", (dialog, which) -> finish())
                    .setCancelable(false)
                    .show();
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
        int id = getResources().getIdentifier(name, "color", getPackageName());
        return getResources().getColor(id);
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
        return button;
    }

    private void buildScreen() {
        int background = color("md_theme_background");
        int onSurface = color("md_theme_onSurface");
        int secondary = color("md_theme_onSurfaceVariant");

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(background);

        LinearLayout toolbar = new LinearLayout(this);
        toolbar.setGravity(Gravity.CENTER_VERTICAL);
        toolbar.setPadding(dp(8), dp(8), dp(12), dp(8));
        Button back = button("‹");
        back.setTextSize(TypedValue.COMPLEX_UNIT_SP, 30f);
        back.setOnClickListener(view -> finish());
        toolbar.addView(back, new LinearLayout.LayoutParams(dp(52), dp(52)));
        TextView title = text("密码箱", 22f, onSurface, true);
        toolbar.addView(title, new LinearLayout.LayoutParams(0, -2, 1f));
        Button add = button("新增账号");
        add.setOnClickListener(view -> showEditor(null));
        toolbar.addView(add, new LinearLayout.LayoutParams(-2, dp(48)));
        root.addView(toolbar, new LinearLayout.LayoutParams(-1, -2));

        status = text("", 14f, secondary, false);
        status.setPadding(dp(20), 0, dp(20), dp(12));
        root.addView(status, new LinearLayout.LayoutParams(-1, -2));

        ScrollView scroll = new ScrollView(this);
        list = new LinearLayout(this);
        list.setOrientation(LinearLayout.VERTICAL);
        list.setPadding(dp(16), 0, dp(16), dp(24));
        scroll.addView(list, new ScrollView.LayoutParams(-1, -2));
        root.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1f));
        setContentView(root);
        renderRecords();
    }

    private void renderRecords() {
        list.removeAllViews();
        status.setText(records.isEmpty()
                ? "未保存账号 · Android Keystore 加密"
                : "已保存 " + records.size() + " 个账号 · Android Keystore 加密");
        if (records.isEmpty()) {
            TextView empty = text("还没有保存账号。", 16f, color("md_theme_onSurfaceVariant"), false);
            empty.setGravity(Gravity.CENTER);
            empty.setPadding(0, dp(64), 0, 0);
            list.addView(empty, new LinearLayout.LayoutParams(-1, -2));
            return;
        }
        for (Record record : records) {
            list.addView(recordCard(record), cardParams());
        }
    }

    private LinearLayout.LayoutParams cardParams() {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-1, -2);
        params.setMargins(0, 0, 0, dp(12));
        return params;
    }

    private View recordCard(Record record) {
        int onSurface = color("md_theme_onSurface");
        int secondary = color("md_theme_onSurfaceVariant");
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(14), dp(16), dp(12));
        GradientDrawable background = new GradientDrawable();
        background.setColor(color("md_theme_surfaceVariant"));
        background.setCornerRadius(dp(16));
        card.setBackground(background);

        card.addView(text(record.name, 18f, onSurface, true), new LinearLayout.LayoutParams(-1, -2));
        if (!record.school.isEmpty()) {
            card.addView(text(record.school, 14f, secondary, false), new LinearLayout.LayoutParams(-1, -2));
        }
        TextView username = text("用户名  " + record.username, 15f, onSurface, false);
        username.setPadding(0, dp(10), 0, 0);
        card.addView(username, new LinearLayout.LayoutParams(-1, -2));
        card.addView(text("密码  ••••••••", 15f, onSurface, false), new LinearLayout.LayoutParams(-1, -2));
        if (!record.notes.isEmpty()) {
            TextView notes = text(record.notes, 14f, secondary, false);
            notes.setPadding(0, dp(8), 0, 0);
            card.addView(notes, new LinearLayout.LayoutParams(-1, -2));
        }

        LinearLayout copyActions = new LinearLayout(this);
        Button copyUsername = button("复制用户名");
        copyUsername.setOnClickListener(view -> copy("教务用户名", record.username));
        copyActions.addView(copyUsername, new LinearLayout.LayoutParams(0, -2, 1f));
        Button copyPassword = button("复制密码");
        copyPassword.setOnClickListener(view -> copy("教务密码", record.password));
        copyActions.addView(copyPassword, new LinearLayout.LayoutParams(0, -2, 1f));
        card.addView(copyActions, new LinearLayout.LayoutParams(-1, -2));

        LinearLayout editActions = new LinearLayout(this);
        Button edit = button("编辑");
        edit.setOnClickListener(view -> showEditor(record));
        editActions.addView(edit, new LinearLayout.LayoutParams(0, -2, 1f));
        Button delete = button("删除");
        delete.setOnClickListener(view -> confirmDelete(record));
        editActions.addView(delete, new LinearLayout.LayoutParams(0, -2, 1f));
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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            field.setImportantForAutofill(View.IMPORTANT_FOR_AUTOFILL_NO);
        }
        return field;
    }

    private void showEditor(Record existing) {
        LinearLayout fields = new LinearLayout(this);
        fields.setOrientation(LinearLayout.VERTICAL);
        fields.setPadding(dp(20), 0, dp(20), 0);
        EditText name = field("名称", existing == null ? "" : existing.name);
        EditText school = field("学校", existing == null ? "" : existing.school);
        EditText username = field("用户名", existing == null ? "" : existing.username);
        EditText password = field("密码", existing == null ? "" : existing.password);
        password.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD);
        password.setTransformationMethod(PasswordTransformationMethod.getInstance());
        EditText notes = field("备注", existing == null ? "" : existing.notes);
        notes.setSingleLine(false);
        notes.setMinLines(2);
        fields.addView(name);
        fields.addView(school);
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
                    String nameValue = name.getText().toString().trim();
                    String usernameValue = username.getText().toString().trim();
                    String passwordValue = password.getText().toString();
                    if (nameValue.isEmpty()) {
                        name.setError("请输入名称");
                        return;
                    }
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
                            nameValue,
                            school.getText().toString().trim(),
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
    }

    private void confirmDelete(Record record) {
        new AlertDialog.Builder(this)
                .setTitle("删除账号")
                .setMessage("确定删除“" + record.name + "”？")
                .setNegativeButton("取消", null)
                .setPositiveButton("删除", (dialog, which) -> {
                    records.remove(record);
                    persistAndRender();
                })
                .show();
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
        new AlertDialog.Builder(this)
                .setTitle("密码箱保存失败")
                .setMessage(exception.getClass().getSimpleName() + ": " + exception.getMessage())
                .setPositiveButton("关闭", null)
                .show();
    }

    private void showFatalError(Exception exception) {
        new AlertDialog.Builder(this)
                .setTitle("密码箱无法打开")
                .setMessage(exception.getClass().getSimpleName() + ": " + exception.getMessage())
                .setPositiveButton("返回", (dialog, which) -> finish())
                .setCancelable(false)
                .show();
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
