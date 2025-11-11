package com.manuito.tornpda.liveupdates

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

data class LiveUpdateEligibilityResult(
    val eligible: Boolean,
    val reason: LiveUpdateUnsupportedReason?,
    val snapshot: LiveUpdateCapabilitySnapshot,
)

interface LiveUpdateEligibilityProvider {
    fun evaluate(): LiveUpdateEligibilityResult
    fun latestSnapshot(): LiveUpdateCapabilitySnapshot?
}

class LiveUpdateEligibilityEvaluator(
    private val context: Context,
    private val capabilityCache: LiveUpdateCapabilityCache,
    private val oemCapabilityDetector: OemCapabilityDetector,
    private val timeProvider: () -> Long = { System.currentTimeMillis() },
    private val requiredApiLevel: Int = DEFAULT_REQUIRED_API_LEVEL,
    private val apiLevelProvider: () -> Int = { Build.VERSION.SDK_INT },
    private val notificationsAllowedProvider: (() -> Boolean)? = null,
    private val batteryOptimizedProvider: (() -> Boolean)? = null,
    private val vendorProvider: () -> String = { Build.MANUFACTURER ?: "unknown" },
    private val capsuleAvailabilityProvider: (() -> Boolean)? = null,
) : LiveUpdateEligibilityProvider {

    override fun evaluate(): LiveUpdateEligibilityResult {
        val snapshot = buildSnapshot()
        capabilityCache.save(snapshot)
        val reason = determineReason(snapshot)
        return LiveUpdateEligibilityResult(
            eligible = reason == null,
            reason = reason,
            snapshot = snapshot,
        )
    }

    override fun latestSnapshot(): LiveUpdateCapabilitySnapshot? = capabilityCache.load()

    private fun buildSnapshot(): LiveUpdateCapabilitySnapshot {
        val supportedApi = apiLevelProvider() >= requiredApiLevel
        val notificationsEnabled = notificationsAllowedProvider?.invoke() ?: notificationsAllowed()
        val batteryOptimized = batteryOptimizedProvider?.invoke() ?: isBatteryOptimized()
        val vendor = vendorProvider().ifEmpty { "unknown" }.lowercase()
        val oemCapsule = capsuleAvailabilityProvider?.invoke() ?: oemCapabilityDetector.isOnePlusCapsuleAvailable()
        return LiveUpdateCapabilitySnapshot(
            supportedApi = supportedApi,
            oemCapsule = oemCapsule,
            notificationsEnabled = notificationsEnabled,
            batteryOptimized = batteryOptimized,
            vendor = vendor,
            timestampMs = timeProvider(),
        )
    }

    private fun determineReason(snapshot: LiveUpdateCapabilitySnapshot): LiveUpdateUnsupportedReason? {
        return when {
            !snapshot.supportedApi -> LiveUpdateUnsupportedReason.API_TOO_OLD
            !snapshot.notificationsEnabled -> LiveUpdateUnsupportedReason.PERMISSION_DENIED
            snapshot.batteryOptimized -> LiveUpdateUnsupportedReason.BATTERY_RESTRICTED
            else -> null
        }
    }

    private fun notificationsAllowed(): Boolean {
        val managerCompat = NotificationManagerCompat.from(context)
        if (!managerCompat.areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val granted = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
            if (!granted) return false
        }
        return true
    }

    private fun isBatteryOptimized(): Boolean {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return true
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        val packageName = context.packageName
        return !powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    companion object {
        // Android 15 / API 35 is the earliest version expected to support Live Updates.
        private const val DEFAULT_REQUIRED_API_LEVEL = 35
    }
}
