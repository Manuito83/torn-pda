package com.manuito.tornpda.liveupdates

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LiveUpdateChannelBridge(
    private val travelManager: LiveUpdateManager,
    private val racingManager: LiveUpdateManager,
    private val eventEmitter: LiveUpdateEventEmitter,
) : MethodChannel.MethodCallHandler, LiveUpdateManagerListener {

    init {
        travelManager.addListener(this)
        racingManager.addListener(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                START_TRAVEL_ACTIVITY -> {
                    val payload = (call.arguments as? Map<*, *>)?.mapKeys { it.key.toString() }.orEmpty()
                    val startResult = travelManager.startOrUpdate(payload)
                    result.success(startResult.toMap())
                }

                START_RACING_ACTIVITY -> {
                    val payload = (call.arguments as? Map<*, *>)?.mapKeys { it.key.toString() }.orEmpty()
                    val startResult = racingManager.startOrUpdate(payload)
                    result.success(startResult.toMap())
                }

                END_TRAVEL_ACTIVITY -> {
                    val sessionId = (call.arguments as? Map<*, *>)?.get("sessionId") as? String
                    val endResult = travelManager.end(sessionId)
                    result.success(endResult.toMap())
                }

                END_RACING_ACTIVITY -> {
                    val sessionId = (call.arguments as? Map<*, *>)?.get("sessionId") as? String
                    val endResult = racingManager.end(sessionId)
                    result.success(endResult.toMap())
                }

                IS_ANY_TRAVEL_ACTIVITY_ACTIVE -> {
                    result.success(travelManager.isAnyActive())
                }

                IS_ANY_RACING_ACTIVITY_ACTIVE -> {
                    result.success(racingManager.isAnyActive())
                }

                GET_LIVE_UPDATE_CAPABILITIES -> {
                    val snapshot = travelManager.getCapabilitySnapshot() ?: racingManager.getCapabilitySnapshot()
                    result.success(snapshot?.toMap())
                }

                GET_PUSH_TO_START_TOKEN -> {
                    // Android does not support push-to-start tokens
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
        travelManager.removeListener(this)
        racingManager.removeListener(this)
    }

    companion object {
        const val CHANNEL_NAME = "com.tornpda.liveactivity"
        private const val START_TRAVEL_ACTIVITY = "startTravelActivity"
        private const val START_RACING_ACTIVITY = "startRacingActivity"
        private const val END_TRAVEL_ACTIVITY = "endTravelActivity"
        private const val END_RACING_ACTIVITY = "endRacingActivity"
        private const val IS_ANY_TRAVEL_ACTIVITY_ACTIVE = "isAnyTravelActivityActive"
        private const val IS_ANY_RACING_ACTIVITY_ACTIVE = "isAnyRacingActivityActive"
        private const val GET_PUSH_TO_START_TOKEN = "getPushToStartToken"
        private const val GET_LIVE_UPDATE_CAPABILITIES = "getLiveUpdateCapabilities"
    }
}
