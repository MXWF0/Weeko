package io.github.mxwf.weeko.about;

import android.os.Handler;
import android.os.Looper;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

final class GitHubUpdateChecker {
    enum Channel { STABLE, TEST }

    interface Callback {
        void onResult(Result result);
        void onFailure(String message);
    }

    static final class Result {
        final boolean updateAvailable;
        final String version;
        final String notes;
        final String assetName;
        final String assetUrl;
        final String releaseUrl;

        Result(boolean updateAvailable, String version, String notes, String assetName,
               String assetUrl, String releaseUrl) {
            this.updateAvailable = updateAvailable;
            this.version = version;
            this.notes = notes;
            this.assetName = assetName;
            this.assetUrl = assetUrl;
            this.releaseUrl = releaseUrl;
        }
    }

    private static final String API_ROOT = "https://api.github.com/repos/MXWF0/Weeko/releases";
    private static final String RELEASE_ROOT = "https://github.com/MXWF0/Weeko/releases/";
    private static final Pattern VERSION_PATTERN = Pattern.compile(
            "^v?(\\d+)\\.(\\d+)\\.(\\d+)(?:-([0-9A-Za-z.-]+))?$"
    );

    private GitHubUpdateChecker() {}

    static void check(Channel channel, String currentVersion, Callback callback) {
        new Thread(() -> {
            try {
                Result result = request(channel, currentVersion);
                post(() -> callback.onResult(result));
            } catch (UpdateException exception) {
                post(() -> callback.onFailure(exception.getMessage()));
            }
        }, "weeko-update-check").start();
    }

    private static void post(Runnable action) {
        new Handler(Looper.getMainLooper()).post(action);
    }

    private static Result request(Channel channel, String currentVersion) throws UpdateException {
        HttpURLConnection connection = null;
        try {
            String endpoint = channel == Channel.STABLE ? API_ROOT + "/latest" : API_ROOT;
            connection = (HttpURLConnection) new URL(endpoint).openConnection();
            connection.setConnectTimeout(10_000);
            connection.setReadTimeout(15_000);
            connection.setRequestProperty("Accept", "application/vnd.github+json");
            connection.setRequestProperty("X-GitHub-Api-Version", "2022-11-28");
            connection.setRequestProperty("User-Agent", "Weeko-Android/1.0.0");

            int status = connection.getResponseCode();
            String statusError = httpFailureMessage(
                    status, connection.getHeaderField("X-RateLimit-Remaining"), channel);
            if (statusError != null) throw new UpdateException(statusError);

            String body = readBody(connection.getInputStream());
            JSONObject release = channel == Channel.STABLE ? parseStable(body) : parseTest(body);
            return parseRelease(release, currentVersion);
        } catch (IOException exception) {
            throw new UpdateException("网络连接失败，请检查网络后重试。");
        } catch (JSONException exception) {
            throw new UpdateException("GitHub 返回了无法识别的 Release 数据。");
        } finally {
            if (connection != null) connection.disconnect();
        }
    }

    static String httpFailureMessage(int status, String remaining, Channel channel) {
        if (status == 404 && channel == Channel.STABLE) {
            return "Weeko 仓库尚未发布稳定版 Release。";
        }
        if (status == 403 && "0".equals(remaining)) {
            return "GitHub API 请求次数已达上限，请稍后重试。";
        }
        if (status == 403) {
            return "GitHub 拒绝了更新请求，请稍后重试。";
        }
        if (status < 200 || status >= 300) {
            return "更新服务返回 HTTP " + status + "，请稍后重试。";
        }
        return null;
    }

    private static JSONObject parseStable(String body) throws JSONException, UpdateException {
        JSONObject release = new JSONObject(body);
        if (release.optBoolean("draft") || release.optBoolean("prerelease")) {
            throw new UpdateException("GitHub latest Release 不是可用的稳定版。");
        }
        return release;
    }

    private static JSONObject parseTest(String body) throws JSONException, UpdateException {
        JSONArray releases = new JSONArray(body);
        for (int index = 0; index < releases.length(); index++) {
            JSONObject release = releases.getJSONObject(index);
            if (!release.optBoolean("draft") && release.optBoolean("prerelease")) return release;
        }
        throw new UpdateException("Weeko 仓库尚未发布测试版 Release。");
    }

    private static Result parseRelease(JSONObject release, String currentVersion)
            throws JSONException, UpdateException {
        Version remote = Version.parse(requiredString(release, "tag_name"));
        Version current = Version.parse(currentVersion);
        String releaseUrl = requiredString(release, "html_url");
        if (!releaseUrl.startsWith(RELEASE_ROOT)) {
            throw new UpdateException("Release 页面地址不属于 MXWF0/Weeko。");
        }

        String expectedAsset = "Weeko-v" + remote.display + ".apk";
        JSONArray assets = release.getJSONArray("assets");
        String assetName = null;
        String assetUrl = null;
        for (int index = 0; index < assets.length(); index++) {
            JSONObject asset = assets.getJSONObject(index);
            String name = asset.optString("name");
            if (expectedAsset.equalsIgnoreCase(name)) {
                String candidateUrl = requiredString(asset, "browser_download_url");
                if (!candidateUrl.startsWith(RELEASE_ROOT + "download/")) {
                    throw new UpdateException("Release APK 下载地址不属于 MXWF0/Weeko。");
                }
                assetName = name;
                assetUrl = candidateUrl;
                break;
            }
        }
        if (assetUrl == null) {
            throw new UpdateException("Release 中没有匹配的 Weeko APK：" + expectedAsset);
        }

        return new Result(
                remote.compareTo(current) > 0,
                remote.display,
                release.optString("body", "").trim(),
                assetName,
                assetUrl,
                releaseUrl
        );
    }

    private static String requiredString(JSONObject object, String name)
            throws JSONException, UpdateException {
        String value = object.getString(name).trim();
        if (value.isEmpty()) throw new UpdateException("GitHub Release 缺少字段：" + name);
        return value;
    }

    private static String readBody(InputStream input) throws IOException {
        StringBuilder body = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(input, StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) body.append(line).append('\n');
        }
        return body.toString();
    }

    private static final class Version implements Comparable<Version> {
        final BigInteger major;
        final BigInteger minor;
        final BigInteger patch;
        final String suffix;
        final String display;

        Version(BigInteger major, BigInteger minor, BigInteger patch, String suffix, String display) {
            this.major = major;
            this.minor = minor;
            this.patch = patch;
            this.suffix = suffix;
            this.display = display;
        }

        static Version parse(String raw) throws UpdateException {
            Matcher matcher = VERSION_PATTERN.matcher(raw.trim());
            if (!matcher.matches()) throw new UpdateException("无法比较版本号：" + raw);
            String display = matcher.group(1) + "." + matcher.group(2) + "." + matcher.group(3);
            String suffix = matcher.group(4);
            if (suffix != null) display += "-" + suffix;
            return new Version(
                    new BigInteger(matcher.group(1)),
                    new BigInteger(matcher.group(2)),
                    new BigInteger(matcher.group(3)),
                    suffix,
                    display
            );
        }

        @Override
        public int compareTo(Version other) {
            if (!major.equals(other.major)) return major.compareTo(other.major);
            if (!minor.equals(other.minor)) return minor.compareTo(other.minor);
            if (!patch.equals(other.patch)) return patch.compareTo(other.patch);
            if (suffix == null && other.suffix != null) return 1;
            if (suffix != null && other.suffix == null) return -1;
            if (suffix == null) return 0;
            return compareSuffix(suffix, other.suffix);
        }

        private static int compareSuffix(String left, String right) {
            List<String> leftParts = splitSuffix(left);
            List<String> rightParts = splitSuffix(right);
            int size = Math.max(leftParts.size(), rightParts.size());
            for (int index = 0; index < size; index++) {
                if (index >= leftParts.size()) return -1;
                if (index >= rightParts.size()) return 1;
                String a = leftParts.get(index);
                String b = rightParts.get(index);
                int result = a.matches("\\d+") && b.matches("\\d+")
                        ? new BigInteger(a).compareTo(new BigInteger(b))
                        : a.compareToIgnoreCase(b);
                if (result != 0) return result;
            }
            return 0;
        }

        private static List<String> splitSuffix(String value) {
            Matcher matcher = Pattern.compile("[A-Za-z]+|\\d+").matcher(value);
            List<String> parts = new ArrayList<>();
            while (matcher.find()) parts.add(matcher.group());
            return parts;
        }
    }

    private static final class UpdateException extends Exception {
        UpdateException(String message) { super(message); }
    }
}
