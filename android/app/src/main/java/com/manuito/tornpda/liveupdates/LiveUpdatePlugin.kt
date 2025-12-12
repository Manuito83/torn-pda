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
        val sessionRegistry = LiveUpdateSessionRegistry(appContext)
        val adapter = createAdapter(appContext)
        val manager = DefaultLiveUpdateManager(
            adapter = adapter,
            eligibilityProvider = eligibilityEvaluator,
            sessionStore = sessionRegistry,
        )
        val bridge = LiveUpdateChannelBridge(
            manager = manager,
            eventEmitter = MethodChannelEventEmitter(channel),
        )
        channel.setMethodCallHandler(bridge)

        val capabilityMonitor = LiveUpdateCapabilityMonitor(appContext, eligibilityEvaluator) { snapshot ->
            manager.onCapability(snapshot)
        }
        manager.attachCapabilityMonitor(capabilityMonitor)
    }

    private fun createAdapter(context: Context): LiveUpdateAdapter {
        val tapIntentFactory = LiveUpdateTapIntentFactory(context)
        return if (Build.VERSION.SDK_INT >= MIN_NATIVE_ADAPTER_API) {
            AndroidLiveUpdateAdapter(context, tapIntentFactory)
        } else {
            NoOpLiveUpdateAdapter()
        }
    }
}
