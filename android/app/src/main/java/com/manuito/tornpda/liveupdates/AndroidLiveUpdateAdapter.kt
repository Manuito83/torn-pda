package com.manuito.tornpda.liveupdates

import android.annotation.SuppressLint
import android.app.Notification
import android.content.Context
import android.text.format.DateUtils
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.manuito.tornpda.R
import kotlin.math.max
import kotlin.math.min

/**
 * Renders travel countdowns on Android surfaces (lock screen, notification shade, OEM capsules)
 * using high-priority notifications and dismissal callbacks.
 */
class AndroidLiveUpdateAdapter(
    private val context: Context,
    private val tapIntentFactory: LiveUpdateTapIntentFactory,
) : LiveUpdateAdapter, LiveUpdateNotificationReceiver.Listener {

    private val notificationManager = NotificationManagerCompat.from(context)
    private var listener: LiveUpdateAdapterListener? = null
    private var activeSessionId: String? = null
    private var cachedPayload: LiveUpdatePayload? = null

    init {
        LiveUpdateNotificationReceiver.registerListener(this)
    }

    override fun startOrUpdate(sessionId: String, payload: LiveUpdatePayload): LiveUpdateAdapterResult {
        LiveUpdateNotificationChannel.ensureCreated(context)
        val isExistingSession = activeSessionId == sessionId && cachedPayload != null

        activeSessionId = sessionId
        cachedPayload = payload

        val tapIntent = tapIntentFactory.buildTravelTapIntent(sessionId, payload.travelIdentifier)
        val dismissIntent = LiveUpdateNotificationReceiver.createDismissIntent(context, sessionId)
        val notification = buildNotification(payload, tapIntent, dismissIntent)
        notifySurface(sessionId.hashCode(), notification)

        val eventStatus = when {
            payload.hasArrived -> LiveUpdateLifecycleStatus.ARRIVED
            isExistingSession -> LiveUpdateLifecycleStatus.UPDATED
            else -> LiveUpdateLifecycleStatus.STARTED
        }

        listener?.onStatus(
            LiveUpdateStatusEvent(
                sessionId = sessionId,
                status = eventStatus,
                surface = LiveUpdateSurface.NOTIFICATION,
            ),
        )

        val adapterStatus = if (isExistingSession) {
            LiveUpdateRequestStatus.UPDATED
        } else {
            LiveUpdateRequestStatus.STARTED
        }

        return LiveUpdateAdapterResult(status = adapterStatus)
    }

    override fun end(sessionId: String?): LiveUpdateAdapterResult {
        val resolvedId = sessionId ?: activeSessionId
        resolvedId?.let {
            notificationManager.cancel(it.hashCode())
            clearState(it)
        }
        return LiveUpdateAdapterResult(status = LiveUpdateRequestStatus.UPDATED)
    }

    override fun isActivityActive(): Boolean = cachedPayload != null

    override fun setListener(listener: LiveUpdateAdapterListener?) {
        this.listener = listener
    }

    override fun onNotificationDismissed(sessionId: String) {
        if (sessionId != activeSessionId) return
        listener?.onStatus(
            LiveUpdateStatusEvent(
                sessionId = sessionId,
                status = LiveUpdateLifecycleStatus.DISMISSED,
                surface = LiveUpdateSurface.NOTIFICATION,
            ),
        )
        clearState(sessionId)
    }

    @SuppressLint("MissingPermission")
    private fun notifySurface(notificationId: Int, notification: Notification) {
        notificationManager.notify(notificationId, notification)
    }

    private fun clearState(sessionId: String) {
        if (sessionId == activeSessionId) {
            cancelArrivedAlarm(sessionId)
            cachedPayload = null
            activeSessionId = null
        }
    }

    private fun buildNotification(
        payload: LiveUpdatePayload,
        tapIntent: android.app.PendingIntent,
        dismissIntent: android.app.PendingIntent,
    ): Notification {
        val destination = payload.currentDestinationDisplayName ?: context.getString(R.string.live_update_destination_unknown)
        val origin = payload.originDisplayName ?: context.getString(R.string.live_update_destination_unknown)
        val title = payload.activityStateTitle ?: context.getString(R.string.live_update_channel_name)
        val etaText = formatEta(payload)
        val secondary = context.getString(R.string.live_update_notification_secondary, origin, destination)

        val extrasBundle = android.os.Bundle()
        payload.extras.forEach { (key, value) ->
            when (value) {
                is String -> extrasBundle.putString(key, value)
                is Boolean -> extrasBundle.putBoolean(key, value)
                is Int -> extrasBundle.putInt(key, value)
                is Long -> extrasBundle.putLong(key, value)
                is Double -> extrasBundle.putDouble(key, value)
            }
        }

        val builder = NotificationCompat.Builder(context, LiveUpdateNotificationChannel.CHANNEL_ID)
            .setSmallIcon(R.drawable.notification_travel)
            .setContentTitle("$title $destination")
            .setContentText(etaText)
            .setStyle(NotificationCompat.BigTextStyle().bigText("$etaText • $secondary"))
            .setContentIntent(tapIntent)
            .setDeleteIntent(dismissIntent)
            .setOnlyAlertOnce(true)
            .setOngoing(!payload.hasArrived)
            .setAutoCancel(payload.hasArrived)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setExtras(extrasBundle)

        val progress = computeProgress(payload)
        if (progress != null) {
            builder.setProgress(progress.totalSeconds.toInt(), progress.elapsedSeconds.toInt(), false)
        } else {
            builder.setProgress(0, 0, false)
        }

        val arrivalMillis = (payload.arrivalTimeTimestamp ?: 0L) * 1000
        if (!payload.hasArrived && arrivalMillis > 0) {
            builder.setUsesChronometer(true)
            builder.setChronometerCountDown(true)
            builder.setWhen(arrivalMillis)
            
            // Schedule "Arrived" update
            scheduleArrivedAlarm(payload, arrivalMillis)
        }

        return builder.build()
    }

    private fun scheduleArrivedAlarm(payload: LiveUpdatePayload, arrivalMillis: Long) {
        val sessionId = activeSessionId ?: return
        val destination = payload.currentDestinationDisplayName ?: context.getString(R.string.live_update_destination_unknown)
        
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? android.app.AlarmManager
        val intent = LiveUpdateNotificationReceiver.createArrivedIntent(context, sessionId, destination)
        
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            if (alarmManager?.canScheduleExactAlarms() == true) {
                alarmManager.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, arrivalMillis, intent)
            } else {
                alarmManager?.setAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, arrivalMillis, intent)
            }
        } else {
            alarmManager?.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, arrivalMillis, intent)
        }
    }

    private fun cancelArrivedAlarm(sessionId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? android.app.AlarmManager
        // We need a dummy destination to recreate the same PendingIntent structure for matching
        val intent = LiveUpdateNotificationReceiver.createArrivedIntent(context, sessionId, "dummy")
        alarmManager?.cancel(intent)
    }

    private fun formatEta(payload: LiveUpdatePayload): String {
        val arrival = payload.arrivalTimeTimestamp ?: return context.getString(R.string.live_update_unknown_eta)
        val reference = payload.currentServerTimestamp ?: (System.currentTimeMillis() / 1000)
        val remainingSeconds = arrival - reference
        return if (remainingSeconds <= 0 || payload.hasArrived) {
            context.getString(R.string.live_update_arrived_label)
        } else {
            val formatted = DateUtils.formatElapsedTime(remainingSeconds)
            context.getString(R.string.live_update_eta_pattern, formatted)
        }
    }

    private fun computeProgress(payload: LiveUpdatePayload): ProgressInfo? {
        val arrival = payload.arrivalTimeTimestamp ?: return null
        val departure = payload.departureTimeTimestamp ?: return null
        val reference = payload.currentServerTimestamp ?: (System.currentTimeMillis() / 1000)
        val totalSeconds = max(1L, arrival - departure)
        val elapsedSeconds = min(totalSeconds, max(0L, reference - departure))
        return ProgressInfo(totalSeconds, elapsedSeconds)
    }

    private data class ProgressInfo(
        val totalSeconds: Long,
        val elapsedSeconds: Long,
    )
}
