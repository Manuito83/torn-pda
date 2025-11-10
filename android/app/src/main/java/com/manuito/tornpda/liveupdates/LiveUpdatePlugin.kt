package com.manuito.tornpda.liveupdates

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object LiveUpdatePlugin {

    @JvmStatic
    fun register(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LiveUpdateChannelBridge.CHANNEL_NAME,
        )
        val bridge = LiveUpdateChannelBridge(
            manager = NoOpLiveUpdateManager(),
            eventEmitter = MethodChannelEventEmitter(channel),
        )
        channel.setMethodCallHandler(bridge)
    }
}
