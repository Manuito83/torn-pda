package com.manuito.tornpda;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.SizeF;
import android.view.View;
import android.widget.RemoteViews;

import androidx.collection.ArrayMap;

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
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds,
            SharedPreferences widgetData) {

        for (int widgetId : appWidgetIds) {
            createRemoteViews(context, appWidgetManager, widgetId);
        }
    }

    // Creates the RemoteViews for the given size
    private RemoteViews createRemoteViews(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
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

        RemoteViews remoteViews = null;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            remoteViews = new RemoteViews(viewMapping);
        } else {
            // Old SDK do not get customization
            remoteViews = new RemoteViews(context.getPackageName(), R.layout.bars_layout);
            remoteViews = loadWidgetData(remoteViews, context);
        }

        appWidgetManager.updateAppWidget(appWidgetId, remoteViews);
        return remoteViews;
    }

    // Assigns data fields
    public RemoteViews loadWidgetData(RemoteViews view, Context context) {
        SharedPreferences prefs = context.getSharedPreferences("HomeWidgetPreferences", context.MODE_PRIVATE);

        // ## TAPS ##
        // Open App on Widget Click
        PendingIntent pendingIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class,
                null);
        view.setOnClickPendingIntent(R.id.widget_container, pendingIntent);
        view.setOnClickPendingIntent(R.id.widget_error_message, pendingIntent);

        // ## MAIN LAYOUT ##
        // Main layout visibility
        boolean main_visibility = prefs.getBoolean("main_layout_visibility", false);
        int mainVis = View.VISIBLE;
        if (!main_visibility) {
            mainVis = View.GONE;
        }
        view.setViewVisibility(R.id.widget_main_layout, mainVis);

        // Assign Title by calling Dart Code in the Background
        view.setTextViewText(R.id.widget_title, prefs.getString("title", "-"));

        // Assign click callback from Title
        PendingIntent backgroundIntent = HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(context,
                Uri.parse("homeWidgetExample://titleClicked"));
        view.setOnClickPendingIntent(R.id.widget_title, backgroundIntent);

        // Assign Message
        String message = prefs.getString("message", "-");
        view.setTextViewText(R.id.widget_message, message);

        // Assign Energy
        String energy = prefs.getString("energy_text", "-");
        view.setTextViewText(R.id.widget_energy_text, energy);

        // Assign Energy Progress Bar
        int energy_current = prefs.getInt("energy_current", 0);
        int energy_max = prefs.getInt("energy_max", 100);
        view.setProgressBar(R.id.widget_energy_bar, energy_max, energy_current, false);

        // Assign Nerve
        String nerve = prefs.getString("nerve_text", "-");
        view.setTextViewText(R.id.widget_nerve_text, nerve);

        // Assign Nerve Progress Bar
        int nerve_current = prefs.getInt("nerve_current", 0);
        int nerve_max = prefs.getInt("nerve_max", 50);
        view.setProgressBar(R.id.widget_nerve_bar, nerve_max, nerve_current, false);

        // ## ERROR LAYOUT ##
        // Error layout visibility
        boolean errorVisibility = prefs.getBoolean("error_layout_visibility", true);
        int errorVis= View.VISIBLE;
        if (!errorVisibility) {
            errorVis = View.GONE;
        }
        view.setViewVisibility(R.id.widget_error_layout, errorVis);

        // Assign error message text
        String errorMessage = prefs.getString("error_message", "Loading...");
        view.setTextViewText(R.id.widget_error_message, errorMessage);

        // Assign click callback from reload icon
        PendingIntent reloadIntent = HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(context,
                Uri.parse("homeWidgetExample://reloadClicked"));
        view.setOnClickPendingIntent(R.id.widget_icon_reload, reloadIntent);

        return view;
    }

}