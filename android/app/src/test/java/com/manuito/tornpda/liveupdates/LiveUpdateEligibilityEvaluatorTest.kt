package com.manuito.tornpda.liveupdates

import android.content.ContextWrapper
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LiveUpdateEligibilityEvaluatorTest {

    private val context = object : ContextWrapper(null) {}

    @Test
    fun apiTooOldProducesUnsupportedReason() {
        val cache = InMemoryCapabilityCache()
        val evaluator = createEvaluator(
            cache = cache,
            apiLevel = 30,
            notificationsAllowed = true,
            batteryOptimized = false,
        )

        val result = evaluator.evaluate()

        assertFalse(result.eligible)
        assertEquals(LiveUpdateUnsupportedReason.API_TOO_OLD, result.reason)
        assertFalse(result.snapshot.supportedApi)
        assertEquals(result.snapshot, cache.lastSaved)
    }

    @Test
    fun notificationsDisabledProducesPermissionDenied() {
        val evaluator = createEvaluator(
            apiLevel = 40,
            notificationsAllowed = false,
            batteryOptimized = false,
        )

        val result = evaluator.evaluate()

        assertEquals(LiveUpdateUnsupportedReason.PERMISSION_DENIED, result.reason)
        assertFalse(result.snapshot.notificationsEnabled)
    }

    @Test
    fun batteryOptimizedProducesBatteryRestrictedReason() {
        val evaluator = createEvaluator(
            apiLevel = 40,
            notificationsAllowed = true,
            batteryOptimized = true,
        )

        val result = evaluator.evaluate()

        assertEquals(LiveUpdateUnsupportedReason.BATTERY_RESTRICTED, result.reason)
        assertTrue(result.snapshot.batteryOptimized)
    }

    @Test
    fun eligibleSnapshotIncludesVendor() {
        val evaluator = createEvaluator(
            apiLevel = 40,
            notificationsAllowed = true,
            batteryOptimized = false,
            vendor = "OnePlus",
        )

        val result = evaluator.evaluate()
        assertTrue(result.eligible)
        assertEquals("oneplus", result.snapshot.vendor)
        val latest = evaluator.latestSnapshot()
        assertEquals(result.snapshot, latest)
    }

    private fun createEvaluator(
        cache: InMemoryCapabilityCache = InMemoryCapabilityCache(),
        apiLevel: Int,
        notificationsAllowed: Boolean,
        batteryOptimized: Boolean,
        vendor: String = "Pixel",
    ): LiveUpdateEligibilityEvaluator {
        return LiveUpdateEligibilityEvaluator(
            context = context,
            capabilityCache = cache,
            timeProvider = { 42L },
            requiredApiLevel = 35,
            apiLevelProvider = { apiLevel },
            notificationsAllowedProvider = { notificationsAllowed },
            batteryOptimizedProvider = { batteryOptimized },
            vendorProvider = { vendor },
        )
    }

    private class InMemoryCapabilityCache : LiveUpdateCapabilityCache {
        var lastSaved: LiveUpdateCapabilitySnapshot? = null

        override fun save(snapshot: LiveUpdateCapabilitySnapshot) {
            lastSaved = snapshot
        }

        override fun load(): LiveUpdateCapabilitySnapshot? = lastSaved
    }
}
