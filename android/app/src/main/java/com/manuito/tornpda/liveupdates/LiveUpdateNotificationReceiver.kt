package com.manuito.tornpda.liveupdates

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.util.concurrent.CopyOnWriteArraySet

class LiveUpdateNotificationReceiver : BroadcastReceiver() {

    interface Listener {
        fun onNotificationDismissed(sessionId: String)
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == ACTION_DISMISSED) {
            val sessionId = intent.getStringExtra(EXTRA_SESSION_ID) ?: return
            listeners.forEach { it.onNotificationDismissed(sessionId) }
        } else if (intent?.action == ACTION_ARRIVED) {
            val contextNonNull = context ?: return
            val sessionId = intent.getStringExtra(EXTRA_SESSION_ID) ?: return
            val destination = intent.getStringExtra(EXTRA_DESTINATION) ?: "Unknown"
            val origin = intent.getStringExtra(EXTRA_ORIGIN)
            val earliestReturnTs = if (intent.hasExtra(EXTRA_EARLIEST_RETURN_TS)) {
                intent.getLongExtra(EXTRA_EARLIEST_RETURN_TS, 0L)
            } else null

            showArrivedNotification(contextNonNull, sessionId, destination, origin, earliestReturnTs)
        }
    }

    private fun showArrivedNotification(
        context: Context,
        sessionId: String,
        destination: String,
        origin: String?,
        earliestReturnTs: Long?,
    ) {
        val channelId = LiveUpdateNotificationChannel.CHANNEL_ID

        // Recreate the tap intent to open the app
        val tapIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
            it.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            PendingIntent.getActivity(context, 0, it, PendingIntent.FLAG_IMMUTABLE)
        }

        val destinationIcon = getDestinationIcon(destination)
        val timeFormat = android.text.format.DateFormat.getTimeFormat(context)
        val nowFormatted = timeFormat.format(java.util.Date())

        val arrivedTitle = context.getString(com.manuito.tornpda.R.string.live_update_arrived_in_pattern, destination)
        val arrivedContentText = context.getString(com.manuito.tornpda.R.string.live_update_arrived_at_pattern, nowFormatted)

        val route = if (origin != null) {
            context.getString(com.manuito.tornpda.R.string.live_update_notification_secondary, origin, destination)
        } else null

        val earliestReturnText = if (earliestReturnTs != null && earliestReturnTs > 0) {
            val returnFormatted = timeFormat.format(java.util.Date(earliestReturnTs * 1000))
            context.getString(com.manuito.tornpda.R.string.live_update_earliest_return_pattern, returnFormatted)
        } else null

        val bigTextLines = buildList {
            add(arrivedContentText)
            route?.let { add(it) }
            earliestReturnText?.let { add(it) }
        }

        val builder = androidx.core.app.NotificationCompat.Builder(context, channelId)
            .setSmallIcon(destinationIcon)
            .setContentTitle(arrivedTitle)
            .setContentText(arrivedContentText)
            .setContentIntent(tapIntent)
            .setAutoCancel(true)
            .setPriority(androidx.core.app.NotificationCompat.PRIORITY_HIGH)
            .setUsesChronometer(false)
            .setShowWhen(true)
            .setWhen(System.currentTimeMillis())
            .setStyle(
                androidx.core.app.NotificationCompat.BigTextStyle()
                    .bigText(bigTextLines.joinToString("\n"))
            )

        route?.let { builder.setSubText(it) }

        androidx.core.app.NotificationManagerCompat.from(context).notify(sessionId.hashCode(), builder.build())
    }

    /**
     * Returns the appropriate drawable resource ID for the given travel destination
     * Uses plane_left when returning to Torn, plane_right when traveling abroad
     */
    private fun getDestinationIcon(destination: String?): Int {
        return when (destination?.lowercase()) {
            "torn" -> com.manuito.tornpda.R.drawable.plane_left
            else -> com.manuito.tornpda.R.drawable.plane_right
        }
    }

    companion object {
        private const val ACTION_DISMISSED = "com.manuito.tornpda.liveupdates.ACTION_NOTIFICATION_DISMISSED"
        private const val ACTION_ARRIVED = "com.manuito.tornpda.liveupdates.ACTION_NOTIFICATION_ARRIVED"
        private const val EXTRA_SESSION_ID = "extra_session_id"
        private const val EXTRA_DESTINATION = "extra_destination"
        private const val EXTRA_ORIGIN = "extra_origin"
        private const val EXTRA_EARLIEST_RETURN_TS = "extra_earliest_return_ts"
        
        private val listeners = CopyOnWriteArraySet<Listener>()

        fun registerListener(listener: Listener) {
            listeners.add(listener)
        }

        fun unregisterListener(listener: Listener) {
            listeners.remove(listener)
        }

        fun createDismissIntent(context: Context, sessionId: String): PendingIntent {
            val intent = Intent(context, LiveUpdateNotificationReceiver::class.java).apply {
                action = ACTION_DISMISSED
                putExtra(EXTRA_SESSION_ID, sessionId)
            }
            val flags = PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val requestCode = sessionId.hashCode()
            return PendingIntent.getBroadcast(context, requestCode, intent, flags)
        }

        fun createArrivedIntent(
            context: Context,
            sessionId: String,
            destination: String,
            origin: String? = null,
            earliestReturnTimestamp: Long? = null,
        ): PendingIntent {
            val intent = Intent(context, LiveUpdateNotificationReceiver::class.java).apply {
                action = ACTION_ARRIVED
                putExtra(EXTRA_SESSION_ID, sessionId)
                putExtra(EXTRA_DESTINATION, destination)
                origin?.let { putExtra(EXTRA_ORIGIN, it) }
                earliestReturnTimestamp?.let { putExtra(EXTRA_EARLIEST_RETURN_TS, it) }
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            // Use a distinct request code to avoid collision with other intents
            val requestCode = sessionId.hashCode() + 1
            return PendingIntent.getBroadcast(context, requestCode, intent, flags)
        }
    }
}
