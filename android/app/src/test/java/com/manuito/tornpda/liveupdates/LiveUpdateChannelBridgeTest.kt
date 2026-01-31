package com.manuito.tornpda.liveupdates

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LiveUpdateChannelBridgeTest {

    @Test
    fun startCallReturnsStructuredResult() {
        val manager = FakeManager()
        val emitter = RecordingEmitter()
        val bridge = LiveUpdateChannelBridge(manager, emitter)

        val call = MethodCall("startTravelActivity", mapOf("foo" to "bar"))
        val result = RecordingResult()

        bridge.onMethodCall(call, result)

        val payload = manager.lastStartPayload
        requireNotNull(payload)
        assertEquals("bar", payload["foo"])

        val response = result.successValue as Map<*, *>
        assertEquals("started", response["status"])
        assertEquals("session-123", response["sessionId"])
        assertTrue(response.containsKey("capabilitySnapshot"))
    }

    @Test
    fun endCallPassesSessionId() {
        val manager = FakeManager()
        val emitter = RecordingEmitter()
        val bridge = LiveUpdateChannelBridge(manager, emitter)

        val call = MethodCall("endTravelActivity", mapOf("sessionId" to "session-123"))
        val result = RecordingResult()

        bridge.onMethodCall(call, result)

        assertEquals("session-123", manager.lastEndSessionId)
        val response = result.successValue as Map<*, *>
        assertTrue(response["success"] as Boolean)
    }

    @Test
    fun capabilityRequestsReturnCachedSnapshot() {
        val manager = FakeManager()
        val emitter = RecordingEmitter()
        val bridge = LiveUpdateChannelBridge(manager, emitter)

        val result = RecordingResult()
        bridge.onMethodCall(MethodCall("getLiveUpdateCapabilities", null), result)

        val response = result.successValue as Map<*, *>
        assertEquals("oneplus", response["vendor"])
    }

    @Test
    fun managerEventsEmitThroughEmitter() {
        val manager = FakeManager()
        val emitter = RecordingEmitter()
        val bridge = LiveUpdateChannelBridge(manager, emitter)

        manager.emitStatus()
        manager.emitCapability()

        assertEquals("liveUpdateStatusChanged", emitter.lastMethod)
        assertEquals("timeout", emitter.lastPayload["status"])

        assertEquals("liveUpdateCapabilityChanged", emitter.secondMethod)
        assertEquals(false, emitter.secondPayload["supportedApi"])

        manager.isAnyActiveValue = true
        val isAnyResult = RecordingResult()
        bridge.onMethodCall(MethodCall("isAnyTravelActivityActive", null), isAnyResult)
        assertTrue(isAnyResult.successValue as Boolean)
    }

    @Test
    fun unknownMethodReturnsNotImplemented() {
        val manager = FakeManager()
        val emitter = RecordingEmitter()
        val bridge = LiveUpdateChannelBridge(manager, emitter)

        val result = RecordingResult()
        bridge.onMethodCall(MethodCall("unknown", null), result)

        assertTrue(result.notImplemented)
        assertFalse(result.hadError)
    }

    private class FakeManager : LiveUpdateManager {
        var lastStartPayload: Map<String, Any?>? = null
        var lastEndSessionId: String? = null
        var listener: LiveUpdateManagerListener? = null
        var isAnyActiveValue: Boolean = false

        override fun startOrUpdate(payload: Map<String, Any?>): LiveUpdateStartResult {
            lastStartPayload = payload
            return LiveUpdateStartResult(
                status = LiveUpdateRequestStatus.STARTED,
                sessionId = "session-123",
                capabilitySnapshot = LiveUpdateCapabilitySnapshot(
                    supportedApi = true,
                    oemCapsule = true,
                    notificationsEnabled = false,
                    batteryOptimized = false,
                    vendor = "oneplus",
                    timestampMs = 10L,
                ),
            )
        }

        override fun end(sessionId: String?): LiveUpdateEndResult {
            lastEndSessionId = sessionId
            return LiveUpdateEndResult(success = true)
        }

        override fun isAnyActive(): Boolean = isAnyActiveValue

        override fun getCapabilitySnapshot(): LiveUpdateCapabilitySnapshot? {
            return LiveUpdateCapabilitySnapshot(
                supportedApi = true,
                oemCapsule = false,
                notificationsEnabled = true,
                batteryOptimized = true,
                vendor = "oneplus",
                timestampMs = 20L,
            )
        }

        override fun addListener(listener: LiveUpdateManagerListener) {
            this.listener = listener
        }

        override fun removeListener(listener: LiveUpdateManagerListener) {
            if (this.listener == listener) {
                this.listener = null
            }
        }

        fun emitStatus() {
            listener?.onStatus(
                LiveUpdateStatusEvent(
                    sessionId = "session-123",
                    status = LiveUpdateLifecycleStatus.TIMEOUT,
                    surface = LiveUpdateSurface.LOCKSCREEN,
                    reason = LiveUpdateUnsupportedReason.BATTERY_RESTRICTED,
                )
            )
        }

        fun emitCapability() {
            listener?.onCapability(
                LiveUpdateCapabilitySnapshot(
                    supportedApi = false,
                    oemCapsule = false,
                    notificationsEnabled = true,
                    batteryOptimized = true,
                    vendor = "pixel",
                    timestampMs = 30L,
                )
            )
        }
    }

    private class RecordingEmitter : LiveUpdateEventEmitter {
        var lastMethod: String? = null
        var lastPayload: Map<String, Any?> = emptyMap()
        var secondMethod: String? = null
        var secondPayload: Map<String, Any?> = emptyMap()

        override fun emitStatus(payload: Map<String, Any?>) {
            lastMethod = "liveUpdateStatusChanged"
            lastPayload = payload
        }

        override fun emitCapability(payload: Map<String, Any?>) {
            secondMethod = "liveUpdateCapabilityChanged"
            secondPayload = payload
        }
    }

    private class RecordingResult : MethodChannel.Result {
        var successValue: Any? = null
        var errorCode: String? = null
        var hadError: Boolean = false
        var notImplemented: Boolean = false

        override fun success(result: Any?) {
            successValue = result
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            this.errorCode = errorCode
            hadError = true
        }

        override fun notImplemented() {
            notImplemented = true
        }
    }
}
