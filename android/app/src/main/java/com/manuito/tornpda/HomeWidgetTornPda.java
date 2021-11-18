package com.manuito.tornpda;

import android.app.Activity;
import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.SharedPreferences;
import android.net.Uri;
import android.widget.RemoteViews;
import es.antonborri.home_widget.HomeWidgetBackgroundIntent;
import es.antonborri.home_widget.HomeWidgetLaunchIntent;
import es.antonborri.home_widget.HomeWidgetPlugin;
import es.antonborri.home_widget.HomeWidgetProvider;


public class HomeWidgetTornPda extends HomeWidgetProvider {
    
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds, SharedPreferences widgetData) {

        for (int widgetId :appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.example_layout);

            // Open App on Widget Click
            PendingIntent pendingIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(context, MainActivity.class, null);
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent);

            // Swap Title Text by calling Dart Code in the Background
            views.setTextViewText(R.id.widget_title, widgetData.getString("title", null) == null ? "Cuac" : widgetData.getString("title", null));

            PendingIntent backgroundIntent = HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(context, Uri.parse("homeWidgetExample://titleClicked"));
            views.setOnClickPendingIntent(R.id.widget_title, backgroundIntent);

            String message = widgetData.getString("message", null);
            views.setTextViewText(R.id.widget_message, message == null ? "Bu" : message);

            // Update
            appWidgetManager.updateAppWidget(widgetId, views);
        }

    }

}