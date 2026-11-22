package com.manuito.tornpda;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.loader.FlutterLoader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.ExecutorService;

final class HcppLaunchPolicy {
    private static final String PREFS = "tornpda_hcpp";
    private static final String REQUESTED = "requested";
    private static final String UNCONFIRMED = "unconfirmed";
    private static final String TRIPPED_VERSION = "trippedVersion";
    private static final String TRIP_EVENT_BUILD = "tripEventBuild";
    private static final String FLAG = "--enable-hcpp-and-surface-control";

    private HcppLaunchPolicy() {}

    // Must run before anything reads FlutterInjector
    static void installLoader(@NonNull Context context) {
        SharedPreferences prefs = prefs(context);
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE || !prefs.getBoolean(REQUESTED, false)) {
            return;
        }
        long version;
        try {
            version = context.getPackageManager().getPackageInfo(context.getPackageName(), 0).getLongVersionCode();
        } catch (PackageManager.NameNotFoundException e) {
            version = 0;
        }
        if (prefs.contains(TRIPPED_VERSION) && prefs.getLong(TRIPPED_VERSION, 0) != version) {
            prefs.edit().putInt(UNCONFIRMED, 0).remove(TRIPPED_VERSION).commit();
        }
        // Last two HCPP launches never drew
        if (prefs.getInt(UNCONFIRMED, 0) >= 2) {
            SharedPreferences.Editor trip = prefs.edit().putBoolean(REQUESTED, false).putLong(TRIPPED_VERSION, version);
            if (!prefs.contains(TRIPPED_VERSION)) {
                trip.putLong(TRIP_EVENT_BUILD, version);
            }
            trip.apply();
            return;
        }
        FlutterInjector defaults = new FlutterInjector.Builder().build();
        try {
            FlutterInjector.setInstance(new FlutterInjector.Builder()
                    .setFlutterLoader(new HcppLoader(defaults.getFlutterJNIFactory().provideFlutterJNI(),
                            defaults.executorService()))
                    .setExecutorService(defaults.executorService())
                    .build());
        } catch (IllegalStateException e) {
            Log.w("HcppLaunchPolicy", "FlutterInjector already read, no HCPP", e);
        }
    }

    // True when this launch draws with HCPP
    static boolean countLaunch(@NonNull Context context) {
        if (!(FlutterInjector.instance().flutterLoader() instanceof HcppLoader)) {
            return false;
        }
        SharedPreferences prefs = prefs(context);
        prefs.edit().putInt(UNCONFIRMED, prefs.getInt(UNCONFIRMED, 0) + 1).commit();
        return true;
    }

    static void confirmLaunch(@NonNull Context context) {
        prefs(context).edit().putInt(UNCONFIRMED, 0).apply();
    }

    static void setRequested(@NonNull Context context, boolean requested, boolean rearm) {
        SharedPreferences.Editor editor = prefs(context).edit().putBoolean(REQUESTED, requested);
        if (rearm) {
            editor.putInt(UNCONFIRMED, 0).remove(TRIPPED_VERSION);
        }
        editor.apply();
    }

    static boolean isTripped(@NonNull Context context) {
        return prefs(context).contains(TRIPPED_VERSION);
    }

    @Nullable
    static Long takeTripEvent(@NonNull Context context) {
        SharedPreferences prefs = prefs(context);
        if (!prefs.contains(TRIP_EVENT_BUILD)) {
            return null;
        }
        long build = prefs.getLong(TRIP_EVENT_BUILD, 0);
        prefs.edit().remove(TRIP_EVENT_BUILD).apply();
        return build;
    }

    private static SharedPreferences prefs(@NonNull Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    private static final class HcppLoader extends FlutterLoader {
        HcppLoader(@NonNull FlutterJNI flutterJNI, @NonNull ExecutorService executor) {
            super(flutterJNI, executor);
        }

        @Override
        public void ensureInitializationComplete(@NonNull Context applicationContext, @Nullable String[] args) {
            List<String> flags = new ArrayList<>();
            if (args != null) {
                flags.addAll(Arrays.asList(args));
            }
            flags.add(FLAG);
            super.ensureInitializationComplete(applicationContext, flags.toArray(new String[0]));
        }
    }
}
