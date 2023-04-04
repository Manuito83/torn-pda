package com.manuito.tornpda;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.net.Uri;
import android.opengl.Visibility;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.util.SizeF;
import android.view.View;
import android.widget.RemoteViews;

import androidx.annotation.DrawableRes;
import androidx.annotation.NonNull;
import androidx.collection.ArrayMap;

import java.util.List;
import java.util.Map;

import es.antonborri.home_widget.HomeWidgetBackgroundIntent;
import es.antonborri.home_widget.HomeWidgetLaunchIntent;
import es.antonborri.home_widget.HomeWidgetProvider;

public class HomeWidgetTornPda extends HomeWidgetProvider {
    // Fires when widget is resized
    @Override
    public void onAppWidgetOptionsChanged(
            Context context, AppWidgetManager appWidgetManager, int appWidgetId, Bundle newOptions) {

        createRemoteViews(context, appWidgetManager, appWidgetId);
    }

    // Fires when widget is updated
    @Override
    public void onUpdate(@NonNull Context context, @NonNull AppWidgetManager appWidgetManager, int[] appWidgetIds,
                         @NonNull SharedPreferences widgetData) {

        for (int widgetId : appWidgetIds) {
            createRemoteViews(context, appWidgetManager, widgetId);
        }
    }

    private void setClickListeners(View view, List<View.OnClickListener> clickListeners){
        view.setOnClickListener(v -> {
            for(View.OnClickListener listener: clickListeners){
                listener.onClick(v);
            }
        });
    }

    // Creates the RemoteViews for the given size
    private void createRemoteViews(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        RemoteViews smallView = new RemoteViews(context.getPackageName(), R.layout.bars_layout_narrow);
        RemoteViews mediumView = new RemoteViews(context.getPackageName(), R.layout.bars_layout);
        RemoteViews largeView = new RemoteViews(context.getPackageName(), R.layout.bars_layout);

        smallView = loadWidgetData(smallView, context);
        mediumView = loadWidgetData(mediumView, context);
        largeView = loadWidgetData(largeView, context);

        Map<SizeF, RemoteViews> viewMapping = new ArrayMap<>();
        viewMapping.put(new SizeF(120f, 110f), smallView);
        viewMapping.put(new SizeF(270f, 110f), mediumView);
        viewMapping.put(new SizeF(270f, 280f), largeView);

        RemoteViews remoteViews;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            remoteViews = new RemoteViews(viewMapping);
        } else {
            // Old SDK do not get customization
            remoteViews = new RemoteViews(context.getPackageName(), R.layout.bars_layout);
            remoteViews = loadWidgetData(remoteViews, context);
        }

        appWidgetManager.updateAppWidget(appWidgetId, remoteViews);
    }

    // Assigns data fields
    public RemoteViews loadWidgetData(RemoteViews view, Context context) {
        SharedPreferences prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);
        boolean updatesActive = prefs.getBoolean("background_active", false);

        // ## Open App on Widget Click ##
        PendingIntent openAppIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class,null);
        view.setOnClickPendingIntent(R.id.widget_title, openAppIntent);
        view.setOnClickPendingIntent(R.id.widget_status_green, openAppIntent);
        view.setOnClickPendingIntent(R.id.widget_status_red, openAppIntent);
        view.setOnClickPendingIntent(R.id.widget_status_blue, openAppIntent);
        view.setOnClickPendingIntent(R.id.widget_message, openAppIntent);
        view.setOnClickPendingIntent(R.id.widget_container, openAppIntent);
        view.setOnClickPendingIntent(R.id.widget_error_message, openAppIntent);
        view.setOnClickPendingIntent(R.id.widget_pda_logo_main, openAppIntent);
        view.setOnClickPendingIntent(R.id.widget_pda_logo_error, openAppIntent);

        // ## Intents that need to be capture by the app (in Drawer)
        PendingIntent energyBoxIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://energy-box-clicked"));
        view.setOnClickPendingIntent(R.id.widget_energy_box, energyBoxIntent);

        PendingIntent nerveBoxIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://nerve-box-clicked"));
        view.setOnClickPendingIntent(R.id.widget_nerve_box, nerveBoxIntent);

        PendingIntent happyBoxIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://happy-box-clicked"));
        view.setOnClickPendingIntent(R.id.widget_happy_box, happyBoxIntent);

        PendingIntent lifeBoxIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://life-box-clicked"));
        view.setOnClickPendingIntent(R.id.widget_life_box, lifeBoxIntent);

        PendingIntent blueStatusIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://blue-status-clicked"));
        view.setOnClickPendingIntent(R.id.widget_status_blue, blueStatusIntent);

        // ## MAIN LAYOUT ##
        // Main layout visibility
        boolean main_visibility = prefs.getBoolean("main_layout_visibility", false);
        int mainVis;
        if (!main_visibility || !updatesActive) {
            mainVis = View.GONE;
        } else {
            mainVis = View.VISIBLE;
        }
        view.setViewVisibility(R.id.widget_main_layout, mainVis);

        // Assign Title by calling Dart Code in the Background
        view.setTextViewText(R.id.widget_title, prefs.getString("title", "Player"));

        // Assign click callback from Title
        /*
        PendingIntent backgroundIntent = HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(context, Uri.parse("pdaWidget://title-clicked"));
        view.setOnClickPendingIntent(R.id.widget_title, backgroundIntent);
        */

        // ## STATUS
        String status = prefs.getString("status", "Status");
        String statusColor = prefs.getString("status_color", "green");
        String country = prefs.getString("country", "Torn");
        if (!country.equals("Torn")) {
            if (!statusColor.equals("red")) {
                // If we are flying to/from or visiting a country (not in hospital)
                if (status.contains("Visiting")) {
                    if (country.contains("Japan")) {
                        view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.flag_japan);
                    } else if (country.contains("Hawaii")) {
                        view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.flag_hawaii);
                    } else if (country.contains("China")) {
                        view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.flag_china);
                    } else if (country.contains("Argentina")) {
                        view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.flag_argentina);
                    } else if (country.contains("United Kingdom")) {
                        view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.flag_uk);
                    } else if (country.contains("Cayman")) {
                        view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.flag_cayman);
                    } else if (country.contains("South Africa")) {
                        view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.flag_south_africa);
                    } else if (country.contains("Switzerland")) {
                        view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.flag_switzerland);
                    } else if (country.contains("Mexico")) {
                        view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.flag_mexico);
                    } else if (country.contains("UAE")) {
                        view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.flag_uae);
                    } else if (country.contains("Canada")) {
                        view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.flag_canada);
                    }
                } else if (status.contains("Torn in")) {
                    view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.plane_right);
                } else {
                    view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.plane_left);
                }
                view.setViewVisibility(R.id.widget_status_green, View.GONE);
                view.setViewVisibility(R.id.widget_status_red, View.GONE);
                view.setViewVisibility(R.id.widget_status_blue, View.VISIBLE);
                view.setTextViewText(R.id.widget_status_blue, status);

                PendingIntent blueStatusIconIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://blue-status-icon-clicked"));
                view.setOnClickPendingIntent(R.id.widget_status_icon_main, blueStatusIconIntent);
                view.setViewVisibility(R.id.widget_status_icon_main, View.VISIBLE);
                view.setViewVisibility(R.id.widget_status_extra_icon_main, View.GONE);
            } else {
                // Special case for when we are hospitalized abroad
                view.setViewVisibility(R.id.widget_status_green, View.GONE);
                view.setViewVisibility(R.id.widget_status_red, View.VISIBLE);
                view.setViewVisibility(R.id.widget_status_blue, View.GONE);
                view.setTextViewText(R.id.widget_status_red, status);

                // TODO??? Or to hospital??
                // Report blue status clicked, even though we are in hospital, so that the browser opens to the country
                PendingIntent blueStatusIconIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://blue-status-icon-clicked"));
                view.setOnClickPendingIntent(R.id.widget_status_icon_main, blueStatusIconIntent);
                view.setViewVisibility(R.id.widget_status_icon_main, View.VISIBLE);
                view.setViewVisibility(R.id.widget_status_extra_icon_main, View.VISIBLE);
            }
        } else if (statusColor.equals("red")) {
            view.setViewVisibility(R.id.widget_status_green, View.GONE);
            view.setViewVisibility(R.id.widget_status_red, View.VISIBLE);
            view.setViewVisibility(R.id.widget_status_blue, View.GONE);
            view.setTextViewText(R.id.widget_status_red, status);
            if (status.contains("Hospital")) {
                view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.hospital);
                PendingIntent redStatusIconIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://hospital-status-icon-clicked"));
                view.setOnClickPendingIntent(R.id.widget_status_icon_main, redStatusIconIntent);
            } else if (status.contains("Jail")) {
                view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.jail);
                PendingIntent redStatusIconIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://jail-status-icon-clicked"));
                view.setOnClickPendingIntent(R.id.widget_status_icon_main, redStatusIconIntent);
            }
            view.setViewVisibility(R.id.widget_status_icon_main, View.VISIBLE);
            view.setViewVisibility(R.id.widget_status_extra_icon_main, View.GONE);
        } else {
            view.setViewVisibility(R.id.widget_status_green, View.VISIBLE);
            view.setViewVisibility(R.id.widget_status_red, View.GONE);
            view.setViewVisibility(R.id.widget_status_blue, View.GONE);
            view.setTextViewText(R.id.widget_status_green, status);
            view.setViewVisibility(R.id.widget_status_icon_main, View.GONE);
            view.setViewVisibility(R.id.widget_status_extra_icon_main, View.GONE);
        }

        // Assign click callback from reload icon
        PendingIntent reloadIntent = HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(context, Uri.parse("pdaWidget://reload-clicked"), "Reloading...");
        view.setOnClickPendingIntent(R.id.widget_icon_reload, reloadIntent);

        // ## ENERGY
        // Assign Energy Text
        String energy = prefs.getString("energy_text", "-");
        view.setTextViewText(R.id.widget_energy_text, energy);

        // Assign Energy Progress Bar
        int energy_current = prefs.getInt("energy_current", 0);
        int energy_max = prefs.getInt("energy_max", 100);
        view.setProgressBar(R.id.widget_energy_bar, energy_max, energy_current, false);

        // ## NERVE
        // Assign Nerve Text
        String nerve = prefs.getString("nerve_text", "-");
        view.setTextViewText(R.id.widget_nerve_text, nerve);

        // Assign Nerve Progress Bar
        int nerve_current = prefs.getInt("nerve_current", 0);
        int nerve_max = prefs.getInt("nerve_max", 50);
        view.setProgressBar(R.id.widget_nerve_bar, nerve_max, nerve_current, false);

        // ## HAPPY
        // Assign Happy Text
        String happy = prefs.getString("happy_text", "-");
        view.setTextViewText(R.id.widget_happy_text, happy);

        // Assign Nerve Progress Bar
        int happy_current = prefs.getInt("happy_current", 0);
        int happy_max = prefs.getInt("happy_max", 50);
        view.setProgressBar(R.id.widget_happy_bar, happy_max, happy_current, false);

        // ## LIFE
        // Assign Life Text
        String life = prefs.getString("life_text", "-");
        view.setTextViewText(R.id.widget_life_text, life);

        // Assign Nerve Progress Bar
        int life_current = prefs.getInt("life_current", 0);
        int life_max = prefs.getInt("life_max", 50);
        view.setProgressBar(R.id.widget_life_bar, life_max, life_current, false);

        // ## Assign Last Updated time text
        String lastUpdated = prefs.getString("last_updated", "-");
        view.setTextViewText(R.id.widget_last_updated, lastUpdated);

        // ## ERROR LAYOUT ##
        // Error layout visibility
        boolean errorVisibility = prefs.getBoolean("error_layout_visibility", true);
        int errorVis;
        if (!errorVisibility && updatesActive) {
            errorVis = View.GONE;
        } else {
            errorVis = View.VISIBLE;
            // If updates are not active, we just positioned the widget, so we don't need the "Reload"
            // text and icons, since the only thing we need to do is launch the app
            if (!updatesActive) {
                view.setViewVisibility(R.id.widget_icon_reload_error, View.GONE);
                view.setViewVisibility(R.id.widget_error_action_text, View.GONE);
                view.setViewPadding(R.id.widget_error_message, 5, 25, 0, 0);
            } else {
                view.setViewVisibility(R.id.widget_icon_reload_error, View.VISIBLE);
                view.setViewVisibility(R.id.widget_error_action_text, View.VISIBLE);
                view.setViewPadding(R.id.widget_error_message, 0, 0, 0, 0);
            }
        }
        view.setViewVisibility(R.id.widget_error_layout, errorVis);

        // Assign error message text
        String errorMessage = prefs.getString("error_message", "Loading...");
        if (!updatesActive) {
            errorMessage = "Open app to initialise (tap icon)";
        }
        view.setTextViewText(R.id.widget_error_message, errorMessage);

        // Assign click callback from error reload icon
        view.setOnClickPendingIntent(R.id.widget_icon_reload_error, reloadIntent);

        return view;
    }

}