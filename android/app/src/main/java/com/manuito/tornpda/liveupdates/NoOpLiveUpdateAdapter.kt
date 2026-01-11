package com.manuito.tornpda.liveupdates

import android.util.Log

/**
 * Temporary adapter used while the Android Live Update SDK is unavailable.
 * Always reports the platform as unsupported so Flutter can fall back to notifications/widgets.
 */
class NoOpLiveUpdateAdapter : LiveUpdateAdapter {

    private var listener: LiveUpdateAdapterListener? = null

    override fun startOrUpdate(sessionId: String, payload: LiveUpdatePayload): LiveUpdateAdapterResult {
        Log.d(TAG, "startOrUpdate called for session=$sessionId but platform not available.")
        return LiveUpdateAdapterResult(
            status = LiveUpdateRequestStatus.UNSUPPORTED,
            reason = LiveUpdateUnsupportedReason.API_TOO_OLD,
        )
    }

    override fun end(sessionId: String?): LiveUpdateAdapterResult {
        Log.d(TAG, "end called for session=$sessionId but no Live Update active.")
        return LiveUpdateAdapterResult(status = LiveUpdateRequestStatus.UPDATED)
    }

    override fun isActivityActive(): Boolean = false

    override fun setListener(listener: LiveUpdateAdapterListener?) {
        this.listener = listener
    }

    companion object {
        private const val TAG = "NoOpLiveUpdateAdapter"
    }
}
