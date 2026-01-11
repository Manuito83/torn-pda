package com.manuito.tornpda.liveupdates

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LiveUpdateChannelBridge(
    private val manager: LiveUpdateManager,
    private val eventEmitter: LiveUpdateEventEmitter,
) : MethodChannel.MethodCallHandler, LiveUpdateManagerListener {

    init {
        manager.addListener(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                START_TRAVEL_ACTIVITY -> {
                    val payload = (call.arguments as? Map<*, *>)?.mapKeys { it.key.toString() }.orEmpty()
                    val startResult = manager.startOrUpdate(payload)
                    result.success(startResult.toMap())
                }

                END_TRAVEL_ACTIVITY -> {
                    val sessionId = (call.arguments as? Map<*, *>)?.get("sessionId") as? String
                    val endResult = manager.end(sessionId)
                    result.success(endResult.toMap())
                }

                IS_ANY_TRAVEL_ACTIVITY_ACTIVE -> {
                    result.success(manager.isAnyActive())
                }

                GET_LIVE_UPDATE_CAPABILITIES -> {
                    val snapshot = manager.getCapabilitySnapshot()
                    result.success(snapshot?.toMap())
                }

                GET_PUSH_TO_START_TOKEN -> {
                    // Android does not support push-to-start tokens yet.
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        } catch (exception: Exception) {
            result.error("LIVE_UPDATE_ERROR", exception.message, null)
        }
    }

    override fun onStatus(event: LiveUpdateStatusEvent) {
        eventEmitter.emitStatus(event.toMap())
    }

    override fun onCapability(snapshot: LiveUpdateCapabilitySnapshot) {
        eventEmitter.emitCapability(snapshot.toMap())
    }

    fun dispose() {
        manager.removeListener(this)
    }

    companion object {
        const val CHANNEL_NAME = "com.tornpda.liveactivity"
        private const val START_TRAVEL_ACTIVITY = "startTravelActivity"
        private const val END_TRAVEL_ACTIVITY = "endTravelActivity"
        private const val IS_ANY_TRAVEL_ACTIVITY_ACTIVE = "isAnyTravelActivityActive"
        private const val GET_PUSH_TO_START_TOKEN = "getPushToStartToken"
        private const val GET_LIVE_UPDATE_CAPABILITIES = "getLiveUpdateCapabilities"
    }
}
