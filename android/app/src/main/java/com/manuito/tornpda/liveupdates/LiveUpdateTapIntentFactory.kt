package com.manuito.tornpda.liveupdates

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import com.manuito.tornpda.MainActivity

class LiveUpdateTapIntentFactory(private val context: Context) {

    fun buildTravelTapIntent(sessionId: String, travelIdentifier: String?): PendingIntent {
        return buildTapIntent(
            sessionId = sessionId,
            action = LiveUpdateIntentExtras.ACTION_TRAVEL_LIVE_UPDATE,
            route = LiveUpdateIntentExtras.ROUTE_TRAVEL,
            entryPoint = LiveUpdateIntentExtras.ENTRY_POINT_TRAVEL,
            contentIdentifier = travelIdentifier,
        )
    }

    fun buildRacingTapIntent(sessionId: String, stateIdentifier: String?): PendingIntent {
        return buildTapIntent(
            sessionId = sessionId,
            action = LiveUpdateIntentExtras.ACTION_RACING_LIVE_UPDATE,
            route = LiveUpdateIntentExtras.ROUTE_RACING,
            entryPoint = LiveUpdateIntentExtras.ENTRY_POINT_RACING,
            contentIdentifier = stateIdentifier,
        )
    }

    private fun buildTapIntent(
        sessionId: String,
        action: String,
        route: String,
        entryPoint: String,
        contentIdentifier: String?,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            this.action = action
            data = Uri.parse(
                when (route) {
                    LiveUpdateIntentExtras.ROUTE_TRAVEL -> "tornpda://travel/live"
                    LiveUpdateIntentExtras.ROUTE_RACING -> "tornpda://www.torn.com/page.php?sid=racing"
                    else -> "tornpda://www.torn.com"
                }
            )
            putExtra(LiveUpdateIntentExtras.EXTRA_TARGET_ROUTE, route)
            putExtra(LiveUpdateIntentExtras.EXTRA_ENTRY_POINT, entryPoint)
            putExtra(LiveUpdateIntentExtras.EXTRA_SESSION_ID, sessionId)
            contentIdentifier?.let {
                putExtra(LiveUpdateIntentExtras.EXTRA_CONTENT_IDENTIFIER, it)
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
