package com.manuito.tornpda;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;
import android.app.NotificationManager;
import android.content.Context;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "tornpda.channel";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        // Setups a method channel for the Flutter part
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL).
            setMethodCallHandler((call, result) -> {
                if(call.method.equals("cancelNotifications")){
                    cancelNotifications();
                }
            }
        );
    }

    // This cancel Firebase notifications upon request from the Flutter app, as they need a TAG, which
    // in this case is "pdaFirebase". Id equals 0 por FCM notifications.
    private void cancelNotifications() {
        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        notificationManager.cancel("pdaFirebase", 0);
    }
}
