package com.manuito.tornpda.liveupdates

import io.flutter.plugin.common.MethodChannel

class MethodChannelEventEmitter(
    private val methodChannel: MethodChannel,
) : LiveUpdateEventEmitter {

    override fun emitStatus(payload: Map<String, Any?>) {
        methodChannel.invokeMethod("liveUpdateStatusChanged", payload)
    }

    override fun emitCapability(payload: Map<String, Any?>) {
        methodChannel.invokeMethod("liveUpdateCapabilityChanged", payload)
    }
}
