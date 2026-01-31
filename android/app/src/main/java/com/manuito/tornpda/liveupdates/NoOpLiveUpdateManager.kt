package com.manuito.tornpda.liveupdates

class NoOpLiveUpdateManager : LiveUpdateManager {

    private val listeners = mutableSetOf<LiveUpdateManagerListener>()

    override fun startOrUpdate(payload: Map<String, Any?>): LiveUpdateStartResult {
        return LiveUpdateStartResult(
            status = LiveUpdateRequestStatus.UNSUPPORTED,
            reason = LiveUpdateUnsupportedReason.API_TOO_OLD,
        )
    }

    override fun end(sessionId: String?): LiveUpdateEndResult {
        return LiveUpdateEndResult(success = true)
    }

    override fun isAnyActive(): Boolean = false

    override fun getCapabilitySnapshot(): LiveUpdateCapabilitySnapshot? {
        return LiveUpdateCapabilitySnapshot(
            supportedApi = false,
            oemCapsule = false,
            notificationsEnabled = false,
            batteryOptimized = true,
            vendor = "unknown",
        )
    }

    override fun addListener(listener: LiveUpdateManagerListener) {
        listeners.add(listener)
    }

    override fun removeListener(listener: LiveUpdateManagerListener) {
        listeners.remove(listener)
    }
}
