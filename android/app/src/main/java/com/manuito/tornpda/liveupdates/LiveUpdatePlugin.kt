package com.manuito.tornpda.liveupdates

import android.content.Context
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object LiveUpdatePlugin {

    private const val MIN_NATIVE_ADAPTER_API = 26

    @JvmStatic
    fun register(flutterEngine: FlutterEngine, context: Context) {
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LiveUpdateChannelBridge.CHANNEL_NAME,
        )

        val appContext = context.applicationContext
        val capabilityStore = LiveUpdateCapabilityStore(appContext)
        val eligibilityEvaluator = LiveUpdateEligibilityEvaluator(appContext, capabilityStore)
        val travelManager = createManager(appContext, LiveUpdateActivityType.TRAVEL, eligibilityEvaluator)
        val racingManager = createManager(appContext, LiveUpdateActivityType.RACING, eligibilityEvaluator)
        val bridge = LiveUpdateChannelBridge(
            travelManager = travelManager,
            racingManager = racingManager,
            eventEmitter = MethodChannelEventEmitter(channel),
        )
        channel.setMethodCallHandler(bridge)

        val capabilityMonitor = LiveUpdateCapabilityMonitor(appContext, eligibilityEvaluator) { snapshot ->
            travelManager.onCapability(snapshot)
            racingManager.onCapability(snapshot)
        }
        travelManager.attachCapabilityMonitor(capabilityMonitor)
    }

    private fun createManager(
        context: Context,
        activityType: LiveUpdateActivityType,
        eligibilityEvaluator: LiveUpdateEligibilityEvaluator,
    ): DefaultLiveUpdateManager {
        return DefaultLiveUpdateManager(
            activityType = activityType,
            adapter = createAdapter(context, activityType),
            eligibilityProvider = eligibilityEvaluator,
            sessionStore = LiveUpdateSessionRegistry(context, activityType),
        )
    }

    private fun createAdapter(context: Context, activityType: LiveUpdateActivityType): LiveUpdateAdapter {
        val tapIntentFactory = LiveUpdateTapIntentFactory(context)
        return if (Build.VERSION.SDK_INT >= MIN_NATIVE_ADAPTER_API) {
            when (activityType) {
                LiveUpdateActivityType.TRAVEL -> AndroidTravelLiveUpdateAdapter(context, tapIntentFactory)
                LiveUpdateActivityType.RACING -> AndroidRacingLiveUpdateAdapter(context, tapIntentFactory)
            }
        } else {
            NoOpLiveUpdateAdapter()
        }
    }
}
