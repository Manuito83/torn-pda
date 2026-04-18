package com.manuito.tornpda.liveupdates

import android.annotation.SuppressLint
import android.app.Notification
import android.content.Context
import androidx.core.app.NotificationManagerCompat
import kotlinx.coroutines.*

/**
 * Manages the lifecycle and rendering of the travel live update notification
 * Handles periodic updates for progress bar animation and system alarm scheduling
 */
class AndroidTravelLiveUpdateAdapter(
    private val context: Context,
    private val tapIntentFactory: LiveUpdateTapIntentFactory,
    private val contentBuilder: LiveUpdateNotificationContentBuilder = LiveUpdateNotificationContentBuilder(),
) : LiveUpdateAdapter, LiveUpdateNotificationReceiver.Listener {

    private val notificationManager = NotificationManagerCompat.from(context)
    private var listener: LiveUpdateAdapterListener? = null
    private var activeSessionId: String? = null
    private var cachedPayload: LiveUpdatePayload? = null
    private val notificationFactory = TravelLiveUpdateNotificationFactory(context, contentBuilder)

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var updateJob: Job? = null

    init {
        LiveUpdateNotificationReceiver.registerListener(this)
    }

    override fun startOrUpdate(sessionId: String, payload: LiveUpdatePayload): LiveUpdateAdapterResult {
        LiveUpdateNotificationChannel.ensureCreated(context, LiveUpdateActivityType.TRAVEL)
        val isExistingSession = activeSessionId == sessionId && cachedPayload != null
        // Skip re-posting when content is unchanged to avoid a visual flash
        // on IMPORTANCE_HIGH channels when the app resumes
        val contentChanged = !isExistingSession ||
            cachedPayload?.travelIdentifier != payload.travelIdentifier ||
            cachedPayload?.hasArrived != payload.hasArrived

        activeSessionId = sessionId
        cachedPayload = payload

        val tapIntent = tapIntentFactory.buildTravelTapIntent(sessionId, payload.travelIdentifier)
        val dismissIntent = LiveUpdateNotificationReceiver.createDismissIntent(context, sessionId)
        if (contentChanged) {
            val notification = notificationFactory.build(sessionId, payload, tapIntent, dismissIntent)
            notifySurface(sessionId.hashCode(), notification)
        }
        TravelLiveUpdateRefreshScheduler.scheduleNextRefresh(context, sessionId, payload)
        TravelLiveUpdateRefreshScheduler.scheduleArrived(context, sessionId, payload)

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
            TravelLiveUpdateRefreshScheduler.cancelRefresh(context, sessionId)
            TravelLiveUpdateRefreshScheduler.cancelArrived(context, sessionId)
            cachedPayload = null
            activeSessionId = null
        }
    }

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

                val notification = notificationFactory.build(sessionId, current, tapIntent, dismissIntent)
                notifySurface(sessionId.hashCode(), notification)
            }
        }
    }

}
