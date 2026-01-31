package com.manuito.tornpda;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.service.notification.StatusBarNotification;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import java.util.List;
import io.flutter.plugin.common.MethodChannel;
import com.manuito.tornpda.liveupdates.LiveUpdatePlugin;
import com.manuito.tornpda.liveupdates.LiveUpdateNotificationChannel;
import android.os.Bundle;
import android.window.SplashScreenView;
import androidx.core.view.WindowCompat;
import android.appwidget.AppWidgetManager;
import android.os.PowerManager;
import android.app.ActivityManager;
import android.os.Debug;
import java.util.Map;
import java.util.HashMap;
import android.app.ActivityManager.MemoryInfo;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "tornpda.channel";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // Aligns the Flutter view vertically with the window.
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Disable the Android splash screen fade out animation to avoid
            // a flicker before the similar frame is drawn in Flutter.
            getSplashScreen()
                    .setOnExitAnimationListener(
                            (SplashScreenView splashScreenView) -> {
                                splashScreenView.remove();
                            });
        }

        super.onCreate(savedInstanceState);
    }

    private MethodChannel.Result myResult;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        // Setups a method channel for the Flutter part
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "cancelNotifications":
                            cancelNotifications();
                            result.success(null);
                            break;

                        case "deleteNotificationChannels":
                            deleteNotificationChannels();
                            result.success(null);
                            break;

                        case "widgetCount":
                            AppWidgetManager awm = AppWidgetManager.getInstance(this);
                            ComponentName name = new ComponentName(this, HomeWidgetTornPda.class);
                            int[] ids = awm.getAppWidgetIds(name);
                            result.success(ids);
                            break;

                        case "checkBatteryOptimization":
                            boolean isRestricted = isBatteryOptimizationRestricted();
                            result.success(isRestricted);
                            break;

                        case "openBatterySettings":
                            openBatterySettings();
                            result.success(null);
                            break;

                        case "getMemoryInfoDetailed":
                            // Gather per-process memory info broken down by type
                            Debug.MemoryInfo mi = new Debug.MemoryInfo();
                            Debug.getMemoryInfo(mi);

                            Map<String, Long> memMap = new HashMap<>();
                            memMap.put("dalvikPss", mi.dalvikPss * 1024L);
                            memMap.put("nativePss", mi.nativePss * 1024L);
                            memMap.put("otherPss", mi.otherPss * 1024L);
                            memMap.put("totalPss", mi.getTotalPss() * 1024L);

                            result.success(memMap);
                            break;

                        case "getDeviceMemoryInfo":
                            try {
                                ActivityManager am = (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
                                if (am == null) {
                                    throw new IllegalStateException("ActivityManager is null");
                                }

                                android.app.ActivityManager.MemoryInfo sysMem = new android.app.ActivityManager.MemoryInfo();
                                am.getMemoryInfo(sysMem);

                                Map<String, Long> devMap = new HashMap<>();
                                devMap.put("totalMem", sysMem.totalMem);
                                devMap.put("availMem", sysMem.availMem);

                                result.success(devMap);

                            } catch (Exception e) {
                                result.error(
                                        "UNAVAILABLE",
                                        "Failed to get device memory info: " + e.getMessage(),
                                        null
                                );
                            }
                            break;

                        default:
                            result.notImplemented();
                    }
                });

        LiveUpdatePlugin.register(flutterEngine, this);
    }

    // This cancels Firebase notifications upon request from the Flutter app, as the
    // local plugins also cancel their scheduled ones when cancelAll() is called.
    // Note: It is also possible to use "cancel("TAG", 0)" but giving a TAG in FCM
    // Android options overwrites the notifications with the same tag.
    // There is an alternative which is preparing multiple tags.
    private void cancelNotifications() {
        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            StatusBarNotification[] activeNotifications = notificationManager.getActiveNotifications();
            for (StatusBarNotification notification : activeNotifications) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    String channelId = notification.getNotification().getChannelId();
                    if (LiveUpdateNotificationChannel.CHANNEL_ID.equals(channelId)) {
                        continue;
                    }
                }
                notificationManager.cancel(notification.getTag(), notification.getId());
            }
        } else {
            notificationManager.cancelAll();
        }
    }

    // Deletes all notification channels
    private void deleteNotificationChannels() {
        // Oreo or above, otherwise it will fail (can't be cached in Flutter)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager notificationManager = (NotificationManager) getSystemService(
                    Context.NOTIFICATION_SERVICE);
            List<NotificationChannel> channels = notificationManager.getNotificationChannels();
            for (NotificationChannel channel : channels) {
                notificationManager.deleteNotificationChannel(channel.getId());
            }
        }
    }

    // Checks if the battery optimization is restricted
    private boolean isBatteryOptimizationRestricted() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PowerManager powerManager = (PowerManager) getSystemService(POWER_SERVICE);
            String packageName = getPackageName();
            return !powerManager.isIgnoringBatteryOptimizations(packageName);
        }
        return false; // Not restricted for versions below Marshmallow
    }

    // Opens the battery optimization settings screen
    private void openBatterySettings() {
        Intent intent = new Intent(android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS);
        startActivity(intent);
    }
}
