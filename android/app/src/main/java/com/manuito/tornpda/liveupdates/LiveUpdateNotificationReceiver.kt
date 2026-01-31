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
            
            showArrivedNotification(contextNonNull, sessionId, destination)
        }
    }

    private fun showArrivedNotification(context: Context, sessionId: String, destination: String) {
        val channelId = LiveUpdateNotificationChannel.CHANNEL_ID
        
        // Recreate the tap intent to open the app
        val tapIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
            it.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            PendingIntent.getActivity(context, 0, it, PendingIntent.FLAG_IMMUTABLE)
        }

        val destinationIcon = getDestinationIcon(destination)
        val notification = androidx.core.app.NotificationCompat.Builder(context, channelId)
            .setSmallIcon(destinationIcon)
            .setContentTitle("Arrived at $destination")
            .setContentText("Travel completed")
            .setContentIntent(tapIntent)
            .setAutoCancel(true)
            .setPriority(androidx.core.app.NotificationCompat.PRIORITY_HIGH)
            .setUsesChronometer(false)
            .setShowWhen(true)
            .setWhen(System.currentTimeMillis())
            .build()

        androidx.core.app.NotificationManagerCompat.from(context).notify(sessionId.hashCode(), notification)
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

        fun createArrivedIntent(context: Context, sessionId: String, destination: String): PendingIntent {
            val intent = Intent(context, LiveUpdateNotificationReceiver::class.java).apply {
                action = ACTION_ARRIVED
                putExtra(EXTRA_SESSION_ID, sessionId)
                putExtra(EXTRA_DESTINATION, destination)
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            // Use a distinct request code to avoid collision with other intents
            val requestCode = sessionId.hashCode() + 1
            return PendingIntent.getBroadcast(context, requestCode, intent, flags)
        }
    }
}
