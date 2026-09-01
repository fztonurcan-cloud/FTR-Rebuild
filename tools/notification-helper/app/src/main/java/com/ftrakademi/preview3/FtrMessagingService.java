package com.ftrakademi.preview3;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

public final class FtrMessagingService extends FirebaseMessagingService {
    private static final AtomicInteger IDS = new AtomicInteger(290700);

    @Override
    public void onNewToken(String token) {
        super.onNewToken(token);
        FtrNotificationApplication.storeToken(this, token);
    }

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        super.onMessageReceived(remoteMessage);

        String title = null;
        String body = null;
        RemoteMessage.Notification notification = remoteMessage.getNotification();
        if (notification != null) {
            title = notification.getTitle();
            body = notification.getBody();
        }

        Map<String, String> data = remoteMessage.getData();
        if ((title == null || title.trim().isEmpty()) && data != null) {
            title = data.get("title");
        }
        if ((body == null || body.trim().isEmpty()) && data != null) {
            body = data.get("body");
        }

        if (title == null || title.trim().isEmpty()) title = "FTR Akademi";
        if (body == null || body.trim().isEmpty()) body = "Yeni bir bildiriminiz var.";

        showNotification(title, body);
    }

    private void showNotification(String title, String body) {
        NotificationManager manager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager == null) return;

        Intent launch = getPackageManager().getLaunchIntentForPackage(getPackageName());
        PendingIntent pendingIntent = null;
        if (launch != null) {
            launch.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            int flags = PendingIntent.FLAG_UPDATE_CURRENT;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                flags |= PendingIntent.FLAG_IMMUTABLE;
            }
            pendingIntent = PendingIntent.getActivity(this, 2907, launch, flags);
        }

        int smallIcon = getResources().getIdentifier("ic_launcher", "drawable", getPackageName());
        if (smallIcon == 0) smallIcon = getApplicationInfo().icon;
        if (smallIcon == 0) smallIcon = android.R.drawable.ic_dialog_info;

        Notification.Builder builder;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder = new Notification.Builder(this, FtrNotificationApplication.CHANNEL_ID);
        } else {
            builder = new Notification.Builder(this);
        }
        builder.setSmallIcon(smallIcon)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(new Notification.BigTextStyle().bigText(body))
                .setAutoCancel(true);
        if (pendingIntent != null) builder.setContentIntent(pendingIntent);

        manager.notify(IDS.incrementAndGet(), builder.build());
    }
}
