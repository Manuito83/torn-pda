package com.manuito.tornpda.liveupdates

import android.annotation.SuppressLint
import android.app.Notification
import android.content.Context
import android.os.Build
import android.text.format.DateUtils
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person
import androidx.core.graphics.drawable.IconCompat
import com.manuito.tornpda.R
import kotlinx.coroutines.*
import kotlin.math.max
import kotlin.math.min

/**
 * Manages the lifecycle and rendering of the travel live update notification
 * Handles periodic updates for progress bar animation and system alarm scheduling
 */
class AndroidLiveUpdateAdapter(
    private val context: Context,
    private val tapIntentFactory: LiveUpdateTapIntentFactory,
) : LiveUpdateAdapter, LiveUpdateNotificationReceiver.Listener {

    private val notificationManager = NotificationManagerCompat.from(context)
    private var listener: LiveUpdateAdapterListener? = null
    private var activeSessionId: String? = null
    private var cachedPayload: LiveUpdatePayload? = null
    
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var updateJob: Job? = null

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
        
        // Initiate the update loop to refresh the progress bar
        startUpdateLoop(sessionId, tapIntent, dismissIntent)

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
            updateJob?.cancel()
            cancelArrivedAlarm(sessionId)
            cachedPayload = null
            activeSessionId = null
        }
    }

    /**
     * Returns the appropriate drawable resource ID for the given travel destination
     * Uses plane_left when returning to Torn, plane_right when traveling abroad
     */
    private fun getDestinationIcon(destination: String?): Int {
        return when (destination?.lowercase()) {
            "torn" -> R.drawable.plane_left
            else -> R.drawable.plane_right
        }
    }
    
    /**
     * Starts a coroutine loop to update the notification every minute
     * This ensures the progress bar reflects the current travel status
     */
    private fun startUpdateLoop(
        sessionId: String, 
        tapIntent: android.app.PendingIntent, 
        dismissIntent: android.app.PendingIntent
    ) {
        updateJob?.cancel()
        val payload = cachedPayload ?: return
        
        if (payload.hasArrived) return

        updateJob = scope.launch {
            while (isActive) {
                delay(60_000) 
                
                if (activeSessionId != sessionId) break
                val current = cachedPayload ?: break
                if (current.hasArrived) break
                
                val notification = buildNotification(current, tapIntent, dismissIntent)
                notifySurface(sessionId.hashCode(), notification)
            }
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

        // On Android 15+ build with the framework Builder to set shortCriticalText natively.
        if (Build.VERSION.SDK_INT >= 35) {
            return buildFrameworkNotification(
                payload = payload,
                title = title,
                destination = destination,
                etaText = etaText,
                secondary = secondary,
                extrasBundle = extrasBundle,
                tapIntent = tapIntent,
                dismissIntent = dismissIntent,
            )
        }

        val destinationIcon = getDestinationIcon(payload.currentDestinationDisplayName)
        val builder = NotificationCompat.Builder(context, LiveUpdateNotificationChannel.CHANNEL_ID)
            .setSmallIcon(destinationIcon)
            .setContentTitle("$title $destination")
            .setContentText(etaText)
            .setContentIntent(tapIntent)
            .setDeleteIntent(dismissIntent)
            .setOnlyAlertOnce(true)
            .setOngoing(!payload.hasArrived)
            .setAutoCancel(payload.hasArrived)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setExtras(extrasBundle)

        // Standard BigTextStyle is used for reliability across different Android versions
        builder.setStyle(NotificationCompat.BigTextStyle().bigText("$etaText • $secondary"))
        builder.setCategory(NotificationCompat.CATEGORY_STATUS)

        val progress = computeProgress(payload)
        if (progress != null) {
            builder.setProgress(progress.totalSeconds.toInt(), progress.elapsedSeconds.toInt(), false)
        } else {
            builder.setProgress(0, 0, false)
        }

        val arrivalMillis = (payload.arrivalTimeTimestamp ?: 0L) * 1000
        if (!payload.hasArrived && arrivalMillis > 0) {
            builder.setShowWhen(true)
            builder.setUsesChronometer(true)
            builder.setChronometerCountDown(true)
            builder.setWhen(arrivalMillis)
            
            // Set subtext to assist system in identifying context
            builder.setSubText(context.getString(R.string.live_update_channel_name))
            
            // Enable promoted ongoing (Live Update) when supported (Android 15+); fallback is no-op on older SDKs
            enablePromotedOngoing(builder)

            // Provide a compact status-chip text for Android 15+ surfaces (if available)
            applyShortCriticalText(builder, payload)
            
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
        
        // If arrived, show Arrived label
        if (payload.hasArrived) {
            return context.getString(R.string.live_update_arrived_label)
        }
        
        // Format as local clock time (e.g. 09:53 or 21:53)
        val date = java.util.Date(arrival * 1000)
        val format = android.text.format.DateFormat.getTimeFormat(context)
        val formatted = format.format(date)
        return context.getString(R.string.live_update_eta_pattern, formatted)
    }

    private fun computeProgress(payload: LiveUpdatePayload): ProgressInfo? {
        val arrival = payload.arrivalTimeTimestamp ?: return null
        val departure = payload.departureTimeTimestamp ?: return null
        
        // Calculate progress based on current system time
        val reference = System.currentTimeMillis() / 1000
        val totalSeconds = max(1L, arrival - departure)
        val elapsedSeconds = min(totalSeconds, max(0L, reference - departure))
        return ProgressInfo(totalSeconds, elapsedSeconds)
    }

    private fun applyShortCriticalText(builder: NotificationCompat.Builder, payload: LiveUpdatePayload) {
        val shortText = buildShortCriticalText(payload) ?: return
        // setShortCriticalText is framework-only (API 35+); call reflectively to keep backward compatibility
        try {
            val method = builder.javaClass.getMethod("setShortCriticalText", CharSequence::class.java)
            method.invoke(builder, shortText)
        } catch (_: Exception) {
            // Safely ignore on older devices or when the compat shim lacks the API
        }
    }

    private fun buildShortCriticalText(payload: LiveUpdatePayload): String? {
        if (payload.hasArrived) {
            return context.getString(R.string.live_update_arrived_label)
        }

        val arrival = payload.arrivalTimeTimestamp ?: return null
        val date = java.util.Date(arrival * 1000)
        val format = android.text.format.DateFormat.getTimeFormat(context)
        val formatted = format.format(date)
        // Short hint prefixed with T(Travel), keeps under chip width constraints (~7-8 chars typical)
        return "T $formatted"
    }

    private fun enablePromotedOngoing(builder: NotificationCompat.Builder) {
        try {
            val method = builder.javaClass.getMethod("setRequestPromotedOngoing", Boolean::class.javaPrimitiveType)
            method.invoke(builder, true)
        } catch (_: Exception) {
            // Ignore if not supported by current SDK or compat library
        }
    }

    private fun invokeFrameworkPromotedOngoing(builder: Notification.Builder) {
        try {
            val method = builder.javaClass.getMethod("setRequestPromotedOngoing", Boolean::class.javaPrimitiveType)
            method.invoke(builder, true)
        } catch (_: Exception) {
            // Ignore if not supported on this SDK
        }
    }

    private fun invokeFrameworkShortCriticalText(builder: Notification.Builder, text: CharSequence) {
        try {
            val method = builder.javaClass.getMethod("setShortCriticalText", CharSequence::class.java)
            method.invoke(builder, text)
        } catch (_: Exception) {
            // Ignore if not supported on this SDK
        }
    }

    @SuppressLint("NewApi")
    private fun buildFrameworkNotification(
        payload: LiveUpdatePayload,
        title: String,
        destination: String,
        etaText: String,
        secondary: String,
        extrasBundle: android.os.Bundle,
        tapIntent: android.app.PendingIntent,
        dismissIntent: android.app.PendingIntent,
    ): Notification {
        val arrivalMillis = (payload.arrivalTimeTimestamp ?: 0L) * 1000
        val destinationIcon = getDestinationIcon(payload.currentDestinationDisplayName)
        val builder = Notification.Builder(context, LiveUpdateNotificationChannel.CHANNEL_ID)
            .setSmallIcon(destinationIcon)
            .setContentTitle("$title $destination")
            .setContentText(etaText)
            .setContentIntent(tapIntent)
            .setDeleteIntent(dismissIntent)
            .setOnlyAlertOnce(true)
            .setOngoing(!payload.hasArrived)
            .setAutoCancel(payload.hasArrived)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setExtras(extrasBundle)
            .setCategory(Notification.CATEGORY_STATUS)

        // BigTextStyle
        builder.setStyle(Notification.BigTextStyle().bigText("$etaText • $secondary"))

        // Progress
        val progress = computeProgress(payload)
        if (progress != null) {
            builder.setProgress(progress.totalSeconds.toInt(), progress.elapsedSeconds.toInt(), false)
        }

        if (!payload.hasArrived && arrivalMillis > 0) {
            builder.setShowWhen(true)
            builder.setUsesChronometer(true)
            builder.setChronometerCountDown(true)
            builder.setWhen(arrivalMillis)
            builder.setSubText(context.getString(R.string.live_update_channel_name))
            invokeFrameworkPromotedOngoing(builder)

            buildShortCriticalText(payload)?.let { invokeFrameworkShortCriticalText(builder, it) }

            scheduleArrivedAlarm(payload, arrivalMillis)
        }

        return builder.build()
    }

    private data class ProgressInfo(
        val totalSeconds: Long,
        val elapsedSeconds: Long,
    )
}
