package com.manuito.tornpda.liveupdates

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.content.getSystemService
import com.manuito.tornpda.R

object LiveUpdateNotificationChannel {
    const val TRAVEL_CHANNEL_ID = "live_updates_travel"
    const val RACING_CHANNEL_ID = "live_updates_racing"

    fun ensureCreated(context: Context, activityType: LiveUpdateActivityType) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService<NotificationManager>() ?: return
        val channelId = channelIdFor(activityType)

        // Migrate existing HIGH-importance channel down to DEFAULT to stop heads-up re-popping
        val existing = manager.getNotificationChannel(channelId)
        if (existing != null) {
            if (existing.importance == NotificationManager.IMPORTANCE_HIGH) {
                manager.deleteNotificationChannel(channelId)
            } else {
                return
            }
        }

        val channel = NotificationChannel(
            channelId,
            channelName(context, activityType),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = channelDescription(context, activityType)
            enableVibration(false)
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            // Configure channel to be silent
            setSound(null, null)
        }
        manager.createNotificationChannel(channel)
    }

    fun channelIdFor(activityType: LiveUpdateActivityType): String {
        return when (activityType) {
            LiveUpdateActivityType.TRAVEL -> TRAVEL_CHANNEL_ID
            LiveUpdateActivityType.RACING -> RACING_CHANNEL_ID
        }
    }

    private fun channelName(context: Context, activityType: LiveUpdateActivityType): String {
        return when (activityType) {
            LiveUpdateActivityType.TRAVEL -> context.getString(R.string.travel_live_update_channel_name)
            LiveUpdateActivityType.RACING -> context.getString(R.string.racing_live_update_channel_name)
        }
    }

    private fun channelDescription(context: Context, activityType: LiveUpdateActivityType): String {
        return when (activityType) {
            LiveUpdateActivityType.TRAVEL -> context.getString(R.string.travel_live_update_channel_description)
            LiveUpdateActivityType.RACING -> context.getString(R.string.racing_live_update_channel_description)
        }
    }
}
