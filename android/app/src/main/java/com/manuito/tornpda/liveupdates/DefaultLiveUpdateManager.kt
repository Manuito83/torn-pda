package com.manuito.tornpda.liveupdates

import android.util.Log
import java.util.UUID

class DefaultLiveUpdateManager(
    private val adapter: LiveUpdateAdapter,
    private val eligibilityProvider: LiveUpdateEligibilityProvider,
    private val sessionStore: LiveUpdateSessionStore,
    private val sessionIdProvider: () -> String = { UUID.randomUUID().toString() },
) : LiveUpdateManager, LiveUpdateAdapterListener {

    private val lock = Any()
    private val listeners = mutableSetOf<LiveUpdateManagerListener>()
    private var capabilityMonitor: LiveUpdateCapabilityMonitor? = null

    init {
        adapter.setListener(this)
    }

    override fun startOrUpdate(payload: Map<String, Any?>): LiveUpdateStartResult = synchronized(lock) {
        val parsedPayload = LiveUpdatePayload.fromMap(payload)
        if (!parsedPayload.isValid) {
            Log.w(TAG, "Received invalid Live Update payload: $payload")
            return@synchronized LiveUpdateStartResult(
                status = LiveUpdateRequestStatus.ERROR,
                reason = LiveUpdateUnsupportedReason.INTERNAL_ERROR,
                errorMessage = "Missing arrival/departure timestamps",
            )
        }

        val eligibility = eligibilityProvider.evaluate()
        notifyCapability(eligibility.snapshot)

        if (!eligibility.eligible) {
            return@synchronized LiveUpdateStartResult(
                status = LiveUpdateRequestStatus.UNSUPPORTED,
                reason = eligibility.reason,
                capabilitySnapshot = eligibility.snapshot,
            )
        }

        val now = System.currentTimeMillis()
        val existingSession = sessionStore.current()
        val sessionId = existingSession?.sessionId ?: sessionIdProvider()
        sessionStore.markActive(
            LiveUpdateSessionState(
                sessionId = sessionId,
                travelIdentifier = parsedPayload.travelIdentifier,
                startedAtMs = existingSession?.startedAtMs ?: now,
                lastUpdatedAtMs = now,
            ),
        )

        val adapterResult = adapter.startOrUpdate(sessionId, parsedPayload)
        if (adapterResult.status == LiveUpdateRequestStatus.UNSUPPORTED) {
            sessionStore.clear(sessionId)
            return@synchronized LiveUpdateStartResult(
                status = LiveUpdateRequestStatus.UNSUPPORTED,
                reason = adapterResult.reason ?: LiveUpdateUnsupportedReason.UNKNOWN,
                capabilitySnapshot = eligibility.snapshot,
                errorMessage = adapterResult.errorMessage,
            )
        }

        if (adapterResult.status == LiveUpdateRequestStatus.ERROR) {
            sessionStore.clear(sessionId)
            return@synchronized LiveUpdateStartResult(
                status = LiveUpdateRequestStatus.ERROR,
                reason = adapterResult.reason,
                capabilitySnapshot = eligibility.snapshot,
                errorMessage = adapterResult.errorMessage,
            )
        }

        notifyStatus(
            LiveUpdateStatusEvent(
                sessionId = sessionId,
                status = mapToLifecycle(adapterResult.status),
            ),
        )

        LiveUpdateStartResult(
            status = adapterResult.status,
            sessionId = sessionId,
            capabilitySnapshot = eligibility.snapshot,
            reason = adapterResult.reason,
            errorMessage = adapterResult.errorMessage,
        )
    }

    override fun end(sessionId: String?): LiveUpdateEndResult = synchronized(lock) {
        val resolvedSessionId = sessionId ?: sessionStore.current()?.sessionId
        val adapterResult = adapter.end(resolvedSessionId)
        val success = adapterResult.status != LiveUpdateRequestStatus.ERROR
        if (success) {
            sessionStore.clear(resolvedSessionId)
            notifyStatus(
                LiveUpdateStatusEvent(
                    sessionId = resolvedSessionId,
                    status = LiveUpdateLifecycleStatus.ENDED,
                ),
            )
        }
        LiveUpdateEndResult(
            success = success,
            reason = adapterResult.reason,
            errorMessage = adapterResult.errorMessage,
        )
    }

    override fun isAnyActive(): Boolean {
        return sessionStore.isActive() || adapter.isActivityActive()
    }

    override fun getCapabilitySnapshot(): LiveUpdateCapabilitySnapshot? {
        val cached = eligibilityProvider.latestSnapshot()
        if (cached != null) return cached
        val result = eligibilityProvider.evaluate()
        notifyCapability(result.snapshot)
        return result.snapshot
    }

    override fun addListener(listener: LiveUpdateManagerListener) {
        listeners.add(listener)
    }

    override fun removeListener(listener: LiveUpdateManagerListener) {
        listeners.remove(listener)
    }

    override fun onStatus(event: LiveUpdateStatusEvent) {
        notifyStatus(event)
        if (event.status == LiveUpdateLifecycleStatus.DISMISSED ||
            event.status == LiveUpdateLifecycleStatus.TIMEOUT ||
            event.status == LiveUpdateLifecycleStatus.ENDED
        ) {
            sessionStore.clear(event.sessionId)
        }
    }

    fun onCapability(snapshot: LiveUpdateCapabilitySnapshot) {
        notifyCapability(snapshot)
    }

    fun attachCapabilityMonitor(monitor: LiveUpdateCapabilityMonitor) {
        capabilityMonitor?.stop()
        capabilityMonitor = monitor
        monitor.start()
    }

    private fun notifyStatus(event: LiveUpdateStatusEvent) {
        listeners.toList().forEach { it.onStatus(event) }
    }

    private fun notifyCapability(snapshot: LiveUpdateCapabilitySnapshot) {
        listeners.toList().forEach { it.onCapability(snapshot) }
    }

    private fun mapToLifecycle(status: LiveUpdateRequestStatus): LiveUpdateLifecycleStatus {
        return when (status) {
            LiveUpdateRequestStatus.STARTED -> LiveUpdateLifecycleStatus.STARTED
            LiveUpdateRequestStatus.UPDATED -> LiveUpdateLifecycleStatus.UPDATED
            LiveUpdateRequestStatus.UNSUPPORTED -> LiveUpdateLifecycleStatus.DISMISSED
            LiveUpdateRequestStatus.ERROR -> LiveUpdateLifecycleStatus.DISMISSED
        }
    }

    companion object {
        private const val TAG = "DefaultLiveUpdateMgr"
    }
}
