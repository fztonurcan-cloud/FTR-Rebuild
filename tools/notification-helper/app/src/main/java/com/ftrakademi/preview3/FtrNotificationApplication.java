package com.ftrakademi.preview3;

import android.Manifest;
import android.app.Activity;
import android.app.Application;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

public final class FtrNotificationApplication extends Application implements Application.ActivityLifecycleCallbacks {
    public static final String CHANNEL_ID = "ftr_general";
    private static final String TAG = "FTR-PUSH";
    private static final String PREFS = "ftr_push_v1";
    private static final String KEY_TOKEN = "fcm_token";
    private static final String KEY_PERMISSION_ASKED = "notification_permission_asked";

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
        initializeFirebaseFromAsset();
        registerActivityLifecycleCallbacks(this);
        refreshToken();
    }

    private void initializeFirebaseFromAsset() {
        try {
            if (!FirebaseApp.getApps(this).isEmpty()) {
                return;
            }

            String json = readAsset("ftr-firebase.json");
            JSONObject root = new JSONObject(json);
            JSONObject projectInfo = root.getJSONObject("project_info");
            JSONArray clients = root.getJSONArray("client");
            JSONObject selected = null;
            for (int i = 0; i < clients.length(); i++) {
                JSONObject candidate = clients.getJSONObject(i);
                String pkg = candidate.getJSONObject("client_info")
                        .getJSONObject("android_client_info")
                        .optString("package_name", "");
                if (getPackageName().equals(pkg)) {
                    selected = candidate;
                    break;
                }
            }
            if (selected == null) {
                throw new IllegalStateException("Firebase client for package not found");
            }

            String appId = selected.getJSONObject("client_info").getString("mobilesdk_app_id");
            String apiKey = selected.getJSONArray("api_key").getJSONObject(0).getString("current_key");
            String projectId = projectInfo.getString("project_id");
            String senderId = projectInfo.getString("project_number");
            String storageBucket = projectInfo.optString("storage_bucket", null);

            FirebaseOptions.Builder builder = new FirebaseOptions.Builder()
                    .setApplicationId(appId)
                    .setApiKey(apiKey)
                    .setProjectId(projectId)
                    .setGcmSenderId(senderId);
            if (storageBucket != null && !storageBucket.isEmpty()) {
                builder.setStorageBucket(storageBucket);
            }

            FirebaseApp.initializeApp(this, builder.build());
            Log.i(TAG, "Firebase initialized for push notifications");
        } catch (Throwable t) {
            Log.e(TAG, "Firebase initialization failed", t);
        }
    }

    private String readAsset(String name) throws Exception {
        try (InputStream in = getAssets().open(name);
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[4096];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
            return out.toString(StandardCharsets.UTF_8.name());
        }
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager manager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            if (manager != null) {
                NotificationChannel channel = new NotificationChannel(
                        CHANNEL_ID,
                        "FTR Akademi",
                        NotificationManager.IMPORTANCE_DEFAULT
                );
                channel.setDescription("FTR Akademi duyuru ve eğitim bildirimleri");
                manager.createNotificationChannel(channel);
            }
        }
    }

    private void refreshToken() {
        try {
            FirebaseMessaging.getInstance().getToken().addOnCompleteListener(task -> {
                if (!task.isSuccessful() || task.getResult() == null) {
                    Log.w(TAG, "FCM token could not be obtained", task.getException());
                    return;
                }
                storeToken(task.getResult());
            });
        } catch (Throwable t) {
            Log.e(TAG, "FCM token request failed", t);
        }
    }

    public static void storeToken(Context context, String token) {
        if (token == null || token.isEmpty()) return;
        context.getSharedPreferences(PREFS, MODE_PRIVATE).edit().putString(KEY_TOKEN, token).apply();
        Log.i(TAG, "FCM token stored");
    }

    private void storeToken(String token) {
        storeToken(this, token);
    }

    @Override
    public void onActivityResumed(Activity activity) {
        if (!"com.ftrakademi.preview3.MainActivity".equals(activity.getClass().getName())) {
            return;
        }
        if (Build.VERSION.SDK_INT < 33) {
            return;
        }
        if (activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            return;
        }
        SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        if (prefs.getBoolean(KEY_PERMISSION_ASKED, false)) {
            return;
        }
        prefs.edit().putBoolean(KEY_PERMISSION_ASKED, true).apply();
        activity.requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 2907);
    }

    @Override public void onActivityCreated(Activity activity, Bundle state) { }
    @Override public void onActivityStarted(Activity activity) { }
    @Override public void onActivityPaused(Activity activity) { }
    @Override public void onActivityStopped(Activity activity) { }
    @Override public void onActivitySaveInstanceState(Activity activity, Bundle outState) { }
    @Override public void onActivityDestroyed(Activity activity) { }
}
