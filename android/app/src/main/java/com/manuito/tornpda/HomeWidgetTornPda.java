package com.manuito.tornpda;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.ArrayMap;
import android.util.SizeF;
import android.view.View;
import android.widget.RemoteViews;
import androidx.annotation.NonNull;

import java.util.Map;

import es.antonborri.home_widget.HomeWidgetBackgroundIntent;
import es.antonborri.home_widget.HomeWidgetProvider;

public class HomeWidgetTornPda extends HomeWidgetProvider {

    @Override
    public void onAppWidgetOptionsChanged(Context context, AppWidgetManager appWidgetManager, int appWidgetId, Bundle newOptions) {
        assert context != null;
        SharedPreferences prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);
        createRemoteViews(context, appWidgetManager, appWidgetId, prefs);
    }

    @Override
    public void onUpdate(@NonNull Context context, @NonNull AppWidgetManager appWidgetManager, int[] appWidgetIds, @NonNull SharedPreferences widgetData) {
        // Called when widget is updated
        SharedPreferences prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);
        for (int widgetId : appWidgetIds) {
            createRemoteViews(context, appWidgetManager, widgetId, prefs);
        }
    }

    /**
     * Creates and updates the RemoteViews based on the widget's size
     *
     * @param context          The application context.
     * @param appWidgetManager The AppWidgetManager instance.
     * @param appWidgetId      The ID of the widget to update.
     * @param prefs            SharedPreferences containing user preferences.
     */
    private void createRemoteViews(Context context, AppWidgetManager appWidgetManager, int appWidgetId, SharedPreferences prefs) {
        boolean dark = prefs.getBoolean("darkMode", false);
        boolean oneRowNoShortcuts = prefs.getBoolean("removeShortcutsOneRowLayout", false);

        // **One Row Narrow**
        int oneRowNarrowLayoutId;
        if (dark) {
            if (oneRowNoShortcuts) {
                oneRowNarrowLayoutId = R.layout.bars_layout_one_row_narrow_dark_ns;
            } else {
                oneRowNarrowLayoutId = R.layout.bars_layout_one_row_narrow_dark;
            }
        } else {
            if (oneRowNoShortcuts) {
                oneRowNarrowLayoutId = R.layout.bars_layout_one_row_narrow_ns;
            } else {
                oneRowNarrowLayoutId = R.layout.bars_layout_one_row_narrow;
            }
        }

        // **One Row Wide**
        int oneRowWideLayoutId;
        if (dark) {
            if (oneRowNoShortcuts) {
                oneRowWideLayoutId = R.layout.bars_layout_one_row_wide_dark_ns;
            } else {
                oneRowWideLayoutId = R.layout.bars_layout_one_row_wide_dark;
            }
        } else {
            if (oneRowNoShortcuts) {
                oneRowWideLayoutId = R.layout.bars_layout_one_row_wide_ns;
            } else {
                oneRowWideLayoutId = R.layout.bars_layout_one_row_wide;
            }
        }

        // **Two Rows**
        int twoRowNarrowLayoutId = dark ? R.layout.bars_layout_two_row_narrow_dark : R.layout.bars_layout_two_row_narrow;
        int twoRowWideLayoutId = dark ? R.layout.bars_layout_two_row_wide_dark : R.layout.bars_layout_two_row_wide;

        RemoteViews oneRowNarrow = new RemoteViews(context.getPackageName(), oneRowNarrowLayoutId);
        RemoteViews oneRowWide = new RemoteViews(context.getPackageName(), oneRowWideLayoutId);
        RemoteViews twoRowNarrow = new RemoteViews(context.getPackageName(), twoRowNarrowLayoutId);
        RemoteViews twoRowWide = new RemoteViews(context.getPackageName(), twoRowWideLayoutId);

        oneRowNarrow = loadWidgetData(oneRowNarrow, context, prefs);
        oneRowWide = loadWidgetData(oneRowWide, context, prefs);
        twoRowNarrow = loadWidgetData(twoRowNarrow, context, prefs);
        twoRowWide = loadWidgetData(twoRowWide, context, prefs);

        Map<SizeF, RemoteViews> viewMapping = new ArrayMap<>();
        viewMapping.put(new SizeF(60f, 0f), oneRowNarrow);
        viewMapping.put(new SizeF(300f, 0f), oneRowWide);
        viewMapping.put(new SizeF(60f, 150f), twoRowNarrow);
        viewMapping.put(new SizeF(300f, 150f), twoRowWide);

        RemoteViews remoteViews;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            remoteViews = new RemoteViews(viewMapping);
        } else {
            remoteViews = twoRowWide;
        }

        appWidgetManager.updateAppWidget(appWidgetId, remoteViews);

    }

    /**
     * Loads data into the RemoteViews
     *
     * @param view    The RemoteViews instance to populate.
     * @param context The application context.
     * @param prefs   SharedPreferences containing user preferences.
     * @return The updated RemoteViews instance.
     */
    public RemoteViews loadWidgetData(RemoteViews view, Context context, SharedPreferences prefs) {
        setupClickListeners(view, context);
        setupMainLayout(view, prefs);
        setupStatusSection(view, context, prefs);
        setupMessagesSection(view, prefs);
        setupEventsSection(view, prefs);
        setupMoneySection(view, prefs);
        setupLastUpdateSection(view, prefs);
        setupReloadSection(view, context, prefs);
        setupEnergySection(view, prefs);
        setupNerveSection(view, prefs);
        setupHappySection(view, prefs);
        setupLifeSection(view, prefs);
        setupChainSection(view, prefs);
        setupDrugsSection(view, context, prefs);
        setupMedicalSection(view, context, prefs);
        setupBoosterSection(view, context, prefs);
        setupShortcutsSection(view, context, prefs);
        setupErrorLayout(view, prefs);
        return view;
    }

    /**
     * Sets up click listeners for widgets that are always present
     *
     * @param view    The RemoteViews instance.
     * @param context The application context.
     */
    private void setupClickListeners(RemoteViews view, Context context) {
        // Open the main application when specific elements are clicked
        PendingIntent openAppIntent = getUniquePendingIntent(context, "OpenApp", "pdaWidget://open:app", 0);
        int[] clickableIds = {
                R.id.widget_status_green,
                R.id.widget_status_red,
                R.id.widget_status_blue,
                R.id.widget_error_message,
                R.id.widget_pda_logo_main,
                R.id.widget_pda_logo_error
        };
        for (int id : clickableIds) {
            view.setOnClickPendingIntent(id, openAppIntent);
        }

        // Energy Box Click Listener
        PendingIntent energyBoxIntent = getUniquePendingIntent(context, "EnergyBoxClicked", "pdaWidget://energy:box:clicked", 1);
        view.setOnClickPendingIntent(R.id.widget_energy_box, energyBoxIntent);

        // Nerve Box Click Listener
        PendingIntent nerveBoxIntent = getUniquePendingIntent(context, "NerveBoxClicked", "pdaWidget://nerve:box:clicked", 2);
        view.setOnClickPendingIntent(R.id.widget_nerve_box, nerveBoxIntent);

        // Happy Box Click Listener
        PendingIntent happyBoxIntent = getUniquePendingIntent(context, "HappyBoxClicked", "pdaWidget://happy:box:clicked", 3);
        view.setOnClickPendingIntent(R.id.widget_happy_box, happyBoxIntent);

        // Life Box Click Listener
        PendingIntent lifeBoxIntent = getUniquePendingIntent(context, "LifeBoxClicked", "pdaWidget://life:box:clicked", 4);
        view.setOnClickPendingIntent(R.id.widget_life_box, lifeBoxIntent);

        // Chain Box Click Listener
        PendingIntent chainBoxIntent = getUniquePendingIntent(context, "ChainBoxClicked", "pdaWidget://chain:box:clicked", 5);
        view.setOnClickPendingIntent(R.id.widget_chain_box, chainBoxIntent);

        // Blue Status Click Listener
        PendingIntent blueStatusIconIntent = getUniquePendingIntent(context, "BlueStatusIconClicked", "pdaWidget://blue:status:icon:clicked", 6);
        view.setOnClickPendingIntent(R.id.widget_status_icon_main, blueStatusIconIntent);
        view.setOnClickPendingIntent(R.id.widget_status_blue, blueStatusIconIntent);

        // Messages Click Listener
        PendingIntent messagesIntent = getUniquePendingIntent(context, "MessagesClicked", "pdaWidget://messages:clicked", 7);
        view.setOnClickPendingIntent(R.id.widget_main_messages_box, messagesIntent);

        // Events Click Listener
        PendingIntent eventsIntent = getUniquePendingIntent(context, "EventsClicked", "pdaWidget://events:clicked", 8);
        view.setOnClickPendingIntent(R.id.widget_main_events_box, eventsIntent);

        // Empty Shortcuts Click Listener
        PendingIntent emptyShortcutsIntent = getUniquePendingIntent(context, "EmptyShortcutsClicked", "pdaWidget://empty:shortcuts:clicked", 9);
        view.setOnClickPendingIntent(R.id.widget_shortcuts_empty_box, emptyShortcutsIntent);
    }

    /**
     * Sets up the main layout visibility based on preferences and background service status.
     *
     * @param view    The RemoteViews instance.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupMainLayout(RemoteViews view, SharedPreferences prefs) {
        boolean backgroundServiceRunning = prefs.getBoolean("background_active", false);
        boolean mainVisibility = prefs.getBoolean("main_layout_visibility", false);
        int mainVis = (!mainVisibility || !backgroundServiceRunning) ? View.GONE : View.VISIBLE;
        view.setViewVisibility(R.id.widget_main_layout, mainVis);
    }

    /**
     * Sets up the status section of the widget.
     *
     * @param view    The RemoteViews instance.
     * @param context The application context.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupStatusSection(RemoteViews view, Context context, SharedPreferences prefs) {
        String status = prefs.getString("status", "Status");
        String statusColor = prefs.getString("status_color", "green");
        String country = prefs.getString("country", "Torn");
        String travel = prefs.getString("travel", "no");

        // Set initial visibility
        view.setViewVisibility(R.id.widget_status_icon_main, View.VISIBLE);
        view.setViewVisibility(R.id.widget_status_extra_icon_main, View.GONE);

        // Handle travel status
        if (!travel.equals("no")) {
            setCountryFlag(view, country);
            handleTravelStatus(view, travel);

            if (!statusColor.equals("red")) {
                // Show blue status
                view.setTextViewText(R.id.widget_status_blue, status);
                view.setViewVisibility(R.id.widget_status_green, View.GONE);
                view.setViewVisibility(R.id.widget_status_red, View.GONE);
                view.setViewVisibility(R.id.widget_status_blue, View.VISIBLE);

                PendingIntent blueStatusIconIntent = getUniquePendingIntent(context, "BlueStatusIconClicked",
                        "pdaWidget://blue:status:icon:clicked", 10);
                view.setOnClickPendingIntent(R.id.widget_status_icon_main, blueStatusIconIntent);
                view.setOnClickPendingIntent(R.id.widget_status_blue, blueStatusIconIntent);
            } else {
                // Show red status for hospitalized abroad
                view.setTextViewText(R.id.widget_status_red, status);
                view.setViewVisibility(R.id.widget_status_green, View.GONE);
                view.setViewVisibility(R.id.widget_status_red, View.VISIBLE);
                view.setViewVisibility(R.id.widget_status_blue, View.GONE);
                view.setViewVisibility(R.id.widget_status_extra_icon_main, View.VISIBLE);

                PendingIntent abroadHospitalStatusIconIntent = getUniquePendingIntent(context, "AbroadHospitalStatusIconClicked",
                        "pdaWidget://blue:status:icon:clicked", 11);
                view.setOnClickPendingIntent(R.id.widget_status_icon_main, abroadHospitalStatusIconIntent);
                view.setOnClickPendingIntent(R.id.widget_status_red, abroadHospitalStatusIconIntent);
                view.setOnClickPendingIntent(R.id.widget_status_extra_icon_main, abroadHospitalStatusIconIntent);
            }
        } else {
            if (statusColor.equals("red")) {
                // Show red status locally
                view.setTextViewText(R.id.widget_status_red, status);
                view.setViewVisibility(R.id.widget_status_green, View.GONE);
                view.setViewVisibility(R.id.widget_status_red, View.VISIBLE);
                view.setViewVisibility(R.id.widget_status_blue, View.GONE);

                if (status.contains("Hospital")) {
                    view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.hospital);
                    PendingIntent hospitalStatusIconIntent = getUniquePendingIntent(context, "HospitalStatusIconClicked",
                            "pdaWidget://hospital:status:icon:clicked", 12);
                    view.setOnClickPendingIntent(R.id.widget_status_icon_main, hospitalStatusIconIntent);
                    view.setOnClickPendingIntent(R.id.widget_status_red, hospitalStatusIconIntent);
                } else if (status.contains("Jail")) {
                    view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.jail);
                    PendingIntent jailStatusIconIntent = getUniquePendingIntent(context, "JailStatusIconClicked",
                            "pdaWidget://jail:status:icon:clicked", 13);
                    view.setOnClickPendingIntent(R.id.widget_status_icon_main, jailStatusIconIntent);
                    view.setOnClickPendingIntent(R.id.widget_status_red, jailStatusIconIntent);
                }
            } else {
                // Show green status
                view.setViewVisibility(R.id.widget_status_green, View.VISIBLE);
                view.setViewVisibility(R.id.widget_status_red, View.GONE);
                view.setViewVisibility(R.id.widget_status_blue, View.GONE);
                view.setTextViewText(R.id.widget_status_green, status);
                view.setViewVisibility(R.id.widget_status_icon_main, View.GONE);
            }
        }
    }

    /**
     * Sets the appropriate country flag based on the country name
     *
     * @param view    The RemoteViews instance.
     * @param country The country name.
     */
    private void setCountryFlag(RemoteViews view, String country) {
        switch (country) {
            case "Japan":
                view.setImageViewResource(R.id.widget_status_extra_icon_main, R.drawable.flag_japan);
                break;
            case "Hawaii":
                view.setImageViewResource(R.id.widget_status_extra_icon_main, R.drawable.flag_hawaii);
                break;
            case "China":
                view.setImageViewResource(R.id.widget_status_extra_icon_main, R.drawable.flag_china);
                break;
            case "Argentina":
                view.setImageViewResource(R.id.widget_status_extra_icon_main, R.drawable.flag_argentina);
                break;
            case "United Kingdom":
                view.setImageViewResource(R.id.widget_status_extra_icon_main, R.drawable.flag_uk);
                break;
            case "Cayman Islands":
                view.setImageViewResource(R.id.widget_status_extra_icon_main, R.drawable.flag_cayman);
                break;
            case "South Africa":
                view.setImageViewResource(R.id.widget_status_extra_icon_main, R.drawable.flag_south_africa);
                break;
            case "Switzerland":
                view.setImageViewResource(R.id.widget_status_extra_icon_main, R.drawable.flag_switzerland);
                break;
            case "Mexico":
                view.setImageViewResource(R.id.widget_status_extra_icon_main, R.drawable.flag_mexico);
                break;
            case "UAE":
                view.setImageViewResource(R.id.widget_status_extra_icon_main, R.drawable.flag_uae);
                break;
            case "Canada":
                view.setImageViewResource(R.id.widget_status_extra_icon_main, R.drawable.flag_canada);
                break;
            default:
                view.setImageViewResource(R.id.widget_status_extra_icon_main, 0);
                view.setViewVisibility(R.id.widget_status_extra_icon_main, View.GONE);
                break;
        }
    }

    /**
     * Handles the travel status
     *
     * @param view    The RemoteViews instance.
     * @param travel  The travel status.
     */
    private void handleTravelStatus(RemoteViews view, String travel) {
        switch (travel) {
            case "right":
                // Show plane and flag
                view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.plane_right);
                view.setViewVisibility(R.id.widget_status_extra_icon_main, View.VISIBLE);
                break;
            case "left":
                // Only show plane
                view.setImageViewResource(R.id.widget_status_icon_main, R.drawable.plane_left);
                break;
            case "visiting":
                // Only show flag
                view.setViewVisibility(R.id.widget_status_icon_main, View.GONE);
                view.setViewVisibility(R.id.widget_status_extra_icon_main, View.VISIBLE);
                break;
        }
    }

    /**
     * Sets up the messages section of the widget
     *
     * @param view    The RemoteViews instance.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupMessagesSection(RemoteViews view, SharedPreferences prefs) {
        int messages = prefs.getInt("messages", 0);
        if (messages > 0) {
            view.setTextViewText(R.id.widget_messages_text, String.valueOf(messages));
            view.setViewVisibility(R.id.widget_messages_text, View.VISIBLE);
            view.setViewVisibility(R.id.widget_messages_icon_black, View.GONE);
            view.setViewVisibility(R.id.widget_messages_icon_green, View.VISIBLE);
        } else {
            view.setViewVisibility(R.id.widget_messages_text, View.GONE);
            view.setViewVisibility(R.id.widget_messages_icon_black, View.VISIBLE);
            view.setViewVisibility(R.id.widget_messages_icon_green, View.GONE);
        }
    }

    /**
     * Sets up the events section of the widget
     *
     * @param view    The RemoteViews instance.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupEventsSection(RemoteViews view, SharedPreferences prefs) {
        int events = prefs.getInt("events", 0);
        if (events > 0) {
            view.setTextViewText(R.id.widget_events_text, String.valueOf(events));
            view.setViewVisibility(R.id.widget_events_text, View.VISIBLE);
            view.setViewVisibility(R.id.widget_events_icon_black, View.GONE);
            view.setViewVisibility(R.id.widget_events_icon_green, View.VISIBLE);
        } else {
            view.setViewVisibility(R.id.widget_events_text, View.GONE);
            view.setViewVisibility(R.id.widget_events_icon_black, View.VISIBLE);
            view.setViewVisibility(R.id.widget_events_icon_green, View.GONE);
        }
    }

    /**
     * Sets up the money section of the widget
     *
     * @param view    The RemoteViews instance.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupMoneySection(RemoteViews view, SharedPreferences prefs) {
        String money = prefs.getString("money", "0");
        boolean moneyEnabled = prefs.getBoolean("money_enabled", true);
        if (moneyEnabled) {
            view.setTextViewText(R.id.widget_money_text, money);
            view.setViewVisibility(R.id.widget_money_text, View.VISIBLE);
        } else {
            view.setViewVisibility(R.id.widget_money_text, View.GONE);
        }
    }

    /**
     * Sets up the last update section of the widget
     *
     * @param view    The RemoteViews instance.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupLastUpdateSection(RemoteViews view, SharedPreferences prefs) {
        String lastUpdated = prefs.getString("last_updated", "Update");
        view.setTextViewText(R.id.widget_last_updated, lastUpdated);
    }

    /**
     * Sets up the reload functionality and icons in the widget
     *
     * @param view    The RemoteViews instance.
     * @param context The application context.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupReloadSection(RemoteViews view, Context context, SharedPreferences prefs) {
        boolean backgroundServiceRunning = prefs.getBoolean("background_active", false);
        boolean reloadingNow = prefs.getBoolean("reloading", false);

        // Create the reload intent with the message "Reloading..."
        PendingIntent reloadIntent = getUniqueBroadcastPendingIntent(context, Uri.parse("pdaWidget://reload_clicked"), "Reloading...");

        if (backgroundServiceRunning) {
            // In normal layout
            if (reloadingNow) {
                view.setViewVisibility(R.id.widget_icon_reload, View.INVISIBLE);
                view.setViewVisibility(R.id.widget_icon_reload_active, View.VISIBLE);
            } else {
                view.setViewVisibility(R.id.widget_icon_reload, View.VISIBLE);
                view.setViewVisibility(R.id.widget_icon_reload_active, View.GONE);
            }
            view.setOnClickPendingIntent(R.id.widget_update_box, reloadIntent);
        }

        // In error layout
        if (reloadingNow) {
            view.setViewVisibility(R.id.widget_icon_reload_error, View.INVISIBLE);
            view.setViewVisibility(R.id.widget_icon_reload_error_active, View.VISIBLE);
        } else {
            view.setViewVisibility(R.id.widget_icon_reload_error, View.VISIBLE);
            view.setViewVisibility(R.id.widget_icon_reload_error_active, View.GONE);
        }
        view.setOnClickPendingIntent(R.id.widget_icon_reload_error, reloadIntent);
        view.setOnClickPendingIntent(R.id.widget_error_action_text, reloadIntent);
    }

    /**
     * Sets up the energy section of the widget
     *
     * @param view    The RemoteViews instance.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupEnergySection(RemoteViews view, SharedPreferences prefs) {
        String energy = prefs.getString("energy_text", "0");
        view.setTextViewText(R.id.widget_energy_text, energy);

        int energyCurrent = prefs.getInt("energy_current", 0);
        int energyMax = prefs.getInt("energy_max", 100);
        view.setProgressBar(R.id.widget_energy_bar, energyMax, energyCurrent, false);
    }

    /**
     * Sets up the nerve section of the widget
     *
     * @param view    The RemoteViews instance.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupNerveSection(RemoteViews view, SharedPreferences prefs) {
        String nerve = prefs.getString("nerve_text", "0");
        view.setTextViewText(R.id.widget_nerve_text, nerve);

        int nerveCurrent = prefs.getInt("nerve_current", 0);
        int nerveMax = prefs.getInt("nerve_max", 50);
        view.setProgressBar(R.id.widget_nerve_bar, nerveMax, nerveCurrent, false);
    }

    /**
     * Sets up the happy section of the widget
     *
     * @param view    The RemoteViews instance.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupHappySection(RemoteViews view, SharedPreferences prefs) {
        String happy = prefs.getString("happy_text", "0");
        view.setTextViewText(R.id.widget_happy_text, happy);

        int happyCurrent = prefs.getInt("happy_current", 0);
        int happyMax = prefs.getInt("happy_max", 50);
        view.setProgressBar(R.id.widget_happy_bar, happyMax, happyCurrent, false);
    }

    /**
     * Sets up the life section of the widget
     *
     * @param view    The RemoteViews instance.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupLifeSection(RemoteViews view, SharedPreferences prefs) {
        String life = prefs.getString("life_text", "0");
        view.setTextViewText(R.id.widget_life_text, life);

        int lifeCurrent = prefs.getInt("life_current", 0);
        int lifeMax = prefs.getInt("life_max", 50);
        view.setProgressBar(R.id.widget_life_bar, lifeMax, lifeCurrent, false);
    }

    /**
     * Sets up the chain section of the widget
     *
     * @param view    The RemoteViews instance.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupChainSection(RemoteViews view, SharedPreferences prefs) {
        String chain = prefs.getString("chain_text", "0");
        view.setTextViewText(R.id.widget_chain_text, chain);

        int chainCurrent = prefs.getInt("chain_current", 0);
        int chainMax = prefs.getInt("chain_max", 10);
        view.setProgressBar(R.id.widget_chain_bar, chainMax, chainCurrent, false);
    }

    /**
     * Sets up the drugs section of the widget
     *
     * @param view    The RemoteViews instance.
     * @param context The application context.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupDrugsSection(RemoteViews view, Context context, SharedPreferences prefs) {
        int drugLevel = prefs.getInt("drug_level", 0);
        String drugString = prefs.getString("drug_string", "");
        view.setViewVisibility(R.id.widget_drugs_box, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_drugs1, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_drugs2, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_drugs3, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_drugs4, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_drugs5, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_drugs_box, View.VISIBLE);

        boolean cooldownTapOpensApp = prefs.getBoolean("cooldown_tap_opens_browser", false);
        PendingIntent drugIntent;
        if (cooldownTapOpensApp) {
            drugIntent = getUniquePendingIntent(context, "DrugClicked", "pdaWidget://drug:clicked", 14);
        } else {
            drugIntent = getUniqueBroadcastPendingIntent(context, Uri.parse("pdaWidget://drug:clicked"), drugString);
        }

        view.setOnClickPendingIntent(R.id.widget_drugs_box, drugIntent);

        switch (drugLevel) {
            case 1:
                view.setViewVisibility(R.id.widget_icon_drugs1, View.VISIBLE);
                break;
            case 2:
                view.setViewVisibility(R.id.widget_icon_drugs2, View.VISIBLE);
                break;
            case 3:
                view.setViewVisibility(R.id.widget_icon_drugs3, View.VISIBLE);
                break;
            case 4:
                view.setViewVisibility(R.id.widget_icon_drugs4, View.VISIBLE);
                break;
            case 5:
                view.setViewVisibility(R.id.widget_icon_drugs5, View.VISIBLE);
                break;
            case 0:
            default:
                view.setViewVisibility(R.id.widget_drugs_box, View.INVISIBLE);
                break;
        }
    }

    /**
     * Sets up the medical section of the widget
     *
     * @param view    The RemoteViews instance.
     * @param context The application context.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupMedicalSection(RemoteViews view, Context context, SharedPreferences prefs) {
        int medicalLevel = prefs.getInt("medical_level", 0);
        String medicalString = prefs.getString("medical_string", "");
        view.setViewVisibility(R.id.widget_medical_box, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_medical1, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_medical2, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_medical3, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_medical4, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_medical5, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_medical_box, View.VISIBLE);

        boolean cooldownTapOpensApp = prefs.getBoolean("cooldown_tap_opens_browser", false);
        PendingIntent medicalIntent;
        if (cooldownTapOpensApp) {
            medicalIntent = getUniquePendingIntent(context, "MedicalClicked", "pdaWidget://medical:clicked", 15);
        } else {
            medicalIntent = getUniqueBroadcastPendingIntent(context, Uri.parse("pdaWidget://medical:clicked"), medicalString);
        }

        view.setOnClickPendingIntent(R.id.widget_medical_box, medicalIntent);

        switch (medicalLevel) {
            case 1:
                view.setViewVisibility(R.id.widget_icon_medical1, View.VISIBLE);
                break;
            case 2:
                view.setViewVisibility(R.id.widget_icon_medical2, View.VISIBLE);
                break;
            case 3:
                view.setViewVisibility(R.id.widget_icon_medical3, View.VISIBLE);
                break;
            case 4:
                view.setViewVisibility(R.id.widget_icon_medical4, View.VISIBLE);
                break;
            case 5:
                view.setViewVisibility(R.id.widget_icon_medical5, View.VISIBLE);
                break;
            case 0:
            default:
                view.setViewVisibility(R.id.widget_medical_box, View.INVISIBLE);
                break;
        }
    }

    /**
     * Sets up the booster section of the widget
     *
     * @param view    The RemoteViews instance.
     * @param context The application context.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupBoosterSection(RemoteViews view, Context context, SharedPreferences prefs) {
        int boosterLevel = prefs.getInt("booster_level", 0);
        String boosterString = prefs.getString("booster_string", "");
        view.setViewVisibility(R.id.widget_booster_box, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_booster1, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_booster2, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_booster3, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_booster4, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_icon_booster5, View.INVISIBLE);
        view.setViewVisibility(R.id.widget_booster_box, View.VISIBLE);

        boolean cooldownTapOpensApp = prefs.getBoolean("cooldown_tap_opens_browser", false);
        PendingIntent boosterIntent;
        if (cooldownTapOpensApp) {
            boosterIntent = getUniquePendingIntent(context, "BoosterClicked", "pdaWidget://booster:clicked", 16);
        } else {
            boosterIntent = getUniqueBroadcastPendingIntent(context, Uri.parse("pdaWidget://booster:clicked"), boosterString);
        }

        view.setOnClickPendingIntent(R.id.widget_booster_box, boosterIntent);

        switch (boosterLevel) {
            case 1:
                view.setViewVisibility(R.id.widget_icon_booster1, View.VISIBLE);
                break;
            case 2:
                view.setViewVisibility(R.id.widget_icon_booster2, View.VISIBLE);
                break;
            case 3:
                view.setViewVisibility(R.id.widget_icon_booster3, View.VISIBLE);
                break;
            case 4:
                view.setViewVisibility(R.id.widget_icon_booster4, View.VISIBLE);
                break;
            case 5:
                view.setViewVisibility(R.id.widget_icon_booster5, View.VISIBLE);
                break;
            case 0:
            default:
                view.setViewVisibility(R.id.widget_booster_box, View.INVISIBLE);
                break;
        }
    }

    /**
     * Sets up the shortcuts section of the widget
     *
     * @param view    The RemoteViews instance.
     * @param context The application context.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupShortcutsSection(RemoteViews view, Context context, SharedPreferences prefs) {
        int shortcutsNumber = prefs.getInt("shortcuts_number", 0);
        if (shortcutsNumber == 0) {
            view.setTextViewText(R.id.widget_shortcuts_empty_text, "No shortcuts configured, add some?");
            view.setViewVisibility(R.id.widget_shortcuts_empty_box, View.VISIBLE);
        } else {
            view.setViewVisibility(R.id.widget_shortcuts_empty_box, View.GONE);
            for (int i = 1; i <= 9; i++) {
                String nameKey = "shortcut" + i + "_name";
                String urlKey = "shortcut" + i + "_url";
                String shortcutName = prefs.getString(nameKey, "");
                String shortcutUrl = prefs.getString(urlKey, "");

                int textViewId = context.getResources().getIdentifier("widget_shortcuts_shortcut" + i + "_text", "id", context.getPackageName());
                if (textViewId == 0) continue; // Skip if the ID is not found

                if (!shortcutName.isEmpty()) {
                    view.setViewVisibility(textViewId, View.VISIBLE);
                    view.setTextViewText(textViewId, shortcutName);
                    PendingIntent shortcutIntent = getUniquePendingIntent(context, "Shortcut" + i + "Clicked",
                            "pdaWidget://shortcut:" + shortcutUrl, 20 + i);
                    view.setOnClickPendingIntent(textViewId, shortcutIntent);
                } else {
                    view.setViewVisibility(textViewId, View.INVISIBLE);
                }
            }
        }
    }

    /**
     * Sets up the error layout of the widget
     *
     * @param view    The RemoteViews instance.
     * @param prefs   SharedPreferences containing user preferences.
     */
    private void setupErrorLayout(RemoteViews view, SharedPreferences prefs) {
        boolean backgroundServiceRunning = prefs.getBoolean("background_active", false);
        boolean errorVisibility = prefs.getBoolean("error_layout_visibility", true);
        int errorVis = (!errorVisibility && backgroundServiceRunning) ? View.GONE : View.VISIBLE;
        view.setViewVisibility(R.id.widget_error_layout, errorVis);

        if (errorVis == View.VISIBLE) {
            String errorMessage = prefs.getString("error_message", "Loading...");
            if (!backgroundServiceRunning) {
                errorMessage = "Open app to initialise (tap icon)\n\nNOTE: the widget can be resized, several layouts are available!\n\n";
            }
            view.setTextViewText(R.id.widget_error_message, errorMessage);
        }
    }

    /**
     * Generates a unique PendingIntent for different actions
     *
     * @param context     The application context.
     * @param action      The action string for the intent.
     * @param uri         The URI string for the intent.
     * @param requestCode The unique request code for the PendingIntent.
     * @return A unique PendingIntent.
     */
    private PendingIntent getUniquePendingIntent(Context context, String action, String uri, int requestCode) {
        Intent intent = new Intent(context, MainActivity.class);
        intent.setAction(action);
        intent.setData(Uri.parse(uri));
        return PendingIntent.getActivity(context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT | getImmutableFlag());
    }

    /**
     * Generates a unique PendingIntent for broadcast actions
     *
     * @param context     The application context.
     * @param uri         The URI string for the intent.
     * @param extra       An extra string to include in the intent.
     * @return PendingIntent for broadcasts > HomeWidgetPackage does not accept unique requestCodes (defaults to 0)
     */
    private PendingIntent getUniqueBroadcastPendingIntent(Context context, Uri uri, String extra) {
        return HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(context, uri, extra);
    }

    /**
     * Retrieves the immutable flag for PendingIntent based on the SDK version.
     * Ensures that the PendingIntent is created with the FLAG_IMMUTABLE flag
     * on Android versions Marshmallow (API level 23) and above. Starting from Android 12
     * (API level 31), it is mandatory to specify the mutability of PendingIntents for security reasons.
     * (<a href="https://developer.android.com/about/versions/12/behavior-changes-12#pending-intent-mutability">)
     *
     * @return The appropriate flag for PendingIntent.
     */
    private int getImmutableFlag() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return PendingIntent.FLAG_IMMUTABLE;
        } else {
            return 0;
        }
    }
}
