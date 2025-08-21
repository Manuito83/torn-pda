package com.manuito.tornpda;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.text.Html;
import android.view.View;
import android.widget.RemoteViews;
import androidx.annotation.NonNull;
import es.antonborri.home_widget.HomeWidgetBackgroundIntent;
import es.antonborri.home_widget.HomeWidgetProvider;

public class HomeWidgetRankedWar extends HomeWidgetProvider {

    @Override
    public void onUpdate(@NonNull Context context, @NonNull AppWidgetManager appWidgetManager, int[] appWidgetIds, @NonNull SharedPreferences widgetData) {
        for (int widgetId : appWidgetIds) {
            try {
                boolean isDarkMode = widgetData.getBoolean("darkMode", false);
                int layoutId = isDarkMode ? R.layout.ranked_war_layout_large_dark : R.layout.ranked_war_layout_large;
                RemoteViews view = new RemoteViews(context.getPackageName(), layoutId);
                loadRankedWarData(view, context, widgetData, isDarkMode);
                appWidgetManager.updateAppWidget(widgetId, view);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private void loadRankedWarData(RemoteViews view, Context context, SharedPreferences prefs, boolean isDarkMode) {
        setupHeader(view, context, prefs, isDarkMode);
        setupClickListeners(view, context);
        boolean widgetVisible = prefs.getBoolean("rw_widget_visibility", false);
        view.setViewVisibility(R.id.rw_upcoming_layout, View.GONE);
        view.setViewVisibility(R.id.rw_active_layout, View.GONE);
        view.setViewVisibility(R.id.rw_finished_layout, View.GONE);
        view.setViewVisibility(R.id.rw_no_war_layout, View.GONE);
        if (!widgetVisible) {
            setupNoWarLayout(view, "No ranked war data");
            return;
        }
        String state = prefs.getString("rw_state", "none");
        switch (state) {
            case "upcoming":
                setupUpcomingWarLayout(view, prefs);
                break;
            case "active":
                setupActiveWarLayout(view, prefs);
                break;
            case "finished":
                setupFinishedWarLayout(view, prefs);
                break;
            default:
                setupNoWarLayout(view, "No ranked war data");
                break;
        }
    }

    // setupHeader y setupClickListeners sin cambios
    private void setupHeader(RemoteViews view, Context context, SharedPreferences prefs, boolean isDarkMode) {
        String lastUpdated = prefs.getString("last_updated", "Updating...");
        view.setTextViewText(R.id.rw_last_updated, "Updating...".equals(lastUpdated) ? "" : lastUpdated);
        boolean reloadingNow = prefs.getBoolean("reloading", false);
        view.setViewVisibility(R.id.rw_icon_reload_active, reloadingNow ? View.VISIBLE : View.GONE);
        view.setViewVisibility(R.id.rw_icon_reload, reloadingNow ? View.GONE : View.VISIBLE);
        int reloadIconColor = isDarkMode ? Color.parseColor("#9E9E9E") : Color.parseColor("#888888");
        view.setInt(R.id.rw_icon_reload, "setColorFilter", reloadIconColor);
        int playerChain = prefs.getInt("rw_player_chain", 0);
        view.setViewVisibility(R.id.rw_chaining_indicator, playerChain >= 10 ? View.VISIBLE : View.GONE);
    }

    private void setupClickListeners(RemoteViews view, Context context) {
        PendingIntent reloadIntent = HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(context, Uri.parse("pdaWidget://reload_clicked"));
        view.setOnClickPendingIntent(R.id.rw_reload_box, reloadIntent);
        Intent openAppIntent = new Intent(context, MainActivity.class);
        openAppIntent.setData(Uri.parse("pdaWidget://open:app"));
        PendingIntent pendingIntent = PendingIntent.getActivity(context, 0, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT | getImmutableFlag());
        view.setOnClickPendingIntent(R.id.rw_widget_container, pendingIntent);
    }

    private void setupUpcomingWarLayout(RemoteViews view, SharedPreferences prefs) {
        view.setViewVisibility(R.id.rw_upcoming_layout, View.VISIBLE);
        String countdown = prefs.getString("rw_countdown_string", "Loading...");
        String date = prefs.getString("rw_date_string", "");
        String playerTag = decodeHtml(prefs.getString("rw_player_faction_tag", ""));
        String enemyName = decodeHtml(prefs.getString("rw_enemy_faction_name", ""));
        boolean upcomingSoon = prefs.getBoolean("rw_upcoming_soon", false);

        view.setInt(R.id.rw_upcoming_icon, "setColorFilter", Color.parseColor("#FFA500"));
        view.setTextViewText(R.id.rw_upcoming_countdown, countdown);
        view.setTextViewText(R.id.rw_upcoming_date, date);
        view.setTextViewText(R.id.rw_upcoming_player_tag, playerTag);
        view.setTextViewText(R.id.rw_upcoming_enemy_name, enemyName);

        if (upcomingSoon) {
            view.setTextColor(R.id.rw_upcoming_countdown, Color.parseColor("#FFA500"));
            view.setInt(R.id.rw_upcoming_layout, "setBackgroundColor", Color.parseColor("#FFA500"));
        } else {
            view.setInt(R.id.rw_upcoming_layout, "setBackgroundColor", Color.TRANSPARENT);
        }
    }

    private void setupActiveWarLayout(RemoteViews view, SharedPreferences prefs) {
        view.setViewVisibility(R.id.rw_active_layout, View.VISIBLE);
        int playerScore = prefs.getInt("rw_player_score", 0);
        int enemyScore = prefs.getInt("rw_enemy_score", 0);
        int targetScore = prefs.getInt("rw_target_score", 1);
        String playerTag = decodeHtml(prefs.getString("rw_player_faction_tag", ""));
        String enemyName = decodeHtml(prefs.getString("rw_enemy_faction_name", ""));
        int progress = Math.abs(playerScore - enemyScore);
        double percentageValue = (targetScore > 0) ? ((double) progress * 100.0) / targetScore : 0.0;
        String percentageText = String.format("%.1f%%", percentageValue);
        view.setTextViewText(R.id.rw_active_player_tag, playerTag);
        view.setTextViewText(R.id.rw_active_enemy_name, enemyName);
        view.setTextViewText(R.id.rw_active_player_score, String.format("%,d", playerScore));
        view.setTextViewText(R.id.rw_active_enemy_score, String.format("%,d", enemyScore));
        view.setTextViewText(R.id.rw_active_progress_text, String.format("%d / %d", progress, targetScore));
        view.setTextViewText(R.id.rw_active_percentage, percentageText);
        int greenColor = Color.parseColor("#4CAF50");
        int redColor = Color.parseColor("#F44336");
        view.setTextColor(R.id.rw_active_player_score, playerScore >= enemyScore ? greenColor : redColor);
        view.setTextColor(R.id.rw_active_enemy_score, enemyScore > playerScore ? greenColor : redColor);
        view.setProgressBar(R.id.rw_active_progress_bar, targetScore, progress, false);
    }

    private void setupFinishedWarLayout(RemoteViews view, SharedPreferences prefs) {
        view.setViewVisibility(R.id.rw_finished_layout, View.VISIBLE);
        String winner = decodeHtml(prefs.getString("rw_winner", ""));
        int playerScore = prefs.getInt("rw_player_score", 0);
        int enemyScore = prefs.getInt("rw_enemy_score", 0);
        String playerTag = decodeHtml(prefs.getString("rw_player_faction_tag", ""));
        String enemyName = decodeHtml(prefs.getString("rw_enemy_faction_name", ""));
        String endDate = prefs.getString("rw_end_date_string", "");
        boolean playerWon = playerScore >= enemyScore;
        int resultColor = playerWon ? Color.parseColor("#4CAF50") : Color.parseColor("#F44336");

        view.setInt(R.id.rw_finished_layout, "setBackgroundColor", resultColor);
        
        view.setTextViewText(R.id.rw_finished_winner_name, winner);
        view.setTextColor(R.id.rw_finished_winner_name, resultColor);
        view.setImageViewResource(R.id.rw_finished_icon, R.drawable.trophy);
        view.setInt(R.id.rw_finished_icon, "setColorFilter", resultColor);
        view.setTextViewText(R.id.rw_finished_end_date, "Ended " + endDate);
        view.setTextViewText(R.id.rw_finished_player_tag, playerTag);
        view.setTextViewText(R.id.rw_finished_enemy_name, enemyName);
        view.setTextViewText(R.id.rw_finished_player_score, String.format("%,d", playerScore));
        view.setTextViewText(R.id.rw_finished_enemy_score, String.format("%,d", enemyScore));
        view.setTextColor(R.id.rw_finished_player_score, playerWon ? resultColor : Color.parseColor("#F44336"));
        view.setTextColor(R.id.rw_finished_enemy_score, !playerWon ? resultColor : Color.parseColor("#F44336"));
    }

    private void setupNoWarLayout(RemoteViews view, String message) {
        view.setViewVisibility(R.id.rw_no_war_layout, View.VISIBLE);
        view.setTextViewText(R.id.rw_no_war_text, message);
    }

    private int getImmutableFlag() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return PendingIntent.FLAG_IMMUTABLE;
        } else {
            return 0;
        }
    }

    private String decodeHtml(String source) {
        if (source == null || source.isEmpty()) return "";
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            return Html.fromHtml(source, Html.FROM_HTML_MODE_LEGACY).toString();
        } else {
            return Html.fromHtml(source).toString();
        }
    }
}