package com.manuito.tornpda.liveupdates

/**
 * Bridges Torn PDA travel payloads into the underlying Android Live Update / capsule surface.
 * Implementations may wrap the upcoming Android Live Update SDK or OEM-specific renderers.
 */
interface LiveUpdateAdapter {
    /**
     * Start or refresh the Live Update with the provided payload.
     * The manager creates the Torn PDA session id and passes it here for telemetry correlation.
     */
    fun startOrUpdate(sessionId: String, payload: LiveUpdatePayload): LiveUpdateAdapterResult

    /**
     * Request termination of the Live Update. Implementations should be idempotent.
     */
    fun end(sessionId: String?): LiveUpdateAdapterResult

    /**
     * Whether the adapter currently believes an activity is active. Used as a fast path for
     * [LiveUpdateManager.isAnyActive].
     */
    fun isActivityActive(): Boolean

    /**
     * Propagate adapter generated lifecycle events (dismissals, timeout, arrival) back to the manager.
     */
    fun setListener(listener: LiveUpdateAdapterListener?)
}

/**
 * Lightweight result describing how the adapter handled the request.
 */
data class LiveUpdateAdapterResult(
    val status: LiveUpdateRequestStatus,
    val reason: LiveUpdateUnsupportedReason? = null,
    val errorMessage: String? = null,
)

/**
 * Adapter emitted lifecycle callbacks.
 */
interface LiveUpdateAdapterListener {
    fun onStatus(event: LiveUpdateStatusEvent)
}
