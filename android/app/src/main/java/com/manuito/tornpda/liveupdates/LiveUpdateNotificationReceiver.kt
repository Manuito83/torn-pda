package com.manuito.tornpda.liveupdates

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import java.util.concurrent.CopyOnWriteArraySet

class LiveUpdateNotificationReceiver : BroadcastReceiver() {

    interface Listener {
        fun onNotificationDismissed(sessionId: String)
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == ACTION_DISMISSED) {
            val sessionId = intent.getStringExtra(EXTRA_SESSION_ID) ?: return
            context?.let {
                TravelLiveUpdateRefreshScheduler.cancelRefresh(it, sessionId)
                TravelLiveUpdateRefreshScheduler.cancelArrived(it, sessionId)
                RacingLiveUpdateRefreshScheduler.cancelRefresh(it, sessionId)
                cancelFinishedCleanup(it, sessionId)
            }
            listeners.forEach { it.onNotificationDismissed(sessionId) }
        } else if (intent?.action == ACTION_REFRESH) {
            val contextNonNull = context ?: return
            val sessionId = intent.getStringExtra(EXTRA_SESSION_ID) ?: return
            val payload = LiveUpdatePayload.fromMap(
                activityType = LiveUpdateActivityType.TRAVEL,
                arguments = intent.extras.toPayloadArguments(),
            )
            if (!payload.isValidFor(LiveUpdateActivityType.TRAVEL)) return

            LiveUpdateNotificationChannel.ensureCreated(contextNonNull, LiveUpdateActivityType.TRAVEL)
            val tapIntent = LiveUpdateTapIntentFactory(contextNonNull).buildTravelTapIntent(sessionId, payload.travelIdentifier)
            val dismissIntent = createDismissIntent(contextNonNull, sessionId)
            val notification = TravelLiveUpdateNotificationFactory(contextNonNull).build(
                sessionId = sessionId,
                payload = payload,
                tapIntent = tapIntent,
                dismissIntent = dismissIntent,
            )
            NotificationManagerCompat.from(contextNonNull).notify(sessionId.hashCode(), notification)
            TravelLiveUpdateRefreshScheduler.scheduleNextRefresh(contextNonNull, sessionId, payload)
            TravelLiveUpdateRefreshScheduler.scheduleArrived(contextNonNull, sessionId, payload)
        } else if (intent?.action == ACTION_RACING_REFRESH) {
            val contextNonNull = context ?: return
            val sessionId = intent.getStringExtra(EXTRA_SESSION_ID) ?: return
            Log.d(TAG, "Racing refresh alarm fired. session=$sessionId")
            val payload = LiveUpdatePayload.fromMap(
                activityType = LiveUpdateActivityType.RACING,
                arguments = intent.extras.toPayloadArguments(),
            )
            if (!payload.isValidFor(LiveUpdateActivityType.RACING)) {
                Log.w(TAG, "Racing refresh: invalid payload, aborting. stateId=${payload.stateIdentifier}, title=${payload.titleText}")
                return
            }

            val pendingResult = goAsync()
            Thread {
                try {
                    val apiKey = payload.extras[EXTRA_API_KEY] as? String
                    if (apiKey.isNullOrBlank()) {
                        Log.w(TAG, "Racing refresh: no API key in payload, cancelling chain.")
                        RacingLiveUpdateRefreshScheduler.cancelRefresh(contextNonNull, sessionId)
                        return@Thread
                    }

                    Log.d(TAG, "Racing refresh: calling API... phase=${payload.phase}")
                    when (val result = RacingLiveUpdateApiClient.fetchLatestState(apiKey)) {
                        is RacingFetchResult.Active -> {
                            val latestState = result.state
                            Log.d(TAG, "Racing refresh: API returned Active. phase=${latestState.phase}, id=${latestState.stateIdentifier}")
                            val updatedArguments = payload.extras.toMutableMap().apply {
                                put("stateIdentifier", latestState.stateIdentifier)
                                put("phase", latestState.phase)
                                put("titleText", latestState.titleText)
                                put("bodyText", latestState.bodyText)
                                put("targetTimeTimestamp", latestState.targetTimestamp)
                                put("currentServerTimestamp", System.currentTimeMillis() / 1000)
                                put("showTimer", latestState.hasTimer)
                            }
                            val updatedPayload = LiveUpdatePayload.fromMap(
                                activityType = LiveUpdateActivityType.RACING,
                                arguments = updatedArguments,
                            )

                            LiveUpdateNotificationChannel.ensureCreated(contextNonNull, LiveUpdateActivityType.RACING)
                            val tapIntent = LiveUpdateTapIntentFactory(contextNonNull)
                                .buildRacingTapIntent(sessionId, updatedPayload.stateIdentifier)
                            val dismissIntent = createDismissIntent(contextNonNull, sessionId)
                            val notification = RacingLiveUpdateNotificationFactory(contextNonNull)
                                .build(updatedPayload, tapIntent, dismissIntent)
                            NotificationManagerCompat.from(contextNonNull).notify(sessionId.hashCode(), notification)
                            RacingLiveUpdateRefreshScheduler.scheduleNextRefresh(contextNonNull, sessionId, updatedPayload)

                            // Finished: schedule a demotion alarm to convert
                            // the ongoing chip to a normal notification
                            if (latestState.phase.equals("finished", ignoreCase = true)) {
                                scheduleFinishedCleanup(contextNonNull, sessionId, updatedArguments)
                            }
                        }

                        is RacingFetchResult.Inactive -> {
                            Log.d(TAG, "Racing refresh: API returned Inactive. Cancelling notification and chain.")
                            // User is no longer racing — cancel notification and refresh chain
                            NotificationManagerCompat.from(contextNonNull).cancel(sessionId.hashCode())
                            RacingLiveUpdateRefreshScheduler.cancelRefresh(contextNonNull, sessionId)
                        }

                        is RacingFetchResult.TransientError -> {
                            Log.w(TAG, "Racing refresh: API returned TransientError. Keeping notification, retrying.")
                            // Could not determine state — keep notification and retry
                            // Deterministic end: cancel if the last-known target time
                            // has long passed, since the race is certainly over
                            val target = payload.targetTimeTimestamp
                            val now = System.currentTimeMillis() / 1000
                            if (target != null && target > 0 && now > target + DETERMINISTIC_EXPIRY_SECONDS) {
                                NotificationManagerCompat.from(contextNonNull).cancel(sessionId.hashCode())
                                RacingLiveUpdateRefreshScheduler.cancelRefresh(contextNonNull, sessionId)
                            } else {
                                RacingLiveUpdateRefreshScheduler.scheduleNextRefresh(contextNonNull, sessionId, payload)
                            }
                        }
                    }
                } finally {
                    pendingResult.finish()
                }
            }.start()
        } else if (intent?.action == ACTION_ARRIVED) {
            val contextNonNull = context ?: return
            val sessionId = intent.getStringExtra(EXTRA_SESSION_ID) ?: return
            val destination = intent.getStringExtra(EXTRA_DESTINATION) ?: "Unknown"
            val origin = intent.getStringExtra(EXTRA_ORIGIN)
            val earliestReturnTs = if (intent.hasExtra(EXTRA_EARLIEST_RETURN_TS)) {
                intent.getLongExtra(EXTRA_EARLIEST_RETURN_TS, 0L)
            } else null

            TravelLiveUpdateRefreshScheduler.cancelRefresh(contextNonNull, sessionId)
            showArrivedNotification(contextNonNull, sessionId, destination, origin, earliestReturnTs)
        } else if (intent?.action == ACTION_RACING_FINISHED_CLEANUP) {
            val contextNonNull = context ?: return
            val sessionId = intent.getStringExtra(EXTRA_SESSION_ID) ?: return
            Log.d(TAG, "Racing finished cleanup: demoting chip to normal notification. session=$sessionId")

            // Rebuild with ongoing=true but non-promoted so the chip
            // disappears but the notification and status-bar icon persist
            val payload = LiveUpdatePayload.fromMap(
                activityType = LiveUpdateActivityType.RACING,
                arguments = intent.extras.toPayloadArguments(),
            )
            if (!payload.isValidFor(LiveUpdateActivityType.RACING)) {
                // Payload lost — cancel the notification entirely
                NotificationManagerCompat.from(contextNonNull).cancel(sessionId.hashCode())
                return
            }

            LiveUpdateNotificationChannel.ensureCreated(contextNonNull, LiveUpdateActivityType.RACING)
            val tapIntent = LiveUpdateTapIntentFactory(contextNonNull)
                .buildRacingTapIntent(sessionId, payload.stateIdentifier)
            val dismissIntent = createDismissIntent(contextNonNull, sessionId)
            val notification = RacingLiveUpdateNotificationFactory(contextNonNull)
                .build(payload, tapIntent, dismissIntent, ongoing = true, promoted = false)
            NotificationManagerCompat.from(contextNonNull).notify(sessionId.hashCode(), notification)

            // Clear persisted session so this finished race is not
            // re-adopted when the app is next opened
            LiveUpdateSessionRegistry(contextNonNull, LiveUpdateActivityType.RACING).clear()
        }
    }

    private fun showArrivedNotification(
        context: Context,
        sessionId: String,
        destination: String,
        origin: String?,
        earliestReturnTs: Long?,
    ) {
        val channelId = LiveUpdateNotificationChannel.channelIdFor(LiveUpdateActivityType.TRAVEL)

        // Recreate the tap intent to open the app
        val tapIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
            it.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            PendingIntent.getActivity(context, 0, it, PendingIntent.FLAG_IMMUTABLE)
        }

        val destinationIcon = getDestinationIcon(destination)
        val timeFormat = android.text.format.DateFormat.getTimeFormat(context)
        val nowFormatted = timeFormat.format(java.util.Date())

        val arrivedTitle = context.getString(com.manuito.tornpda.R.string.live_update_arrived_in_pattern, destination)
        val arrivedContentText = context.getString(com.manuito.tornpda.R.string.live_update_arrived_at_pattern, nowFormatted)

        val route = if (origin != null) {
            context.getString(com.manuito.tornpda.R.string.live_update_notification_secondary, origin, destination)
        } else null

        val earliestReturnText = if (earliestReturnTs != null && earliestReturnTs > 0) {
            val returnFormatted = timeFormat.format(java.util.Date(earliestReturnTs * 1000))
            context.getString(com.manuito.tornpda.R.string.live_update_earliest_return_pattern, returnFormatted)
        } else null

        val bigTextLines = buildList {
            add(arrivedContentText)
            route?.let { add(it) }
            earliestReturnText?.let { add(it) }
        }

        val builder = androidx.core.app.NotificationCompat.Builder(context, channelId)
            .setSmallIcon(destinationIcon)
            .setContentTitle(arrivedTitle)
            .setContentText(arrivedContentText)
            .setContentIntent(tapIntent)
            .setAutoCancel(true)
            .setPriority(androidx.core.app.NotificationCompat.PRIORITY_HIGH)
            .setUsesChronometer(false)
            .setShowWhen(true)
            .setWhen(System.currentTimeMillis())
            .setStyle(
                androidx.core.app.NotificationCompat.BigTextStyle()
                    .bigText(bigTextLines.joinToString("\n"))
            )

        route?.let { builder.setSubText(it) }

        androidx.core.app.NotificationManagerCompat.from(context).notify(sessionId.hashCode(), builder.build())
    }

    /**
     * Returns the appropriate drawable resource ID for the given travel destination
     * Uses plane_left when returning to Torn, plane_right when traveling abroad
     */
    private fun getDestinationIcon(destination: String?): Int {
        return when (destination?.lowercase()) {
            "torn" -> com.manuito.tornpda.R.drawable.plane_left
            else -> com.manuito.tornpda.R.drawable.plane_right
        }
    }

    companion object {
        private const val TAG = "RacingLU"
        private const val ACTION_DISMISSED = "com.manuito.tornpda.liveupdates.ACTION_NOTIFICATION_DISMISSED"
        private const val ACTION_REFRESH = "com.manuito.tornpda.liveupdates.ACTION_NOTIFICATION_REFRESH"
        private const val ACTION_RACING_REFRESH = "com.manuito.tornpda.liveupdates.ACTION_RACING_NOTIFICATION_REFRESH"
        private const val ACTION_ARRIVED = "com.manuito.tornpda.liveupdates.ACTION_NOTIFICATION_ARRIVED"
        private const val ACTION_RACING_FINISHED_CLEANUP = "com.manuito.tornpda.liveupdates.ACTION_RACING_FINISHED_CLEANUP"
        private const val EXTRA_SESSION_ID = "extra_session_id"
        private const val EXTRA_DESTINATION = "extra_destination"
        private const val EXTRA_ORIGIN = "extra_origin"
        private const val EXTRA_EARLIEST_RETURN_TS = "extra_earliest_return_ts"
        private const val EXTRA_API_KEY = "apiKey"
        /** If the last-known target time is this far in the past and we still
         *  can't reach the API, the race is certainly over. 30 minutes. */
        private const val DETERMINISTIC_EXPIRY_SECONDS = 30 * 60L
        /** How long the "finished" chip stays visible before auto-cleanup. */
        private const val FINISHED_CLEANUP_DELAY_MS = 5 * 60 * 1000L
        
        private val listeners = CopyOnWriteArraySet<Listener>()

        fun registerListener(listener: Listener) {
            listeners.add(listener)
        }

        fun unregisterListener(listener: Listener) {
            listeners.remove(listener)
        }

        fun createDismissIntent(context: Context, sessionId: String): PendingIntent {
            val intent = Intent(context, LiveUpdateNotificationReceiver::class.java).apply {
                action = ACTION_DISMISSED
                putExtra(EXTRA_SESSION_ID, sessionId)
            }
            val flags = PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val requestCode = sessionId.hashCode()
            return PendingIntent.getBroadcast(context, requestCode, intent, flags)
        }

        fun createRefreshIntent(
            context: Context,
            sessionId: String,
            payloadArguments: Map<String, Any?>,
        ): PendingIntent {
            val intent = Intent(context, LiveUpdateNotificationReceiver::class.java).apply {
                action = ACTION_REFRESH
                putExtra(EXTRA_SESSION_ID, sessionId)
                payloadArguments.forEach { (key, value) ->
                    when (value) {
                        is String -> putExtra(key, value)
                        is Boolean -> putExtra(key, value)
                        is Int -> putExtra(key, value)
                        is Long -> putExtra(key, value)
                        is Double -> putExtra(key, value)
                        is Float -> putExtra(key, value)
                    }
                }
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val requestCode = sessionId.hashCode() + 2
            return PendingIntent.getBroadcast(context, requestCode, intent, flags)
        }

        fun createRacingRefreshIntent(
            context: Context,
            sessionId: String,
            payloadArguments: Map<String, Any?>,
        ): PendingIntent {
            val intent = Intent(context, LiveUpdateNotificationReceiver::class.java).apply {
                action = ACTION_RACING_REFRESH
                putExtra(EXTRA_SESSION_ID, sessionId)
                payloadArguments.forEach { (key, value) ->
                    when (value) {
                        is String -> putExtra(key, value)
                        is Boolean -> putExtra(key, value)
                        is Int -> putExtra(key, value)
                        is Long -> putExtra(key, value)
                        is Double -> putExtra(key, value)
                        is Float -> putExtra(key, value)
                    }
                }
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val requestCode = sessionId.hashCode() + 3
            return PendingIntent.getBroadcast(context, requestCode, intent, flags)
        }

        fun createArrivedIntent(
            context: Context,
            sessionId: String,
            destination: String,
            origin: String? = null,
            earliestReturnTimestamp: Long? = null,
        ): PendingIntent {
            val intent = Intent(context, LiveUpdateNotificationReceiver::class.java).apply {
                action = ACTION_ARRIVED
                putExtra(EXTRA_SESSION_ID, sessionId)
                putExtra(EXTRA_DESTINATION, destination)
                origin?.let { putExtra(EXTRA_ORIGIN, it) }
                earliestReturnTimestamp?.let { putExtra(EXTRA_EARLIEST_RETURN_TS, it) }
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            // Use a distinct request code to avoid collision with other intents
            val requestCode = sessionId.hashCode() + 1
            return PendingIntent.getBroadcast(context, requestCode, intent, flags)
        }

        /**
         * Schedules a one-shot alarm that demotes the finished chip to a
         * normal (non-ongoing) notification after [FINISHED_CLEANUP_DELAY_MS].
         * Payload arguments are forwarded so the handler can rebuild the
         * notification without an API call.
         */
        fun scheduleFinishedCleanup(
            context: Context,
            sessionId: String,
            payloadArguments: Map<String, Any?> = emptyMap(),
        ) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? android.app.AlarmManager ?: return
            val intent = Intent(context, LiveUpdateNotificationReceiver::class.java).apply {
                action = ACTION_RACING_FINISHED_CLEANUP
                putExtra(EXTRA_SESSION_ID, sessionId)
                payloadArguments.forEach { (key, value) ->
                    when (value) {
                        is String -> putExtra(key, value)
                        is Boolean -> putExtra(key, value)
                        is Int -> putExtra(key, value)
                        is Long -> putExtra(key, value)
                        is Double -> putExtra(key, value)
                        is Float -> putExtra(key, value)
                    }
                }
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val requestCode = sessionId.hashCode() + 4
            val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, flags)
            alarmManager.setAndAllowWhileIdle(
                android.app.AlarmManager.RTC_WAKEUP,
                System.currentTimeMillis() + FINISHED_CLEANUP_DELAY_MS,
                pendingIntent,
            )
        }

        /** Cancels a pending finished-cleanup alarm (e.g. user swiped/tapped). */
        private fun cancelFinishedCleanup(context: Context, sessionId: String) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? android.app.AlarmManager ?: return
            val intent = Intent(context, LiveUpdateNotificationReceiver::class.java).apply {
                action = ACTION_RACING_FINISHED_CLEANUP
                putExtra(EXTRA_SESSION_ID, sessionId)
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val requestCode = sessionId.hashCode() + 4
            val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, flags)
            alarmManager.cancel(pendingIntent)
        }

        private fun android.os.Bundle?.toPayloadArguments(): Map<String, Any?> {
            if (this == null) return emptyMap()
            return keySet()
                .filter { it != EXTRA_SESSION_ID }
                .associateWith { key -> when {
                    containsKey(key) -> get(key)
                    else -> null
                } }
        }
    }
}
