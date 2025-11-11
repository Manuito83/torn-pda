package com.manuito.tornpda.liveupdates

import android.content.Context
import android.util.Log

/**
 * Primary adapter that will call into the Android Live Update SDK once available.
 * For now it prepares navigation intents and reports structured errors so Flutter
 * can fall back to legacy widgets/notifications.
 */
class AndroidLiveUpdateAdapter(
    private val context: Context,
    private val tapIntentFactory: LiveUpdateTapIntentFactory,
) : LiveUpdateAdapter {

    private var listener: LiveUpdateAdapterListener? = null
    private var cachedPayload: LiveUpdatePayload? = null

    override fun startOrUpdate(sessionId: String, payload: LiveUpdatePayload): LiveUpdateAdapterResult {
        cachedPayload = payload
        val tapIntent = tapIntentFactory.buildTravelTapIntent(sessionId, payload.travelIdentifier)
        Log.d(TAG, "Prepared tap intent for session=$sessionId, destination=${payload.currentDestinationDisplayName}")

        // TODO: Wire up the Android Live Update API once Google exposes the SDK.
        // Until then, return an error so Flutter can fall back to notifications/widgets.
        return LiveUpdateAdapterResult(
            status = LiveUpdateRequestStatus.UNSUPPORTED,
            reason = LiveUpdateUnsupportedReason.INTERNAL_ERROR,
            errorMessage = "Android Live Update SDK not integrated yet",
        )
    }

    override fun end(sessionId: String?): LiveUpdateAdapterResult {
        cachedPayload = null
        Log.d(TAG, "Requested end for session=$sessionId (no active Live Update yet).")
        return LiveUpdateAdapterResult(status = LiveUpdateRequestStatus.UPDATED)
    }

    override fun isActivityActive(): Boolean = cachedPayload != null

    override fun setListener(listener: LiveUpdateAdapterListener?) {
        this.listener = listener
    }

    companion object {
        private const val TAG = "AndroidLiveUpdateAdapter"
    }
}
