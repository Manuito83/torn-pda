package com.manuito.tornpda.liveupdates

import android.content.Context
import android.content.SharedPreferences

interface LiveUpdateCapabilityCache {
    fun save(snapshot: LiveUpdateCapabilitySnapshot)
    fun load(): LiveUpdateCapabilitySnapshot?
}

/**
 * Persists the most recent capability snapshot and session metadata so Flutter can access it
 * even after the process restarts.
 */
class LiveUpdateCapabilityStore(context: Context) : LiveUpdateCapabilityCache {

    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    override fun save(snapshot: LiveUpdateCapabilitySnapshot) {
        prefs.edit().apply {
            putBoolean(KEY_SUPPORTED_API, snapshot.supportedApi)
            putBoolean(KEY_OEM_CAPSULE, snapshot.oemCapsule)
            putBoolean(KEY_NOTIFICATIONS_ENABLED, snapshot.notificationsEnabled)
            putBoolean(KEY_BATTERY_OPTIMIZED, snapshot.batteryOptimized)
            putString(KEY_VENDOR, snapshot.vendor)
            snapshot.timestampMs?.let { putLong(KEY_TIMESTAMP, it) } ?: remove(KEY_TIMESTAMP)
        }.apply()
    }

    override fun load(): LiveUpdateCapabilitySnapshot? {
        if (!prefs.contains(KEY_SUPPORTED_API)) return null
        return LiveUpdateCapabilitySnapshot(
            supportedApi = prefs.getBoolean(KEY_SUPPORTED_API, false),
            oemCapsule = prefs.getBoolean(KEY_OEM_CAPSULE, false),
            notificationsEnabled = prefs.getBoolean(KEY_NOTIFICATIONS_ENABLED, false),
            batteryOptimized = prefs.getBoolean(KEY_BATTERY_OPTIMIZED, true),
            vendor = prefs.getString(KEY_VENDOR, "unknown").orEmpty(),
            timestampMs = if (prefs.contains(KEY_TIMESTAMP)) prefs.getLong(KEY_TIMESTAMP, 0L) else null,
        )
    }

    companion object {
        private const val PREFS_NAME = "live_update_capabilities"
        private const val KEY_SUPPORTED_API = "supported_api"
        private const val KEY_OEM_CAPSULE = "oem_capsule"
        private const val KEY_NOTIFICATIONS_ENABLED = "notifications_enabled"
        private const val KEY_BATTERY_OPTIMIZED = "battery_optimized"
        private const val KEY_VENDOR = "vendor"
        private const val KEY_TIMESTAMP = "timestamp"
    }
}
