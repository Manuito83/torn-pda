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
        RemoteViews smallView = new RemoteViews(context.getPackageName(), R.layout.bars_layout);
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
        boolean backgroundServiceRunning = prefs.getBoolean("background_active", false);

        // ## Open App on Widget Click with no URI ##
        PendingIntent openAppIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class,null);
        view.setOnClickPendingIntent(R.id.widget_status_green, openAppIntent);
        view.setOnClickPendingIntent(R.id.widget_status_red, openAppIntent);
        view.setOnClickPendingIntent(R.id.widget_status_blue, openAppIntent);
        view.setOnClickPendingIntent(R.id.widget_error_message, openAppIntent);
        view.setOnClickPendingIntent(R.id.widget_pda_logo_main, openAppIntent);
        view.setOnClickPendingIntent(R.id.widget_pda_logo_error, openAppIntent);

        // ## Intents that need to be capture by the app (in Drawer) with URI
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

        PendingIntent messagesIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://messages-clicked"));
        view.setOnClickPendingIntent(R.id.widget_main_messages_box, messagesIntent);

        PendingIntent eventsIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://events-clicked"));
        view.setOnClickPendingIntent(R.id.widget_main_events_box, eventsIntent);

        PendingIntent emptyShortcutsIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://empty-shortcuts-clicked"));
        view.setOnClickPendingIntent(R.id.widget_shortcuts_empty_box, emptyShortcutsIntent);

        // ## MAIN LAYOUT ##
        // Main layout visibility
        boolean main_visibility = prefs.getBoolean("main_layout_visibility", false);
        int mainVis;
        if (!main_visibility || !backgroundServiceRunning) {
            mainVis = View.GONE;
        } else {
            mainVis = View.VISIBLE;
        }
        view.setViewVisibility(R.id.widget_main_layout, mainVis);

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
                    view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.plane_left);
                } else {
                    view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.plane_right);
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

        // ## MESSAGES
        int messages = prefs.getInt("messages", 0);
        if (messages > 0) {
            view.setTextViewText(R.id.widget_messages_text, Integer.toString(messages));
            view.setViewVisibility(R.id.widget_messages_text, View.VISIBLE);
            view.setViewVisibility(R.id.widget_messages_icon_black, View.GONE);
            view.setViewVisibility(R.id.widget_messages_icon_green, View.VISIBLE);
        } else {
            view.setViewVisibility(R.id.widget_messages_text, View.GONE);
            view.setViewVisibility(R.id.widget_messages_icon_black, View.VISIBLE);
            view.setViewVisibility(R.id.widget_messages_icon_green, View.GONE);
        }

        // ## EVENTS
        int events = prefs.getInt("events", 0);
        if (events > 0) {
            view.setTextViewText(R.id.widget_events_text, Integer.toString(events));
            view.setViewVisibility(R.id.widget_events_text, View.VISIBLE);
            view.setViewVisibility(R.id.widget_events_icon_black, View.GONE);
            view.setViewVisibility(R.id.widget_events_icon_green, View.VISIBLE);
        } else {
            view.setViewVisibility(R.id.widget_events_text, View.GONE);
            view.setViewVisibility(R.id.widget_events_icon_black, View.VISIBLE);
            view.setViewVisibility(R.id.widget_events_icon_green, View.GONE);
        }

        // ## ENERGY
        // Assign Energy Text
        String energy = prefs.getString("energy_text", "0");
        view.setTextViewText(R.id.widget_energy_text, energy);

        int energy_current = prefs.getInt("energy_current", 0);
        int energy_max = prefs.getInt("energy_max", 100);
        view.setProgressBar(R.id.widget_energy_bar, energy_max, energy_current, false);

        // ## NERVE
        // Assign Nerve Text
        String nerve = prefs.getString("nerve_text", "0");
        view.setTextViewText(R.id.widget_nerve_text, nerve);

        int nerve_current = prefs.getInt("nerve_current", 0);
        int nerve_max = prefs.getInt("nerve_max", 50);
        view.setProgressBar(R.id.widget_nerve_bar, nerve_max, nerve_current, false);

        // ## HAPPY
        // Assign Happy Text
        String happy = prefs.getString("happy_text", "0");
        view.setTextViewText(R.id.widget_happy_text, happy);

        int happy_current = prefs.getInt("happy_current", 0);
        int happy_max = prefs.getInt("happy_max", 50);
        view.setProgressBar(R.id.widget_happy_bar, happy_max, happy_current, false);

        // ## LIFE
        // Assign Life Text
        String life = prefs.getString("life_text", "0");
        view.setTextViewText(R.id.widget_life_text, life);

        int life_current = prefs.getInt("life_current", 0);
        int life_max = prefs.getInt("life_max", 50);
        view.setProgressBar(R.id.widget_life_bar, life_max, life_current, false);

        // ## CHAIN
        // Assign Chain Text
        String chain = prefs.getString("chain_text", "0");
        view.setTextViewText(R.id.widget_chain_text, chain);

        int chain_current = prefs.getInt("chain_current", 0);
        int chain_max = prefs.getInt("chain_max", 10);
        view.setProgressBar(R.id.widget_chain_bar, chain_max, chain_current, false);

        // ## LAST UPDATE
        String lastUpdated = prefs.getString("last_updated", "Update");
        view.setTextViewText(R.id.widget_last_updated, lastUpdated);

        boolean reloadingNow = prefs.getBoolean("reloading", false);
        if (reloadingNow) {
            view.setViewVisibility(R.id.widget_icon_reload, View.INVISIBLE);
            view.setViewVisibility(R.id.widget_icon_reload_active, View.VISIBLE);
        } else {
            view.setViewVisibility(R.id.widget_icon_reload, View.VISIBLE);
            view.setViewVisibility(R.id.widget_icon_reload_active, View.GONE);
        }

        PendingIntent reloadIntent = HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(context, Uri.parse("pdaWidget://reload-clicked"), "Reloading...");
        view.setOnClickPendingIntent(R.id.widget_update_box, reloadIntent);

        // ## DRUGS
        int drugLevel = prefs.getInt("drug_level", 0);
        String drugString = prefs.getString("drug_string", "");
        view.setViewVisibility(R.id.widget_drugs_box, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_drugs1, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_drugs2, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_drugs3, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_drugs4, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_drugs5, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_drugs_box, View.VISIBLE);
        PendingIntent drugIntent = HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(context, Uri.parse("pdaWidget://drug-clicked"), drugString);
        view.setOnClickPendingIntent(R.id.widget_drugs_box, drugIntent);
        if (drugLevel == 0) {
            view.setViewVisibility(R.id.widget_drugs_box, View.INVISIBLE);
        } else if (drugLevel == 1) {
            view.setViewVisibility(R.id.widget_icon_drugs1, View.VISIBLE);
        } else if (drugLevel == 2) {
            view.setViewVisibility(R.id.widget_icon_drugs2, View.VISIBLE);
        } else if (drugLevel == 3) {
            view.setViewVisibility(R.id.widget_icon_drugs3, View.VISIBLE);
        } else if (drugLevel == 4) {
            view.setViewVisibility(R.id.widget_icon_drugs4, View.VISIBLE);
        } else if (drugLevel == 5) {
            view.setViewVisibility(R.id.widget_icon_drugs5, View.VISIBLE);
        }

        // ## MEDICAL
        int medicalLevel = prefs.getInt("medical_level", 0);
        String medicalString = prefs.getString("medical_string", "");
        view.setViewVisibility(R.id.widget_medical_box, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_medical1, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_medical2, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_medical3, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_medical4, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_medical5, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_medical_box, View.VISIBLE);
        PendingIntent medicalIntent = HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(context, Uri.parse("pdaWidget://medical-clicked"), medicalString);
        view.setOnClickPendingIntent(R.id.widget_medical_box, medicalIntent);
        if (medicalLevel == 0) {
            view.setViewVisibility(R.id.widget_medical_box, View.INVISIBLE);
        } else if (medicalLevel == 1) {
            view.setViewVisibility(R.id.widget_icon_medical1, View.VISIBLE);
        } else if (medicalLevel == 2) {
            view.setViewVisibility(R.id.widget_icon_medical2, View.VISIBLE);
        } else if (medicalLevel == 3) {
            view.setViewVisibility(R.id.widget_icon_medical3, View.VISIBLE);
        } else if (medicalLevel == 4) {
            view.setViewVisibility(R.id.widget_icon_medical4, View.VISIBLE);
        } else if (medicalLevel == 5) {
            view.setViewVisibility(R.id.widget_icon_medical5, View.VISIBLE);
        }

        // ## BOOSTER
        int boosterLevel = prefs.getInt("booster_level", 0);
        String boosterString = prefs.getString("booster_string", "");
        view.setViewVisibility(R.id.widget_booster_box, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_booster1, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_booster2, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_booster3, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_booster4, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_booster5, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_booster_box, View.VISIBLE);
        PendingIntent boosterIntent = HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(context, Uri.parse("pdaWidget://booster-clicked"), boosterString);
        view.setOnClickPendingIntent(R.id.widget_booster_box, boosterIntent);
        if (boosterLevel == 0) {
            view.setViewVisibility(R.id.widget_booster_box, View.INVISIBLE);
        } else if (boosterLevel == 1) {
            view.setViewVisibility(R.id.widget_icon_booster1, View.VISIBLE);
        } else if (boosterLevel == 2) {
            view.setViewVisibility(R.id.widget_icon_booster2, View.VISIBLE);
        } else if (boosterLevel == 3) {
            view.setViewVisibility(R.id.widget_icon_booster3, View.VISIBLE);
        } else if (boosterLevel == 4) {
            view.setViewVisibility(R.id.widget_icon_booster4, View.VISIBLE);
        } else if (boosterLevel == 5) {
            view.setViewVisibility(R.id.widget_icon_booster5, View.VISIBLE);
        }

        // ## SHORTCUTS
        int shortcutsNumber = prefs.getInt("shortcuts_number", 0);
        if (shortcutsNumber == 0) {
            view.setTextViewText(R.id.widget_shortcuts_empty_text, "No shortcuts configured, add some?");
            view.setViewVisibility(R.id.widget_shortcuts_empty_box, View.VISIBLE);
        } else {
            view.setViewVisibility(R.id.widget_shortcuts_empty_box, View.GONE);
            
            // Short 1
            String shortcut1_name = prefs.getString("shortcut1_name", "");
            if (!shortcut1_name.isEmpty()) {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut1_text, View.VISIBLE);
                view.setTextViewText(R.id.widget_shortcuts_shortcut1_text, shortcut1_name);
                String shortcut1_url = prefs.getString("shortcut1_url", "");
                PendingIntent shortcut1_intent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://shortcut:" + shortcut1_url));
                view.setOnClickPendingIntent(R.id.widget_shortcuts_shortcut1_text, shortcut1_intent);
            } else {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut1_text, View.INVISIBLE);
            }

            // Short 2
            String shortcut2_name = prefs.getString("shortcut2_name", "");
            if (!shortcut2_name.isEmpty()) {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut2_text, View.VISIBLE);
                view.setTextViewText(R.id.widget_shortcuts_shortcut2_text, shortcut2_name);
                String shortcut2_url = prefs.getString("shortcut2_url", "");
                PendingIntent shortcut2_intent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://shortcut:" + shortcut2_url));
                view.setOnClickPendingIntent(R.id.widget_shortcuts_shortcut2_text, shortcut2_intent);
            } else {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut2_text, View.INVISIBLE);
            }

            // Short 3
            String shortcut3_name = prefs.getString("shortcut3_name", "");
            if (!shortcut3_name.isEmpty()) {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut3_text, View.VISIBLE);
                view.setTextViewText(R.id.widget_shortcuts_shortcut3_text, shortcut3_name);
                String shortcut3_url = prefs.getString("shortcut3_url", "");
                PendingIntent shortcut3_intent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://shortcut:" + shortcut3_url));
                view.setOnClickPendingIntent(R.id.widget_shortcuts_shortcut3_text, shortcut3_intent);
            } else {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut3_text, View.INVISIBLE);
            }

            // Short 4
            String shortcut4_name = prefs.getString("shortcut4_name", "");
            if (!shortcut4_name.isEmpty()) {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut4_text, View.VISIBLE);
                view.setTextViewText(R.id.widget_shortcuts_shortcut4_text, shortcut4_name);
                String shortcut4_url = prefs.getString("shortcut4_url", "");
                PendingIntent shortcut4_intent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://shortcut:" + shortcut4_url));
                view.setOnClickPendingIntent(R.id.widget_shortcuts_shortcut4_text, shortcut4_intent);
            } else {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut4_text, View.INVISIBLE);
            }

            // Short 5
            String shortcut5_name = prefs.getString("shortcut5_name", "");
            if (!shortcut5_name.isEmpty()) {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut5_text, View.VISIBLE);
                view.setTextViewText(R.id.widget_shortcuts_shortcut5_text, shortcut5_name);
                String shortcut5_url = prefs.getString("shortcut5_url", "");
                PendingIntent shortcut5_intent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://shortcut:" + shortcut5_url));
                view.setOnClickPendingIntent(R.id.widget_shortcuts_shortcut5_text, shortcut5_intent);
            } else {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut5_text, View.INVISIBLE);
            }

            // Short 6
            String shortcut6_name = prefs.getString("shortcut6_name", "");
            if (!shortcut6_name.isEmpty()) {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut6_text, View.VISIBLE);
                view.setTextViewText(R.id.widget_shortcuts_shortcut6_text, shortcut6_name);
                String shortcut6_url = prefs.getString("shortcut6_url", "");
                PendingIntent shortcut6_intent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://shortcut:" + shortcut6_url));
                view.setOnClickPendingIntent(R.id.widget_shortcuts_shortcut6_text, shortcut6_intent);
            } else {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut6_text, View.INVISIBLE);
            }

            // Short 7
            String shortcut7_name = prefs.getString("shortcut7_name", "");
            if (!shortcut7_name.isEmpty()) {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut7_text, View.VISIBLE);
                view.setTextViewText(R.id.widget_shortcuts_shortcut7_text, shortcut7_name);
                String shortcut7_url = prefs.getString("shortcut7_url", "");
                PendingIntent shortcut7_intent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://shortcut:" + shortcut7_url));
                view.setOnClickPendingIntent(R.id.widget_shortcuts_shortcut7_text, shortcut7_intent);
            } else {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut7_text, View.INVISIBLE);
            }

            // Short 8
            String shortcut8_name = prefs.getString("shortcut8_name", "");
            if (!shortcut8_name.isEmpty()) {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut8_text, View.VISIBLE);
                view.setTextViewText(R.id.widget_shortcuts_shortcut8_text, shortcut8_name);
                String shortcut8_url = prefs.getString("shortcut8_url", "");
                PendingIntent shortcut8_intent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://shortcut:" + shortcut8_url));
                view.setOnClickPendingIntent(R.id.widget_shortcuts_shortcut8_text, shortcut8_intent);
            } else {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut8_text, View.INVISIBLE);
            }

            // Short 9
            String shortcut9_name = prefs.getString("shortcut9_name", "");
            if (!shortcut9_name.isEmpty()) {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut9_text, View.VISIBLE);
                view.setTextViewText(R.id.widget_shortcuts_shortcut9_text, shortcut9_name);
                String shortcut9_url = prefs.getString("shortcut9_url", "");
                PendingIntent shortcut9_intent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, Uri.parse("pdaWidget://shortcut:" + shortcut9_url));
                view.setOnClickPendingIntent(R.id.widget_shortcuts_shortcut9_text, shortcut9_intent);
            } else {
                view.setViewVisibility(R.id.widget_shortcuts_shortcut9_text, View.INVISIBLE);
            }
        }

        // ## ERROR LAYOUT ##
        // Error layout visibility
        boolean errorVisibility = prefs.getBoolean("error_layout_visibility", true);
        int errorVis;
        if (!errorVisibility && backgroundServiceRunning) {
            errorVis = View.GONE;
        } else {
            errorVis = View.VISIBLE;
            // If updates are not active, we just positioned the widget, so we don't need the "Reload"
            // text and icons, since the only thing we need to do is launch the app
            if (!backgroundServiceRunning) {
                view.setViewVisibility(R.id.widget_icon_reload_error, View.GONE);
                view.setViewVisibility(R.id.widget_error_action_text, View.GONE);
                view.setViewPadding(R.id.widget_error_message, 5, 25, 0, 0);
            } else {
                view.setViewPadding(R.id.widget_error_message, 0, 0, 0, 0);
                if (reloadingNow) {
                    view.setViewVisibility(R.id.widget_icon_reload_error, View.INVISIBLE);
                    view.setViewVisibility(R.id.widget_icon_reload_error_active, View.VISIBLE);
                } else {
                    view.setViewVisibility(R.id.widget_icon_reload_error, View.VISIBLE);
                    view.setViewVisibility(R.id.widget_icon_reload_error_active, View.GONE);
                }
            }
        }
        view.setViewVisibility(R.id.widget_error_layout, errorVis);

        // Assign error message text
        String errorMessage = prefs.getString("error_message", "Loading...");
        if (!backgroundServiceRunning) {
            errorMessage = "Open app to initialise (tap icon)";
        }
        view.setTextViewText(R.id.widget_error_message, errorMessage);

        // Assign click callback from error reload icon and text
        view.setOnClickPendingIntent(R.id.widget_icon_reload_error, reloadIntent);
        view.setOnClickPendingIntent(R.id.widget_error_action_text, reloadIntent);

        return view;
    }

}