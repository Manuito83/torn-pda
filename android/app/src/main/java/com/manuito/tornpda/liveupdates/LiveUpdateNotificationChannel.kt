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

    // One card per feature: a fixed id makes a new session replace the old
    // card instead of posting a second one next to it
    const val TRAVEL_NOTIFICATION_ID = 610001
    const val RACING_NOTIFICATION_ID = 610002

    fun ensureCreated(context: Context, activityType: LiveUpdateActivityType) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService<NotificationManager>() ?: return
        val channelId = channelIdFor(activityType)

        // Migrate HIGH-importance channels down to DEFAULT; HIGH re-popped heads-up on every refresh.
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

    fun notificationIdFor(activityType: LiveUpdateActivityType): Int {
        return when (activityType) {
            LiveUpdateActivityType.TRAVEL -> TRAVEL_NOTIFICATION_ID
            LiveUpdateActivityType.RACING -> RACING_NOTIFICATION_ID
        }
    }

    /**
     * Clears cards that older builds posted on this channel under session-derived
     * ids. Only touches our own channel, everything else is left alone.
     */
    fun sweepForeignIds(context: Context, activityType: LiveUpdateActivityType) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService<NotificationManager>() ?: return
        val channelId = channelIdFor(activityType)
        val keepId = notificationIdFor(activityType)
        manager.activeNotifications
            .filter { it.notification.channelId == channelId && it.id != keepId }
            .forEach { manager.cancel(it.tag, it.id) }
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
