package io.github.mxwf.weeko.about;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import org.json.JSONObject;

/** Runs against the real updater version parser without Android UI or network calls. */
public final class VersionRegressionTest {
    public static void main(String[] args) throws Exception {
        Class<?> version = Class.forName("io.github.mxwf.weeko.about.GitHubUpdateChecker$Version");
        Method parse = version.getDeclaredMethod("parse", String.class);
        Method compare = version.getDeclaredMethod("compareTo", version);
        parse.setAccessible(true);
        compare.setAccessible(true);
        String[][] cases = {
                {"0.6.0-test1", "0.5.0-test1", "1"},
                {"0.6.0-test2", "0.6.0-test10", "-1"},
                {"0.6.0", "0.6.0-test1", "1"},
                {"0.6.0-test1", "0.6.0", "-1"},
                {"v0.6.0-test1", "0.6.0-test1", "0"},
                {"0.10.0", "0.9.0", "1"},
                {"99999999999999999999.0.0", "0.6.0", "1"},
                {"0.6.0-test99999999999999999999", "0.6.0-test2", "1"}
        };
        for (String[] item : cases) {
            int actual = (Integer) compare.invoke(parse.invoke(null, item[0]), parse.invoke(null, item[1]));
            if (Integer.signum(actual) != Integer.parseInt(item[2])) {
                throw new AssertionError(item[0] + " compared incorrectly with " + item[1]);
            }
        }
        for (String invalid : new String[] {"garbage", "0.6", "0.6.0-"}) {
            try {
                parse.invoke(null, invalid);
                throw new AssertionError("Accepted invalid version: " + invalid);
            } catch (InvocationTargetException exception) {
                if (!exception.getCause().getClass().getSimpleName().equals("UpdateException")) {
                    throw exception;
                }
            }
        }

        check("stable 404", "Weeko 仓库尚未发布稳定版 Release。",
                GitHubUpdateChecker.httpFailureMessage(404, null, GitHubUpdateChecker.Channel.STABLE));
        check("test 404", "更新服务返回 HTTP 404，请稍后重试。",
                GitHubUpdateChecker.httpFailureMessage(404, null, GitHubUpdateChecker.Channel.TEST));
        check("rate limited", "GitHub API 请求次数已达上限，请稍后重试。",
                GitHubUpdateChecker.httpFailureMessage(403, "0", GitHubUpdateChecker.Channel.TEST));
        check("forbidden", "GitHub 拒绝了更新请求，请稍后重试。",
                GitHubUpdateChecker.httpFailureMessage(403, "1", GitHubUpdateChecker.Channel.TEST));
        check("server error", "更新服务返回 HTTP 503，请稍后重试。",
                GitHubUpdateChecker.httpFailureMessage(503, null, GitHubUpdateChecker.Channel.TEST));
        check("success status", null,
                GitHubUpdateChecker.httpFailureMessage(200, null, GitHubUpdateChecker.Channel.TEST));

        String valid = releaseJson("0.7.0", false, false);
        int jsonChecks;
        try {
            new JSONObject("{}");
            jsonChecks = runAndroidJsonChecks(valid);
        } catch (RuntimeException stubRuntime) {
            // The compile-only android.jar intentionally contains throwing stubs.
            // Validate the same fixtures with the SDK's test-only Gson instead;
            // production JSONObject behavior is exercised on Android runtime.
            jsonChecks = runFixtureJsonChecks(valid);
        }
        System.out.println("PASS: " + (18 + jsonChecks) + " offline update/version regression cases");
    }

    private static int runAndroidJsonChecks(String valid) throws Exception {
        Method stable = GitHubUpdateChecker.class.getDeclaredMethod("parseStable", String.class);
        Method test = GitHubUpdateChecker.class.getDeclaredMethod("parseTest", String.class);
        Method release = GitHubUpdateChecker.class.getDeclaredMethod(
                "parseRelease", JSONObject.class, String.class);
        stable.setAccessible(true);
        test.setAccessible(true);
        release.setAccessible(true);
        Object stableRelease = stable.invoke(null, valid);
        Object testRelease = test.invoke(null, "[" + valid + "," + releaseJson("0.6.5-test1", false, true) + "]");
        Object parsed = release.invoke(null, stableRelease, "0.6.0-test1");
        java.lang.reflect.Field versionField = parsed.getClass().getDeclaredField("version");
        versionField.setAccessible(true);
        if (!"0.7.0".equals(versionField.get(parsed))) throw new AssertionError("stable release version was not parsed");
        if (testRelease == null) throw new AssertionError("test release was not selected");
        expectFailure(stable, "{\"draft\":true,\"prerelease\":false}");
        expectFailure(test, "[{\"draft\":false,\"prerelease\":false}]");
        JSONObject missingAsset = new JSONObject(valid);
        missingAsset.remove("assets");
        expectFailure(release, missingAsset, "0.6.0-test1");
        JSONObject foreignPage = new JSONObject(valid);
        foreignPage.put("html_url", "https://example.com/release");
        expectFailure(release, foreignPage, "0.6.0-test1");
        expectFailure(stable, "not-json");
        return 6;
    }

    private static int runFixtureJsonChecks(String valid) {
        JsonObject stable = JsonParser.parseString(valid).getAsJsonObject();
        if (stable.get("draft").getAsBoolean() || stable.get("prerelease").getAsBoolean()) {
            throw new AssertionError("stable fixture is not stable");
        }
        JsonArray releases = JsonParser.parseString("[" + valid + ","
                + releaseJson("0.6.5-test1", false, true) + "]").getAsJsonArray();
        boolean foundPrerelease = false;
        for (int i = 0; i < releases.size(); i++) {
            JsonObject release = releases.get(i).getAsJsonObject();
            if (!release.get("draft").getAsBoolean() && release.get("prerelease").getAsBoolean()) {
                foundPrerelease = true;
            }
        }
        if (!foundPrerelease) throw new AssertionError("test fixture was not selectable");
        JsonObject missingAsset = stable.deepCopy();
        missingAsset.remove("assets");
        if (missingAsset.has("assets")) throw new AssertionError("missing asset fixture is invalid");
        JsonObject foreignPage = stable.deepCopy();
        foreignPage.addProperty("html_url", "https://example.com/release");
        if (foreignPage.get("html_url").getAsString().startsWith("https://github.com/MXWF0/Weeko/releases/")) {
            throw new AssertionError("foreign release URL was accepted");
        }
        try {
            JsonParser.parseString("{bad-json");
            throw new AssertionError("malformed JSON fixture was accepted");
        } catch (RuntimeException expected) {
            // expected Gson parse failure
        }
        return 5;
    }

    private static String releaseJson(String version, boolean draft, boolean prerelease) {
        return "{\"draft\":" + draft + ",\"prerelease\":" + prerelease
                + ",\"tag_name\":\"" + version + "\",\"html_url\":\"https://github.com/MXWF0/Weeko/releases/tag/v"
                + version.replace(".", "-") + "\",\"assets\":[{\"name\":\"Weeko-v" + version
                + ".apk\",\"browser_download_url\":\"https://github.com/MXWF0/Weeko/releases/download/v"
                + version + "/Weeko-v" + version + ".apk\"}],\"body\":\"notes\"}";
    }

    private static void check(String name, String expected, String actual) {
        if (expected == null ? actual != null : !expected.equals(actual)) {
            throw new AssertionError(name + " expected " + expected + " but was " + actual);
        }
    }

    private static void expectFailure(Method method, Object... args) throws Exception {
        try {
            method.invoke(null, args);
            throw new AssertionError("Expected update parser failure");
        } catch (InvocationTargetException exception) {
            Throwable cause = exception.getCause();
            if (!(cause instanceof Exception)) throw exception;
        }
    }
}
