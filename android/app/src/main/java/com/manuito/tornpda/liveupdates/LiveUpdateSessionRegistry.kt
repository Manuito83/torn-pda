package com.manuito.tornpda.liveupdates

import android.content.Context
import android.content.SharedPreferences

data class LiveUpdateSessionState(
    val sessionId: String,
    val activityType: LiveUpdateActivityType,
    val contentIdentifier: String?,
    val startedAtMs: Long,
    val lastUpdatedAtMs: Long,
)

interface LiveUpdateSessionStore {
    fun markActive(state: LiveUpdateSessionState)
    fun clear(sessionId: String? = null)
    fun current(): LiveUpdateSessionState?
    fun isActive(): Boolean
}

class LiveUpdateSessionRegistry(
    context: Context,
    private val activityType: LiveUpdateActivityType = LiveUpdateActivityType.TRAVEL,
) : LiveUpdateSessionStore {

    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences("${PREFS_NAME}_${activityType.wireName}", Context.MODE_PRIVATE)

    @Volatile
    private var cachedState: LiveUpdateSessionState? = readFromPrefs()

    override fun markActive(state: LiveUpdateSessionState) {
        cachedState = state
        prefs.edit()
            .putString(KEY_SESSION_ID, state.sessionId)
            .putString(KEY_ACTIVITY_TYPE, state.activityType.wireName)
            .putString(KEY_CONTENT_IDENTIFIER, state.contentIdentifier)
            .putLong(KEY_STARTED_AT, state.startedAtMs)
            .putLong(KEY_LAST_UPDATED_AT, state.lastUpdatedAtMs)
            .apply()
    }

    override fun clear(sessionId: String?) {
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
        val storedType = LiveUpdateActivityType.fromWireName(prefs.getString(KEY_ACTIVITY_TYPE, activityType.wireName))
        val contentIdentifier = prefs.getString(KEY_CONTENT_IDENTIFIER, null)
            ?: if (storedType == LiveUpdateActivityType.TRAVEL) prefs.getString(KEY_LEGACY_TRAVEL_IDENTIFIER, null) else null
        return LiveUpdateSessionState(
            sessionId = sessionId,
            activityType = storedType,
            contentIdentifier = contentIdentifier,
            startedAtMs = startedAt,
            lastUpdatedAtMs = lastUpdated,
        )
    }

    companion object {
        private const val PREFS_NAME = "live_update_session"
        private const val KEY_SESSION_ID = "session_id"
        private const val KEY_ACTIVITY_TYPE = "activity_type"
        private const val KEY_CONTENT_IDENTIFIER = "content_identifier"
        private const val KEY_LEGACY_TRAVEL_IDENTIFIER = "travel_identifier"
        private const val KEY_STARTED_AT = "started_at"
        private const val KEY_LAST_UPDATED_AT = "last_updated_at"
    }
}
