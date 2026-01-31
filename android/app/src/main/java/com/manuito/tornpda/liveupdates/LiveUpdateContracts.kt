package com.manuito.tornpda.liveupdates

enum class LiveUpdateRequestStatus(val wireName: String) {
    STARTED("started"),
    UPDATED("updated"),
    UNSUPPORTED("unsupported"),
    ERROR("error");

    companion object {
        fun fromWireName(value: String?): LiveUpdateRequestStatus {
            return values().firstOrNull { it.wireName == value } ?: STARTED
        }
    }
}

enum class LiveUpdateUnsupportedReason(val wireName: String) {
    API_TOO_OLD("API_TOO_OLD"),
    OEM_UNAVAILABLE("OEM_UNAVAILABLE"),
    PERMISSION_DENIED("PERMISSION_DENIED"),
    BATTERY_RESTRICTED("BATTERY_RESTRICTED"),
    INTERNAL_ERROR("INTERNAL_ERROR"),
    UNKNOWN("UNKNOWN");
}

enum class LiveUpdateLifecycleStatus(val wireName: String) {
    STARTED("started"),
    UPDATED("updated"),
    ARRIVED("arrived"),
    TIMEOUT("timeout"),
    DISMISSED("dismissed"),
    ENDED("ended");
}

enum class LiveUpdateSurface(val wireName: String) {
    LOCKSCREEN("lockscreen"),
    SHADE("shade"),
    CAPSULE("capsule"),
    NOTIFICATION("notification"),
    UNKNOWN("unknown");
}

data class LiveUpdateCapabilitySnapshot(
    val supportedApi: Boolean,
    val oemCapsule: Boolean,
    val notificationsEnabled: Boolean,
    val batteryOptimized: Boolean,
    val vendor: String,
    val timestampMs: Long? = null,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "supportedApi" to supportedApi,
        "oemCapsule" to oemCapsule,
        "notificationsEnabled" to notificationsEnabled,
        "batteryOptimized" to batteryOptimized,
        "vendor" to vendor,
        "timestamp" to timestampMs,
    )
}

data class LiveUpdateStartResult(
    val status: LiveUpdateRequestStatus,
    val sessionId: String? = null,
    val capabilitySnapshot: LiveUpdateCapabilitySnapshot? = null,
    val reason: LiveUpdateUnsupportedReason? = null,
    val errorMessage: String? = null,
) {
    fun toMap(): Map<String, Any?> = buildMap {
        put("status", status.wireName)
        sessionId?.let { put("sessionId", it) }
        capabilitySnapshot?.let { put("capabilitySnapshot", it.toMap()) }
        reason?.let { put("reason", it.wireName) }
        errorMessage?.let { put("errorMessage", it) }
    }
}

data class LiveUpdateEndResult(
    val success: Boolean,
    val reason: LiveUpdateUnsupportedReason? = null,
    val errorMessage: String? = null,
) {
    fun toMap(): Map<String, Any?> = buildMap {
        put("success", success)
        reason?.let { put("reason", it.wireName) }
        errorMessage?.let { put("errorMessage", it) }
    }
}

data class LiveUpdateStatusEvent(
    val sessionId: String? = null,
    val status: LiveUpdateLifecycleStatus = LiveUpdateLifecycleStatus.STARTED,
    val surface: LiveUpdateSurface = LiveUpdateSurface.UNKNOWN,
    val reason: LiveUpdateUnsupportedReason? = null,
) {
    fun toMap(): Map<String, Any?> = buildMap {
        sessionId?.let { put("sessionId", it) }
        put("status", status.wireName)
        put("surface", surface.wireName)
        reason?.let { put("reason", it.wireName) }
    }
}

interface LiveUpdateManagerListener {
    fun onStatus(event: LiveUpdateStatusEvent)
    fun onCapability(snapshot: LiveUpdateCapabilitySnapshot)
}

interface LiveUpdateManager {
    fun startOrUpdate(payload: Map<String, Any?>): LiveUpdateStartResult
    fun end(sessionId: String?): LiveUpdateEndResult
    fun isAnyActive(): Boolean
    fun getCapabilitySnapshot(): LiveUpdateCapabilitySnapshot?
    fun addListener(listener: LiveUpdateManagerListener)
    fun removeListener(listener: LiveUpdateManagerListener)
}

interface LiveUpdateEventEmitter {
    fun emitStatus(payload: Map<String, Any?>)
    fun emitCapability(payload: Map<String, Any?>)
}

object LiveUpdateIntentExtras {
    const val EXTRA_TARGET_ROUTE = "live_update_target_route"
    const val EXTRA_ENTRY_POINT = "live_update_entry_point"
    const val EXTRA_SESSION_ID = "live_update_session_id"
    const val EXTRA_TRAVEL_IDENTIFIER = "live_update_travel_identifier"
    const val ROUTE_TRAVEL = "travel"
    const val ENTRY_POINT_TRAVEL = "live_update_travel"
    const val ACTION_TRAVEL_LIVE_UPDATE = "com.manuito.tornpda.action.TRAVEL_LIVE_UPDATE"
}
