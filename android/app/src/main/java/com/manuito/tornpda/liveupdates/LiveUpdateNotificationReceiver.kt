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
                TravelLiveUpdateRefreshScheduler.cancelAbroadPoll(it, sessionId)
                RacingLiveUpdateRefreshScheduler.cancelRefresh(it, sessionId)
                cancelFinishedCleanup(it, sessionId)
                // The adapter listener only exists while the app runs; clear here too
                // or a swipe with the app dead leaves the session deduping forever
                LiveUpdateSessionRegistry(it, LiveUpdateActivityType.TRAVEL).clear(sessionId)
                LiveUpdateSessionRegistry(it, LiveUpdateActivityType.RACING).clear(sessionId)
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
            if (isStaleTravelChain(contextNonNull, sessionId)) return

            LiveUpdateNotificationChannel.ensureCreated(contextNonNull, LiveUpdateActivityType.TRAVEL)
            val tapIntent = LiveUpdateTapIntentFactory(contextNonNull).buildTravelTapIntent(sessionId, payload.travelIdentifier)
            val dismissIntent = createDismissIntent(contextNonNull, sessionId)
            val notification = TravelLiveUpdateNotificationFactory(contextNonNull).build(
                sessionId = sessionId,
                payload = payload,
                tapIntent = tapIntent,
                dismissIntent = dismissIntent,
            )
            NotificationManagerCompat.from(contextNonNull)
                .notify(LiveUpdateNotificationChannel.TRAVEL_NOTIFICATION_ID, notification)
            TravelLiveUpdateRefreshScheduler.scheduleNextRefresh(contextNonNull, sessionId, payload)
            TravelLiveUpdateRefreshScheduler.scheduleArrived(contextNonNull, sessionId, payload)
            armAbroadWatchIfArrivedAbroad(contextNonNull, sessionId, payload)
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
            if (isStaleRacingChain(contextNonNull, sessionId)) return

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
                            NotificationManagerCompat.from(contextNonNull)
                                .notify(LiveUpdateNotificationChannel.RACING_NOTIFICATION_ID, notification)
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
                            NotificationManagerCompat.from(contextNonNull).cancel(LiveUpdateNotificationChannel.RACING_NOTIFICATION_ID)
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
                                NotificationManagerCompat.from(contextNonNull).cancel(LiveUpdateNotificationChannel.RACING_NOTIFICATION_ID)
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
            val payload = LiveUpdatePayload.fromMap(
                activityType = LiveUpdateActivityType.TRAVEL,
                arguments = intent.extras.toPayloadArguments(),
            )
            if (isStaleTravelChain(contextNonNull, sessionId)) return

            TravelLiveUpdateRefreshScheduler.cancelRefresh(contextNonNull, sessionId)
            showArrivedNotification(contextNonNull, sessionId, payload)

            val destination = payload.currentDestinationDisplayName
            if (destination.isNullOrBlank() || destination.equals(TORN, ignoreCase = true)) {
                TravelLiveUpdateRefreshScheduler.cancelAbroadPoll(contextNonNull, sessionId)
            } else {
                armAbroadWatchIfArrivedAbroad(contextNonNull, sessionId, payload)
            }
        } else if (intent?.action == ACTION_TRAVEL_POLL) {
            val contextNonNull = context ?: return
            val sessionId = intent.getStringExtra(EXTRA_SESSION_ID) ?: return
            val payload = LiveUpdatePayload.fromMap(
                activityType = LiveUpdateActivityType.TRAVEL,
                arguments = intent.extras.toPayloadArguments(),
            )
            if (isStaleTravelChain(contextNonNull, sessionId)) return
            val apiKey = payload.extras[EXTRA_API_KEY] as? String
            if (apiKey.isNullOrBlank()) {
                Log.w(TAG_TRAVEL, "Abroad poll: no API key in payload, cancelling chain.")
                TravelLiveUpdateRefreshScheduler.cancelAbroadPoll(contextNonNull, sessionId)
                return
            }

            val pendingResult = goAsync()
            Thread {
                try {
                    handleAbroadPoll(contextNonNull, sessionId, payload, apiKey)
                } finally {
                    pendingResult.finish()
                }
            }.start()
        } else if (intent?.action == ACTION_RACING_FINISHED_CLEANUP) {
            val contextNonNull = context ?: return
            val sessionId = intent.getStringExtra(EXTRA_SESSION_ID) ?: return
            if (isStaleRacingChain(contextNonNull, sessionId)) return
            Log.d(TAG, "Racing finished cleanup: demoting chip to normal notification. session=$sessionId")

            // Rebuild with ongoing=true but non-promoted so the chip
            // disappears but the notification and status-bar icon persist
            val payload = LiveUpdatePayload.fromMap(
                activityType = LiveUpdateActivityType.RACING,
                arguments = intent.extras.toPayloadArguments(),
            )
            if (!payload.isValidFor(LiveUpdateActivityType.RACING)) {
                // Payload lost — cancel the notification entirely
                NotificationManagerCompat.from(contextNonNull).cancel(LiveUpdateNotificationChannel.RACING_NOTIFICATION_ID)
                return
            }

            LiveUpdateNotificationChannel.ensureCreated(contextNonNull, LiveUpdateActivityType.RACING)
            val tapIntent = LiveUpdateTapIntentFactory(contextNonNull)
                .buildRacingTapIntent(sessionId, payload.stateIdentifier)
            val dismissIntent = createDismissIntent(contextNonNull, sessionId)
            val notification = RacingLiveUpdateNotificationFactory(contextNonNull)
                .build(payload, tapIntent, dismissIntent, ongoing = true, promoted = false)
            NotificationManagerCompat.from(contextNonNull)
                .notify(LiveUpdateNotificationChannel.RACING_NOTIFICATION_ID, notification)

            // Clear persisted session so this finished race is not
            // re-adopted when the app is next opened
            LiveUpdateSessionRegistry(contextNonNull, LiveUpdateActivityType.RACING).clear()
        }
    }

    /**
     * Arms the poll on an arrival abroad, and no-ops otherwise. Called from both the
     * refresh and the arrival alarm, which share an instant and cancel each other.
     */
    private fun armAbroadWatchIfArrivedAbroad(
        context: Context,
        sessionId: String,
        payload: LiveUpdatePayload,
    ) {
        val destination = payload.currentDestinationDisplayName
        if (destination.isNullOrBlank() || destination.equals(TORN, ignoreCase = true)) return
        val arrival = payload.arrivalTimeTimestamp ?: return
        val toleranceMillis = TravelLiveUpdateRefreshScheduler.ARRIVAL_TOLERANCE_SECONDS * 1000
        if (arrival * 1000 > System.currentTimeMillis() + toleranceMillis) return

        Log.d(TAG_TRAVEL, "Arrived in $destination, handing over to the abroad poll.")
        TravelLiveUpdateRefreshScheduler.scheduleAbroadPoll(
            context,
            sessionId,
            payload.withExtra("hasArrived", true),
        )
    }

    /**
     * With a fixed notification id, an alarm chain left behind by an older session
     * would repaint over the live card. Cancel the orphan instead of letting it fire.
     */
    private fun isStaleTravelChain(context: Context, sessionId: String): Boolean {
        val current = LiveUpdateSessionRegistry(context, LiveUpdateActivityType.TRAVEL).current() ?: return false
        if (current.sessionId == sessionId) return false
        Log.d(TAG_TRAVEL, "Alarm from stale session $sessionId ignored, current is ${current.sessionId}.")
        TravelLiveUpdateRefreshScheduler.cancelRefresh(context, sessionId)
        TravelLiveUpdateRefreshScheduler.cancelArrived(context, sessionId)
        TravelLiveUpdateRefreshScheduler.cancelAbroadPoll(context, sessionId)
        return true
    }

    private fun isStaleRacingChain(context: Context, sessionId: String): Boolean {
        val current = LiveUpdateSessionRegistry(context, LiveUpdateActivityType.RACING).current() ?: return false
        if (current.sessionId == sessionId) return false
        Log.d(TAG, "Racing: alarm from stale session $sessionId ignored, current is ${current.sessionId}.")
        RacingLiveUpdateRefreshScheduler.cancelRefresh(context, sessionId)
        cancelFinishedCleanup(context, sessionId)
        return true
    }

    /** Runs off the main thread. */
    private fun handleAbroadPoll(
        context: Context,
        sessionId: String,
        payload: LiveUpdatePayload,
        apiKey: String,
    ) {
        when (val result = TravelLiveUpdateApiClient.fetchLatestState(apiKey)) {
            is TravelFetchResult.Flying -> {
                val enRoute = LiveUpdatePayload.fromMap(
                    activityType = LiveUpdateActivityType.TRAVEL,
                    arguments = TravelLiveUpdateParser.buildEnRouteArguments(
                        state = result.state,
                        nowSeconds = System.currentTimeMillis() / 1000,
                        apiKey = apiKey,
                        originCountry = payload.routeCountry ?: payload.currentDestinationDisplayName,
                    ),
                )
                if (!enRoute.isValidFor(LiveUpdateActivityType.TRAVEL)) {
                    Log.w(TAG_TRAVEL, "Abroad poll: built an invalid en-route payload, retrying later.")
                    TravelLiveUpdateRefreshScheduler.scheduleAbroadPoll(context, sessionId, payload)
                    return
                }

                Log.d(TAG_TRAVEL, "Abroad poll: flight detected to ${enRoute.currentDestinationDisplayName}.")
                LiveUpdateNotificationChannel.ensureCreated(context, LiveUpdateActivityType.TRAVEL)
                LiveUpdateNotificationChannel.sweepForeignIds(context, LiveUpdateActivityType.TRAVEL)
                val tapIntent = LiveUpdateTapIntentFactory(context).buildTravelTapIntent(sessionId, enRoute.travelIdentifier)
                val dismissIntent = createDismissIntent(context, sessionId)
                val notification = TravelLiveUpdateNotificationFactory(context).build(
                    sessionId = sessionId,
                    payload = enRoute,
                    tapIntent = tapIntent,
                    dismissIntent = dismissIntent,
                )
                NotificationManagerCompat.from(context)
                    .notify(LiveUpdateNotificationChannel.TRAVEL_NOTIFICATION_ID, notification)

                TravelLiveUpdateRefreshScheduler.cancelAbroadPoll(context, sessionId)
                TravelLiveUpdateRefreshScheduler.scheduleNextRefresh(context, sessionId, enRoute)
                TravelLiveUpdateRefreshScheduler.scheduleArrived(context, sessionId, enRoute)

                // Promote the session so Flutter reuses this id
                val registry = LiveUpdateSessionRegistry(context, LiveUpdateActivityType.TRAVEL)
                val nowMs = System.currentTimeMillis()
                registry.markActive(
                    LiveUpdateSessionState(
                        sessionId = sessionId,
                        activityType = LiveUpdateActivityType.TRAVEL,
                        contentIdentifier = enRoute.travelIdentifier,
                        startedAtMs = registry.current()?.startedAtMs ?: nowMs,
                        lastUpdatedAtMs = nowMs,
                        lastHasArrived = false,
                        watchOnly = false,
                    ),
                )
            }

            is TravelFetchResult.Abroad -> {
                TravelLiveUpdateRefreshScheduler.scheduleAbroadPoll(context, sessionId, payload)
            }

            TravelFetchResult.Home -> {
                Log.d(TAG_TRAVEL, "Abroad poll: user is in Torn, tearing the session down.")
                NotificationManagerCompat.from(context).cancel(LiveUpdateNotificationChannel.TRAVEL_NOTIFICATION_ID)
                TravelLiveUpdateRefreshScheduler.cancelAbroadPoll(context, sessionId)
                TravelLiveUpdateRefreshScheduler.cancelRefresh(context, sessionId)
                TravelLiveUpdateRefreshScheduler.cancelArrived(context, sessionId)
                LiveUpdateSessionRegistry(context, LiveUpdateActivityType.TRAVEL).clear()
            }

            TravelFetchResult.TransientError -> {
                Log.w(TAG_TRAVEL, "Abroad poll: could not determine state, retrying later.")
                TravelLiveUpdateRefreshScheduler.scheduleAbroadPoll(context, sessionId, payload)
            }
        }
    }

    private fun showArrivedNotification(
        context: Context,
        sessionId: String,
        payload: LiveUpdatePayload,
    ) {
        val channelId = LiveUpdateNotificationChannel.channelIdFor(LiveUpdateActivityType.TRAVEL)

        // Recreate the tap intent to open the app
        val tapIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
            it.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            PendingIntent.getActivity(context, 0, it, PendingIntent.FLAG_IMMUTABLE)
        }

        val destination = payload.currentDestinationDisplayName
            ?: context.getString(com.manuito.tornpda.R.string.live_update_destination_unknown)
        val origin = payload.originDisplayName
        val earliestReturnTs = payload.earliestReturnTimestamp

        val notificationIcon = TravelLiveUpdateAssets.notificationIcon(destination)
        val timeFormat = android.text.format.DateFormat.getTimeFormat(context)

        val arrivedAtMillis = (payload.arrivalTimeTimestamp ?: 0L) * 1000
        val arrivedAt = if (arrivedAtMillis > 0L) java.util.Date(arrivedAtMillis) else java.util.Date()
        val arrivedFormatted = timeFormat.format(arrivedAt)

        val arrivedTitle = context.getString(com.manuito.tornpda.R.string.live_update_arrived_in_pattern, destination)
        val arrivedContentText = context.getString(com.manuito.tornpda.R.string.live_update_arrived_at_pattern, arrivedFormatted)

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
            .setSmallIcon(notificationIcon)
            .setLargeIcon(
                android.graphics.BitmapFactory.decodeResource(
                    context.resources,
                    TravelLiveUpdateAssets.flagIconFor(destination, payload.routeCountry),
                )
            )
            .setContentTitle(arrivedTitle)
            .setContentText(arrivedContentText)
            .setContentIntent(tapIntent)
            .setAutoCancel(true)
            .setPriority(androidx.core.app.NotificationCompat.PRIORITY_HIGH)
            .setUsesChronometer(false)
            .setShowWhen(true)
            .setWhen(arrivedAt.time)
            .setStyle(
                androidx.core.app.NotificationCompat.BigTextStyle()
                    .bigText(bigTextLines.joinToString("\n"))
            )

        route?.let { builder.setSubText(it) }

        androidx.core.app.NotificationManagerCompat.from(context)
            .notify(LiveUpdateNotificationChannel.TRAVEL_NOTIFICATION_ID, builder.build())
    }

    companion object {
        private const val TAG = "RacingLU"
        private const val TAG_TRAVEL = "TravelLiveUpdate"
        private const val TORN = "Torn"
        private const val ACTION_DISMISSED = "com.manuito.tornpda.liveupdates.ACTION_NOTIFICATION_DISMISSED"
        private const val ACTION_REFRESH = "com.manuito.tornpda.liveupdates.ACTION_NOTIFICATION_REFRESH"
        private const val ACTION_RACING_REFRESH = "com.manuito.tornpda.liveupdates.ACTION_RACING_NOTIFICATION_REFRESH"
        private const val ACTION_ARRIVED = "com.manuito.tornpda.liveupdates.ACTION_NOTIFICATION_ARRIVED"
        private const val ACTION_TRAVEL_POLL = "com.manuito.tornpda.liveupdates.ACTION_TRAVEL_ABROAD_POLL"
        private const val ACTION_RACING_FINISHED_CLEANUP = "com.manuito.tornpda.liveupdates.ACTION_RACING_FINISHED_CLEANUP"
        private const val EXTRA_SESSION_ID = "extra_session_id"
        internal const val EXTRA_API_KEY = "apiKey"
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

        /** Carries the whole payload: the handler needs it to arm the abroad poll. */
        fun createArrivedIntent(
            context: Context,
            sessionId: String,
            payloadArguments: Map<String, Any?>,
        ): PendingIntent {
            val intent = Intent(context, LiveUpdateNotificationReceiver::class.java).apply {
                action = ACTION_ARRIVED
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
            // Use a distinct request code to avoid collision with other intents
            val requestCode = sessionId.hashCode() + 1
            return PendingIntent.getBroadcast(context, requestCode, intent, flags)
        }

        fun createTravelPollIntent(
            context: Context,
            sessionId: String,
            payloadArguments: Map<String, Any?>,
        ): PendingIntent {
            val intent = Intent(context, LiveUpdateNotificationReceiver::class.java).apply {
                action = ACTION_TRAVEL_POLL
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
            val requestCode = sessionId.hashCode() + 5
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
