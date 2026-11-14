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
import android.net.Uri;
import android.os.Build;
import java.util.List;
import io.flutter.plugin.common.MethodChannel;
import com.manuito.tornpda.liveupdates.LiveUpdatePlugin;
import com.manuito.tornpda.liveupdates.LiveUpdateNotificationChannel;
import android.os.Bundle;
import android.window.SplashScreenView;
import androidx.core.view.WindowCompat;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsAnimationCompat;
import androidx.core.view.WindowInsetsCompat;
import android.appwidget.AppWidgetManager;
import android.os.PowerManager;
import android.app.ActivityManager;
import android.os.Debug;
import java.util.Map;
import java.util.HashMap;
import android.app.ActivityManager.MemoryInfo;
import android.app.ApplicationExitInfo;
import android.content.SharedPreferences;
import java.util.ArrayList;
import android.app.PendingIntent;
import android.app.PictureInPictureParams;
import android.app.RemoteAction;
import android.content.BroadcastReceiver;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.graphics.drawable.Icon;
import android.util.Rational;
import androidx.core.content.ContextCompat;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Rect;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.view.PixelCopy;
import android.view.View;
import java.util.Arrays;
import io.flutter.plugin.common.MethodCall;
import android.content.ContentResolver;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "tornpda.channel";
    private static final String PIP_CHANNEL = "tornpda.pip";
    private static final String PIP_ACTION = "com.manuito.tornpda.PIP_ACTION";
    private static final String SHARE_CHANNEL = "tornpda.share";
    private static final long SHARE_IMAGE_MAX = 32L * 1024 * 1024;

    private MethodChannel pipChannel;
    private BroadcastReceiver pipReceiver;
    private boolean pipAutoEnter;
    private boolean pipAutoPending;
    private boolean pipOwnLaunch;
    private List<Map<String, String>> pipAutoActions;
    private HandlerThread pixelProbeThread;
    private MethodChannel shareChannel;
    private Map<String, String> pendingShare;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // Aligns the Flutter view vertically with the window.
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);

        ViewCompat.setWindowInsetsAnimationCallback(
                getWindow().getDecorView(),
                new WindowInsetsAnimationCompat.Callback(WindowInsetsAnimationCompat.Callback.DISPATCH_MODE_STOP) {
                    @NonNull
                    @Override
                    public WindowInsetsCompat onProgress(
                            @NonNull WindowInsetsCompat insets,
                            @NonNull List<WindowInsetsAnimationCompat> runningAnimations) {
                        return insets;
                    }
                });

        // Skipped on Android 13: registering the listener makes the system transfer the
        // splash view, which crashes in ActivityThread.syncTransferSplashscreenViewTransaction
        // on OPPO/realme/OnePlus ROMs (SurfaceControl already released)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
                && Build.VERSION.SDK_INT != Build.VERSION_CODES.TIRAMISU) {
            // Disable the Android splash screen fade out animation to avoid
            // a flicker before the similar frame is drawn in Flutter.
            getSplashScreen()
                    .setOnExitAnimationListener(
                            (SplashScreenView splashScreenView) -> {
                                splashScreenView.remove();
                            });
        }

        // Skip restores and launches from recents
        if (savedInstanceState == null
                && (getIntent().getFlags() & Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) == 0) {
            pendingShare = readShare(getIntent());
        }

        super.onCreate(savedInstanceState);
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        Map<String, String> share = readShare(intent);
        if (share == null) return;
        if (shareChannel == null) {
            pendingShare = share;
            return;
        }
        // Dart may not be listening yet
        shareChannel.invokeMethod("shared", share, new MethodChannel.Result() {
            @Override
            public void success(Object result) {}

            @Override
            public void error(@NonNull String code, String message, Object details) {
                pendingShare = share;
            }

            @Override
            public void notImplemented() {
                pendingShare = share;
            }
        });
    }

    // Only images from other apps
    private void copySharedImage(String raw) throws IOException {
        Uri uri = raw == null ? null : Uri.parse(raw);
        String authority = uri == null ? null : uri.getAuthority();
        if (uri == null || !"content".equals(uri.getScheme()) || authority == null
                || authority.startsWith(getPackageName())) {
            throw new IOException("rejected");
        }
        ContentResolver resolver = getContentResolver();
        String type = resolver.getType(uri);
        if (type == null || !type.startsWith("image/")) throw new IOException("rejected");
        File dir = new File(getCacheDir(), "chat_share");
        if (!dir.isDirectory() && !dir.mkdirs()) throw new IOException("unreadable");
        File out = new File(dir, "shared");
        long total = 0;
        boolean tooBig = false;
        try (InputStream in = resolver.openInputStream(uri); OutputStream os = new FileOutputStream(out)) {
            if (in == null) throw new IOException();
            byte[] buffer = new byte[64 * 1024];
            int read;
            while ((read = in.read(buffer)) != -1) {
                total += read;
                if (total > SHARE_IMAGE_MAX) {
                    tooBig = true;
                    break;
                }
                os.write(buffer, 0, read);
            }
        } catch (IOException | RuntimeException e) {
            out.delete();
            throw new IOException("unreadable");
        }
        if (tooBig) {
            out.delete();
            throw new IOException("too_big");
        }
    }

    @SuppressWarnings("deprecation")
    private static Map<String, String> readShare(Intent intent) {
        if (intent == null || !Intent.ACTION_SEND.equals(intent.getAction()) || intent.getType() == null) {
            return null;
        }
        Map<String, String> share = new HashMap<>();
        share.put("type", intent.getType());
        CharSequence text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT);
        if (text != null) share.put("text", text.toString());
        if (intent.getType().startsWith("image/")) {
            Uri stream = intent.getParcelableExtra(Intent.EXTRA_STREAM);
            if (stream != null) share.put("image", stream.toString());
        }
        return share.size() > 1 ? share : null;
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

                        case "probeWebViewPixels":
                            probeWebViewPixels(call, result);
                            break;

                        case "getProcessExitReasons":
                            try {
                                result.success(getProcessExitReasons());
                            } catch (Exception e) {
                                result.error("UNAVAILABLE", "Failed to get exit reasons: " + e.getMessage(), null);
                            }
                            break;

                        default:
                            result.notImplemented();
                    }
                });

        pipChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), PIP_CHANNEL);
        pipChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "isSupported":
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                            && getPackageManager().hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE));
                    break;

                case "enter":
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                        result.success(false);
                        break;
                    }
                    try {
                        PictureInPictureParams params = buildPipParams(call.argument("actions"), false);
                        boolean entered;
                        if (isInPictureInPictureMode()) {
                            setPictureInPictureParams(params);
                            entered = true;
                        } else {
                            entered = enterPictureInPictureMode(params);
                        }
                        result.success(entered);
                    } catch (Exception e) {
                        result.error("PIP", e.getMessage(), null);
                    }
                    break;

                case "autoEnter":
                    pipAutoEnter = Boolean.TRUE.equals(call.argument("enabled"));
                    pipAutoActions = call.argument("actions");
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !isInPictureInPictureMode()) {
                        setPictureInPictureParams(buildPipParams(pipAutoActions, pipAutoEnter));
                    }
                    result.success(null);
                    break;

                case "expand":
                    startActivity(new Intent(this, MainActivity.class));
                    result.success(null);
                    break;

                default:
                    result.notImplemented();
            }
        });

        shareChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SHARE_CHANNEL);
        shareChannel.setMethodCallHandler((call, result) -> {
            if ("take".equals(call.method)) {
                result.success(pendingShare);
                pendingShare = null;
            } else if ("readImage".equals(call.method)) {
                String raw = call.argument("uri");
                new Thread(() -> {
                    try {
                        copySharedImage(raw);
                        runOnUiThread(() -> result.success(null));
                    } catch (Exception e) {
                        String code = e instanceof IOException && e.getMessage() != null
                                ? e.getMessage()
                                : "unreadable";
                        runOnUiThread(() -> result.error(code, null, null));
                    }
                }).start();
            } else {
                result.notImplemented();
            }
        });

        LiveUpdatePlugin.register(flutterEngine, this);
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    private PictureInPictureParams buildPipParams(List<Map<String, String>> actions, boolean autoEnter) {
        List<RemoteAction> remoteActions = new ArrayList<>();
        if (actions != null) {
            for (Map<String, String> action : actions) {
                String id = action.get("id");
                int requestCode;
                int icon;
                if ("profile".equals(id)) {
                    requestCode = 2;
                    icon = R.drawable.ic_pip_profile;
                } else if ("panic".equals(id)) {
                    requestCode = 3;
                    icon = R.drawable.ic_pip_panic;
                } else {
                    requestCode = 1;
                    icon = R.drawable.ic_pip_open;
                }
                Intent intent = new Intent(PIP_ACTION).setPackage(getPackageName()).putExtra("id", id);
                PendingIntent pending = PendingIntent.getBroadcast(this, requestCode, intent,
                        PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
                String title = action.get("title");
                remoteActions.add(new RemoteAction(Icon.createWithResource(this, icon), title, title, pending));
            }
        }
        PictureInPictureParams.Builder builder = new PictureInPictureParams.Builder()
                .setAspectRatio(new Rational(4, 3))
                .setActions(remoteActions);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setSeamlessResizeEnabled(false);
            builder.setAutoEnterEnabled(autoEnter);
        }
        return builder.build();
    }

    @Override
    public void startActivityForResult(Intent intent, int requestCode, Bundle options) {
        pipOwnLaunch = true;
        super.startActivityForResult(intent, requestCode, options);
    }

    // Android 12+ enters by itself
    @Override
    public void onUserLeaveHint() {
        super.onUserLeaveHint();
        if (!pipAutoEnter || pipOwnLaunch || Build.VERSION.SDK_INT < Build.VERSION_CODES.O
                || Build.VERSION.SDK_INT >= Build.VERSION_CODES.S || isInPictureInPictureMode() || pipChannel == null) {
            return;
        }
        pipAutoPending = true;
        pipChannel.invokeMethod("autoEntering", null);
        try {
            enterPictureInPictureMode(buildPipParams(pipAutoActions, false));
        } catch (Exception e) {
            pipAutoPending = false;
            pipChannel.invokeMethod("changed", false);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        pipOwnLaunch = false;
        if (pipAutoPending && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !isInPictureInPictureMode()
                && pipChannel != null) {
            pipChannel.invokeMethod("changed", false);
        }
        pipAutoPending = false;
    }

    private void unregisterPipReceiver() {
        if (pipReceiver == null) return;
        unregisterReceiver(pipReceiver);
        pipReceiver = null;
    }

    @Override
    public void onPictureInPictureModeChanged(boolean isInPictureInPictureMode, Configuration newConfig) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig);
        pipAutoPending = false;
        if (!isInPictureInPictureMode) {
            unregisterPipReceiver();
        } else if (pipReceiver == null) {
            pipReceiver = new BroadcastReceiver() {
                @Override
                public void onReceive(Context context, Intent received) {
                    if (pipChannel != null) {
                        pipChannel.invokeMethod("action", received.getStringExtra("id"));
                    }
                }
            };
            ContextCompat.registerReceiver(this, pipReceiver, new IntentFilter(PIP_ACTION),
                    ContextCompat.RECEIVER_NOT_EXPORTED);
        }
        if (pipChannel != null) {
            pipChannel.invokeMethod("changed", isInPictureInPictureMode);
        }
    }

    @Override
    protected void onDestroy() {
        unregisterPipReceiver();
        if (pixelProbeThread != null) {
            pixelProbeThread.quitSafely();
            pixelProbeThread = null;
        }
        super.onDestroy();
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
                    if (LiveUpdateNotificationChannel.TRAVEL_CHANNEL_ID.equals(channelId)
                            || LiveUpdateNotificationChannel.RACING_CHANNEL_ID.equals(channelId)) {
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

    // Main process exits not reported yet
    private List<Map<String, Object>> getProcessExitReasons() throws Exception {
        List<Map<String, Object>> exits = new ArrayList<>();
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            return exits;
        }

        ActivityManager am = (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
        if (am == null) {
            return exits;
        }

        String packageName = getPackageName();
        SharedPreferences prefs = getSharedPreferences("tornpda_exit_info", MODE_PRIVATE);
        long lastReported = prefs.getLong("lastReportedExitTimestamp", 0);
        long installed = getPackageManager().getPackageInfo(packageName, 0).lastUpdateTime;
        long threshold = Math.max(lastReported, installed);
        long newest = lastReported;

        List<ApplicationExitInfo> infos = am.getHistoricalProcessExitReasons(packageName, 0, 5);
        for (ApplicationExitInfo info : infos) {
            if (!packageName.equals(info.getProcessName()) || info.getTimestamp() <= threshold) {
                continue;
            }
            Map<String, Object> exit = new HashMap<>();
            exit.put("reason", info.getReason());
            exit.put("status", info.getStatus());
            exit.put("importance", info.getImportance());
            exit.put("timestamp", info.getTimestamp());
            exit.put("description", info.getDescription());
            exits.add(exit);
            newest = Math.max(newest, info.getTimestamp());
        }

        if (newest > lastReported) {
            prefs.edit().putLong("lastReportedExitTimestamp", newest).apply();
        }
        return exits;
    }

    // On-screen pixels at 1/8 scale
    private void probeWebViewPixels(MethodCall call, MethodChannel.Result result) {
        Integer left = call.argument("left");
        Integer top = call.argument("top");
        Integer width = call.argument("width");
        Integer height = call.argument("height");
        List<Double> points = call.argument("points");
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || left == null || top == null || width == null
                || height == null || points == null) {
            result.success(null);
            return;
        }

        int[] origin = new int[2];
        View flutterView = findViewById(FLUTTER_VIEW_ID);
        if (flutterView != null) flutterView.getLocationInWindow(origin);
        View decor = getWindow().getDecorView();
        Rect source = new Rect(left + origin[0], top + origin[1], left + origin[0] + width, top + origin[1] + height);
        if (!source.intersect(0, 0, decor.getWidth(), decor.getHeight())) {
            result.success(null);
            return;
        }

        int bitmapWidth = Math.max(1, source.width() / 8);
        int bitmapHeight = Math.max(1, source.height() / 8);
        Bitmap bitmap = Bitmap.createBitmap(bitmapWidth, bitmapHeight, Bitmap.Config.ARGB_8888);
        if (pixelProbeThread == null) {
            pixelProbeThread = new HandlerThread("tornpda-pixel-probe");
            pixelProbeThread.start();
        }
        Handler mainHandler = new Handler(Looper.getMainLooper());

        try {
            PixelCopy.request(getWindow(), source, bitmap, copyResult -> {
                Map<String, Object> out = new HashMap<>();
                out.put("copyResult", copyResult);
                if (copyResult == PixelCopy.SUCCESS) {
                    List<List<Integer>> pixels = new ArrayList<>();
                    for (int i = 0; i + 1 < points.size(); i += 2) {
                        int x = Math.min(bitmapWidth - 1, Math.max(0, (int) (points.get(i) * bitmapWidth)));
                        int y = Math.min(bitmapHeight - 1, Math.max(0, (int) (points.get(i + 1) * bitmapHeight)));
                        int color = bitmap.getPixel(x, y);
                        pixels.add(Arrays.asList(Color.red(color), Color.green(color), Color.blue(color)));
                    }
                    out.put("pixels", pixels);
                }
                bitmap.recycle();

                long graphicsMb = -1;
                try {
                    Debug.MemoryInfo memoryInfo = new Debug.MemoryInfo();
                    Debug.getMemoryInfo(memoryInfo);
                    String graphics = memoryInfo.getMemoryStat("summary.graphics");
                    // Reported in KB
                    if (graphics != null) graphicsMb = Long.parseLong(graphics) / 1024;
                } catch (Exception ignored) {
                }
                out.put("graphicsMb", graphicsMb);

                mainHandler.post(() -> result.success(out));
            }, new Handler(pixelProbeThread.getLooper()));
        } catch (IllegalArgumentException e) {
            bitmap.recycle();
            result.success(null);
        }
    }

    // Opens the battery optimization settings screen
    private void openBatterySettings() {
        Intent intent = new Intent(android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS);
        startActivity(intent);
    }
}
