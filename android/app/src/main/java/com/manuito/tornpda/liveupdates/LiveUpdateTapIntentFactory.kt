package com.manuito.tornpda.liveupdates

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.manuito.tornpda.MainActivity

class LiveUpdateTapIntentFactory(private val context: Context) {

    fun buildTravelTapIntent(sessionId: String, travelIdentifier: String?): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = LiveUpdateIntentExtras.ACTION_TRAVEL_LIVE_UPDATE
            putExtra(LiveUpdateIntentExtras.EXTRA_TARGET_ROUTE, LiveUpdateIntentExtras.ROUTE_TRAVEL)
            putExtra(LiveUpdateIntentExtras.EXTRA_ENTRY_POINT, LiveUpdateIntentExtras.ENTRY_POINT_TRAVEL)
            putExtra(LiveUpdateIntentExtras.EXTRA_SESSION_ID, sessionId)
            travelIdentifier?.let {
                putExtra(LiveUpdateIntentExtras.EXTRA_TRAVEL_IDENTIFIER, it)
            }
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntentFlags = PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag()
        val requestCode = sessionId.hashCode()
        return PendingIntent.getActivity(context, requestCode, intent, pendingIntentFlags)
    }

    private fun immutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }
}
