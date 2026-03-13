package com.manuito.tornpda.liveupdates

import android.annotation.SuppressLint
import android.app.Notification
import android.content.Context
import android.util.Log
import androidx.core.app.NotificationManagerCompat

class AndroidRacingLiveUpdateAdapter(
    private val context: Context,
    private val tapIntentFactory: LiveUpdateTapIntentFactory,
) : LiveUpdateAdapter, LiveUpdateNotificationReceiver.Listener {

    private val notificationManager = NotificationManagerCompat.from(context)
    private val notificationFactory = RacingLiveUpdateNotificationFactory(context)
    private var listener: LiveUpdateAdapterListener? = null
    private var activeSessionId: String? = null
    private var cachedPayload: LiveUpdatePayload? = null

    init {
        LiveUpdateNotificationReceiver.registerListener(this)
    }

    override fun startOrUpdate(sessionId: String, payload: LiveUpdatePayload): LiveUpdateAdapterResult {
        LiveUpdateNotificationChannel.ensureCreated(context, LiveUpdateActivityType.RACING)
        val isExistingSession = activeSessionId == sessionId && cachedPayload != null
        // Skip re-posting when content is unchanged to avoid a visual flash
        // on IMPORTANCE_HIGH channels when the app resumes
        val contentChanged = !isExistingSession ||
            cachedPayload?.stateIdentifier != payload.stateIdentifier

        activeSessionId = sessionId
        cachedPayload = payload

        Log.d("RacingLU", "Adapter: startOrUpdate phase=${payload.phase} contentChanged=$contentChanged existing=$isExistingSession")
        if (contentChanged) {
            val tapIntent = tapIntentFactory.buildRacingTapIntent(sessionId, payload.stateIdentifier)
            val dismissIntent = LiveUpdateNotificationReceiver.createDismissIntent(context, sessionId)
            notifySurface(sessionId.hashCode(), notificationFactory.build(payload, tapIntent, dismissIntent))

            // Schedule the demotion alarm so the chip converts to a normal
            // notification even if the app is backgrounded or killed
            if (isFinished(payload)) {
                LiveUpdateNotificationReceiver.scheduleFinishedCleanup(
                    context, sessionId, payload.extras,
                )
            }
        }
        RacingLiveUpdateRefreshScheduler.scheduleNextRefresh(context, sessionId, payload)

        listener?.onStatus(
            LiveUpdateStatusEvent(
                sessionId = sessionId,
                status = when {
                    isFinished(payload) -> LiveUpdateLifecycleStatus.ARRIVED
                    isExistingSession -> LiveUpdateLifecycleStatus.UPDATED
                    else -> LiveUpdateLifecycleStatus.STARTED
                },
                surface = LiveUpdateSurface.NOTIFICATION,
            ),
        )

        return LiveUpdateAdapterResult(
            status = if (isExistingSession) LiveUpdateRequestStatus.UPDATED else LiveUpdateRequestStatus.STARTED,
        )
    }

    override fun end(sessionId: String?): LiveUpdateAdapterResult {
        val resolvedId = sessionId ?: activeSessionId
        resolvedId?.let {
            val wasFinished = cachedPayload?.let { p -> isFinished(p) } == true
            if (wasFinished) {
                // Finished: keep notification visible and let the cleanup
                // alarm demote it from chip to normal tray entry
                Log.d("RacingLU", "Adapter: end() skipping cancel — finished notification stays for demotion.")
            } else {
                notificationManager.cancel(it.hashCode())
            }
            RacingLiveUpdateRefreshScheduler.cancelRefresh(context, it)
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
        RacingLiveUpdateRefreshScheduler.cancelRefresh(context, sessionId)
        clearState(sessionId)
    }

    @SuppressLint("MissingPermission")
    private fun notifySurface(notificationId: Int, notification: Notification) {
        notificationManager.notify(notificationId, notification)
    }

    private fun clearState(sessionId: String) {
        if (sessionId == activeSessionId) {
            cachedPayload = null
            activeSessionId = null
        }
    }

    private fun isFinished(payload: LiveUpdatePayload): Boolean = payload.phase.equals("finished", ignoreCase = true)
}
