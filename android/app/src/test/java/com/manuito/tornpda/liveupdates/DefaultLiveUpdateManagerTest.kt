package com.manuito.tornpda.liveupdates

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class DefaultLiveUpdateManagerTest {

    private val baseSnapshot = LiveUpdateCapabilitySnapshot(
        supportedApi = true,
        oemCapsule = false,
        notificationsEnabled = true,
        batteryOptimized = false,
        vendor = "pixel",
        timestampMs = 10L,
    )

    @Test
    fun startReturnsUnsupportedWhenEligibilityFails() {
        val eligibility = FakeEligibilityProvider(
            LiveUpdateEligibilityResult(
                eligible = false,
                reason = LiveUpdateUnsupportedReason.PERMISSION_DENIED,
                snapshot = baseSnapshot,
            ),
        )
        val adapter = RecordingAdapter()
        val sessionStore = RecordingSessionStore()
        val manager = DefaultLiveUpdateManager(adapter, eligibility, sessionStore) { "session-1" }

        val result = manager.startOrUpdate(payload())

        assertEquals(LiveUpdateRequestStatus.UNSUPPORTED, result.status)
        assertEquals(LiveUpdateUnsupportedReason.PERMISSION_DENIED, result.reason)
        assertEquals(0, adapter.startCalls)
        assertNull(sessionStore.current())
    }

    @Test
    fun startSuccessPersistsSessionAndReusesIdOnUpdate() {
        val eligibility = FakeEligibilityProvider(successResult())
        val adapter = RecordingAdapter()
        val sessionStore = RecordingSessionStore()
        val manager = DefaultLiveUpdateManager(adapter, eligibility, sessionStore) { "session-xyz" }

        adapter.nextResult = LiveUpdateAdapterResult(LiveUpdateRequestStatus.STARTED)
        val firstResult = manager.startOrUpdate(payload())
        assertEquals("session-xyz", firstResult.sessionId)
        assertTrue(sessionStore.isActive())

        adapter.nextResult = LiveUpdateAdapterResult(LiveUpdateRequestStatus.UPDATED)
        val secondResult = manager.startOrUpdate(payload(hasArrived = true))
        assertEquals("session-xyz", secondResult.sessionId)
        assertEquals(2, adapter.startCalls)
    }

    @Test
    fun endClearsSessionAndEmitsEvent() {
        val eligibility = FakeEligibilityProvider(successResult())
        val adapter = RecordingAdapter()
        val sessionStore = RecordingSessionStore()
        val manager = DefaultLiveUpdateManager(adapter, eligibility, sessionStore) { "session-end" }
        val listener = RecordingListener()
        manager.addListener(listener)

        adapter.nextResult = LiveUpdateAdapterResult(LiveUpdateRequestStatus.STARTED)
        manager.startOrUpdate(payload())
        assertTrue(sessionStore.isActive())

        manager.end(null)

        assertFalse(sessionStore.isActive())
        assertEquals(LiveUpdateLifecycleStatus.ENDED, listener.lastStatus?.status)
    }

    @Test
    fun adapterTimeoutEventClearsSession() {
        val eligibility = FakeEligibilityProvider(successResult())
        val adapter = RecordingAdapter()
        val sessionStore = RecordingSessionStore()
        val manager = DefaultLiveUpdateManager(adapter, eligibility, sessionStore) { "session-timeout" }

        adapter.nextResult = LiveUpdateAdapterResult(LiveUpdateRequestStatus.STARTED)
        manager.startOrUpdate(payload())
        assertTrue(sessionStore.isActive())

        adapter.emitStatus(LiveUpdateLifecycleStatus.TIMEOUT, "session-timeout")

        assertFalse(sessionStore.isActive())
    }

    @Test
    fun startWithIdenticalTravelStateSkipsAdapter() {
        val eligibility = FakeEligibilityProvider(successResult())
        val adapter = RecordingAdapter()
        val sessionStore = RecordingSessionStore()
        val manager = DefaultLiveUpdateManager(adapter, eligibility, sessionStore) { "session-dedup" }

        adapter.nextResult = LiveUpdateAdapterResult(LiveUpdateRequestStatus.STARTED)
        manager.startOrUpdate(payload(hasArrived = false))
        assertEquals(1, adapter.startCalls)

        // Second identical call — same trip, same state (en-route)
        adapter.nextResult = LiveUpdateAdapterResult(LiveUpdateRequestStatus.UPDATED)
        val result = manager.startOrUpdate(payload(hasArrived = false))
        assertEquals(LiveUpdateRequestStatus.UPDATED, result.status)
        assertEquals("session-dedup", result.sessionId)
        // Adapter must NOT be called again
        assertEquals(1, adapter.startCalls)
    }

    @Test
    fun startTransitionToArrivedCallsAdapter() {
        val eligibility = FakeEligibilityProvider(successResult())
        val adapter = RecordingAdapter()
        val sessionStore = RecordingSessionStore()
        val manager = DefaultLiveUpdateManager(adapter, eligibility, sessionStore) { "session-arrive" }

        adapter.nextResult = LiveUpdateAdapterResult(LiveUpdateRequestStatus.STARTED)
        manager.startOrUpdate(payload(hasArrived = false))
        assertEquals(1, adapter.startCalls)

        // Transition to arrived — adapter MUST be called
        adapter.nextResult = LiveUpdateAdapterResult(LiveUpdateRequestStatus.UPDATED)
        manager.startOrUpdate(payload(hasArrived = true))
        assertEquals(2, adapter.startCalls)
    }

    @Test
    fun startWithDifferentTripCallsAdapter() {
        val eligibility = FakeEligibilityProvider(successResult())
        val adapter = RecordingAdapter()
        val sessionStore = RecordingSessionStore()
        val manager = DefaultLiveUpdateManager(adapter, eligibility, sessionStore) { "session-trips" }

        adapter.nextResult = LiveUpdateAdapterResult(LiveUpdateRequestStatus.STARTED)
        manager.startOrUpdate(payload(travelIdentifier = "trip-A"))
        assertEquals(1, adapter.startCalls)

        // Different trip — adapter MUST be called
        adapter.nextResult = LiveUpdateAdapterResult(LiveUpdateRequestStatus.UPDATED)
        manager.startOrUpdate(payload(travelIdentifier = "trip-B"))
        assertEquals(2, adapter.startCalls)
    }

    private fun payload(
        hasArrived: Boolean = false,
        travelIdentifier: String = "torn-1700",
    ): Map<String, Any?> {
        return mapOf(
            "arrivalTimeTimestamp" to 1700L,
            "departureTimeTimestamp" to 1600L,
            "travelIdentifier" to travelIdentifier,
            "hasArrived" to hasArrived,
        )
    }

    private fun successResult(): LiveUpdateEligibilityResult {
        return LiveUpdateEligibilityResult(
            eligible = true,
            reason = null,
            snapshot = baseSnapshot,
        )
    }

    private class FakeEligibilityProvider(
        private val result: LiveUpdateEligibilityResult,
    ) : LiveUpdateEligibilityProvider {
        override fun evaluate(): LiveUpdateEligibilityResult = result
        override fun latestSnapshot(): LiveUpdateCapabilitySnapshot? = result.snapshot
    }

    private class RecordingAdapter : LiveUpdateAdapter {
        var startCalls = 0
        var endCalls = 0
        var adapterListener: LiveUpdateAdapterListener? = null
        var nextResult: LiveUpdateAdapterResult = LiveUpdateAdapterResult(LiveUpdateRequestStatus.STARTED)
        var lastPayload: LiveUpdatePayload? = null

        override fun startOrUpdate(sessionId: String, payload: LiveUpdatePayload): LiveUpdateAdapterResult {
            startCalls += 1
            lastPayload = payload
            return nextResult
        }

        override fun end(sessionId: String?): LiveUpdateAdapterResult {
            endCalls += 1
            return LiveUpdateAdapterResult(LiveUpdateRequestStatus.UPDATED)
        }

        override fun isActivityActive(): Boolean = startCalls > endCalls

        override fun setListener(listener: LiveUpdateAdapterListener?) {
            this.adapterListener = listener
        }

        fun emitStatus(status: LiveUpdateLifecycleStatus, sessionId: String) {
            adapterListener?.onStatus(
                LiveUpdateStatusEvent(
                    sessionId = sessionId,
                    status = status,
                    surface = LiveUpdateSurface.LOCKSCREEN,
                ),
            )
        }
    }

    private class RecordingSessionStore : LiveUpdateSessionStore {
        private var state: LiveUpdateSessionState? = null

        override fun markActive(state: LiveUpdateSessionState) {
            this.state = state
        }

        override fun clear(sessionId: String?) {
            if (sessionId != null && state?.sessionId != sessionId) return
            state = null
        }

        override fun current(): LiveUpdateSessionState? = state

        override fun isActive(): Boolean = state != null
    }

    private class RecordingListener : LiveUpdateManagerListener {
        var lastStatus: LiveUpdateStatusEvent? = null
        override fun onStatus(event: LiveUpdateStatusEvent) {
            lastStatus = event
        }

        override fun onCapability(snapshot: LiveUpdateCapabilitySnapshot) = Unit
    }
}
