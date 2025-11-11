package com.manuito.tornpda.liveupdates

/**
 * Decorator that injects OEM capsule hints into the payload so downstream adapters can
 * mirror content on vendor-specific surfaces (e.g., OnePlus 13 "island").
 */
class OemCapsuleAdapter(
    private val delegate: LiveUpdateAdapter,
) : LiveUpdateAdapter {

    override fun startOrUpdate(sessionId: String, payload: LiveUpdatePayload): LiveUpdateAdapterResult {
        val decoratedPayload = payload.withExtra("oemCapsulePreferred", true)
        return delegate.startOrUpdate(sessionId, decoratedPayload)
    }

    override fun end(sessionId: String?): LiveUpdateAdapterResult {
        return delegate.end(sessionId)
    }

    override fun isActivityActive(): Boolean = delegate.isActivityActive()

    override fun setListener(listener: LiveUpdateAdapterListener?) {
        delegate.setListener(listener)
    }
}
