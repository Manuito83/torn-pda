package com.manuito.tornpda;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.view.View;
import android.widget.RemoteViews;
import androidx.annotation.NonNull;
import es.antonborri.home_widget.HomeWidgetBackgroundIntent;
import es.antonborri.home_widget.HomeWidgetProvider;

public class HomeWidgetRankedWar extends HomeWidgetProvider {

    @Override
    public void onUpdate(@NonNull Context context, @NonNull AppWidgetManager appWidgetManager, int[] appWidgetIds, @NonNull SharedPreferences widgetData) {
        SharedPreferences prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);
        for (int widgetId : appWidgetIds) {
            createRemoteViews(context, appWidgetManager, widgetId, prefs);
        }
    }

    private void createRemoteViews(Context context, AppWidgetManager appWidgetManager, int appWidgetId, SharedPreferences prefs) {
        boolean dark = prefs.getBoolean("darkMode", false);
        int layoutId = dark ? R.layout.ranked_war_layout_large_dark : R.layout.ranked_war_layout_large;

        RemoteViews view = new RemoteViews(context.getPackageName(), layoutId);
        loadRankedWarData(view, context, prefs);

        appWidgetManager.updateAppWidget(appWidgetId, view);
    }

    /**
     * Loads and displays data into the Ranked War RemoteViews
     */
    public void loadRankedWarData(RemoteViews view, Context context, SharedPreferences prefs) {
        setupHeader(view, context, prefs);
        setupClickListeners(view, context);

        String state = prefs.getString("rw_state", "none");

        view.setViewVisibility(R.id.rw_upcoming_layout, View.GONE);
        view.setViewVisibility(R.id.rw_active_layout, View.GONE);
        view.setViewVisibility(R.id.rw_no_war_layout, View.GONE);

        switch (state) {
            case "upcoming":
                setupUpcomingWarLayout(view, prefs);
                break;
            case "active":
                setupActiveWarLayout(view, prefs);
                break;
            default:
                boolean widgetVisible = prefs.getBoolean("rw_widget_visibility", false);
                if (!widgetVisible) {
                    setupNoWarLayout(view, "No war data available");
                } else {
                    setupNoWarLayout(view, "No active war");
                }
                break;
        }
    }

    /**
     * Sets up the header area with update time and reload button
     */
    private void setupHeader(RemoteViews view, Context context, SharedPreferences prefs) {
        String lastUpdated = prefs.getString("last_updated", "Updating...");
        if ("Updating...".equals(lastUpdated)) {
            view.setTextViewText(R.id.rw_last_updated, "");
        } else {
            view.setTextViewText(R.id.rw_last_updated, lastUpdated);
        }

        boolean reloadingNow = prefs.getBoolean("reloading", false);
        if (reloadingNow) {
            view.setViewVisibility(R.id.rw_icon_reload, View.GONE);
            view.setViewVisibility(R.id.rw_icon_reload_active, View.VISIBLE);
        } else {
            view.setViewVisibility(R.id.rw_icon_reload, View.VISIBLE);
            view.setViewVisibility(R.id.rw_icon_reload_active, View.GONE);
        }
    }

    /**
     * Sets up click listeners for the widget
     */
    private void setupClickListeners(RemoteViews view, Context context) {
        PendingIntent reloadIntent = getUniqueBroadcastPendingIntent(context, Uri.parse("pdaWidget://reload_clicked"), "Reloading...");
        view.setOnClickPendingIntent(R.id.rw_reload_box, reloadIntent);

        PendingIntent openAppIntent = getUniquePendingIntent(context, "OpenAppRankedWar", "pdaWidget://open:app", 30);
        view.setOnClickPendingIntent(R.id.rw_widget_container, openAppIntent);
    }

    /**
     * Sets up the layout for an upcoming war
     */
    private void setupUpcomingWarLayout(RemoteViews view, SharedPreferences prefs) {
        view.setViewVisibility(R.id.rw_upcoming_layout, View.VISIBLE);
        String countdown = prefs.getString("rw_countdown_string", "Loading...");
        String date = prefs.getString("rw_date_string", "");
        view.setTextViewText(R.id.rw_countdown_text, countdown);
        view.setTextViewText(R.id.rw_date_text, date);
    }

    /**
     * Sets up the layout for an active war
     */
    private void setupActiveWarLayout(RemoteViews view, SharedPreferences prefs) {
        view.setViewVisibility(R.id.rw_active_layout, View.VISIBLE);

        int playerScore = prefs.getInt("rw_player_score", 0);
        int enemyScore = prefs.getInt("rw_enemy_score", 0);
        int targetScore = prefs.getInt("rw_target_score", 1);
        String playerTag = prefs.getString("rw_player_faction_tag", "");
        String enemyName = prefs.getString("rw_enemy_faction_name", "");

        // Calculate progress for both the progress bar and the text
        int progress = Math.abs(playerScore - enemyScore);

        // Calculate the percentage value. Use double for division to get decimals.
        // Add a check to prevent division by zero.
        double percentageValue = (targetScore > 0) ? ((double) progress * 100.0) / targetScore : 0.0;

        // Format the percentage into a string like "5.4%"
        String percentageText = String.format("%.1f%%", percentageValue);

        // Format the progress text string for inside the bar ("134 / 2500")
        String progressText = String.format("%d / %d", progress, targetScore);

        view.setTextViewText(R.id.rw_player_faction_tag, playerTag);
        view.setTextViewText(R.id.rw_enemy_faction_name, enemyName);
        view.setTextViewText(R.id.rw_player_score, String.format("%,d", playerScore));
        view.setTextViewText(R.id.rw_enemy_score, String.format("%,d", enemyScore));
        view.setTextViewText(R.id.rw_progress_text, progressText);
        view.setTextViewText(R.id.rw_percentage_text, percentageText); // Now uses the calculated string

        int greenColor = Color.parseColor("#4CAF50");
        int redColor = Color.parseColor("#C60303");
        view.setTextColor(R.id.rw_player_score, playerScore >= enemyScore ? greenColor : redColor);
        view.setTextColor(R.id.rw_enemy_score, enemyScore > playerScore ? greenColor : redColor);

        view.setProgressBar(R.id.rw_progress_bar, targetScore, progress, false);
    }

    /**
     * Sets up the layout when there is no active war
     */
    private void setupNoWarLayout(RemoteViews view, String message) {
        view.setViewVisibility(R.id.rw_no_war_layout, View.VISIBLE);
        view.setTextViewText(R.id.rw_no_war_text, message);
    }

    /**
     * Generates a unique PendingIntent for broadcast actions
     */
    private PendingIntent getUniqueBroadcastPendingIntent(Context context, Uri uri, String extra) {
        return HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(context, uri, extra);
    }

    /**
     * Generates a unique PendingIntent for different actions
     */
    private PendingIntent getUniquePendingIntent(Context context, String action, String uri, int requestCode) {
        Intent intent = new Intent(context, MainActivity.class);
        intent.setAction(action);
        intent.setData(Uri.parse(uri));
        return PendingIntent.getActivity(context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT | getImmutableFlag());
    }

    /**
     * Retrieves the immutable flag for PendingIntent based on the SDK version
     */
    private int getImmutableFlag() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return PendingIntent.FLAG_IMMUTABLE;
        } else {
            return 0;
        }
    }
}