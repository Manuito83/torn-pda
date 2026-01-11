package com.manuito.tornpda.liveupdates

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.PowerManager
import android.util.Log

/**
 * Listens to OS signals that may impact Live Update eligibility (notification permission, battery
 * saver, OEM setting toggles) and refreshes the cached snapshot when they occur.
 */
class LiveUpdateCapabilityMonitor(
    private val context: Context,
    private val evaluator: LiveUpdateEligibilityProvider,
    private val callback: (LiveUpdateCapabilitySnapshot) -> Unit,
) {

    private var started = false

    private val capabilityReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            refresh("intent:${intent?.action}")
        }
    }

    private val intentFilter: IntentFilter = IntentFilter().apply {
        addAction(Intent.ACTION_BATTERY_CHANGED)
        addAction(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
        addAction(Intent.ACTION_USER_PRESENT)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            addAction(NotificationManager.ACTION_APP_BLOCK_STATE_CHANGED)
        }
    }

    fun start() {
        if (started) return
        started = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(capabilityReceiver, intentFilter, Context.RECEIVER_EXPORTED)
        } else {
            context.registerReceiver(capabilityReceiver, intentFilter)
        }
        refresh("startup")
    }

    fun stop() {
        if (!started) return
        started = false
        try {
            context.unregisterReceiver(capabilityReceiver)
        } catch (ignored: IllegalArgumentException) {
            Log.w(TAG, "Receiver already unregistered.")
        }
    }

    fun refresh(trigger: String? = null) {
        val result = evaluator.evaluate()
        Log.d(TAG, "Capability snapshot refreshed (${trigger ?: "manual"}) -> ${result.snapshot}")
        callback.invoke(result.snapshot)
    }

    companion object {
        private const val TAG = "LiveUpdateCapabilities"
    }
}
