package com.manuito.tornpda.liveupdates

import android.content.Context
import android.content.SharedPreferences

data class LiveUpdateSessionState(
    val sessionId: String,
    val travelIdentifier: String?,
    val startedAtMs: Long,
    val lastUpdatedAtMs: Long,
)

interface LiveUpdateSessionStore {
    fun markActive(state: LiveUpdateSessionState)
    fun clear(sessionId: String? = null)
    fun current(): LiveUpdateSessionState?
    fun isActive(): Boolean
}

class LiveUpdateSessionRegistry(context: Context) : LiveUpdateSessionStore {

    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    @Volatile
    private var cachedState: LiveUpdateSessionState? = readFromPrefs()

    override fun markActive(state: LiveUpdateSessionState) {
        cachedState = state
        prefs.edit()
            .putString(KEY_SESSION_ID, state.sessionId)
            .putString(KEY_TRAVEL_IDENTIFIER, state.travelIdentifier)
            .putLong(KEY_STARTED_AT, state.startedAtMs)
            .putLong(KEY_LAST_UPDATED_AT, state.lastUpdatedAtMs)
            .apply()
    }

    override fun clear(sessionId: String? = null) {
        if (sessionId != null && cachedState?.sessionId != sessionId) return
        cachedState = null
        prefs.edit().clear().apply()
    }

    override fun current(): LiveUpdateSessionState? = cachedState

    override fun isActive(): Boolean = cachedState != null

    private fun readFromPrefs(): LiveUpdateSessionState? {
        val sessionId = prefs.getString(KEY_SESSION_ID, null) ?: return null
        val startedAt = prefs.getLong(KEY_STARTED_AT, 0L)
        val lastUpdated = prefs.getLong(KEY_LAST_UPDATED_AT, startedAt)
        val travelIdentifier = prefs.getString(KEY_TRAVEL_IDENTIFIER, null)
        return LiveUpdateSessionState(
            sessionId = sessionId,
            travelIdentifier = travelIdentifier,
            startedAtMs = startedAt,
            lastUpdatedAtMs = lastUpdated,
        )
    }

    companion object {
        private const val PREFS_NAME = "live_update_session"
        private const val KEY_SESSION_ID = "session_id"
        private const val KEY_TRAVEL_IDENTIFIER = "travel_identifier"
        private const val KEY_STARTED_AT = "started_at"
        private const val KEY_LAST_UPDATED_AT = "last_updated_at"
    }
}
