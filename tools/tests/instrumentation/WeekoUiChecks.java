package io.github.mxwf.weeko.tests;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import java.io.File;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

/** Runs under the target's UID. Test writes use an isolated no-backup directory. */
public final class WeekoUiChecks extends Instrumentation {
    private String flow;

    @Override public void onCreate(Bundle arguments) {
        super.onCreate(arguments);
        flow = arguments.getString("flow", "vault-storage");
        start();
    }

    @Override public void onStart() {
        Bundle result = new Bundle();
        try {
            if (!"vault-storage".equals(flow)) throw new IllegalArgumentException("Unknown test flow: " + flow);
            vaultStorage();
            result.putString("stream", "PASS: vault add/edit/delete failure consistency; isolated encrypted save/reopen; real vault untouched\n");
            finish(Activity.RESULT_OK, result);
        } catch (Exception error) {
            result.putString("stream", "FAIL: " + error.toString() + "\n");
            finish(Activity.RESULT_CANCELED, result);
        }
    }

    private void vaultStorage() throws Exception {
        ActivityMonitor mainMonitor = addMonitor("com.suda.yzune.wakeupschedule.schedule.ScheduleActivity", null, false);
        getTargetContext().startActivity(new Intent().setClassName("io.github.mxwf.weeko",
                "com.suda.yzune.wakeupschedule.SplashActivity")
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK));
        Activity main = waitForMonitorWithTimeout(mainMonitor, 15000);
        removeMonitor(mainMonitor);
        if (main == null) throw new IllegalStateException("Main timetable did not enter lifecycle within 15 seconds");
        Intent launch = new Intent().setClassName("io.github.mxwf.weeko", "io.github.mxwf.weeko.vault.PasswordVaultActivity")
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        ActivityMonitor monitor = addMonitor("io.github.mxwf.weeko.vault.PasswordVaultActivity", null, false);
        runOnMainSync(() -> main.startActivity(launch));
        Activity vault = waitForMonitorWithTimeout(monitor, 15000);
        removeMonitor(monitor);
        if (vault == null) throw new IllegalStateException("Vault did not enter lifecycle within 15 seconds");
        Thread.sleep(500);
        Class<?> type = vault.getClass();
        Field recordsField = type.getDeclaredField("records"); recordsField.setAccessible(true);
        Field baseField = ContextWrapper.class.getDeclaredField("mBase"); baseField.setAccessible(true);
        Method persist = type.getDeclaredMethod("persistAndRender", List.class); persist.setAccessible(true);
        Method read = type.getDeclaredMethod("readRecords"); read.setAccessible(true);
        Class<?> recordType = Class.forName(type.getName()+"$Record", true, type.getClassLoader());
        Constructor<?> constructor = recordType.getDeclaredConstructor(String.class,String.class,String.class,String.class,String.class,String.class);
        constructor.setAccessible(true);
        Object testRecord = constructor.newInstance("weeko-local-check", "local-check", "", "local-check", "not-a-real-password", "");
        Context original = vault.getBaseContext();
        File realFile = new File(original.getNoBackupFilesDir(), "password-vault.bin");
        byte[] realBefore = java.nio.file.Files.readAllBytes(realFile.toPath());
        File testDirectory = new File(original.getNoBackupFilesDir(), "weeko-local-ui-checks");
        if (testDirectory.exists()) throw new IllegalStateException("Isolated test directory already exists");
        if (!testDirectory.mkdir()) throw new IllegalStateException("Cannot create isolated test directory");
        Context failing = new ContextWrapper(original) {
            @Override public File getNoBackupFilesDir() { return new File("/proc/weeko-local-ui-checks"); }
        };
        Context isolated = new ContextWrapper(original) {
            @Override public File getNoBackupFilesDir() { return testDirectory; }
        };
        AtomicReference<Exception> failure = new AtomicReference<>();
        int[] originalSize = new int[1];
        try {
            runOnMainSync(() -> {
                try {
                    List<?> records = (List<?>) recordsField.get(vault);
                    originalSize[0] = records.size();
                    List<Object> before = new ArrayList<>(records);
                    baseField.set(vault, failing);
                    List<Object> add = new ArrayList<>(before); add.add(testRecord);
                    if ((boolean) persist.invoke(vault,add)) throw new IllegalStateException("Expected add failure");
                    if (!before.equals(records)) throw new IllegalStateException("Add failure changed records");
                    if (!before.isEmpty()) {
                        List<Object> edit = new ArrayList<>(before); edit.set(0,testRecord);
                        if ((boolean) persist.invoke(vault,edit) || !before.equals(records)) throw new IllegalStateException("Edit failure changed records");
                        List<Object> delete = new ArrayList<>(before); delete.remove(0);
                        if ((boolean) persist.invoke(vault,delete) || !before.equals(records)) throw new IllegalStateException("Delete failure changed records");
                    } else throw new IllegalStateException("Edit/delete failure needs an existing record");
                    baseField.set(vault,isolated);
                    List<Object> sample = new ArrayList<>(); sample.add(testRecord);
                    if (!(boolean) persist.invoke(vault,sample)) throw new IllegalStateException("Isolated save failed");
                    List<?> reopened = (List<?>) read.invoke(vault);
                    if (reopened.size()!=1) throw new IllegalStateException("Isolated reopen mismatch");
                    byte[] encrypted = java.nio.file.Files.readAllBytes(new File(testDirectory,"password-vault.bin").toPath());
                    String bytes = new String(encrypted,java.nio.charset.StandardCharsets.ISO_8859_1);
                    if (bytes.contains("local-check") || bytes.contains("not-a-real-password")) throw new IllegalStateException("Plaintext found in vault file");
                    baseField.set(vault,original);
                    if (((List<?>)read.invoke(vault)).size()!=originalSize[0]) throw new IllegalStateException("Real vault changed");
                    if (!java.util.Arrays.equals(realBefore,java.nio.file.Files.readAllBytes(realFile.toPath())))
                        throw new IllegalStateException("Real vault bytes changed");
                } catch (Exception error) { failure.set(error); }
            });
            if (failure.get()!=null) throw failure.get();
        } finally {
            runOnMainSync(() -> {
                try { baseField.set(vault,original); } catch (IllegalAccessException error) { throw new IllegalStateException(error); }
                vault.finish();
            });
            File data = new File(testDirectory,"password-vault.bin");
            File temporary = new File(testDirectory,"password-vault.bin.tmp");
            if (data.exists() && !data.delete()) throw new IllegalStateException("Test vault cleanup failed");
            if (temporary.exists() && !temporary.delete()) throw new IllegalStateException("Test temp cleanup failed");
            if (!testDirectory.delete()) throw new IllegalStateException("Test directory cleanup failed");
        }
    }
}
